local Config = require('configs/config') -- Main configuration from configs/config.lua
local Recipes = require('configs/recipes') -- Recipe definitions from configs/recipes.lua

local BlueprintItemsCache = nil -- Cached lookup table of blueprint item names from recipes: { [blueprintItemName] = true }
local adminStations = {} -- Admin-created stations: { [stationKey] = stationConfig }
local adminStationBlips = {} -- Blip handles for admin stations: { [stationKey] = blipHandle }
local adminStationPoints = {} -- lib.points handles for admin stations: { [stationKey] = point }
local adminStationZones = {} -- Track sphere zone names for cleanup: { [stationKey] = zoneName }
local staticStationBlips = {} -- Blip handles for static stations: { [stationId] = blipHandle }
local staticStationPoints = {} -- lib.points handles for static stations: { [stationId] = point }
local staticStationZones = {} -- Track sphere zone names for static stations: { [stationId] = zoneName }
local placedWorkbenchBlips = {} -- Blip handles for placed workbenches: { [workbenchId] = blipHandle }

--- Debug print helper - only prints if Config.Debug is enabled
---@param ... any Arguments to print
local function debugPrint(...)
    if Config.Debug then
        print('[sd-crafting:client]', ...)
    end
end

--- Verbose debug print helper - only prints if Config.DebugVerbose is enabled
--- Used for high-frequency logging like per-second queue ticks
---@param ... any Arguments to print
local function debugPrintVerbose(...)
    if Config.DebugVerbose then
        print('[sd-crafting:client:verbose]', ...)
    end
end

--- Build and cache the blueprint items lookup table from recipes
--- This allows any item name to be a blueprint, regardless of naming convention
---@return table blueprintItems Table with blueprint item names as keys
local function BuildBlueprintCache()
    if BlueprintItemsCache then return BlueprintItemsCache end

    BlueprintItemsCache = {}
    for workbenchType, recipes in pairs(Recipes) do
        for _, recipe in ipairs(recipes) do
            if recipe.blueprint then
                BlueprintItemsCache[recipe.blueprint] = true
            end
        end
    end

    local count = 0
    for _ in pairs(BlueprintItemsCache) do count = count + 1 end
    debugPrint('Client built blueprint cache with', count, 'blueprint items')

    return BlueprintItemsCache
end

--- Check if an item is a blueprint (based on recipes, not name prefix)
---@param itemName string The item name to check
---@return boolean isBlueprint Whether the item is used as a blueprint in any recipe
local function IsBlueprint(itemName)
    if not itemName then return false end
    if not BlueprintItemsCache then BuildBlueprintCache() end
    return BlueprintItemsCache[itemName] == true
end

-- Build blueprint cache on load
BuildBlueprintCache()

--- Register custom metadata display fields with ox_inventory
--- Scans all recipes for showMetadata fields and registers them
local function RegisterMetadataDisplay()
    if GetResourceState('ox_inventory') ~= 'started' then
        return
    end

    local metadataFields = {}
    local count = 0

    -- Scan all recipes for showMetadata fields
    for _, recipeTable in pairs(Recipes) do
        for _, recipe in ipairs(recipeTable) do
            if recipe.showMetadata then
                for key, label in pairs(recipe.showMetadata) do
                    if not metadataFields[key] then
                        metadataFields[key] = label
                        count = count + 1
                    end
                end
            end
        end
    end

    -- Register with ox_inventory if we found any
    if count > 0 then
        exports.ox_inventory:displayMetadata(metadataFields)
        debugPrint('Registered', count, 'custom metadata display fields with ox_inventory')
        for key, label in pairs(metadataFields) do
        debugPrint('  -', key, '=', label)
        end
    end
end

-- Register metadata display on load
RegisterMetadataDisplay()

--- Format a raw item name into a readable label
--- Handles underscores (advanced_lockpick -> Advanced Lockpick)
---@param itemName string The raw item name
---@return string formattedName The formatted label
local function FormatItemName(itemName)
    if not itemName then return '' end
    -- Replace underscores with spaces
    local formatted = itemName:gsub('_', ' ')
    -- Capitalize first letter of each word
    formatted = formatted:gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return formatted
end

local isUIOpen = false -- Whether the crafting UI is currently open
local currentStation = nil -- The station ID currently being used
local currentWorkbenchType = nil -- Current workbench type for per-workbench leveling
local currentRecipeTables = nil -- Which recipe tables to use for current station
local currentTechTreeRecipeIds = nil -- Lookup table of recipe IDs in tech trees (for including in recipe list)
local currentWorkbenchCoords = nil -- Coordinates of current workbench for distance checking
local currentCraftingBehavior = nil -- Station-specific CraftingBehavior (merged with global defaults)
local craftingQueue = {} -- Queue of items being crafted
local isProcessingQueue = false -- Whether the crafting queue is being processed
local queueGeneration = 0 -- Monotonically increasing counter to invalidate old ProcessQueue threads on cancel/restart
local isPlayingCraftingAnim = false -- Whether the crafting animation is playing
local currentOpenShop = nil -- Currently open shop ID for security tracking
local isMonitoringDistance = false -- Whether we're monitoring distance for nearby crafting
local playerPlacedWorkbenches = {} -- Track spawned placed workbenches by id
local isPlacingWorkbench = false -- Whether player is currently placing a workbench
local currentPlacedWorkbenchId = nil -- The current placed workbench ID for permission management
local isSharedCraftingEnabled = false -- Whether shared crafting is enabled
local playerSource = nil -- Player's server source ID for shared queue ownership
local recentlyCompletedItemId = nil -- Track item ID we just completed to prevent sync flickering
local backgroundStationProcessing = {} -- Tracks background processing threads per station (shared mode multi-station crafting)
local itemCacheInitialized = false -- Whether item cache has been initialized
local nearbyCraftingStation = nil -- Station ID for nearby crafting when UI is closed
local nearbyCraftingCoords = nil -- Workbench coords for nearby crafting distance check

--- Get the effective CraftingBehavior for the current station
--- Returns station-specific config if available, otherwise falls back to global Config.CraftingBehavior
---@return table craftingBehavior The effective CraftingBehavior settings
local function GetCraftingBehavior()
    return currentCraftingBehavior or Config.CraftingBehavior or {}
end

--- Collect all unique item names from recipes for pre-caching
---@return table items Array of unique item names
local function GetAllRecipeItems()
    local items = {}
    local seen = {}

    for _, recipeTable in pairs(Recipes) do
        for _, recipe in ipairs(recipeTable) do
            -- Add the recipe output item
            if recipe.name and not seen[recipe.name] then
                seen[recipe.name] = true
                items[#items + 1] = recipe.name
            end

            -- Add all ingredient items
            if recipe.ingredients then
                for _, ing in ipairs(recipe.ingredients) do
                    if ing.item and not seen[ing.item] then
                        seen[ing.item] = true
                        items[#items + 1] = ing.item
                    end
                end
            end
        end
    end

    return items
end

--- Pre-cache all item images and labels on resource start
local function InitializeItemCache()
    if itemCacheInitialized then return end

    local items = GetAllRecipeItems()
    local count = 0

    for _, itemName in ipairs(items) do
        -- Cache image path
        GetItemImage(itemName)
        -- Cache label
        GetItemLabel(itemName)
        count = count + 1
    end

    itemCacheInitialized = true

    debugPrint(('Pre-cached %d items (images & labels)'):format(count))
end

--- Convert camera rotation to direction vector for raycast
---@param rotation table Camera rotation { x, y, z }
---@return table direction Direction vector { x, y, z }
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

--- Perform raycast from gameplay camera (global for admin.lua access)
---@param distance number Maximum raycast distance
---@return boolean hit Whether the raycast hit something
---@return vector3 coords The hit coordinates
---@return number entity The hit entity (if any)
function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    -- Use configurable raycast flags (-1 = everything, works with housing shells)
    local raycastFlags = Config.PlaceableWorkbenches and Config.PlaceableWorkbenches.raycastFlags or -1
    local _, hit, endCoords, _, _, entityHit = GetShapeTestResultIncludingMaterial(
        StartShapeTestSweptSphere(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 0.2, raycastFlags, PlayerPedId(), 4)
    )
    return hit == 1, vector3(endCoords.x, endCoords.y, endCoords.z), entityHit
end

--- Setup instructional buttons scaleform for raycast placement (global for admin.lua access)
---@return number scaleform The scaleform handle
function SetupPlacementScaleform()
    local scaleform = RequestScaleformMovie("instructional_buttons")
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end

    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    -- Cancel button
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    N_0xe83a3e3557a56640(GetControlInstructionalButton(2, 177, true))
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(Locale.T('placement.cancel'))
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()

    -- Place button
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    N_0xe83a3e3557a56640(GetControlInstructionalButton(2, 176, true))
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(Locale.T('placement.place'))
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()

    -- Rotate button
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    N_0xe83a3e3557a56640(GetControlInstructionalButton(2, 16, true))
    N_0xe83a3e3557a56640(GetControlInstructionalButton(2, 15, true))
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(Locale.T('placement.rotate'))
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()

    -- Fine Rotate button (Shift + Scroll)
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(3)
    N_0xe83a3e3557a56640(GetControlInstructionalButton(2, 21, true))
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(Locale.T('placement.fineRotate'))
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

--- Fetch admin-created recipes from the server and merge into the client Recipes cache.
--- Called on player spawn and resource start so admin recipes appear at crafting stations.
local function LoadAdminRecipes()
    local adminRecipes = lib.callback.await('sd-crafting:server:getAdminRecipes', false)
    if not adminRecipes then return end

    for tableName, recipeList in pairs(adminRecipes) do
        if not Recipes[tableName] then
            Recipes[tableName] = {}
        end
        for _, recipe in ipairs(recipeList) do
            local replaced = false
            for i, existing in ipairs(Recipes[tableName]) do
                if existing.id == recipe.id then
                    Recipes[tableName][i] = recipe
                    replaced = true
                    break
                end
            end
            if not replaced then
                Recipes[tableName][#Recipes[tableName] + 1] = recipe
            end
        end
    end
end

--- Sync a single admin recipe into the client Recipes cache (create or update)
---@param tableName string Recipe table name
---@param recipe table The recipe data
RegisterNetEvent('sd-crafting:client:syncAdminRecipe', function(tableName, recipe)
    if not tableName or not recipe then return end
    if not Recipes[tableName] then
        Recipes[tableName] = {}
    end
    for i, existing in ipairs(Recipes[tableName]) do
        if existing.id == recipe.id then
            Recipes[tableName][i] = recipe
            if recipe.showMetadata then RegisterMetadataDisplay() end
            return
        end
    end
    Recipes[tableName][#Recipes[tableName] + 1] = recipe
    if recipe.showMetadata then RegisterMetadataDisplay() end
end)

--- Remove an admin recipe from the client Recipes cache
---@param tableName string Recipe table name
---@param recipeId string The recipe ID to remove
RegisterNetEvent('sd-crafting:client:removeAdminRecipe', function(tableName, recipeId)
    if not tableName or not recipeId or not Recipes[tableName] then return end
    for i, recipe in ipairs(Recipes[tableName]) do
        if recipe.id == recipeId then
            table.remove(Recipes[tableName], i)
            return
        end
    end
end)

--- Sync a tech tree update from admin panel (server sends updated tree on admin changes)
--- Client doesn't maintain its own TechTrees cache — server sends trees via openStation.
--- This event is a no-op but logged for debugging.
---@param treeId string The tech tree ID
---@param _treeData table The updated tree data
RegisterNetEvent('sd-crafting:client:syncAdminTechTree', function(treeId, _treeData)
    debugPrint('Received admin tech tree sync for', treeId)
end)

--- Handle removal of a tech tree from admin panel
--- Client doesn't maintain its own TechTrees cache — this is a no-op with debug logging.
---@param treeId string The tech tree ID that was removed
RegisterNetEvent('sd-crafting:client:removeAdminTechTree', function(treeId)
    debugPrint('Received admin tech tree removal for', treeId)
end)

--- Get recipes from multiple recipe tables, avoiding duplicates
---@param recipeTables table Array of table names like { 'all', 'basic' }
---@return table result Array of unique recipe objects
local function GetRecipesFromTables(recipeTables)
    local result = {}
    local addedIds = {}

    for _, tableName in ipairs(recipeTables) do
        if Recipes[tableName] then
            for _, recipe in ipairs(Recipes[tableName]) do
                if not addedIds[recipe.id] then
                    addedIds[recipe.id] = true
                    result[#result + 1] = recipe
                end
            end
        end
    end

    return result
end

--- Get all recipes as a flat list from all workbench types
---@return table allRecipes Array of all recipe objects
local function GetAllRecipes()
    local allRecipes = {}
    for _, recipes in pairs(Recipes) do
        for _, recipe in ipairs(recipes) do
            allRecipes[#allRecipes + 1] = recipe
        end
    end
    return allRecipes
end

--- Fetch player inventory from server with image paths and slot data
---@return table items Array of inventory items with image paths and slot info
---@return number totalSlots Total number of inventory slots
---@return boolean supportsSlots Whether the inventory system supports slot-based operations
local function FetchPlayerInventory()
    local data = lib.callback.await('sd-crafting:server:getPlayerItems', false)
    if not data then return {}, 0, false end

    local items = data.items or {}
    local totalSlots = data.totalSlots or 0
    local supportsSlots = data.supportsSlots or false

    for _, item in ipairs(items) do
        item.image = GetItemImage(item.item)
    end

    return items, totalSlots, supportsSlots
end

--- Get all ingredient items used in station recipes for filtering
---@param recipeTables table|nil Array of recipe table names
---@return table relevantItems Table with item names as keys
local function GetRelevantItems(recipeTables)
    local relevantItems = {}

    local availableRecipes = GetRecipesFromTables(recipeTables or { 'all' })

    for _, recipe in ipairs(availableRecipes) do
        for _, ing in ipairs(recipe.ingredients) do
            relevantItems[ing.item] = true
        end
        if recipe.blueprint then
            relevantItems[recipe.blueprint] = true
        end
    end

    return relevantItems
end

--- Filter inventory to only show items relevant for crafting
---@param fullInventory table Array of all inventory items
---@param recipeTables table Array of recipe table names
---@return table filteredInventory Array of filtered inventory items
local function GetFilteredInventory(fullInventory, recipeTables)
    if not Config.InventoryPanel or Config.InventoryPanel.showAllItems then
        return fullInventory
    end

    local relevantItems = GetRelevantItems(recipeTables)
    local filteredInventory = {}

    for _, item in ipairs(fullInventory) do
        if relevantItems[item.item] then
            filteredInventory[#filteredInventory + 1] = item
        end
    end

    return filteredInventory
end

--- Get the effective XP reward for a recipe (uses default if not specified)
---@param recipe table The recipe object
---@return number|nil xpReward The XP reward amount or nil if disabled
local function GetEffectiveXpReward(recipe)
    if recipe.xpReward then
        return recipe.xpReward
    end

    if Config.Leveling and Config.Leveling.enabled and Config.Leveling.defaultXpReward then
        local defaultXp = Config.Leveling.defaultXpReward
        if type(defaultXp) == 'table' then
            if defaultXp.enabled then
                return defaultXp.amount or 10
            end
            return nil
        else
            return defaultXp or 10
        end
    end

    return nil
end

--- Get available recipes for a station filtered by blueprints and recipe tables
---@param attachedBlueprints table|nil Array of attached blueprint item names
---@param recipeTables table|nil Array of recipe table names to include
---@param techTreeRecipeIds table|nil Lookup table of recipe IDs in tech trees (always include these)
---@return table recipes Array of prepared recipe objects with images
local function GetStationRecipes(attachedBlueprints, recipeTables, techTreeRecipeIds)
    local recipes = {}

    local availableRecipes = GetRecipesFromTables(recipeTables or { 'all' })

    local attachedLookup = {}
    if attachedBlueprints then
        for _, bp in ipairs(attachedBlueprints) do
            attachedLookup[bp] = true
        end
    end

    for _, recipe in ipairs(availableRecipes) do
        local available = true
        local blueprintMissing = false

        if recipe.blueprint and Config.Blueprints and Config.Blueprints.enabled then
            if not attachedLookup[recipe.blueprint] then
                -- Still include if it's a tech tree recipe (for display purposes only)
                if techTreeRecipeIds and techTreeRecipeIds[recipe.id] then
                    blueprintMissing = true -- Include but mark as not craftable
                else
                    available = false
                end
            end
        end

        if available then
            -- Determine recipe image with priority:
            -- 1. recipe.image (direct NUI path override)
            -- 2. metadata.image (ox_inventory image path)
            -- 3. metadata.imageurl (ox_inventory image URL)
            -- 4. GetItemImage() (automatic from inventory system)
            local recipeImage
            if recipe.image then
                recipeImage = recipe.image
            elseif recipe.metadata and recipe.metadata.image then
                recipeImage = recipe.metadata.image
            elseif recipe.metadata and recipe.metadata.imageurl then
                recipeImage = recipe.metadata.imageurl
            else
                recipeImage = GetItemImage(recipe.name)
            end

            local preparedRecipe = {
                id = recipe.id,
                name = recipe.name,
                label = recipe.label or GetItemLabel(recipe.name) or FormatItemName(recipe.name),
                craftTime = recipe.craftTime,
                category = recipe.category,
                image = recipeImage,
                blueprint = recipe.blueprint,
                blueprintDurabilityLoss = recipe.blueprintDurabilityLoss,
                blueprintMissing = blueprintMissing, -- True if included only for tech tree display
                levelRequired = recipe.levelRequired,
                xpReward = GetEffectiveXpReward(recipe),
                techPointsReward = recipe.techPointsReward,
                cost = recipe.cost,
                outputAmount = recipe.outputAmount,
                failChance = recipe.failChance,
                ingredients = {}
            }

            for _, ing in ipairs(recipe.ingredients) do
                preparedRecipe.ingredients[#preparedRecipe.ingredients + 1] = {
                    item = ing.item,
                    label = ing.label or GetItemLabel(ing.item) or FormatItemName(ing.item),
                    amount = ing.amount,
                    image = GetItemImage(ing.item)
                }
            end

            -- Add tools if present
            if recipe.tools and #recipe.tools > 0 then
                preparedRecipe.tools = {}
                for _, tool in ipairs(recipe.tools) do
                    preparedRecipe.tools[#preparedRecipe.tools + 1] = {
                        item = tool.item,
                        label = tool.label or GetItemLabel(tool.item) or FormatItemName(tool.item),
                        amount = tool.amount or 1,
                        image = GetItemImage(tool.item),
                        consumptionType = tool.consumptionType or 'none',
                        durabilityLoss = tool.durabilityLoss,
                        consumeChance = tool.consumeChance
                    }
                end
            end

            recipes[#recipes + 1] = preparedRecipe
        end
    end

    return recipes
end

--- Convert crafting queue to NUI-compatible format
---@return table nuiQueue Array of queue items formatted for NUI
local function GetQueueForNUI()
    local nuiQueue = {}
    for _, queueItem in ipairs(craftingQueue) do
        -- Determine recipe image with priority:
        -- 1. recipe.image (direct NUI path override)
        -- 2. metadata.image (ox_inventory image path)
        -- 3. metadata.imageurl (ox_inventory image URL)
        -- 4. GetItemImage() (automatic from inventory system)
        local recipeImage
        if queueItem.recipe.image then
            recipeImage = queueItem.recipe.image
        elseif queueItem.recipe.metadata and queueItem.recipe.metadata.image then
            recipeImage = queueItem.recipe.metadata.image
        elseif queueItem.recipe.metadata and queueItem.recipe.metadata.imageurl then
            recipeImage = queueItem.recipe.metadata.imageurl
        else
            recipeImage = GetItemImage(queueItem.recipe.name)
        end

        nuiQueue[#nuiQueue + 1] = {
            id = queueItem.id,
            recipe = {
                id = queueItem.recipe.id,
                name = queueItem.recipe.name,
                label = queueItem.recipe.label,
                craftTime = queueItem.recipe.craftTime,
                ingredients = queueItem.recipe.ingredients,
                image = recipeImage,
                cost = queueItem.recipe.cost,
                blueprint = queueItem.recipe.blueprint,
                outputAmount = queueItem.recipe.outputAmount
            },
            quantity = queueItem.quantity,
            startTime = queueItem.startTime,
            totalTime = queueItem.totalTime,
            remainingTime = queueItem.remainingTime,
            owner = queueItem.owner,
            ownerName = queueItem.ownerName,
            isOwnItem = queueItem.owner == playerSource or queueItem.owner == nil
        }
    end
    return nuiQueue
end

--- Update craftingQueue from new data while preserving ProcessQueue's active item reference
--- Without this, rebuilding the queue creates new table objects that ProcessQueue doesn't reference,
--- causing the timer to desync (ProcessQueue decrements old object, UI reads new object)
--- In shared mode, only preserve if we own the first item (our ProcessQueue actively decrements it).
--- Non-owner players don't decrement, so their local remainingTime would be stale.
---@param newQueue table[] The new queue items to set
local function UpdateCraftingQueue(newQueue)
    local shouldPreserve = isProcessingQueue and #craftingQueue > 0
    if shouldPreserve and isSharedCraftingEnabled then
        local firstItem = craftingQueue[1]
        shouldPreserve = not firstItem.owner or firstItem.owner == playerSource
    end
    local preservedFirstItem = shouldPreserve and craftingQueue[1] or nil
    craftingQueue = newQueue
    if preservedFirstItem and #craftingQueue > 0 and craftingQueue[1].id == preservedFirstItem.id then
        craftingQueue[1] = preservedFirstItem
    end
    debugPrint('UpdateCraftingQueue: Received', #newQueue, 'items, preserved first item:', preservedFirstItem and preservedFirstItem.id or 'none')
end

--- Start crafting animation facing the workbench
---@param stationId string The station identifier
---@param coords vector3|nil Optional coordinates for placed workbenches
local function StartCraftingAnimation(stationId, coords)
    local station = Config.Stations[stationId] or adminStations[stationId]
    local stationCoords = coords
    local interactDistance = 2.0

    -- Get coordinates from config station or placed workbench
    if station then
        stationCoords = station.coords
        interactDistance = station.radius or 2.0
    elseif not stationCoords then
        -- Check if it's a placed workbench
        local placedId = stationId:match('^placed_(%d+)$')
        if placedId then
            placedId = tonumber(placedId)
            if placedId and playerPlacedWorkbenches[placedId] then
                stationCoords = playerPlacedWorkbenches[placedId].data.coords
            end
        end
    end

    -- Return if we couldn't get coordinates
    if not stationCoords then return end

    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    local distance = #(playerCoords - stationCoords)

    local dx = stationCoords.x - playerCoords.x
    local dy = stationCoords.y - playerCoords.y
    local angle = math.atan2(dy, dx)

    local targetX = stationCoords.x - math.cos(angle) * (interactDistance * 0.6)
    local targetY = stationCoords.y - math.sin(angle) * (interactDistance * 0.6)
    local targetZ = stationCoords.z

    isPlayingCraftingAnim = true

    CreateThread(function()
        if distance > interactDistance * 0.8 then
            TaskGoStraightToCoord(ped, targetX, targetY, targetZ, 1.0, -1, 0.0, 0.0)

            local timeout = 50
            while timeout > 0 and isPlayingCraftingAnim do
                local currentCoords = GetEntityCoords(ped)
                local distToTarget = #(currentCoords - vector3(targetX, targetY, targetZ))
                if distToTarget < 0.5 then
                    break
                end
                timeout = timeout - 1
                Wait(100)
            end

            ClearPedTasks(ped)
            Wait(100)
        end

        if not isPlayingCraftingAnim then return end

        TaskTurnPedToFaceCoord(ped, stationCoords.x, stationCoords.y, stationCoords.z, 1000)

        Wait(1000)

        if not isPlayingCraftingAnim then return end

        lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')

        while isPlayingCraftingAnim and isUIOpen do
            ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 3) then
                TaskPlayAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, 8.0, -1, 49, 0, false, false, false)
            end
            Wait(1000)
        end
    end)
end

--- Stop crafting animation and clear ped tasks
local function StopCraftingAnimation()
    if not isPlayingCraftingAnim then return end

    isPlayingCraftingAnim = false
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    RemoveAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
end

--- Get workbench type from station ID
---@param stationId string The station identifier
---@return string|nil workbenchType The workbench type or nil for placed workbenches
local function GetWorkbenchTypeFromStation(stationId)
    local placedId = stationId:match('^placed_(%d+)$')
    if placedId then
        return nil
    end

    local station = Config.Stations[stationId] or adminStations[stationId]
    if station and station.type then
        return station.type
    end

    return 'basic'
end

--- Check job/gang access and show error notification if denied
---@param jobConfig table|nil Job restriction configuration
---@param gangConfig table|nil Gang restriction configuration
---@return boolean hasAccess Whether access is granted
local function CheckWorkbenchAccess(jobConfig, gangConfig)
    if not jobConfig and not gangConfig then
        return true
    end

    local result = lib.callback.await('sd-crafting:server:checkWorkbenchAccess', false, {
        job = jobConfig,
        gang = gangConfig
    })

    if result.hasAccess then
        return true
    end

    local message
    if result.reason == 'job' then
        message = Locale.T('notifications.workbench.jobRequired', { job = result.requiredJob })
    elseif result.reason == 'grade' then
        message = Locale.T('notifications.workbench.jobGradeRequired', { job = result.requiredJob, grade = result.requiredGrade })
    elseif result.reason == 'gang' then
        message = Locale.T('notifications.workbench.gangRequired', { gang = result.requiredGang })
    elseif result.reason == 'gangGrade' then
        message = Locale.T('notifications.workbench.gangGradeRequired', { gang = result.requiredGang, grade = result.requiredGrade })
    else
        message = Locale.T('notifications.workbench.accessDenied')
    end

    ShowNotification({
        title = Locale.T('notifications.workbench.accessDenied'),
        description = message,
        type = 'error'
    })

    return false
end

--- Update inventory display in NUI
local function UpdateInventoryNUI()
    if not isUIOpen then return end

    local inventory, totalSlots, supportsSlots = FetchPlayerInventory()
    local filteredInventory = currentRecipeTables and GetFilteredInventory(inventory, currentRecipeTables) or inventory

    local inventoryWeight = lib.callback.await('sd-crafting:server:getItemsWeight', false, inventory) or 0

    SendNUIMessage({
        action = 'updateInventory',
        inventory = inventory,
        filteredInventory = filteredInventory,
        inventoryWeight = inventoryWeight,
        totalSlots = totalSlots,
        supportsSlots = supportsSlots
    })
end

--- Update blueprints and recipes display in NUI
local function UpdateBlueprintsNUI()
    if not isUIOpen or not currentStation then return end

    local attachedBlueprints, attachedWithLabels = lib.callback.await('sd-crafting:server:getAttachedBlueprints', false, currentStation)
    local playerBlueprints = lib.callback.await('sd-crafting:server:getPlayerBlueprints', false)
    local recipes = GetStationRecipes(attachedBlueprints, currentRecipeTables, currentTechTreeRecipeIds)

    SendNUIMessage({
        action = 'updateBlueprints',
        attachedBlueprints = attachedBlueprints or {},
        attachedWithLabels = attachedWithLabels or {},
        playerBlueprints = playerBlueprints or {},
        recipes = recipes
    })
end

--- Update staged items display in NUI
local function UpdateStagedItemsNUI()
    if not isUIOpen or not currentStation then return end

    local stagedItems, stagedWeight = lib.callback.await('sd-crafting:server:getStagedItems', false, currentStation)
    stagedItems = stagedItems or {}
    stagedWeight = stagedWeight or 0

    for _, item in ipairs(stagedItems) do
        item.image = GetItemImage(item.item)
    end

    SendNUIMessage({
        action = 'updateStagedItems',
        stagedItems = stagedItems,
        stagedWeight = stagedWeight
    })
end

--- Save current crafting queue to server for persistence
local function SaveQueueToServer()
    debugPrint('SaveQueueToServer: Saving queue with', #craftingQueue, 'items, isSharedCraftingEnabled:', isSharedCraftingEnabled)
    if #craftingQueue == 0 then
        lib.callback.await('sd-crafting:server:clearSavedQueue', false)
        return
    end

    -- Only save non-shared queues (shared queues are managed by the server)
    if isSharedCraftingEnabled then return end

    local queueData = {
        queue = craftingQueue,
        stationId = currentStation or nearbyCraftingStation,
        workbenchType = currentWorkbenchType,
        coords = currentWorkbenchCoords or nearbyCraftingCoords
    }

    lib.callback.await('sd-crafting:server:savePlayerQueue', false, queueData)
end

--- Process the crafting queue sequentially
local function ProcessQueue()
    if isProcessingQueue then return end
    if #craftingQueue == 0 then return end

    isProcessingQueue = true
    queueGeneration = queueGeneration + 1 -- Bump generation to invalidate any old threads
    local myGeneration = queueGeneration -- Capture generation for this thread
    debugPrint('ProcessQueue: Started generation:', myGeneration, 'queue size:', #craftingQueue)

    -- Capture station info at start of processing for nearby crafting
    local processingStation = currentStation or nearbyCraftingStation

    CreateThread(function()
        while #craftingQueue > 0 and queueGeneration == myGeneration do
            local currentItem = craftingQueue[1]
            debugPrint('ProcessQueue: Processing item:', currentItem.id, 'recipe:', currentItem.recipe.id, 'remainingTime:', currentItem.remainingTime, 'craftToken:', currentItem.craftToken)

            -- In shared mode, only process items we own
            if isSharedCraftingEnabled and currentItem.owner and currentItem.owner ~= playerSource then
                -- Wait for the owner to process this item or for queue sync
                Wait(1000)
                goto continue
            end

            local syncCounter = 0
            local SYNC_INTERVAL = 10 -- Sync to server every 10 seconds for persistence

            while currentItem.remainingTime > 0 and queueGeneration == myGeneration do
                Wait(1000)

                -- Check if cancelled during wait
                if queueGeneration ~= myGeneration then break end

                currentItem.remainingTime = currentItem.remainingTime - 1
                syncCounter = syncCounter + 1
                debugPrintVerbose('Queue tick - item:', currentItem.id, 'recipe:', currentItem.recipe.id, 'remainingTime:', currentItem.remainingTime, 'generation:', myGeneration)

                -- Sync progress to server periodically (not every tick to reduce network traffic;
                -- other players' React timers count down locally between syncs).
                -- Run in a separate thread to avoid blocking the countdown loop, which would
                -- cause Lua's timer to drift behind React's independent setInterval timer.
                local activeStation = currentStation or processingStation
                if syncCounter >= SYNC_INTERVAL then
                    syncCounter = 0
                    if isSharedCraftingEnabled and activeStation then
                        local syncRemainingTime = currentItem.remainingTime
                        local syncItemId = currentItem.id
                        CreateThread(function()
                            lib.callback.await('sd-crafting:server:updateSharedQueueItem', false, activeStation, syncItemId, {
                                remainingTime = syncRemainingTime
                            })
                        end)
                    else
                        CreateThread(function()
                            SaveQueueToServer()
                        end)
                    end
                end

                -- React handles the visual countdown timer locally
                -- Lua only sends queue updates when items are added/removed/completed
            end

            -- If cancelled (generation changed), exit without completing
            if queueGeneration ~= myGeneration then break end

            -- Use the station stored in the queue item (where the craft was originally started)
            -- Falls back to currentStation or processingStation for legacy items without stationId
            local completionStation = currentItem.stationId or currentStation or processingStation

            currentItem.isCompleting = true

            -- Start completion animation early if UI is open at the SAME station (optimistic success)
            -- Items completing at a different bench (background crafting) skip the animation
            -- to avoid unnecessary delays and showing animations for items not visible in the UI
            local showCompletionAnimation = isUIOpen and currentStation == completionStation
            if showCompletionAnimation then
                SendNUIMessage({
                    action = 'queueItemComplete',
                    itemId = currentItem.id,
                    status = 'success' -- Optimistic, will update if different
                })
                -- Wait for most of animation before giving items
                Wait(650)

                if queueGeneration ~= myGeneration then break end
            end

            -- Guard: verify this item is still at position 1 in the queue
            -- CancelAllCrafting bumps generation (caught above), so reaching here means
            -- the queue was replaced by a bench switch, not a cancellation.
            -- Complete the item as a background craft since ingredients were already consumed.
            if #craftingQueue == 0 or craftingQueue[1].id ~= currentItem.id then
                debugPrint('ProcessQueue: Queue changed during processing, completing item', currentItem.id, 'as background craft')
                local bgStation = currentItem.stationId or processingStation
                if bgStation then
                    local bgSuccess = lib.callback.await('sd-crafting:server:completeCraft', false, {
                        recipeId = currentItem.recipe.id,
                        quantity = currentItem.quantity,
                        stationId = bgStation,
                        workbenchType = currentItem.workbenchType,
                        isUiOpen = false,
                        craftToken = currentItem.craftToken
                    })
                    if bgSuccess and isSharedCraftingEnabled then
                        lib.callback.await('sd-crafting:server:completeSharedQueueItem', false, bgStation)
                    end
                end
                break
            end

            debugPrint('ProcessQueue: Calling completeCraft for item:', currentItem.id, 'craftToken:', currentItem.craftToken)
            local success, data = lib.callback.await('sd-crafting:server:completeCraft', false, {
                recipeId = currentItem.recipe.id,
                quantity = currentItem.quantity,
                stationId = completionStation,
                workbenchType = currentItem.workbenchType,
                isUiOpen = showCompletionAnimation,
                craftToken = currentItem.craftToken
            })
            debugPrint('ProcessQueue: completeCraft returned - success:', success, 'data:', json.encode(data or {}))

            if success then
                if isSharedCraftingEnabled and completionStation then
                    -- Remove from shared queue on server (will broadcast to other players)
                    lib.callback.await('sd-crafting:server:completeSharedQueueItem', false, completionStation)
                end

                -- Check allowCraftingAnywhere config for notification handling
                local anywhereConfig = GetCraftingBehavior().allowCraftingAnywhere
                local isAnywhereEnabled = anywhereConfig and anywhereConfig.enabled
                local shouldNotifyAnywhere = anywhereConfig and anywhereConfig.notifyPlayer

                -- Suppress notifications when allowCraftingAnywhere is enabled, UI is closed, and notifyPlayer is false
                local suppressNotifications = not isUIOpen and isAnywhereEnabled and not shouldNotifyAnywhere

                -- Calculate actual output amount (quantity * outputAmount)
                local recipeOutputAmount = currentItem.recipe.outputAmount or 1

                -- Determine completion status for animation
                local completionStatus = 'success'
                if data and data.failed then
                    completionStatus = 'failure'
                elseif data and data.partialFailure then
                    completionStatus = 'partial'
                end

                -- Update animation if status differs from optimistic success, then wait remaining time
                if showCompletionAnimation then
                    if completionStatus ~= 'success' then
                        -- Update animation to show actual status
                        SendNUIMessage({
                            action = 'queueItemComplete',
                            itemId = currentItem.id,
                            status = completionStatus
                        })
                    end
                    -- Wait remaining animation time
                    Wait(150)
                end

                -- Now remove from local queue
                -- Guard: verify the item is still at position 1 after completion yields
                -- UpdateCraftingQueue may have replaced the queue during the completeCraft/completeSharedQueueItem await,
                -- so table.remove(1) could remove the wrong item
                recentlyCompletedItemId = currentItem.id
                if #craftingQueue > 0 and craftingQueue[1] == currentItem then
                    table.remove(craftingQueue, 1)
                end
                debugPrint('ProcessQueue: Item completed and removed, remaining queue:', #craftingQueue)

                -- Update UI to show item removed
                if isUIOpen then
                    SendNUIMessage({
                        action = 'updateQueue',
                        queue = GetQueueForNUI()
                    })
                end

                -- Check if crafting failed due to fail chance
                if data and data.failed then
                    -- Crafting completely failed - materials consumed but no items given
                    local failedOutput = (data.failedCrafts or currentItem.quantity) * recipeOutputAmount
                    if isUIOpen then
                        UpdateInventoryNUI()
                        UpdateStagedItemsNUI()

                        -- Toast notification for crafting failure
                        SendNUIMessage({
                            action = 'showToast',
                            toastMessage = Locale.T('notifications.crafting.craftingFailed', { quantity = failedOutput, item = currentItem.recipe.label }),
                            toastType = 'error'
                        })
                    elseif not suppressNotifications then
                        ShowNotification({
                            title = Locale.T('notifications.crafting.title'),
                            description = Locale.T('notifications.crafting.craftingFailed', { quantity = failedOutput, item = currentItem.recipe.label }),
                            type = 'error'
                        })
                    end
                    goto continue
                end

                -- Check for partial failure (some succeeded, some failed)
                local successfulOutput = currentItem.quantity * recipeOutputAmount
                local hasPartialFailure = data and data.partialFailure
                if hasPartialFailure then
                    successfulOutput = data.successfulCrafts * recipeOutputAmount
                end

                if isUIOpen then
                    UpdateInventoryNUI()
                    UpdateStagedItemsNUI() -- Update staged items in case AddOutputToStash is enabled

                    if hasPartialFailure then
                        -- Toast notification for partial success
                        local failedOutput = data.failedCrafts * recipeOutputAmount
                        SendNUIMessage({
                            action = 'showToast',
                            toastMessage = Locale.T('notifications.crafting.partialSuccess', { success = successfulOutput, failed = failedOutput, item = currentItem.recipe.label }),
                            toastType = 'warning'
                        })
                    else
                        -- Toast notification for full crafting success
                        SendNUIMessage({
                            action = 'showToast',
                            toastMessage = Locale.T('notifications.crafting.success', { quantity = successfulOutput, item = currentItem.recipe.label }),
                            toastType = 'success'
                        })
                    end
                elseif not suppressNotifications then
                    -- If crafting anywhere with notifyPlayer, show background completion message
                    if isAnywhereEnabled and shouldNotifyAnywhere then
                        if hasPartialFailure then
                            local failedOutput = data.failedCrafts * recipeOutputAmount
                            ShowNotification({
                                title = Locale.T('notifications.crafting.title'),
                                description = Locale.T('notifications.crafting.partialSuccess', { success = successfulOutput, failed = failedOutput, item = currentItem.recipe.label }),
                                type = 'warning'
                            })
                        else
                            ShowNotification({
                                title = Locale.T('notifications.crafting.title'),
                                description = Locale.T('notifications.crafting.completedInBackground', { quantity = successfulOutput, item = currentItem.recipe.label }),
                                type = 'success'
                            })
                        end
                    else
                        if hasPartialFailure then
                            local failedOutput = data.failedCrafts * recipeOutputAmount
                            ShowNotification({
                                title = Locale.T('notifications.crafting.title'),
                                description = Locale.T('notifications.crafting.partialSuccess', { success = successfulOutput, failed = failedOutput, item = currentItem.recipe.label }),
                                type = 'warning'
                            })
                        else
                            ShowNotification({
                                title = Locale.T('notifications.crafting.title'),
                                description = Locale.T('notifications.crafting.success', { quantity = successfulOutput, item = currentItem.recipe.label }),
                                type = 'success'
                            })
                        end
                    end
                end

                if data and data.levelData then
                    if isUIOpen then
                        SendNUIMessage({
                            action = 'updateLevel',
                            playerLevel = {
                                xp = data.levelData.xp,
                                level = data.levelData.level,
                                enabled = true,
                                maxLevel = data.levelData.maxLevel,
                                xpForNextLevel = data.levelData.xpForNextLevel,
                                xpForCurrentLevel = data.levelData.xpForCurrentLevel,
                                workbenchType = data.levelData.workbenchType
                            }
                        })

                        -- Toast notification for XP gained
                        SendNUIMessage({
                            action = 'showToast',
                            toastMessage = Locale.T('notifications.xp.gained', { amount = data.levelData.xpGained }),
                            toastType = 'success'
                        })
                    elseif not suppressNotifications then
                        ShowNotification({
                            title = Locale.T('notifications.xp.title'),
                            description = Locale.T('notifications.xp.gained', { amount = data.levelData.xpGained }),
                            type = 'success'
                        })
                    end

                    if data.levelData.leveledUp and not suppressNotifications then
                        ShowNotification({
                            title = Locale.T('notifications.levelUp.title'),
                            description = Locale.T('notifications.levelUp.description', { level = data.levelData.level }),
                            type = 'success'
                        })
                    end
                end

                if data and data.techPointsData then
                    if isUIOpen then
                        SendNUIMessage({
                            action = 'updateTechPoints',
                            techPoints = { points = data.techPointsData.points, enabled = true }
                        })

                        -- Toast notification for Tech Points gained
                        SendNUIMessage({
                            action = 'showToast',
                            toastMessage = Locale.T('notifications.techPoints.gained', { amount = data.techPointsData.gained }),
                            toastType = 'success'
                        })
                    elseif not suppressNotifications then
                        ShowNotification({
                            title = Locale.T('notifications.techPoints.title'),
                            description = Locale.T('notifications.techPoints.gained', { amount = data.techPointsData.gained }),
                            type = 'success'
                        })
                    end
                end

                if data and data.blueprintDestroyed and not suppressNotifications then
                    -- Show different message for durability break vs random destruction
                    if data.blueprintDurabilityBroke then
                        ShowNotification({
                            title = Locale.T('notifications.blueprint.title'),
                            description = Locale.T('notifications.blueprint.durabilityBroke'),
                            type = 'error'
                        })
                    else
                        ShowNotification({
                            title = Locale.T('notifications.blueprint.title'),
                            description = Locale.T('notifications.blueprint.destroyed'),
                            type = 'error'
                        })
                    end

                    UpdateBlueprintsNUI()
                elseif data and data.blueprintDurabilityReduced and not suppressNotifications then
                    -- Show durability loss notification
                    ShowNotification({
                        title = Locale.T('notifications.blueprint.title'),
                        description = Locale.T('notifications.blueprint.durabilityLost', {
                            current = math.floor(data.blueprintNewDurability),
                            loss = data.blueprintDurabilityLoss
                        }),
                        type = 'inform'
                    })
                end

                -- Handle tool break notifications
                if data and data.toolResults and data.toolResults.toolsBroken and #data.toolResults.toolsBroken > 0 then
                    for _, brokenTool in ipairs(data.toolResults.toolsBroken) do
                        local toolCount = brokenTool.count or 1
                        local message
                        if toolCount > 1 then
                            message = Locale.T('notifications.tool.brokenMultiple', { tool = brokenTool.label, count = toolCount })
                        else
                            message = Locale.T('notifications.tool.brokenByChance', { tool = brokenTool.label })
                        end

                        if isUIOpen then
                            SendNUIMessage({
                                action = 'showToast',
                                toastMessage = message,
                                toastType = 'error'
                            })
                        elseif not suppressNotifications then
                            ShowNotification({
                                title = Locale.T('notifications.tool.title'),
                                description = message,
                                type = 'error'
                            })
                        end
                    end
                end
            else
                if isSharedCraftingEnabled and completionStation then
                    -- Remove from shared queue on server (will broadcast to other players)
                    lib.callback.await('sd-crafting:server:completeSharedQueueItem', false, completionStation)
                end

                -- Remove from local queue on failure
                -- Guard: verify the item is still at position 1 after completion yields
                recentlyCompletedItemId = currentItem.id
                if #craftingQueue > 0 and craftingQueue[1] == currentItem then
                    table.remove(craftingQueue, 1)
                end

                -- Update UI to show item removed
                if isUIOpen then
                    SendNUIMessage({
                        action = 'updateQueue',
                        queue = GetQueueForNUI()
                    })
                end

                ShowNotification({
                    title = Locale.T('notifications.crafting.title'),
                    description = Locale.T('notifications.crafting.failed', { item = currentItem.recipe.label }),
                    type = 'error'
                })
            end

            -- Save queue progress for persistence (only for non-shared queues)
            if not isSharedCraftingEnabled then
                SaveQueueToServer()
            end

            ::continue::
        end
        debugPrint('ProcessQueue: Loop ended, generation:', myGeneration, 'current generation:', queueGeneration, 'remaining items:', #craftingQueue)

        -- Only run cleanup if this thread still owns the current generation
        -- Old "ghost" threads must not interfere with a newer ProcessQueue's state
        if queueGeneration == myGeneration then
            isProcessingQueue = false
            if #craftingQueue == 0 then
                -- Close station and clear nearby crafting info when queue is empty
                if not isSharedCraftingEnabled then
                    lib.callback.await('sd-crafting:server:clearSavedQueue', false)
                end

                if nearbyCraftingStation then
                    TriggerServerEvent('sd-crafting:server:closeStation', nearbyCraftingStation)
                    nearbyCraftingStation = nil
                    nearbyCraftingCoords = nil
                    isMonitoringDistance = false
                end
            else
                -- Queue still has items (e.g., from a different bench after queue replacement
                -- or items added while completing). Restart processing so they don't get
                -- stuck at 0 time with no active ProcessQueue thread.
                debugPrint('ProcessQueue: Restarting for', #craftingQueue, 'remaining items')
                ProcessQueue()
            end
        end
    end)
end

--- Process crafting items for a station in the background when the player switches to another station.
--- Independent from ProcessQueue - has its own countdown, sync, and completion logic.
--- Only used in shared crafting mode to allow concurrent multi-station crafting.
---@param bgStationId string The station identifier to process items for
---@param items table[] Queue items to process (captured from craftingQueue at station close)
local function ProcessBackgroundStation(bgStationId, items)
    if not items or #items == 0 then return end
    if backgroundStationProcessing[bgStationId] then return end

    local bgData = { cancelled = false }
    backgroundStationProcessing[bgStationId] = bgData
    debugPrint('ProcessBackgroundStation: Started for station:', bgStationId, 'with', #items, 'items')

    CreateThread(function()
        for _, currentItem in ipairs(items) do
            if bgData.cancelled then break end

            -- Only process items we own (skip other players' items)
            if currentItem.owner and currentItem.owner ~= playerSource then
                goto continue
            end

            -- Skip items already mid-completion by the orphaned ProcessQueue callback
            -- (ProcessQueue sets isCompleting=true before calling completeCraft, and the
            -- in-flight callback will handle completion + shared queue removal when it returns)
            if currentItem.isCompleting then
                debugPrint('ProcessBackgroundStation: Skipping item', currentItem.id, '- already being completed by ProcessQueue')
                goto continue
            end

            -- Countdown loop
            local syncCounter = 0
            while currentItem.remainingTime > 0 and not bgData.cancelled do
                Wait(1000)
                if bgData.cancelled then break end

                currentItem.remainingTime = currentItem.remainingTime - 1
                syncCounter = syncCounter + 1

                -- Sync progress to server periodically (always uses captured bgStationId, never currentStation)
                if syncCounter >= 10 then
                    syncCounter = 0
                    local syncTime = currentItem.remainingTime
                    local syncId = currentItem.id
                    CreateThread(function()
                        lib.callback.await('sd-crafting:server:updateSharedQueueItem', false, bgStationId, syncId, {
                            remainingTime = syncTime
                        })
                    end)
                end
            end

            if bgData.cancelled then break end

            -- Complete the craft on server
            local success, data = lib.callback.await('sd-crafting:server:completeCraft', false, {
                recipeId = currentItem.recipe.id,
                quantity = currentItem.quantity,
                stationId = bgStationId,
                workbenchType = currentItem.workbenchType,
                isUiOpen = false,
                craftToken = currentItem.craftToken
            })

            if success then
                lib.callback.await('sd-crafting:server:completeSharedQueueItem', false, bgStationId)

                local recipeOutputAmount = currentItem.recipe.outputAmount or 1
                if data and data.failed then
                    local failedOutput = (data.failedCrafts or currentItem.quantity) * recipeOutputAmount
                    ShowNotification({
                        title = Locale.T('notifications.crafting.title'),
                        description = Locale.T('notifications.crafting.craftingFailed', { quantity = failedOutput, item = currentItem.recipe.label }),
                        type = 'error'
                    })
                else
                    local successfulOutput = currentItem.quantity * recipeOutputAmount
                    if data and data.partialFailure then
                        successfulOutput = data.successfulCrafts * recipeOutputAmount
                        local failedOutput = data.failedCrafts * recipeOutputAmount
                        ShowNotification({
                            title = Locale.T('notifications.crafting.title'),
                            description = Locale.T('notifications.crafting.partialSuccess', { success = successfulOutput, failed = failedOutput, item = currentItem.recipe.label }),
                            type = 'warning'
                        })
                    else
                        ShowNotification({
                            title = Locale.T('notifications.crafting.title'),
                            description = Locale.T('notifications.crafting.completedInBackground', { quantity = successfulOutput, item = currentItem.recipe.label }),
                            type = 'success'
                        })
                    end
                end

                if data and data.levelData and data.levelData.leveledUp then
                    ShowNotification({
                        title = Locale.T('notifications.levelUp.title'),
                        description = Locale.T('notifications.levelUp.description', { level = data.levelData.level }),
                        type = 'success'
                    })
                end
            else
                -- Failed - still remove from shared queue so it doesn't block others
                lib.callback.await('sd-crafting:server:completeSharedQueueItem', false, bgStationId)
                ShowNotification({
                    title = Locale.T('notifications.crafting.title'),
                    description = Locale.T('notifications.crafting.failed', { item = currentItem.recipe.label }),
                    type = 'error'
                })
            end

            ::continue::
        end

        -- Clean up only if we still own this slot (not cancelled/replaced)
        if backgroundStationProcessing[bgStationId] == bgData then
            backgroundStationProcessing[bgStationId] = nil
            -- Close station on server since we're done processing
            TriggerServerEvent('sd-crafting:server:closeStation', bgStationId)
        end
        debugPrint('ProcessBackgroundStation: Finished for station:', bgStationId)
    end)
end

--- Open the crafting UI for a specific station
---@param stationId string The station identifier
---@param workbenchType string|nil Optional workbench type, determined from stationId if not provided
---@param recipeTables table|nil Optional recipe tables, determined from station config if not provided
---@param coords vector3|nil Optional coordinates, determined from station config or placed workbench if not provided
---@param isOwner boolean|nil Whether the player is the owner of the placed workbench
---@param placedWorkbenchId number|nil The placed workbench ID if this is a placed workbench
local function OpenCraftingUI(stationId, workbenchType, recipeTables, coords, isOwner, placedWorkbenchId)
    if isUIOpen then return end

    currentStation = stationId

    if workbenchType then
        currentWorkbenchType = workbenchType
    else
        currentWorkbenchType = GetWorkbenchTypeFromStation(stationId)
    end

    if recipeTables then
        currentRecipeTables = recipeTables
    else
        local station = Config.Stations[stationId] or adminStations[stationId]
        if station and station.recipes then
            currentRecipeTables = station.recipes
        else
            currentRecipeTables = { 'all', currentWorkbenchType }
        end
    end

    -- Determine workbench coordinates for distance checking
    if coords then
        currentWorkbenchCoords = coords
    elseif stationId:find('^placed_') then
        -- Placed workbench - get coords from playerPlacedWorkbenches
        local placedId = tonumber(stationId:sub(8))
        if placedId and playerPlacedWorkbenches[placedId] then
            currentWorkbenchCoords = playerPlacedWorkbenches[placedId].data.coords
        else
            currentWorkbenchCoords = GetEntityCoords(PlayerPedId())
        end
    else
        -- Static or admin station - get coords from config
        local station = Config.Stations[stationId] or adminStations[stationId]
        if station and station.coords then
            currentWorkbenchCoords = station.coords
        else
            currentWorkbenchCoords = GetEntityCoords(PlayerPedId())
        end
    end

    isUIOpen = true

    TriggerServerEvent('sd-crafting:server:openStation', stationId)

    -- Initialize durability on blueprints that don't have it yet (so durability bar shows)
    lib.callback.await('sd-crafting:server:initBlueprintDurability', false)

    StartCraftingAnimation(stationId, currentWorkbenchCoords)

    local uiData = lib.callback.await('sd-crafting:server:getCraftingUIData', false, {
        stationId = stationId,
        workbenchType = currentWorkbenchType
    })

    local attachedBlueprints = uiData.attachedBlueprints
    local attachedWithLabels = uiData.attachedWithLabels
    local playerBlueprints = uiData.playerBlueprints
    local validBlueprintItems = uiData.validBlueprintItems
    local playerLevel = uiData.playerLevel
    local craftingInventoryConfig = uiData.craftingInventoryConfig
    local techPoints = uiData.techPoints
    local unlockedNodes = uiData.unlockedNodes
    local techTreeConfig = uiData.techTreeConfig
    local stagedItems = uiData.stagedItems or {}
    local stagedWeight = uiData.stagedWeight or 0
    local inventory = uiData.inventory or {}
    local inventoryWeight = uiData.inventoryWeight or 0
    local inventoryMaxWeight = uiData.inventoryMaxWeight or 120000
    local totalSlots = uiData.totalSlots or 0
    local supportsSlots = uiData.supportsSlots or false

    -- Store station-specific CraftingBehavior (merged with global defaults from server)
    currentCraftingBehavior = uiData.craftingBehavior

    for _, item in ipairs(stagedItems) do
        item.image = GetItemImage(item.item)
    end

    for _, item in ipairs(inventory) do
        item.image = GetItemImage(item.item)
    end

    -- Extract recipe IDs from tech trees so they're included even if blueprint isn't attached
    currentTechTreeRecipeIds = {}
    if techTreeConfig and techTreeConfig.enabled and techTreeConfig.trees then
        for _, tree in pairs(techTreeConfig.trees) do
            if tree.nodes then
                for _, node in ipairs(tree.nodes) do
                    if node.recipeId then
                        currentTechTreeRecipeIds[node.recipeId] = true
                    end
                end
            end
        end
    end

    local recipes = GetStationRecipes(attachedBlueprints, currentRecipeTables, currentTechTreeRecipeIds)
    local filteredInventory = GetFilteredInventory(inventory, currentRecipeTables)

    -- Check if shared crafting is enabled for this station type
    isSharedCraftingEnabled = lib.callback.await('sd-crafting:server:isSharedCraftingEnabled', false, stationId)

    -- Cancel any background processing for this station since ProcessQueue will take over
    if isSharedCraftingEnabled and backgroundStationProcessing[stationId] then
        backgroundStationProcessing[stationId].cancelled = true
        backgroundStationProcessing[stationId] = nil
        debugPrint('OpenCraftingUI: Cancelled background processing for station:', stationId)
    end

    -- Load shared queue if enabled
    if isSharedCraftingEnabled then
        local sharedQueue = lib.callback.await('sd-crafting:server:getSharedQueue', false, stationId)
        local newQueue = {}
        for _, item in ipairs(sharedQueue or {}) do
            newQueue[#newQueue + 1] = {
                id = item.id,
                recipe = item.recipe,
                quantity = item.quantity,
                owner = item.owner,
                ownerName = item.ownerName,
                startTime = item.startTime,
                totalTime = item.totalTime,
                remainingTime = item.remainingTime,
                workbenchType = item.workbenchType,
                craftToken = item.craftToken,
                stationId = item.stationId or stationId
            }
        end
        UpdateCraftingQueue(newQueue)
        -- Start processing if we own the first item
        if #craftingQueue > 0 and craftingQueue[1].owner == playerSource and not isProcessingQueue then
            ProcessQueue()
        end
    else
        -- Only clear queue if we're opening a DIFFERENT station than the one with restored queue
        -- AND there's no active crafting in progress
        -- This preserves restored queues from persistence
        local isRestoredStation = nearbyCraftingStation and nearbyCraftingStation == stationId
        local hasActiveQueue = #craftingQueue > 0 and isProcessingQueue

        if isRestoredStation or hasActiveQueue then
            -- We're opening the station that had the restored queue, or we have an active queue
            -- Clear the nearby tracking since we're now properly in the station
            if isRestoredStation then
                nearbyCraftingStation = nil
                nearbyCraftingCoords = nil
            end
        else
            -- Opening a different station with no active queue, clear
            craftingQueue = {}
        end
    end

    local queue = GetQueueForNUI()

    local inventoryPanelEnabled = Config.InventoryPanel and Config.InventoryPanel.enabled or false
    local showAllItems = Config.InventoryPanel and Config.InventoryPanel.showAllItems or false

    -- Determine if this is a placed workbench and set permissions data
    local isPlacedWorkbench = stationId:find('^placed_') ~= nil
    local permissionsEnabled = Config.Permissions and Config.Permissions.enabled or false
    local historyEnabled = Config.History and Config.History.enabled or false
    local historyOwnerOnlyDelete = Config.History and Config.History.ownerOnlyDelete or false
    local historyDateFormat = Config.History and Config.History.dateFormat or 'DMY'
    currentPlacedWorkbenchId = placedWorkbenchId

    SendNUIMessage({
        action = 'open',
        recipes = recipes,
        inventory = inventory,
        filteredInventory = filteredInventory,
        queue = queue,
        stationId = stationId,
        workbenchType = currentWorkbenchType,
        attachedBlueprints = attachedBlueprints or {},
        attachedWithLabels = attachedWithLabels or {},
        playerBlueprints = playerBlueprints or {},
        validBlueprintItems = validBlueprintItems or {},
        playerLevel = playerLevel or { xp = 0, level = 1, enabled = false },
        inventoryPanelEnabled = inventoryPanelEnabled,
        showAllItems = showAllItems,
        craftingInventoryConfig = craftingInventoryConfig or { enabled = false, perWorkbench = false, maxSlots = 20, maxWeight = 0, returnOnClose = false },
        stagedItems = stagedItems,
        stagedWeight = stagedWeight,
        inventoryWeight = inventoryWeight,
        inventoryMaxWeight = inventoryMaxWeight,
        totalSlots = totalSlots,
        supportsSlots = supportsSlots,
        techPoints = techPoints or { points = 0, enabled = false },
        unlockedNodes = unlockedNodes or {},
        techTreeConfig = techTreeConfig or { enabled = false },
        locale = Config.Locale or 'en',
        -- Permission system data
        isPlacedWorkbench = isPlacedWorkbench,
        isWorkbenchOwner = isOwner or false,
        permissionsEnabled = permissionsEnabled,
        placedWorkbenchId = placedWorkbenchId,
        -- History system data
        historyEnabled = historyEnabled,
        historyOwnerOnlyDelete = historyOwnerOnlyDelete,
        historyDateFormat = historyDateFormat,
        -- Shared crafting data
        sharedCrafting = isSharedCraftingEnabled
    })

    SetNuiFocus(true, true)

    debugPrint('Opened crafting UI for station:', stationId)
    debugPrint('Attached blueprints:', json.encode(attachedBlueprints))
    debugPrint('Player blueprints:', json.encode(playerBlueprints))
    debugPrint('Player level:', json.encode(playerLevel))
    debugPrint('Crafting inventory config:', json.encode(craftingInventoryConfig))
    debugPrint('Staged items:', json.encode(stagedItems))
    debugPrint('Staged weight:', stagedWeight)
    debugPrint('Inventory weight:', inventoryWeight)
end

--- Check if the current player has items being crafted
---@return boolean isCrafting Whether this player is actively crafting
local function IsCraftingInProgress()
    if #craftingQueue == 0 then return false end

    -- In shared mode, only consider it "in progress" for this player if they own items in the queue
    if isSharedCraftingEnabled then
        for _, item in ipairs(craftingQueue) do
            if item.owner == playerSource or item.owner == nil then
                return true
            end
        end
        return false
    end

    return true
end

--- Cancel all items in the crafting queue and refund materials
---@param stationId string The station ID for refunding
local function CancelAllCrafting(stationId)
    if #craftingQueue == 0 and not isProcessingQueue then return end
    debugPrint('CancelAllCrafting: Cancelling', #craftingQueue, 'items, bumping generation from:', queueGeneration)

    -- Bump generation to invalidate any running ProcessQueue thread
    queueGeneration = queueGeneration + 1
    isProcessingQueue = false

    for i = #craftingQueue, 1, -1 do
        local item = craftingQueue[i]
        if not item.isCompleting then
            lib.callback.await('sd-crafting:server:refundItems', false, {
                recipeId = item.recipe.id,
                quantity = item.quantity,
                stationId = stationId,
                craftToken = item.craftToken
            })
            -- Also remove from server's shared queue so items don't reappear when reopening the bench
            if isSharedCraftingEnabled and stationId then
                lib.callback.await('sd-crafting:server:removeFromSharedQueue', false, stationId, item.id)
            end
        end
        table.remove(craftingQueue, i)
    end

    -- Clear saved queue from database so items don't persist across reconnects
    if not isSharedCraftingEnabled then
        lib.callback.await('sd-crafting:server:clearSavedQueue', false)
    end

    -- Sync the now-empty queue to the NUI so React stops its independent countdown timer.
    -- Without this, React keeps showing/counting down items from its stale copy of the queue.
    if isUIOpen then
        SendNUIMessage({
            action = 'updateQueue',
            queue = GetQueueForNUI()
        })
        UpdateInventoryNUI()
    end

    ShowNotification({
        title = Locale.T('notifications.crafting.title'),
        description = Locale.T('notifications.crafting.allCancelled'),
        type = 'inform'
    })
end

--- Start monitoring player distance from workbench for nearby crafting
---@param stationId string The station ID
---@param coords vector3 The workbench coordinates
---@param maxDistance number Maximum allowed distance
local function StartDistanceMonitoring(stationId, coords, maxDistance)
    if isMonitoringDistance then return end
    isMonitoringDistance = true

    CreateThread(function()
        while isMonitoringDistance and #craftingQueue > 0 do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - coords)

            if distance > maxDistance then
                -- Player moved too far, cancel crafting
                CancelAllCrafting(stationId)
                StopCraftingAnimation()
                isMonitoringDistance = false

                -- Clear nearby crafting station info
                nearbyCraftingStation = nil
                nearbyCraftingCoords = nil

                ShowNotification({
                    title = Locale.T('notifications.crafting.title'),
                    description = Locale.T('notifications.crafting.tooFar'),
                    type = 'error'
                })

                TriggerServerEvent('sd-crafting:server:closeStation', stationId)
                break
            end

            Wait(500)
        end

        -- ProcessQueue handles station cleanup when crafting finishes
        isMonitoringDistance = false
    end)
end

--- Close the crafting UI and cleanup
---@param force boolean|nil Force close without checking crafting status
local function CloseCraftingUI(force)
    if not isUIOpen then return end

    local behavior = GetCraftingBehavior()
    local isCrafting = IsCraftingInProgress()

    -- Check if we should prevent closing while crafting
    if not force and isCrafting and behavior.preventCloseWhileCrafting then
        ShowNotification({
            title = Locale.T('notifications.crafting.title'),
            description = Locale.T('notifications.crafting.cannotClose'),
            type = 'error'
        })
        return
    end

    local closingStation = currentStation
    local closingCoords = currentWorkbenchCoords

    -- Handle crafting in progress
    local keepStationOpen = false -- Whether to keep the station open on the server for background crafting
    if isCrafting and not force then
        if behavior.allowCraftingAnywhere and behavior.allowCraftingAnywhere.enabled then
            -- Allow crafting to continue anywhere - no distance restriction
            -- Only set if not already tracking a different station's active craft
            if not nearbyCraftingStation then
                nearbyCraftingStation = closingStation
                nearbyCraftingCoords = closingCoords
            end
            keepStationOpen = nearbyCraftingStation == closingStation

            ShowNotification({
                title = Locale.T('notifications.crafting.title'),
                description = Locale.T('notifications.crafting.continuingAnywhere'),
                type = 'inform'
            })
        elseif behavior.cancelCraftOnClose ~= false then
            -- Cancel and refund all crafting
            CancelAllCrafting(closingStation)
        elseif behavior.allowCraftingNearby and behavior.allowCraftingNearby.enabled then
            -- Store station info for nearby crafting before clearing currentStation
            if not nearbyCraftingStation then
                nearbyCraftingStation = closingStation
                nearbyCraftingCoords = closingCoords
            end

            -- Start monitoring distance - crafting continues in background
            local maxDistance = behavior.allowCraftingNearby.distance or 5.0
            StartDistanceMonitoring(closingStation, closingCoords, maxDistance)

            ShowNotification({
                title = Locale.T('notifications.crafting.title'),
                description = Locale.T('notifications.crafting.continuingNearby', { distance = maxDistance }),
                type = 'inform'
            })
        else
            -- Fall-through: cancelCraftOnClose is false but no continuation mode explicitly enabled
            -- Crafting continues in background - keep the original station open for completion
            if not nearbyCraftingStation then
                nearbyCraftingStation = closingStation
                nearbyCraftingCoords = closingCoords
            end
            keepStationOpen = nearbyCraftingStation == closingStation
        end
    end

    -- In shared mode, transfer active processing to a station-specific background thread
    -- so it continues independently when the player opens another station
    if isSharedCraftingEnabled and isProcessingQueue then
        local bgItems = {}
        for _, item in ipairs(craftingQueue) do
            bgItems[#bgItems + 1] = item
        end
        if #bgItems > 0 then
            queueGeneration = queueGeneration + 1
            isProcessingQueue = false
            craftingQueue = {}
            ProcessBackgroundStation(closingStation, bgItems)
            keepStationOpen = true
        end
    end

    StopCraftingAnimation()

    if closingStation then
        lib.callback.await('sd-crafting:server:returnAllStagedItems', false, closingStation)
    end

    isUIOpen = false
    currentStation = nil
    currentWorkbenchType = nil
    currentRecipeTables = nil
    currentTechTreeRecipeIds = nil
    currentWorkbenchCoords = nil
    currentCraftingBehavior = nil

    if closingStation and not isMonitoringDistance and not keepStationOpen then
        TriggerServerEvent('sd-crafting:server:closeStation', closingStation)
    end

    SendNUIMessage({
        action = 'close'
    })

    SetNuiFocus(false, false)

    debugPrint('Closed crafting UI')
end

--- Show notification triggered from server
---@param data table Notification data {title, description, type}
RegisterNetEvent('sd-crafting:client:notify', function(data)
    ShowNotification(data)
end)

--- Receive staged items sync from server (when another player modifies shared inventory)
---@param stationId string Station identifier
---@param stagedItems table Staged items array
---@param stagedWeight number Total weight of staged items
RegisterNetEvent('sd-crafting:client:syncStagedItems', function(stationId, stagedItems, stagedWeight)
    if not isUIOpen or currentStation ~= stationId then return end

    stagedItems = stagedItems or {}
    stagedWeight = stagedWeight or 0

    for _, item in ipairs(stagedItems) do
        item.image = GetItemImage(item.item)
    end

    SendNUIMessage({
        action = 'updateStagedItems',
        stagedItems = stagedItems,
        stagedWeight = stagedWeight
    })

    debugPrint('Received staged items sync for station:', stationId)
end)

--- Receive tech tree sync from server (when another player unlocks a node on shared workbench)
---@param data table Contains techPoints, unlockedNodes, and workbenchType
RegisterNetEvent('sd-crafting:client:syncTechTree', function(data)
    if not isUIOpen then return end

    SendNUIMessage({
        action = 'updateTechPoints',
        techPoints = { points = data.techPoints, enabled = true, workbenchType = data.workbenchType }
    })

    SendNUIMessage({
        action = 'updateUnlockedNodes',
        unlockedNodes = data.unlockedNodes or {}
    })

    debugPrint('Received tech tree sync - points:', data.techPoints)
end)

--- Handle NUI request to check if closing is allowed
---@param _ any Unused data parameter
---@param cb function Callback to return whether closing is allowed
RegisterNUICallback('canCloseUI', function(_, cb)
    local behavior = GetCraftingBehavior()
    local isCrafting = IsCraftingInProgress()

    if isCrafting and behavior.preventCloseWhileCrafting then
        SendNUIMessage({
            action = 'showToast',
            toastMessage = Locale.T('notifications.crafting.cannotClose'),
            toastType = 'error'
        })
        cb({ canClose = false })
        return
    end

    cb({ canClose = true })
end)

--- Handle NUI request to close the crafting UI
---@param _ any Unused data parameter
---@param cb function Callback to signal completion
RegisterNUICallback('closeUI', function(_, cb)
    CloseCraftingUI()
    cb('ok')
end)

--- Handle NUI request to add item to crafting queue
---@param data table Contains recipeId and optional quantity
---@param cb function Callback to return success status and queue
RegisterNUICallback('addToQueue', function(data, cb)
    local recipeId = data.recipeId
    local quantity = data.quantity or 1

    local recipe = nil
    for _, recipes in pairs(Recipes) do
        for _, r in ipairs(recipes) do
            if r.id == recipeId then
                recipe = r
                break
            end
        end
        if recipe then break end
    end

    if not recipe then
        cb({ success = false, message = 'Recipe not found' })
        return
    end

    local canCraft, errorMsg = lib.callback.await('sd-crafting:server:canCraft', false, {
        recipeId = recipeId,
        quantity = quantity,
        stationId = currentStation,
        workbenchType = currentWorkbenchType
    })

    if not canCraft then
        cb({ success = false, message = errorMsg or 'Missing required items' })
        if errorMsg and errorMsg:find('cash') then
            SendNUIMessage({
                action = 'showToast',
                toastMessage = errorMsg,
                toastType = 'error'
            })
        else
            ShowNotification({
                title = Locale.T('notifications.crafting.title'),
                description = errorMsg or Locale.T('notifications.crafting.missingItems'),
                type = 'error'
            })
        end
        return
    end

    local itemsRemoved, craftToken = lib.callback.await('sd-crafting:server:removeItems', false, {
        recipeId = recipeId,
        quantity = quantity,
        stationId = currentStation
    })

    if not itemsRemoved then
        cb({ success = false, message = 'Failed to remove items' })
        return
    end

    -- Build recipe with auto-fetched label for queue display
    local queueRecipe = {
        id = recipe.id,
        name = recipe.name,
        label = recipe.label or GetItemLabel(recipe.name) or recipe.name,
        craftTime = recipe.craftTime,
        ingredients = recipe.ingredients,
        cost = recipe.cost,
        blueprint = recipe.blueprint,
        outputAmount = recipe.outputAmount,
        image = recipe.image, -- Custom image path (NUI path override)
        metadata = recipe.metadata -- Include metadata for image/imageurl support
    }

    local queueItem = {
        id = 'queue_' .. tostring(GetGameTimer()) .. '_' .. playerSource,
        recipe = queueRecipe,
        quantity = quantity,
        startTime = GetGameTimer(),
        totalTime = recipe.craftTime * quantity,
        remainingTime = recipe.craftTime * quantity,
        workbenchType = currentWorkbenchType,
        craftToken = craftToken,
        stationId = currentStation
    }
    debugPrint('addToQueue: Created item:', queueItem.id, 'recipe:', recipeId, 'quantity:', data.quantity, 'craftToken:', queueItem.craftToken, 'totalTime:', queueItem.totalTime)

    if isSharedCraftingEnabled and currentStation then
        -- Add to shared queue on server
        local success, serverQueue = lib.callback.await('sd-crafting:server:addToSharedQueue', false, currentStation, queueItem)
        if not success then
            cb({ success = false, message = 'Failed to add to shared queue' })
            return
        end
        -- Update local queue from server response (we're excluded from broadcast to avoid race condition)
        if serverQueue then
            local newQueue = {}
            for _, item in ipairs(serverQueue) do
                newQueue[#newQueue + 1] = {
                    id = item.id,
                    recipe = item.recipe,
                    quantity = item.quantity,
                    totalTime = item.totalTime,
                    remainingTime = item.remainingTime,
                    owner = item.owner,
                    ownerName = item.ownerName,
                    workbenchType = item.workbenchType,
                    craftToken = item.craftToken,
                    stationId = item.stationId or currentStation
                }
            end
            UpdateCraftingQueue(newQueue)
            -- Start processing if this player owns the first item
            if #craftingQueue > 0 and craftingQueue[1].owner == playerSource and not isProcessingQueue then
                debugPrint('addToQueue: Starting ProcessQueue, queue size:', #craftingQueue)
                ProcessQueue()
            end
        end
    else
        -- Add to local queue
        craftingQueue[#craftingQueue + 1] = queueItem
        ProcessQueue()
        -- Save queue for persistence (run async to not block)
        CreateThread(function()
            Wait(100)
            SaveQueueToServer()
        end)
    end

    UpdateInventoryNUI()
    UpdateStagedItemsNUI()

    cb({ success = true, queue = GetQueueForNUI() })
end)

--- Handle NUI request to remove item from crafting queue
---@param data table Contains queueItemId to remove
---@param cb function Callback to return success status and queue
RegisterNUICallback('removeFromQueue', function(data, cb)
    local queueItemId = data.queueItemId
    debugPrint('removeFromQueue: Removing item:', data.queueItemId)

    for i, item in ipairs(craftingQueue) do
        if item.id == queueItemId then
            -- Check if this is shared mode and if we own the item
            if isSharedCraftingEnabled and item.owner and item.owner ~= playerSource then
                cb({ success = false, message = 'Cannot remove items you did not add' })
                return
            end

            if item.isCompleting then
                cb({ success = false, message = 'Item is already completing' })
                return
            end

            -- If removing the first item (currently processing), bump generation to cancel it
            if i == 1 and isProcessingQueue then
                queueGeneration = queueGeneration + 1
                isProcessingQueue = false
                debugPrint('removeFromQueue: Cancelled processing, bumped generation to:', queueGeneration)
            end

            lib.callback.await('sd-crafting:server:refundItems', false, {
                recipeId = item.recipe.id,
                quantity = item.quantity,
                stationId = currentStation,
                craftToken = item.craftToken
            })

            if isSharedCraftingEnabled and currentStation then
                -- Remove from shared queue on server
                local success, serverQueue = lib.callback.await('sd-crafting:server:removeFromSharedQueue', false, currentStation, queueItemId)
                -- Update local queue from server response (we're excluded from broadcast to avoid race condition)
                if success and serverQueue then
                    local newQueue = {}
                    for _, serverItem in ipairs(serverQueue) do
                        newQueue[#newQueue + 1] = {
                            id = serverItem.id,
                            recipe = serverItem.recipe,
                            quantity = serverItem.quantity,
                            totalTime = serverItem.totalTime,
                            remainingTime = serverItem.remainingTime,
                            owner = serverItem.owner,
                            ownerName = serverItem.ownerName,
                            workbenchType = serverItem.workbenchType,
                            craftToken = serverItem.craftToken,
                            stationId = serverItem.stationId or currentStation
                        }
                    end
                    UpdateCraftingQueue(newQueue)
                end
            else
                table.remove(craftingQueue, i)
            end

            UpdateInventoryNUI()
            UpdateStagedItemsNUI()

            SendNUIMessage({
                action = 'showToast',
                toastMessage = Locale.T('notifications.crafting.cancelled', { item = item.recipe.label }),
                toastType = 'info'
            })

            cb({ success = true, queue = GetQueueForNUI() })

            -- If there are remaining items after cancelling the first, restart processing
            if i == 1 and #craftingQueue > 0 then
                CreateThread(function()
                    Wait(100) -- Small delay to ensure old thread has exited
                    ProcessQueue()
                end)
            end

            return
        end
    end

    cb({ success = false, message = 'Queue item not found' })
end)

--- Handle NUI request to attach blueprint to station
---@param data table Contains blueprintItem name
---@param cb function Callback to return success status
RegisterNUICallback('attachBlueprint', function(data, cb)
    local blueprintItem = data.blueprintItem

    if not currentStation or not blueprintItem then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message = lib.callback.await('sd-crafting:server:attachBlueprint', false, {
        stationId = currentStation,
        blueprintItem = blueprintItem
    })

    if success then
        ShowNotification({
            title = Locale.T('notifications.blueprint.title'),
            description = message or Locale.T('notifications.blueprint.attached'),
            type = 'success'
        })

        UpdateBlueprintsNUI()
        UpdateInventoryNUI()
    else
        ShowNotification({
            title = Locale.T('notifications.blueprint.title'),
            description = message or Locale.T('notifications.blueprint.attachFailed'),
            type = 'error'
        })
    end

    cb({ success = success, message = message })
end)

--- Handle NUI request to detach blueprint from station
---@param data table Contains blueprintItem name
---@param cb function Callback to return success status
RegisterNUICallback('detachBlueprint', function(data, cb)
    local blueprintItem = data.blueprintItem

    if not currentStation or not blueprintItem then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message, craftingItem = lib.callback.await('sd-crafting:server:detachBlueprint', false, {
        stationId = currentStation,
        blueprintItem = blueprintItem
    })

    if success then
        ShowNotification({
            title = Locale.T('notifications.blueprint.title'),
            description = message or Locale.T('notifications.blueprint.detached'),
            type = 'success'
        })

        UpdateBlueprintsNUI()
        UpdateInventoryNUI()
    else
        -- Map server error to appropriate locale message
        local errorMessage = Locale.T('notifications.blueprint.detachFailed')
        if message == 'blueprint_in_queue' then
            errorMessage = Locale.T('notifications.blueprint.inQueue', { item = craftingItem or 'Unknown' })
        end

        ShowNotification({
            title = Locale.T('notifications.blueprint.title'),
            description = errorMessage,
            type = 'error'
        })
    end

    cb({ success = success, message = message })
end)

--- Handle NUI request to stage item from player inventory to crafting inventory
---@param data table Contains item name, count, optional slot (target), and optional sourceSlot (player inventory)
---@param cb function Callback to return success status
RegisterNUICallback('stageItem', function(data, cb)
    local itemName = data.item
    local count = data.count or 1
    local targetSlot = data.slot
    local sourceSlot = data.sourceSlot -- Slot in player inventory to take item from

    if not currentStation or not itemName then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message, errorCount = lib.callback.await('sd-crafting:server:stageItem', false, {
        stationId = currentStation,
        item = itemName,
        count = count,
        slot = targetSlot,
        sourceSlot = sourceSlot
    })

    if success then
        UpdateInventoryNUI()
        UpdateStagedItemsNUI()

        if IsBlueprint(itemName) then
            UpdateBlueprintsNUI()
        end
        cb({ success = true })
    else
        -- Map server error to locale key with count
        local errorMessage = Locale.T('notifications.staging.addFailed')
        if message == 'staging_full' then
            errorMessage = Locale.T('notifications.staging.stagingFull', { count = errorCount or count })
        end

        -- Return error to NUI for toast notification
        cb({ success = false, message = errorMessage })
    end
end)

--- Handle NUI request to move staged item to a different slot
---@param data table Contains sourceSlot and newSlot positions
---@param cb function Callback to return success status
RegisterNUICallback('moveStagedSlot', function(data, cb)
    local sourceSlot = data.sourceSlot
    local newSlot = data.newSlot

    if not currentStation or sourceSlot == nil or newSlot == nil then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message = lib.callback.await('sd-crafting:server:moveStagedSlot', false, {
        stationId = currentStation,
        sourceSlot = sourceSlot,
        newSlot = newSlot
    })

    cb({ success = success, message = message })
end)

--- Handle NUI request to merge two staged stacks of the same item
---@param data table Contains sourceSlot and targetSlot positions
---@param cb function Callback to return success status
RegisterNUICallback('mergeStagedStacks', function(data, cb)
    local sourceSlot = data.sourceSlot
    local targetSlot = data.targetSlot

    if not currentStation or sourceSlot == nil or targetSlot == nil then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message = lib.callback.await('sd-crafting:server:mergeStagedStacks', false, {
        stationId = currentStation,
        sourceSlot = sourceSlot,
        targetSlot = targetSlot
    })

    -- Translate specific error messages
    if not success and message == 'item_not_stackable' then
        message = Locale.T('notifications.staging.itemNotStackable')
    end

    cb({ success = success, message = message })
end)

--- Handle NUI request to split a staged stack
---@param data table Contains sourceSlot, targetSlot, and amount
---@param cb function Callback to return success status
RegisterNUICallback('splitStagedStack', function(data, cb)
    local sourceSlot = data.sourceSlot
    local targetSlot = data.targetSlot
    local amount = data.amount

    if not currentStation or sourceSlot == nil or targetSlot == nil or not amount then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message = lib.callback.await('sd-crafting:server:splitStagedStack', false, {
        stationId = currentStation,
        sourceSlot = sourceSlot,
        targetSlot = targetSlot,
        amount = amount
    })

    cb({ success = success, message = message })
end)

--- Handle NUI request to unstage item back to player inventory
---@param data table Contains item name and count
---@param cb function Callback to return success status
RegisterNUICallback('unstageItem', function(data, cb)
    local itemName = data.item
    local count = data.count or 1
    local sourceSlot = data.sourceSlot

    if not currentStation or not itemName then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message, errorData = lib.callback.await('sd-crafting:server:unstageItem', false, {
        stationId = currentStation,
        item = itemName,
        count = count,
        sourceSlot = sourceSlot
    })

    if success then
        UpdateInventoryNUI()
        UpdateStagedItemsNUI()

        if IsBlueprint(itemName) then
            UpdateBlueprintsNUI()
        end
        cb({ success = true })
    else
        -- Map server error to locale key with appropriate data
        local errorMessage = Locale.T('notifications.staging.removeFailed')
        if message == 'inventory_full' then
            errorMessage = Locale.T('notifications.staging.inventoryFull', { count = errorData or count })
        elseif message == 'blueprint_in_queue' then
            errorMessage = Locale.T('notifications.blueprint.inQueue', { item = errorData or 'Unknown' })
        end

        -- Return error to NUI for toast notification
        cb({ success = false, message = errorMessage })
    end
end)

--- Handle NUI request to move a staged item to a specific inventory slot
---@param data table Contains item name, count, and target slot
---@param cb function Callback to return success status
RegisterNUICallback('unstageItemToSlot', function(data, cb)
    local itemName = data.item
    local count = data.count or 1
    local targetSlot = data.targetSlot
    local sourceSlot = data.sourceSlot

    if not currentStation or not itemName or not targetSlot then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message, errorData = lib.callback.await('sd-crafting:server:moveToInventorySlot', false, {
        stationId = currentStation,
        itemName = itemName,
        count = count,
        targetSlot = targetSlot,
        sourceSlot = sourceSlot
    })

    if success then
        UpdateInventoryNUI()
        UpdateStagedItemsNUI()

        if IsBlueprint(itemName) then
            UpdateBlueprintsNUI()
        end
        cb({ success = true })
    else
        -- Map server error to locale key with appropriate data
        local errorMessage = Locale.T('notifications.staging.removeFailed')
        if message == 'inventory_full' then
            errorMessage = Locale.T('notifications.staging.inventoryFull', { count = errorData or count })
        elseif message == 'blueprint_in_queue' then
            errorMessage = Locale.T('notifications.blueprint.inQueue', { item = errorData or 'Unknown' })
        end

        -- Return error to NUI for toast notification
        cb({ success = false, message = errorMessage })
    end
end)

--- Handle NUI request to unlock a tech tree node
---@param data table Contains treeId and nodeId
---@param cb function Callback to return success status
RegisterNUICallback('unlockTechNode', function(data, cb)
    local treeId = data.treeId
    local nodeId = data.nodeId

    if not treeId or not nodeId then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, result = lib.callback.await('sd-crafting:server:unlockTechNode', false, {
        treeId = treeId,
        nodeId = nodeId,
        workbenchType = currentWorkbenchType,
        stationId = currentStation
    })

    if success then
        ShowNotification({
            title = Locale.T('notifications.techTree.title'),
            description = Locale.T('notifications.techTree.nodeUnlocked'),
            type = 'success'
        })

        SendNUIMessage({
            action = 'updateTechPoints',
            techPoints = { points = result.newPoints, enabled = true, workbenchType = result.workbenchType }
        })

        local unlockedNodes = lib.callback.await('sd-crafting:server:getUnlockedNodes', false, { workbenchType = currentWorkbenchType, stationId = currentStation })
        SendNUIMessage({
            action = 'updateUnlockedNodes',
            unlockedNodes = unlockedNodes or {}
        })
    else
        ShowNotification({
            title = Locale.T('notifications.techTree.title'),
            description = result or Locale.T('notifications.techTree.unlockFailed'),
            type = 'error'
        })
    end

    cb({ success = success })
end)

--- Handle NUI request to pick up a placed workbench
---@param data table Empty data table
---@param cb function Callback to return success status
RegisterNUICallback('pickupWorkbench', function(data, cb)
    if not currentStation then
        cb({ success = false })
        return
    end

    local workbenchId = tonumber(currentStation:match('^placed_(%d+)$'))
    if not workbenchId then
        cb({ success = false })
        return
    end

    local success = lib.callback.await('sd-crafting:server:pickupWorkbench', false, workbenchId)
    cb({ success = success })
end)

--- Get workbench permissions list
---@param data table Empty data table
---@param cb function Callback to return permissions
RegisterNUICallback('getPermissions', function(data, cb)
    if not currentPlacedWorkbenchId then
        cb({ success = false, permissions = {} })
        return
    end

    local permissions = lib.callback.await('sd-crafting:server:getWorkbenchPermissions', false, currentPlacedWorkbenchId)
    cb({ success = permissions ~= nil, permissions = permissions or {} })
end)

--- Add a player to workbench permissions
---@param data table Contains sourceId (player source ID to add)
---@param cb function Callback to return success status
RegisterNUICallback('addPermission', function(data, cb)
    if not currentPlacedWorkbenchId or not data.sourceId then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message = lib.callback.await('sd-crafting:server:addWorkbenchPermission', false, currentPlacedWorkbenchId, data.sourceId)
    cb({ success = success, message = message })
end)

--- Remove a player from workbench permissions
---@param data table Contains identifier (player identifier to remove)
---@param cb function Callback to return success status
RegisterNUICallback('removePermission', function(data, cb)
    if not currentPlacedWorkbenchId or not data.identifier then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    local success, message = lib.callback.await('sd-crafting:server:removeWorkbenchPermission', false, currentPlacedWorkbenchId, data.identifier)
    cb({ success = success, message = message })
end)

--- Enrich history entries with image paths from the current inventory system
---@param history table Array of history entries from server
---@return table history The same array with image paths added
local function EnrichHistoryImages(history)
    if not history then return {} end
    for _, entry in ipairs(history) do
        entry.output_image = GetItemImage(entry.output_item or entry.recipe_id)
        if entry.ingredients then
            for _, ing in ipairs(entry.ingredients) do
                ing.image = GetItemImage(ing.item)
            end
        end
    end
    return history
end

--- Get workbench crafting history
---@param data table Empty data table
---@param cb function Callback to return history
RegisterNUICallback('getHistory', function(data, cb)
    if not currentPlacedWorkbenchId then
        cb({ success = false, history = {} })
        return
    end

    local history = lib.callback.await('sd-crafting:server:getWorkbenchHistory', false, currentPlacedWorkbenchId)
    cb({ success = history ~= nil, history = EnrichHistoryImages(history) })
end)

--- Delete a history entry from workbench
---@param data table Contains entryIndex (1-based index)
---@param cb function Callback to return success status
RegisterNUICallback('deleteHistoryEntry', function(data, cb)
    if not currentPlacedWorkbenchId or not data.entryIndex then
        cb({ success = false })
        return
    end

    local success = lib.callback.await('sd-crafting:server:deleteHistoryEntry', false, currentPlacedWorkbenchId, data.entryIndex)
    cb({ success = success })
end)

--- Handle real-time history updates from server
---@param workbenchId number The workbench ID that was updated
---@param history table The updated history array
RegisterNetEvent('sd-crafting:client:historyUpdated', function(workbenchId, history)
    if currentPlacedWorkbenchId == workbenchId then
        SendNUIMessage({
            action = 'historyUpdated',
            history = EnrichHistoryImages(history)
        })
    end
end)

exports('OpenCraftingUI', OpenCraftingUI)

local spawnedProps = {} -- Track spawned props by stationId

--- Spawn a station prop and add target interaction
---@param stationId string The station identifier
---@param station table Station configuration from Config.Stations
local function SpawnStationProp(stationId, station)
    if spawnedProps[stationId] then return end

    local propConfig = station.prop
    if not propConfig or not propConfig.enabled or not propConfig.model then return end

    local model = propConfig.model

    lib.requestModel(model)

    local offset = propConfig.offset or vector3(0.0, 0.0, 0.0)
    local spawnCoords = vector3(
        station.coords.x + offset.x,
        station.coords.y + offset.y,
        station.coords.z + offset.z
    )

    local prop = CreateObject(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(prop, station.heading or 0.0)
    FreezeEntityPosition(prop, true)
    SetModelAsNoLongerNeeded(model)

    spawnedProps[stationId] = prop

    Target.addLocalEntity(prop, {
        {
            name = 'crafting_prop_' .. stationId,
            icon = 'fa-solid fa-hammer',
            label = Locale.T('target.openStation', { station = station.label }),
            onSelect = function()
                if not CheckWorkbenchAccess(station.job, station.gang) then
                    return
                end
                if station.owner and GetPlayerIdentifier() ~= station.owner then
                    ShowNotification({
                        title = Locale.T('notifications.workbench.accessDenied'),
                        description = Locale.T('permissions.accessDenied'),
                        type = 'error'
                    })
                    return
                end
                OpenCraftingUI(stationId)
            end
        }
    })

    debugPrint('Spawned prop for station:', stationId, 'Entity:', prop)
end

--- Delete a station prop and remove target
---@param stationId string The station identifier
local function DeleteStationProp(stationId)
    local prop = spawnedProps[stationId]
    if not prop then return end

    if DoesEntityExist(prop) then
        Target.removeLocalEntity(prop)
        DeleteEntity(prop)
    end

    spawnedProps[stationId] = nil

    debugPrint('Deleted prop for station:', stationId)
end

--- Spawn a static station with blip, prop, and target zone (mirrors SpawnAdminStation pattern)
---@param stationId string The Config.Stations key
---@param station table Station configuration data
local function SpawnStaticStation(stationId, station)
    if not station or not station.coords or station.coords.x == 0 then return end

    -- Clean up any existing station to prevent duplicate targets/zones
    if staticStationPoints[stationId] or staticStationZones[stationId] or staticStationBlips[stationId] then
        DeleteStationProp(stationId)
        if staticStationPoints[stationId] then
            staticStationPoints[stationId]:remove()
            staticStationPoints[stationId] = nil
        end
        if staticStationZones[stationId] then
            Target.removeZone(staticStationZones[stationId])
            staticStationZones[stationId] = nil
        end
        if staticStationBlips[stationId] then
            RemoveBlip(staticStationBlips[stationId])
            staticStationBlips[stationId] = nil
        end
    end

    -- Create blip if enabled
    if station.blip and station.blip.enabled then
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, tonumber(station.blip.sprite) or 566)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, (tonumber(station.blip.scale) or 0.7) + 0.0)
        SetBlipColour(blip, tonumber(station.blip.color) or 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.blip.label or station.label)
        EndTextCommandSetBlipName(blip)
        staticStationBlips[stationId] = blip
    end

    local hasProp = station.prop and station.prop.enabled and station.prop.model

    if hasProp then
        local spawnRadius = station.prop.spawnRadius or 50.0

        staticStationPoints[stationId] = lib.points.new({
            coords = station.coords,
            distance = spawnRadius,
            stationId = stationId,
            station = station,
            onEnter = function(self)
                SpawnStationProp(self.stationId, self.station)
            end,
            onExit = function(self)
                DeleteStationProp(self.stationId)
            end
        })
    else
        local zoneName = 'crafting_' .. stationId
        staticStationZones[stationId] = zoneName
        Target.addSphereZone({
            name = zoneName,
            coords = station.coords,
            radius = station.radius or 2.0,
            debug = Config.Debug,
            options = {
                {
                    name = zoneName,
                    icon = 'fa-solid fa-hammer',
                    label = Locale.T('target.openStation', { station = station.label }),
                    onSelect = function()
                        if not CheckWorkbenchAccess(station.job, station.gang) then
                            return
                        end
                        if station.owner and GetPlayerIdentifier() ~= station.owner then
                            ShowNotification({
                                title = Locale.T('notifications.workbench.accessDenied'),
                                description = Locale.T('permissions.accessDenied'),
                                type = 'error'
                            })
                            return
                        end
                        OpenCraftingUI(stationId)
                    end
                }
            }
        })
    end

    debugPrint('Spawned static station:', stationId)
end

--- Remove a static station (prop, blip, target zone) for refresh or cleanup
---@param stationId string The Config.Stations key
local function RemoveStaticStation(stationId)
    DeleteStationProp(stationId)

    if staticStationPoints[stationId] then
        staticStationPoints[stationId]:remove()
        staticStationPoints[stationId] = nil
    end

    if staticStationZones[stationId] then
        Target.removeZone(staticStationZones[stationId])
        staticStationZones[stationId] = nil
    end

    if staticStationBlips[stationId] then
        RemoveBlip(staticStationBlips[stationId])
        staticStationBlips[stationId] = nil
    end

    debugPrint('Removed static station:', stationId)
end

--- Apply station overrides from server to the client's local Config.Stations
---@param overrides table Override data keyed by station key
local function ApplyClientStationOverrides(overrides)
    if not overrides then return end
    local count = 0
    for stationKey, overrideData in pairs(overrides) do
        if Config.Stations[stationKey] then
            local station = Config.Stations[stationKey]
            if overrideData.label ~= nil then station.label = overrideData.label end
            if overrideData.type ~= nil then station.type = overrideData.type end
            if overrideData.radius ~= nil then station.radius = overrideData.radius end
            if overrideData.recipes ~= nil then station.recipes = overrideData.recipes end
            if overrideData.techTrees ~= nil then station.techTrees = overrideData.techTrees end
            if overrideData.blip ~= nil then station.blip = overrideData.blip end
            if overrideData.prop ~= nil then station.prop = overrideData.prop end
            if overrideData.coords ~= nil then
                station.coords = type(overrideData.coords) == 'vector3' and overrideData.coords
                    or vector3(overrideData.coords.x or 0, overrideData.coords.y or 0, overrideData.coords.z or 0)
            end
            if overrideData.heading ~= nil then station.heading = overrideData.heading end
            if overrideData.owner ~= nil then station.owner = overrideData.owner end
            if overrideData.job ~= nil then station.job = overrideData.job end
            if overrideData.gang ~= nil then station.gang = overrideData.gang end
            count = count + 1
        end
    end
    if count > 0 then
        debugPrint(('Applied %d station overrides from database'):format(count))
    end
end

--- Initialize crafting stations with ox_target zones and prop spawning
CreateThread(function()
    Wait(1000)

    -- Load station overrides from server before spawning (DB edits override config values)
    local overrides = lib.callback.await('sd-crafting:server:getStationOverrides', false)
    ApplyClientStationOverrides(overrides)

    for stationId, station in pairs(Config.Stations) do
        SpawnStaticStation(stationId, station)
    end

    debugPrint('Crafting stations initialized')
end)

--- Cleanup props when resource stops
---@param resourceName string Name of the stopping resource
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for stationId, _ in pairs(spawnedProps) do
        DeleteStationProp(stationId)
    end

    -- Cleanup static station blips, points, and zones
    for stationId, _ in pairs(staticStationBlips) do
        RemoveStaticStation(stationId)
    end

    -- Cleanup admin station props, blips, and zones
    for stationKey, _ in pairs(adminStations) do
        RemoveAdminStation(stationKey)
    end
end)

--- Spawn an admin-created station with blip, prop, and target zone
---@param stationKey string The admin station key
---@param station table Station configuration data
local function SpawnAdminStation(stationKey, station)
    if not station or not station.coords then return end

    -- Clean up any existing station to prevent duplicate targets/zones (race between LoadAdminStations and broadcast events)
    if adminStations[stationKey] then
        DeleteStationProp(stationKey)
        if adminStationPoints[stationKey] then
            adminStationPoints[stationKey]:remove()
            adminStationPoints[stationKey] = nil
        end
        if adminStationZones[stationKey] then
            Target.removeZone(adminStationZones[stationKey])
            adminStationZones[stationKey] = nil
        end
        if adminStationBlips[stationKey] then
            RemoveBlip(adminStationBlips[stationKey])
            adminStationBlips[stationKey] = nil
        end
        adminStations[stationKey] = nil
    end

    local coords = type(station.coords) == 'vector3' and station.coords
        or vector3(station.coords.x or 0, station.coords.y or 0, station.coords.z or 0)

    adminStations[stationKey] = {
        label = station.label,
        type = station.type or 'basic',
        coords = coords,
        heading = station.heading or 0,
        radius = station.radius or 2.0,
        recipes = station.recipes,
        techTrees = station.techTrees,
        owner = station.owner,
        prop = station.prop,
        blip = station.blip,
        job = station.job,
        gang = station.gang,
    }

    -- Create blip if enabled
    if station.blip and station.blip.enabled then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, tonumber(station.blip.sprite) or 566)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, (tonumber(station.blip.scale) or 0.7) + 0.0)
        SetBlipColour(blip, tonumber(station.blip.color) or 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.blip.label or station.label)
        EndTextCommandSetBlipName(blip)
        adminStationBlips[stationKey] = blip
    end

    -- Create prop with distance-based spawning, or sphere target zone
    local hasProp = station.prop and station.prop.enabled and station.prop.model

    if hasProp then
        local spawnRadius = station.prop.spawnRadius or 50.0

        adminStationPoints[stationKey] = lib.points.new({
            coords = coords,
            distance = spawnRadius,
            stationId = stationKey,
            station = adminStations[stationKey],
            onEnter = function(self)
                SpawnStationProp(self.stationId, self.station)
            end,
            onExit = function(self)
                DeleteStationProp(self.stationId)
            end
        })
    else
        local zoneName = 'crafting_' .. stationKey
        adminStationZones[stationKey] = zoneName
        Target.addSphereZone({
            name = zoneName,
            coords = coords,
            radius = station.radius or 2.0,
            debug = Config.Debug,
            options = {
                {
                    name = zoneName,
                    icon = 'fa-solid fa-hammer',
                    label = Locale.T('target.openStation', { station = station.label }),
                    onSelect = function()
                        local stationData = adminStations[stationKey]
                        if stationData and not CheckWorkbenchAccess(stationData.job, stationData.gang) then
                            return
                        end
                        if stationData and stationData.owner and GetPlayerIdentifier() ~= stationData.owner then
                            ShowNotification({
                                title = Locale.T('notifications.workbench.accessDenied'),
                                description = Locale.T('permissions.accessDenied'),
                                type = 'error'
                            })
                            return
                        end
                        OpenCraftingUI(stationKey)
                    end
                }
            }
        })
    end

    debugPrint('Spawned admin station:', stationKey)
end

--- Remove an admin-created station (prop, blip, target zone)
---@param stationKey string The admin station key to remove
function RemoveAdminStation(stationKey)
    -- Delete prop if spawned
    DeleteStationProp(stationKey)

    -- Remove lib.points distance tracker
    if adminStationPoints[stationKey] then
        adminStationPoints[stationKey]:remove()
        adminStationPoints[stationKey] = nil
    end

    -- Remove sphere zone
    if adminStationZones[stationKey] then
        Target.removeZone(adminStationZones[stationKey])
        adminStationZones[stationKey] = nil
    end

    -- Remove blip
    if adminStationBlips[stationKey] then
        RemoveBlip(adminStationBlips[stationKey])
        adminStationBlips[stationKey] = nil
    end

    adminStations[stationKey] = nil

    debugPrint('Removed admin station:', stationKey)
end

--- Load all admin stations from server on connect
local function LoadAdminStations()
    local stations = lib.callback.await('sd-crafting:server:getAdminStations', false)
    if stations then
        for stationKey, stationData in pairs(stations) do
            SpawnAdminStation(stationKey, stationData)
        end
        local count = 0
        for _ in pairs(stations) do count = count + 1 end
        debugPrint(('Loaded %d admin stations'):format(count))
    end
end

--- Handle server broadcast to spawn a new admin station
---@param stationKey string The admin station key
---@param stationData table Station configuration data
RegisterNetEvent('sd-crafting:client:spawnAdminStation', function(stationKey, stationData)
    SpawnAdminStation(stationKey, stationData)
end)

--- Handle server broadcast to remove an admin station
---@param stationKey string The admin station key to remove
RegisterNetEvent('sd-crafting:client:removeAdminStation', function(stationKey)
    RemoveAdminStation(stationKey)
end)

--- Handle server broadcast to refresh an admin station (remove and re-add)
---@param stationKey string The admin station key
---@param stationData table Updated station configuration data
RegisterNetEvent('sd-crafting:client:refreshAdminStation', function(stationKey, stationData)
    RemoveAdminStation(stationKey)
    SpawnAdminStation(stationKey, stationData)
end)

--- Handle server broadcast to refresh a static station (remove and re-spawn with new data)
---@param stationKey string The Config.Stations key
---@param stationData table Updated station configuration data
RegisterNetEvent('sd-crafting:client:refreshStaticStation', function(stationKey, stationData)
    -- Update local Config.Stations with new fields
    if Config.Stations[stationKey] then
        if stationData.label ~= nil then Config.Stations[stationKey].label = stationData.label end
        if stationData.type ~= nil then Config.Stations[stationKey].type = stationData.type end
        if stationData.radius ~= nil then Config.Stations[stationKey].radius = stationData.radius end
        if stationData.recipes ~= nil then Config.Stations[stationKey].recipes = stationData.recipes end
        if stationData.techTrees ~= nil then Config.Stations[stationKey].techTrees = stationData.techTrees end
        if stationData.blip ~= nil then Config.Stations[stationKey].blip = stationData.blip end
        if stationData.prop ~= nil then Config.Stations[stationKey].prop = stationData.prop end
        if stationData.owner ~= nil then Config.Stations[stationKey].owner = stationData.owner or nil end
        if stationData.job ~= nil then Config.Stations[stationKey].job = stationData.job end
        if stationData.gang ~= nil then Config.Stations[stationKey].gang = stationData.gang end
        if stationData.coords then
            Config.Stations[stationKey].coords = type(stationData.coords) == 'vector3' and stationData.coords
                or vector3(stationData.coords.x or 0, stationData.coords.y or 0, stationData.coords.z or 0)
        end
        if stationData.heading ~= nil then Config.Stations[stationKey].heading = stationData.heading end
    end

    RemoveStaticStation(stationKey)
    SpawnStaticStation(stationKey, Config.Stations[stationKey])
end)

local spawnedShopPeds = {} -- Track spawned shop peds by shopId

--- Spawn a shop ped and add target interaction
---@param shopId string The shop identifier
---@param shop table Shop configuration from Config.Shops
local function SpawnShopPed(shopId, shop)
    if spawnedShopPeds[shopId] then return end

    local model = shop.model
    if not model then return end

    lib.requestModel(model)

    local ped = CreatePed(0, model, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.heading or 0.0, false, false)
    SetEntityHeading(ped, shop.heading or 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)

    if shop.scenario then
        TaskStartScenarioInPlace(ped, shop.scenario, 0, true)
    end

    spawnedShopPeds[shopId] = ped

    Target.addLocalEntity(ped, {
        {
            name = 'shop_' .. shopId,
            icon = 'fa-solid fa-store',
            label = Locale.T('target.browseShop', { shop = shop.label }),
            onSelect = function()
                OpenShopMenu(shopId, shop)
            end
        }
    })

    debugPrint('Spawned shop ped for:', shopId, 'Entity:', ped)
end

--- Delete a shop ped and remove target
---@param shopId string The shop identifier
local function DeleteShopPed(shopId)
    local ped = spawnedShopPeds[shopId]
    if not ped then return end

    if DoesEntityExist(ped) then
        Target.removeLocalEntity(ped)
        DeleteEntity(ped)
    end

    spawnedShopPeds[shopId] = nil

    debugPrint('Deleted shop ped for:', shopId)
end

--- Open confirmation dialog for shop purchase
---@param shopId string The shop identifier
---@param item table Item configuration with price and currency
---@param quantity number Quantity to purchase
---@param totalCost number Total cost of the purchase
local function OpenShopConfirmationDialog(shopId, item, quantity, totalCost)
    local confirmMessage = ('Purchase %dx %s for $%s?'):format(quantity, item.label, lib.math.groupdigits(totalCost))

    lib.registerContext({
        id = 'crafting_shop_confirmation',
        title = 'Confirm Purchase',
        options = {
            {
                title = 'Confirm Purchase',
                description = confirmMessage,
                icon = 'dollar-sign',
                onSelect = function()
                    TriggerServerEvent('sd-crafting:server:purchaseShopItem', shopId, item.id, quantity)
                    lib.hideContext()
                end
            },
            {
                title = 'Cancel',
                icon = 'times',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })

    lib.showContext('crafting_shop_confirmation')
end

--- Close currently open shop and notify server
local function CloseCurrentShop()
    if currentOpenShop then
        TriggerServerEvent('sd-crafting:server:closeShop', currentOpenShop)
        currentOpenShop = nil
    end
end

--- Open the shop menu using ox_lib context menu
---@param shopId string The shop identifier
---@param shop table Shop configuration from Config.Shops
function OpenShopMenu(shopId, shop)
    CloseCurrentShop()

    TriggerServerEvent('sd-crafting:server:openShop', shopId)
    currentOpenShop = shopId

    local options = {}
    local useImages = shop.useItemImages ~= false

    for _, item in ipairs(shop.items) do
        local titleText = item.label
        if item.price then
            titleText = ('%s – $%s'):format(item.label, lib.math.groupdigits(item.price))
        end

        local iconString
        if useImages then
            iconString = GetItemImage(item.item or item.id)
        end
        if not iconString or iconString == '' then
            iconString = item.icon or 'box'
        end

        options[#options + 1] = {
            title = titleText,
            description = item.description,
            icon = iconString,
            onSelect = function()
                local input = lib.inputDialog(item.label, {
                    { type = 'number', label = 'Quantity', required = true, min = 1 }
                })

                if input and input[1] then
                    local quantity = math.floor(tonumber(input[1]) or 0)
                    if quantity > 0 then
                        local totalCost = item.price * quantity
                        OpenShopConfirmationDialog(shopId, item, quantity, totalCost)
                    end
                end
            end
        }
    end

    options[#options + 1] = {
        title = 'Close',
        icon = 'arrow-left',
        onSelect = function()
            CloseCurrentShop()
            lib.hideContext()
        end
    }

    lib.registerContext({
        id = 'crafting_shop_' .. shopId,
        title = shop.label,
        options = options,
        onExit = function()
            CloseCurrentShop()
        end
    })

    lib.showContext('crafting_shop_' .. shopId)
end

--- Initialize shop peds with blips and targets
CreateThread(function()
    Wait(1500)

    if not Config.Shops then return end

    for shopId, shop in pairs(Config.Shops) do
        if shop.coords and shop.coords.x ~= 0 then
            if shop.blip and shop.blip.enabled then
                local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
                SetBlipSprite(blip, shop.blip.sprite or 59)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, shop.blip.scale or 0.7)
                SetBlipColour(blip, shop.blip.color or 2)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(shop.blip.label or shop.label)
                EndTextCommandSetBlipName(blip)
            end

            local spawnRadius = shop.spawnRadius or 50.0

            lib.points.new({
                coords = shop.coords,
                distance = spawnRadius,
                shopId = shopId,
                shop = shop,
                onEnter = function(self)
                    SpawnShopPed(self.shopId, self.shop)
                end,
                onExit = function(self)
                    DeleteShopPed(self.shopId)
                end
            })
        end
    end

    debugPrint('Shop peds initialized')
end)

--- Cleanup shop peds when resource stops
---@param resourceName string Name of the stopping resource
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CloseCurrentShop()

    for shopId, _ in pairs(spawnedShopPeds) do
        DeleteShopPed(shopId)
    end
end)

--- Spawn a placed workbench prop and add target interaction
---@param data table Workbench data with id, coords, heading, prop, item, type, and propEnabled
local function SpawnPlacedWorkbenchProp(data)
    if playerPlacedWorkbenches[data.id] then return end

    -- Ensure coords is a proper vector3 (may arrive as plain table from network serialization)
    if data.coords and type(data.coords) ~= 'vector3' then
        data.coords = vector3(data.coords.x or 0, data.coords.y or 0, data.coords.z or 0)
    end

    -- Resolve whether the prop should be spawned (default true for backwards compat)
    local propEnabled = true
    if data.propEnabled ~= nil then propEnabled = data.propEnabled end

    local workbenchConfig = Config.PlaceableWorkbenches[data.item]
    local workbenchLabel = data.label or (workbenchConfig and workbenchConfig.label) or 'Workbench'
    local workbenchRecipes = data.recipes or (workbenchConfig and workbenchConfig.recipes) or { 'all', data.type }
    local workbenchJob = data.job or (workbenchConfig and workbenchConfig.job) or nil
    local workbenchGang = data.gang or (workbenchConfig and workbenchConfig.gang) or nil

    -- Target options shared between prop entity and sphere zone
    local targetOptions = {
        {
            name = 'crafting_placed_' .. data.id,
            icon = 'fa-solid fa-hammer',
            label = Locale.T('target.useWorkbench', { workbench = workbenchLabel }),
            onSelect = function()
                if not CheckWorkbenchAccess(workbenchJob, workbenchGang) then
                    return
                end
                local isOwner = false
                if Config.Permissions and Config.Permissions.enabled then
                    local hasPermission, ownerStatus = lib.callback.await('sd-crafting:server:checkWorkbenchPermission', false, data.id)
                    if not hasPermission then
                        ShowNotification({
                            title = Locale.T('notifications.workbench.accessDenied'),
                            description = Locale.T('permissions.accessDenied'),
                            type = 'error'
                        })
                        return
                    end
                    isOwner = ownerStatus
                end
                OpenCraftingUI('placed_' .. data.id, data.type, workbenchRecipes, data.coords, isOwner, data.id)
            end
        },
        {
            name = 'pickup_placed_' .. data.id,
            icon = 'fa-solid fa-hand',
            label = Locale.T('target.pickUpWorkbench'),
            canInteract = function()
                local playerIdentifier = GetPlayerIdentifier()
                return playerIdentifier and playerIdentifier == data.owner
            end,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = Locale.T('notifications.workbench.pickupConfirmTitle'),
                    content = Locale.T('notifications.workbench.pickupConfirmContent'),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    local success = lib.callback.await('sd-crafting:server:pickupWorkbench', false, data.id)
                end
            end
        }
    }

    local entity = nil
    local zoneName = nil

    if propEnabled and data.prop then
        -- Prop enabled: spawn entity and attach target to it
        local model = data.prop
        lib.requestModel(model)
        entity = CreateObject(model, data.coords.x, data.coords.y, data.coords.z, false, false, false)
        SetEntityHeading(entity, data.heading or 0.0)
        FreezeEntityPosition(entity, true)
        SetModelAsNoLongerNeeded(model)
        Target.addLocalEntity(entity, targetOptions)
    else
        -- Prop disabled or no model: use sphere zone for interaction
        zoneName = 'crafting_placed_' .. data.id
        Target.addSphereZone({
            name = zoneName,
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            radius = data.radius or 2.0,
            debug = Config.Debug,
            options = targetOptions,
        })
    end

    playerPlacedWorkbenches[data.id] = {
        entity = entity,
        zoneName = zoneName,
        data = data
    }

    -- Create blip if enabled
    if data.blip and data.blip.enabled then
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, tonumber(data.blip.sprite) or 566)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, (tonumber(data.blip.scale) or 0.7) + 0.0)
        SetBlipColour(blip, tonumber(data.blip.color) or 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(data.blip.label or data.label or 'Workbench')
        EndTextCommandSetBlipName(blip)
        placedWorkbenchBlips[data.id] = blip
    end

    debugPrint(('Spawned placed workbench %d at %.2f, %.2f, %.2f (prop=%s)'):format(data.id, data.coords.x, data.coords.y, data.coords.z, tostring(propEnabled)))
end

--- Remove a placed workbench prop and cleanup target, zone, and blip
---@param id number The workbench ID
local function RemovePlacedWorkbenchProp(id)
    local workbench = playerPlacedWorkbenches[id]
    if not workbench then return end

    -- Remove prop entity and its target if it exists
    if workbench.entity and DoesEntityExist(workbench.entity) then
        Target.removeLocalEntity(workbench.entity)
        DeleteEntity(workbench.entity)
    end

    -- Remove sphere zone target if it exists (prop was disabled)
    if workbench.zoneName then
        Target.removeZone(workbench.zoneName)
    end

    -- Remove blip if one exists
    if placedWorkbenchBlips[id] then
        RemoveBlip(placedWorkbenchBlips[id])
        placedWorkbenchBlips[id] = nil
    end

    playerPlacedWorkbenches[id] = nil

    debugPrint(('Removed placed workbench %d'):format(id))
end

--- Load all placed workbenches from server and spawn props
local function LoadAllPlacedWorkbenches()
    local workbenches = lib.callback.await('sd-crafting:server:getPlacedWorkbenches', false)
    if workbenches then
        for _, data in ipairs(workbenches) do
            SpawnPlacedWorkbenchProp(data)
        end
        debugPrint(('Loaded %d placed workbenches'):format(#workbenches))
    end
end

--- Handle spawning a newly placed workbench
---@param data table Workbench data with id, coords, heading, prop, item, and type
RegisterNetEvent('sd-crafting:client:spawnPlacedWorkbench', function(data)
    SpawnPlacedWorkbenchProp(data)
end)

--- Handle removing a placed workbench
---@param id number The workbench ID to remove
RegisterNetEvent('sd-crafting:client:removePlacedWorkbench', function(id)
    RemovePlacedWorkbenchProp(id)
end)

--- Handle server broadcast to refresh a placed workbench (remove and re-spawn with new data)
---@param id number The workbench ID
---@param workbenchData table Updated workbench data
RegisterNetEvent('sd-crafting:client:refreshPlacedWorkbench', function(id, workbenchData)
    RemovePlacedWorkbenchProp(id)
    SpawnPlacedWorkbenchProp(workbenchData)
end)

--- Handle player workbench placement (gizmo or raycast based on config)
---@param itemName string The workbench item name
---@param workbenchData table Workbench configuration from Config.PlaceableWorkbenches
RegisterNetEvent('sd-crafting:client:startWorkbenchPlacement', function(itemName, workbenchData)
    if isPlacingWorkbench then
        lib.notify({
            title = Locale.T('notifications.workbench.title'),
            description = Locale.T('notifications.workbench.alreadyPlacing'),
            type = 'error'
        })
        return
    end

    isPlacingWorkbench = true
    local model = workbenchData.prop

    lib.requestModel(model)

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Use raycast placement if useGizmo is false
    if Config.useGizmo == false then
        -- Raycast-based placement (like sd-beekeeping)
        local tempProp = CreateObject(model, 1.0, 1.0, 1.0, false, false, false)
        SetEntityHeading(tempProp, heading)
        SetEntityAlpha(tempProp, 200, false)
        SetEntityCollision(tempProp, false, false)
        FreezeEntityPosition(tempProp, true)
        SetModelAsNoLongerNeeded(model)

        if not DoesEntityExist(tempProp) then
            lib.notify({
                title = Locale.T('notifications.workbench.title'),
                description = Locale.T('notifications.workbench.spawnFailed'),
                type = 'error'
            })
            isPlacingWorkbench = false
            return
        end

        local currentHeading = heading
        local raycastDistance = Config.raycastDistance or 10.0

        CreateThread(function()
            local scaleform = SetupPlacementScaleform()

            while isPlacingWorkbench and DoesEntityExist(tempProp) do
                local hit, hitCoords = RayCastGamePlayCamera(raycastDistance)
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

                if hit then
                    local success, groundZ = GetGroundZFor_3dCoord(hitCoords.x, hitCoords.y, hitCoords.z + 10.0, false)
                    if success then
                        local modelHash = GetEntityModel(tempProp)
                        local minDim, _ = GetModelDimensions(modelHash)
                        local zOffset = -minDim.z

                        SetEntityCoords(tempProp, hitCoords.x, hitCoords.y, groundZ + zOffset, false, false, false, true)
                    end
                end

                -- Rotate with scroll wheel or arrow keys (hold Shift for fine rotation)
                local isShiftHeld = IsControlPressed(0, 21) -- Left Shift
                local rotationStep = isShiftHeld and 1.0 or 5.0

                if IsControlJustPressed(0, 15) then -- Scroll up / Right arrow
                    currentHeading = (currentHeading + rotationStep) % 360
                    SetEntityHeading(tempProp, currentHeading)
                end
                if IsControlJustPressed(0, 14) then -- Scroll down / Left arrow
                    currentHeading = (currentHeading - rotationStep) % 360
                    if currentHeading < 0 then currentHeading = currentHeading + 360 end
                    SetEntityHeading(tempProp, currentHeading)
                end

                -- Cancel with Backspace
                if IsControlJustPressed(0, 177) then
                    lib.notify({
                        title = Locale.T('notifications.workbench.title'),
                        description = Locale.T('notifications.workbench.cancelled'),
                        type = 'error'
                    })
                    DeleteEntity(tempProp)
                    isPlacingWorkbench = false
                    return
                end

                -- Place with Enter
                if IsControlJustPressed(0, 176) then
                    local finalCoords = GetEntityCoords(tempProp)
                    local finalHeading = GetEntityHeading(tempProp)

                    local x = math.floor(finalCoords.x * 100 + 0.5) / 100
                    local y = math.floor(finalCoords.y * 100 + 0.5) / 100
                    local z = math.floor(finalCoords.z * 100 + 0.5) / 100
                    local h = math.floor(finalHeading * 10 + 0.5) / 10

                    DeleteEntity(tempProp)

                    local success, workbenchId = lib.callback.await('sd-crafting:server:placeWorkbench', false, itemName, vector3(x, y, z), h)

                    if not success then
                        lib.notify({
                            title = Locale.T('notifications.workbench.title'),
                            description = Locale.T('notifications.workbench.placeFailed'),
                            type = 'error'
                        })
                    end

                    isPlacingWorkbench = false
                    return
                end

                Wait(0)
            end

            isPlacingWorkbench = false
        end)
    else
        -- Gizmo-based placement (original method)
        local forwardX = coords.x + (math.sin(math.rad(-heading)) * 2.0)
        local forwardY = coords.y + (math.cos(math.rad(-heading)) * 2.0)

        local tempProp = CreateObject(model, forwardX, forwardY, coords.z, false, false, false)
        SetEntityHeading(tempProp, heading)
        FreezeEntityPosition(tempProp, true)
        SetModelAsNoLongerNeeded(model)

        if not DoesEntityExist(tempProp) then
            lib.notify({
                title = Locale.T('notifications.workbench.title'),
                description = Locale.T('notifications.workbench.spawnFailed'),
                type = 'error'
            })
            isPlacingWorkbench = false
            return
        end

        lib.notify({
            title = Locale.T('notifications.workbench.placementTitle'),
            description = Locale.T('notifications.workbench.gizmoInstructions'),
            type = 'inform',
            duration = 10000
        })

        local gizmoExport = exports['object_gizmo']
        if not gizmoExport then
            lib.notify({
                title = Locale.T('notifications.error.title'),
                description = Locale.T('notifications.workbench.gizmoError'),
                type = 'error'
            })
            DeleteEntity(tempProp)
            isPlacingWorkbench = false
            return
        end

        gizmoExport:useGizmo(tempProp)

        CreateThread(function()
            while tempProp and DoesEntityExist(tempProp) do
                if IsControlJustPressed(0, 191) then
                    local finalCoords = GetEntityCoords(tempProp)
                    local finalHeading = GetEntityHeading(tempProp)

                    local x = math.floor(finalCoords.x * 100 + 0.5) / 100
                    local y = math.floor(finalCoords.y * 100 + 0.5) / 100
                    local z = math.floor(finalCoords.z * 100 + 0.5) / 100
                    local h = math.floor(finalHeading * 10 + 0.5) / 10

                    -- Release gizmo and clean up input state
                    gizmoExport:useGizmo(nil)
                    Wait(50)
                    SetNuiFocus(false, false)
                    SetNuiFocusKeepInput(false)

                    DeleteEntity(tempProp)
                    tempProp = nil
                    isPlacingWorkbench = false

                    -- Wait for input system to settle before server callback
                    Wait(100)

                    local success, workbenchId = lib.callback.await('sd-crafting:server:placeWorkbench', false, itemName, vector3(x, y, z), h)

                    if not success then
                        lib.notify({
                            title = Locale.T('notifications.workbench.title'),
                            description = Locale.T('notifications.workbench.placeFailed'),
                            type = 'error'
                        })
                    end

                    break
                end

                if IsControlJustPressed(0, 177) then
                    -- Release gizmo and clean up input state
                    gizmoExport:useGizmo(nil)
                    Wait(50)
                    SetNuiFocus(false, false)
                    SetNuiFocusKeepInput(false)

                    DeleteEntity(tempProp)
                    tempProp = nil
                    isPlacingWorkbench = false

                    Wait(100)

                    lib.notify({
                        title = Locale.T('notifications.workbench.title'),
                        description = Locale.T('notifications.workbench.cancelled'),
                        type = 'error'
                    })

                    break
                end

                Wait(0)
            end

            isPlacingWorkbench = false
        end)
    end
end)

--- Load placed workbenches, admin stations, and admin recipes when player spawns
AddEventHandler('playerSpawned', function()
    Wait(2000)
    LoadAdminRecipes()
    RegisterMetadataDisplay()
    LoadAllPlacedWorkbenches()
    LoadAdminStations()
end)

--- Load placed workbenches, admin stations, and admin recipes on resource start for hot reloads
CreateThread(function()
    Wait(3000)
    LoadAdminRecipes()
    RegisterMetadataDisplay()
    LoadAllPlacedWorkbenches()
    LoadAdminStations()
end)

--- Cleanup placed workbenches and save queue when resource stops
---@param resourceName string Name of the stopping resource
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Save crafting queue one final time before resource stops
    if #craftingQueue > 0 and not isSharedCraftingEnabled then
        SaveQueueToServer()
        debugPrint('Saved crafting queue on resource stop')
    end

    for id, _ in pairs(playerPlacedWorkbenches) do
        RemovePlacedWorkbenchProp(id)
    end
end)

--- Load saved crafting queue from server after reconnect
local function LoadSavedQueue()
    local savedData, completedCount = lib.callback.await('sd-crafting:server:getSavedQueue', false)

    -- Notify about items completed while offline
    if completedCount and completedCount > 0 then
        ShowNotification({
            title = Locale.T('notifications.crafting.title'),
            description = Locale.T('notifications.crafting.completedWhileOffline', { count = completedCount }),
            type = 'success'
        })
    end

    if savedData and savedData.queue and #savedData.queue > 0 then
        craftingQueue = savedData.queue
        nearbyCraftingStation = savedData.stationId
        nearbyCraftingCoords = savedData.coords

        -- Ensure all recipes have labels
        for _, item in ipairs(craftingQueue) do
            if item.recipe and not item.recipe.label then
                item.recipe.label = GetItemLabel(item.recipe.name) or item.recipe.name
            end
        end

        ShowNotification({
            title = Locale.T('notifications.crafting.title'),
            description = Locale.T('notifications.crafting.queueRestored', { count = #craftingQueue }),
            type = 'inform'
        })

        -- Open the station for server validation
        if nearbyCraftingStation then
            TriggerServerEvent('sd-crafting:server:openStation', nearbyCraftingStation)
        end

        -- Start processing the restored queue
        ProcessQueue()

        debugPrint('Restored saved crafting queue with', #craftingQueue, 'items, completed while offline:', completedCount or 0)
    end
end

--- Initialize player source and item cache on resource start
CreateThread(function()
    Wait(1000)
    playerSource = GetPlayerServerId(PlayerId())
    debugPrint('Player source:', playerSource)

    -- Pre-cache all item data (images, labels) for better performance
    Wait(500)
    InitializeItemCache()

    -- Check for saved crafting queue after server restart
    Wait(1000)
    LoadSavedQueue()
end)

--- Force close the crafting UI (used by craftsimrelog command)
RegisterNetEvent('sd-crafting:client:forceClose', function()
    if isUIOpen then
        CloseCraftingUI(true)
    end
    -- Cancel any active processing so the server can take over
    if isProcessingQueue then
        queueGeneration = queueGeneration + 1
        isProcessingQueue = false
    end
    craftingQueue = {}
    nearbyCraftingStation = nil
    nearbyCraftingCoords = nil
    isMonitoringDistance = false
    debugPrint('forceClose: Client state cleared for simulated disconnect')
end)

--- Simulate a reconnect by re-running LoadSavedQueue (used by craftsimrelog command)
RegisterNetEvent('sd-crafting:client:simulateReconnect', function()
    debugPrint('simulateReconnect: Running LoadSavedQueue')
    LoadSavedQueue()
end)

--- Handle shared queue sync from server
---@param syncStationId string Station identifier this sync is for
---@param queue table The updated shared queue from server
RegisterNetEvent('sd-crafting:client:syncSharedQueue', function(syncStationId, queue)
    if not isSharedCraftingEnabled then return end
    -- Only process syncs for the currently viewed station
    -- Background station processing manages its own state independently
    if not currentStation or syncStationId ~= currentStation then return end
    debugPrint('syncSharedQueue: Received', #queue, 'items from server for station:', syncStationId)

    -- Update local queue with server queue, but skip recently completed items
    local newQueue = {}
    local foundRecentlyCompleted = false
    for _, item in ipairs(queue) do
        -- Skip the item we just completed locally to prevent flickering
        if item.id == recentlyCompletedItemId then
            foundRecentlyCompleted = true
        else
            -- Ensure recipe has a label (may be missing from server data)
            local recipe = item.recipe
            if recipe and not recipe.label then
                recipe.label = GetItemLabel(recipe.name) or recipe.name
            end

            newQueue[#newQueue + 1] = {
                id = item.id,
                recipe = recipe,
                quantity = item.quantity,
                owner = item.owner,
                ownerName = item.ownerName,
                startTime = item.startTime,
                totalTime = item.totalTime,
                remainingTime = item.remainingTime,
                workbenchType = item.workbenchType,
                craftToken = item.craftToken,
                stationId = item.stationId or currentStation
            }
        end
    end
    UpdateCraftingQueue(newQueue)

    -- Clear the recently completed ID if the server no longer has it
    if not foundRecentlyCompleted then
        recentlyCompletedItemId = nil
    end

    -- Update NUI
    if isUIOpen then
        SendNUIMessage({
            action = 'updateQueue',
            queue = GetQueueForNUI()
        })
    end

    -- Start processing if we own the first item and not already processing
    if #craftingQueue > 0 and craftingQueue[1].owner == playerSource and not isProcessingQueue then
        ProcessQueue()
    end
end)

--- Handle admin-triggered inventory refresh after items are given/refunded
--- Refreshes both the player inventory and staged items panels in the NUI
RegisterNetEvent('sd-crafting:client:adminRefreshInventory', function()
    if isUIOpen then
        UpdateInventoryNUI()
        UpdateStagedItemsNUI()
    end
end)

--- Handle admin-triggered personal queue sync (cancel, remove, force-complete)
---@param queue table The updated personal queue from server (may be empty)
RegisterNetEvent('sd-crafting:client:adminSyncPersonalQueue', function(queue)
    debugPrint('adminSyncPersonalQueue: Received', #queue, 'items from server')

    -- Build new queue with recipe labels resolved
    local newQueue = {}
    for _, item in ipairs(queue) do
        local recipe = item.recipe
        if recipe and not recipe.label then
            recipe.label = GetItemLabel(recipe.name) or recipe.name
        end
        newQueue[#newQueue + 1] = {
            id = item.id,
            recipe = recipe,
            quantity = item.quantity,
            owner = item.owner,
            ownerName = item.ownerName,
            startTime = item.startTime,
            totalTime = item.totalTime,
            remainingTime = item.remainingTime,
            workbenchType = item.workbenchType,
            craftToken = item.craftToken,
            stationId = item.stationId,
        }
    end

    -- Check if the currently active item was removed
    local activeRemoved = isProcessingQueue and #craftingQueue > 0
    if activeRemoved then
        local activeId = craftingQueue[1].id
        local found = false
        for _, item in ipairs(newQueue) do
            if item.id == activeId then
                found = true
                break
            end
        end
        activeRemoved = not found
    end

    -- If the active item was removed, bump generation to kill the ProcessQueue thread
    if activeRemoved then
        debugPrint('adminSyncPersonalQueue: Active item was removed, bumping generation from:', queueGeneration)
        queueGeneration = queueGeneration + 1
        isProcessingQueue = false
        StopCraftingAnimation()
    end

    craftingQueue = newQueue

    -- Update NUI
    if isUIOpen then
        SendNUIMessage({
            action = 'updateQueue',
            queue = GetQueueForNUI()
        })
    end

    -- If there are remaining items and we're not processing, restart
    if #craftingQueue > 0 and not isProcessingQueue then
        ProcessQueue()
    end
end)

