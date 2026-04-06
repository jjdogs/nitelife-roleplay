local Config = require('configs/config') -- Main configuration from configs/config.lua
local TechTrees = require('configs/techtrees') -- Tech tree definitions from configs/techtrees.lua
local Recipes = require('configs/recipes') -- Recipe definitions from configs/recipes.lua
local LogsConfig = require('configs/logs') -- Logging configuration from configs/logs.lua

-- Initialize the Logger with the logs configuration
if LogsConfig and LogsConfig.logs then
    Logger.Setup(LogsConfig.logs)
end

local StationBlueprints = {} -- Blueprint storage: { [stationId] = { [blueprintItem] = true } }
PlayerData = {} -- Player data cache: { [identifier] = { xp, level, tech_points, unlocked_nodes } }
StagedItems = {} -- Staged items: { [stationId] = { [identifier or 'shared'] = { {item, count, slot} } } }
local OpenStations = {} -- Track open stations: { [stationId] = { [source] = true } }
PlacedWorkbenches = {} -- Placed workbenches: { [id] = { id, owner, item, type, prop, coords, heading } }
local OpenShops = {} -- Track open shops: { [shopId] = { [source] = true } }
SharedQueues = {} -- Shared crafting queues: { [stationId] = { {id, recipe, quantity, owner, ownerName, startTime, totalTime, remainingTime} } }
SharedWorkbenchTech = {} -- Shared tech data for placed workbenches: { [techId] = { tech_points = 0, unlocked_nodes = {} } }

--- Generate a unique persistent tech ID for shared workbench tech data
---@return string techId A unique identifier like "tech_<timestamp>_<random>"
local function GenerateTechId()
    return ('tech_%d_%d'):format(os.time(), math.random(100000, 999999))
end
PlayerCraftingQueues = {} -- Persisted crafting queues: { [identifier] = { queue = {}, stationId, workbenchType, coords } }
ServerProcessedQueues = {} -- Queues being processed server-side: { [identifier] = { queue = {}, stationId, stagingKey, isShared, offlineCompletedCount } }
local ServerQueueProcessingActive = false -- Flag to track if server processing loop is running
DirtySharedQueues = {} -- Shared queues that need saving: { [stationId] = true }
DirtyPlayerQueues = {} -- Player queues that need saving: { [identifier] = true }
local QueueSaveThreadActive = false -- Flag to track if periodic save thread is running
local PendingCrafts = {} -- Server-side craft token ledger: { [craftToken] = { identifier, recipeId, quantity, stationId, startedAt, craftTime } }
local craftTokenCounter = 0 -- Monotonically increasing counter for token uniqueness
local CraftCompletionTimestamps = {} -- Per-player per-station last craft completion time: { [identifier:stationId] = os.time() }

AdminStations = {} -- Admin-created stations from database: { [stationKey] = stationConfig }
AdminTypes = {} -- Admin-created workbench types from database: { [typeName] = { levels?, maxLevel? } }
StationOverrides = {} -- Override data for static/placed stations from database: { [stationKey] = overrideFields }
AdminTableNames = {} -- In-memory set of admin-created recipe table names: { [tableName] = true }
AdminTechTreeIds = {} -- In-memory set of admin-created/modified tech tree IDs: { [treeId] = true }
local MAX_INTERACTION_DISTANCE = 10.0 -- Maximum distance for station/shop interactions

local BlueprintItemsCache = nil -- Cached lookup table of blueprint item names from recipes: { [blueprintItemName] = true }

--- Check if server-side queue processing should be active
--- Always true unless CancelCraftOnLeave handles everything
---@return boolean
local function ShouldServerProcessQueues()
    return true
end

--- Debug print helper - only prints if Config.Debug is enabled
---@param ... any Arguments to print
function debugPrint(...)
    if Config.Debug then
        print('[sd-crafting:server]', ...)
    end
end

--- Verbose debug print helper - only prints if Config.DebugVerbose is enabled
--- Used for high-frequency logging like per-second queue ticks
---@param ... any Arguments to print
local function debugPrintVerbose(...)
    if Config.DebugVerbose then
        print('[sd-crafting:server:verbose]', ...)
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
    debugPrint('Built blueprint cache with', count, 'blueprint items')

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

--- Rebuild the blueprint cache (call if recipes are modified at runtime)
function RefreshBlueprintCache()
    BlueprintItemsCache = nil
    BuildBlueprintCache()
end

-- Build blueprint cache on load
BuildBlueprintCache()

--- Generate a unique, non-guessable craft token for server-side validation
---@return string token A unique craft token string
local function GenerateCraftToken()
    craftTokenCounter = craftTokenCounter + 1
    return 'ct_' .. os.time() .. '_' .. craftTokenCounter .. '_' .. math.random(100000, 999999)
end

--- Register a craft token in the PendingCrafts ledger
---@param token string The craft token
---@param identifier string Player persistent identifier
---@param recipeId string Recipe ID being crafted
---@param quantity number Quantity being crafted
---@param stationId string Station identifier
---@param craftTime number Total craft time in seconds
local function RegisterCraftToken(token, identifier, recipeId, quantity, stationId, craftTime)
    PendingCrafts[token] = {
        identifier = identifier,
        recipeId = recipeId,
        quantity = quantity,
        stationId = stationId,
        startedAt = os.time(),
        craftTime = craftTime
    }
    debugPrint('Registered craft token:', token, 'for player:', identifier, 'recipe:', recipeId)
end

--- Validate a craft token without consuming it
---@param token string The craft token to validate
---@param identifier string Player persistent identifier to verify ownership
---@param recipeId string|nil Recipe ID to verify (optional)
---@param enforceTime boolean Whether to enforce minimum craft time
---@param skipIdentityCheck boolean|nil Skip identity validation (for shared queue crafts where a different player may complete)
---@return boolean valid Whether the token is valid
---@return string|nil error Error message if invalid
local function ValidateCraftToken(token, identifier, recipeId, enforceTime, skipIdentityCheck)
    debugPrint('ValidateCraftToken: token:', token, 'identifier:', identifier, 'recipeId:', recipeId, 'enforceTime:', enforceTime)
    if not token then
        return false, 'No craft token provided'
    end

    local pending = PendingCrafts[token]
    if not pending then
        return false, 'Invalid or already consumed craft token'
    end

    if not skipIdentityCheck and pending.identifier ~= identifier then
        return false, 'Craft token does not belong to this player'
    end

    if recipeId and pending.recipeId ~= recipeId then
        return false, 'Craft token recipe mismatch'
    end

    if enforceTime then
        local elapsed = os.time() - pending.startedAt
        local minTime = pending.craftTime - 3 -- 3-second tolerance for network latency
        debugPrint('ValidateCraftToken: Time check - elapsed:', elapsed, 'minTime:', minTime, 'craftTime:', pending.craftTime, 'startedAt:', pending.startedAt)
        if minTime > 0 and elapsed < minTime then
            debugPrint('ValidateCraftToken: REJECTED - craft completed too quickly, elapsed:', elapsed, 'vs minTime:', minTime)
            return false, 'Craft completed too quickly (possible exploit)'
        end
    end

    return true
end

--- Consume (remove) a previously validated craft token from the PendingCrafts ledger
---@param token string The craft token to consume
---@param identifier string Player identifier (for debug logging)
local function ConsumeCraftToken(token, identifier)
    PendingCrafts[token] = nil
    debugPrint('Consumed craft token:', token, 'for player:', identifier)
end

--- Validate and consume a craft token in one step (for operations like refund where consumption is immediate)
---@param token string The craft token to validate and consume
---@param identifier string Player persistent identifier to verify ownership
---@param recipeId string|nil Recipe ID to verify (optional)
---@param enforceTime boolean Whether to enforce minimum craft time
---@param skipIdentityCheck boolean|nil Skip identity validation (for shared queue crafts where a different player may complete)
---@return boolean valid Whether the token is valid
---@return string|nil error Error message if invalid
local function ValidateAndConsumeCraftToken(token, identifier, recipeId, enforceTime, skipIdentityCheck)
    local valid, err = ValidateCraftToken(token, identifier, recipeId, enforceTime, skipIdentityCheck)
    if not valid then
        return false, err
    end
    ConsumeCraftToken(token, identifier)
    return true
end

--- Format a raw item name into a readable label
--- Handles camelCase (advancedlockpick -> Advanced Lockpick) and underscores (advanced_lockpick -> Advanced Lockpick)
---@param itemName string The raw item name
---@return string formattedName The formatted label
local function FormatItemName(itemName)
    if not itemName then return '' end
    -- First replace underscores with spaces
    local formatted = itemName:gsub('_', ' ')
    -- Insert space before each capital letter (for camelCase), but not at the start
    formatted = formatted:gsub('(%l)(%u)', '%1 %2')
    -- Capitalize first letter of each word
    formatted = formatted:gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return formatted
end

--- Get player coordinates from server
---@param source number Player server ID
---@return vector3|nil coords Player coordinates or nil if not found
local function GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        return GetEntityCoords(ped)
    end
    return nil
end

--- Calculate distance between two points
---@param coords1 vector3 First coordinate
---@param coords2 vector3 Second coordinate
---@return number distance Distance between points
local function GetDistance(coords1, coords2)
    if not coords1 or not coords2 then return 999999.0 end
    return #(coords1 - coords2)
end

--- Get station coordinates by station ID
---@param stationId string Station identifier
---@return vector3|nil coords Station coordinates or nil if not found
local function GetStationCoords(stationId)
    if not stationId then return nil end

    local numericId = tonumber(stationId:match('^placed_(%d+)$'))
    if numericId and PlacedWorkbenches[numericId] then
        return PlacedWorkbenches[numericId].coords
    end

    local station = GetStationConfig(stationId)
    if station then
        return station.coords
    end

    return nil
end

--- Get shop coordinates by shop ID
---@param shopId string Shop identifier
---@return vector3|nil coords Shop coordinates or nil if not found
local function GetShopCoords(shopId)
    if not shopId then return nil end

    if Config.Shops and Config.Shops[shopId] then
        return Config.Shops[shopId].coords
    end

    return nil
end

--- Check if player has a station open
---@param source number Player server ID
---@param stationId string Station identifier
---@return boolean isOpen Whether player has station open
local function HasStationOpen(source, stationId)
    if not stationId then return false end
    return OpenStations[stationId] and OpenStations[stationId][source] == true
end

--- Check if player has a shop open
---@param source number Player server ID
---@param shopId string Shop identifier
---@return boolean isOpen Whether player has shop open
local function HasShopOpen(source, shopId)
    if not shopId then return false end
    return OpenShops[shopId] and OpenShops[shopId][source] == true
end

--- Check if player is within interaction distance of a station
---@param source number Player server ID
---@param stationId string Station identifier
---@param maxDistance number|nil Maximum allowed distance (defaults to MAX_INTERACTION_DISTANCE)
---@return boolean isNear Whether player is near station
---@return number|nil distance Actual distance if calculable
local function IsPlayerNearStation(source, stationId, maxDistance)
    maxDistance = maxDistance or MAX_INTERACTION_DISTANCE
    local playerCoords = GetPlayerCoords(source)
    local stationCoords = GetStationCoords(stationId)

    if not playerCoords or not stationCoords then
        return false, nil
    end

    local distance = GetDistance(playerCoords, stationCoords)
    return distance <= maxDistance, distance
end

--- Check if player is within interaction distance of a shop
---@param source number Player server ID
---@param shopId string Shop identifier
---@param maxDistance number|nil Maximum allowed distance (defaults to MAX_INTERACTION_DISTANCE)
---@return boolean isNear Whether player is near shop
---@return number|nil distance Actual distance if calculable
local function IsPlayerNearShop(source, shopId, maxDistance)
    maxDistance = maxDistance or MAX_INTERACTION_DISTANCE
    local playerCoords = GetPlayerCoords(source)
    local shopCoords = GetShopCoords(shopId)

    if not playerCoords or not shopCoords then
        return false, nil
    end

    local distance = GetDistance(playerCoords, shopCoords)
    return distance <= maxDistance, distance
end

--- Validate station access (checks both open state and distance)
---@param source number Player server ID
---@param stationId string Station identifier
---@return boolean hasAccess Whether player has access
---@return string|nil error Error message if no access
local function ValidateStationAccess(source, stationId)
    if not HasStationOpen(source, stationId) then
        debugPrint('Security: Player', source, 'attempted action without station open:', stationId)
        return false, 'Station not open'
    end

    local isNear, distance = IsPlayerNearStation(source, stationId)
    if not isNear then
        debugPrint('Security: Player', source, 'too far from station', stationId, '- distance:', distance or 'unknown')
        return false, 'Too far from station'
    end

    return true
end

--- Validate shop access (checks both open state and distance)
---@param source number Player server ID
---@param shopId string Shop identifier
---@return boolean hasAccess Whether player has access
---@return string|nil error Error message if no access
local function ValidateShopAccess(source, shopId)
    if not HasShopOpen(source, shopId) then
        debugPrint('Security: Player', source, 'attempted purchase without shop open:', shopId)
        return false, 'Shop not open'
    end

    local isNear, distance = IsPlayerNearShop(source, shopId)
    if not isNear then
        debugPrint('Security: Player', source, 'too far from shop', shopId, '- distance:', distance or 'unknown')
        return false, 'Too far from shop'
    end

    return true
end

-- Initialize database tables on resource start
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS sd_crafting_players (
            identifier VARCHAR(60) PRIMARY KEY,
            data JSON NOT NULL DEFAULT '{}',
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS sd_crafting_workbenches (
            id INT AUTO_INCREMENT PRIMARY KEY,
            type VARCHAR(20) NOT NULL,
            station_id VARCHAR(60),
            identifier VARCHAR(60) NOT NULL,
            data JSON NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_type (type),
            INDEX idx_station (station_id, identifier),
            INDEX idx_identifier (identifier)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS sd_crafting_permissions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            workbench_id INT NOT NULL,
            identifier VARCHAR(60) NOT NULL,
            name VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_permission (workbench_id, identifier),
            INDEX idx_workbench (workbench_id),
            INDEX idx_identifier (identifier)
        )
    ]])

    -- Create crafting queue persistence table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS sd_crafting_queues (
            identifier VARCHAR(60) PRIMARY KEY,
            queue_data JSON NOT NULL,
            station_id VARCHAR(60),
            workbench_type VARCHAR(60),
            coords JSON,
            saved_at BIGINT NOT NULL DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    -- Add saved_at column if it doesn't exist (for existing databases)
    MySQL.query([[
        ALTER TABLE sd_crafting_queues ADD COLUMN IF NOT EXISTS saved_at BIGINT NOT NULL DEFAULT 0
    ]])

    -- Unified admin data table (replaces 6 separate admin tables)
    -- Must use .await so table exists before MigrateAdminTables() runs
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS sd_crafting_admin (
            id INT AUTO_INCREMENT PRIMARY KEY,
            category VARCHAR(30) NOT NULL,
            `key` VARCHAR(100) NOT NULL,
            data JSON,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY idx_category_key (category, `key`)
        )
    ]])

    local staged = MySQL.query.await("SELECT * FROM sd_crafting_workbenches WHERE type = 'staged'")
    if staged then
        for _, row in ipairs(staged) do
            local stationId = row.station_id
            local identifier = row.identifier or 'shared'
            local items = json.decode(row.data) or {}

            if not StagedItems[stationId] then
                StagedItems[stationId] = {}
            end
            StagedItems[stationId][identifier] = items
        end
    end

    local placed = MySQL.query.await("SELECT * FROM sd_crafting_workbenches WHERE type = 'placed'")
    if placed then
        -- Batch-load all permissions in one query (avoids N+1 per workbench)
        local allPerms = MySQL.query.await("SELECT workbench_id, identifier, name FROM sd_crafting_permissions")
        local permsByWb = {}
        if allPerms then
            for _, p in ipairs(allPerms) do
                if not permsByWb[p.workbench_id] then permsByWb[p.workbench_id] = {} end
                table.insert(permsByWb[p.workbench_id], { identifier = p.identifier, name = p.name or 'Unknown' })
            end
        end

        for _, row in ipairs(placed) do
            local data = json.decode(row.data) or {}
            PlacedWorkbenches[row.id] = {
                id = row.id,
                owner = row.identifier,
                item = data.item,
                type = data.workbench_type,
                prop = data.prop,
                coords = data.coords and vector3(data.coords.x, data.coords.y, data.coords.z) or vector3(0, 0, 0),
                heading = data.heading or 0,
                permissions = permsByWb[row.id] or {},
                techId = data.techId or nil
            }
        end
        print(('[SD-CRAFTING] Loaded %d placed workbenches from database'):format(#placed))
    end

    debugPrint('Database tables initialized')
    debugPrint('Loaded staged items from database')

    LoadAdminRecipes()
    LoadAdminTables()
    LoadAdminTypes()
    LoadAdminTechTrees()
    LoadAdminStations()
    LoadStationOverrides()
end)

--- Load admin-created/modified recipes from database and merge into Recipes table
--- DB data wins over config: if a recipe with the same ID exists, it is replaced.
--- Tombstone rows (data.deleted == true) remove config-defined recipes persistently.
function LoadAdminRecipes()
    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'recipe' })
    if not rows then return end

    -- Pre-build id→index lookup maps per table for O(1) replacement
    local idIndexMaps = {}
    for tableName, recipes in pairs(Recipes) do
        local map = {}
        for i, recipe in ipairs(recipes) do
            if recipe.id then map[recipe.id] = i end
        end
        idIndexMaps[tableName] = map
    end

    local loaded, deleted = 0, 0
    for _, row in ipairs(rows) do
        local recipeData = json.decode(row.data)
        if not recipeData then goto continue end

        local recipeId = row.key
        local tableName = recipeData._table_name
        if not tableName then goto continue end

        -- Strip internal field before runtime use
        recipeData._table_name = nil

        if recipeData.deleted then
            -- Tombstone: remove matching recipe from config
            if Recipes[tableName] then
                local map = idIndexMaps[tableName]
                local idx = map and map[recipeId]
                if idx and Recipes[tableName][idx] and Recipes[tableName][idx].id == recipeId then
                    table.remove(Recipes[tableName], idx)
                    -- Rebuild map after removal (indices shift)
                    local newMap = {}
                    for i, recipe in ipairs(Recipes[tableName]) do
                        if recipe.id then newMap[recipe.id] = i end
                    end
                    idIndexMaps[tableName] = newMap
                    deleted = deleted + 1
                end
            end
        else
            if not Recipes[tableName] then
                Recipes[tableName] = {}
                idIndexMaps[tableName] = {}
            end

            local map = idIndexMaps[tableName]
            local idx = map[recipeId]
            if idx then
                Recipes[tableName][idx] = recipeData
            else
                table.insert(Recipes[tableName], recipeData)
                map[recipeId] = #Recipes[tableName]
            end
            loaded = loaded + 1
        end

        ::continue::
    end

    RefreshBlueprintCache()
    print(('[SD-CRAFTING] Loaded %d admin recipes from database (%d tombstones applied)'):format(loaded, deleted))
end

--- Load admin-created recipe table names from database so empty tables persist across restarts
--- Also populates AdminTableNames in-memory set for fast lookups
function LoadAdminTables()
    local rows = MySQL.query.await('SELECT `key` FROM sd_crafting_admin WHERE category = ?', { 'table' })
    if not rows then return end

    local created = 0
    for _, row in ipairs(rows) do
        AdminTableNames[row.key] = true
        if not Recipes[row.key] then
            Recipes[row.key] = {}
            created = created + 1
        end
    end

    if created > 0 then
        print(('[SD-CRAFTING] Loaded %d admin recipe tables from database'):format(created))
    end
end

--- Load admin-created workbench types from database, including any stored level config
function LoadAdminTypes()
    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'type' })
    if not rows then return end

    local loaded = 0
    for _, row in ipairs(rows) do
        local decoded = (row.data and json.decode(row.data)) or {}
        -- Normalize level keys from JSON string keys ("1","2") to numeric keys (1,2)
        if decoded.levels then
            local normalized = {}
            for k, v in pairs(decoded.levels) do
                normalized[tonumber(k)] = v
            end
            decoded.levels = normalized
        end
        AdminTypes[row.key] = decoded
        loaded = loaded + 1
    end

    if loaded > 0 then
        print(('[SD-CRAFTING] Loaded %d admin workbench types from database'):format(loaded))
    end
end

--- Load admin-created/modified tech trees from database and merge into TechTrees.Trees
--- DB data wins over config: admin trees replace config trees, tombstones remove them.
--- Also populates AdminTechTreeIds in-memory set for fast lookups
function LoadAdminTechTrees()
    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'techtree' })
    if not rows then return end

    local loaded, deleted = 0, 0
    for _, row in ipairs(rows) do
        local treeData = json.decode(row.data)
        if not treeData then goto continue end

        AdminTechTreeIds[row.key] = true

        if treeData.deleted then
            TechTrees.Trees[row.key] = nil
            deleted = deleted + 1
        else
            TechTrees.Trees[row.key] = treeData
            loaded = loaded + 1
        end

        ::continue::
    end

    print(('[SD-CRAFTING] Loaded %d admin tech trees from database (%d tombstones applied)'):format(loaded, deleted))
end

--- Load admin-created stations from database into AdminStations table
function LoadAdminStations()
    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'station' })
    if not rows then return end

    for _, row in ipairs(rows) do
        local stationData = json.decode(row.data)
        if stationData then
            -- Reconstruct vector3 from JSON coords
            if stationData.coords and type(stationData.coords) == 'table' then
                stationData.coords = vector3(
                    stationData.coords.x or 0,
                    stationData.coords.y or 0,
                    stationData.coords.z or 0
                )
            end
            AdminStations[row.key] = stationData
        end
    end

    print(('[SD-CRAFTING] Loaded %d admin stations from database'):format(#rows))
end

--- Apply a set of override fields onto a target station table (mutates target)
---@param target table The station config to merge into
---@param overrideData table The override fields to apply
local function ApplyStationOverride(target, overrideData)
    if overrideData.label ~= nil then target.label = overrideData.label end
    if overrideData.type ~= nil then target.type = overrideData.type end
    if overrideData.radius ~= nil then target.radius = overrideData.radius end
    if overrideData.recipes ~= nil then target.recipes = overrideData.recipes end
    if overrideData.techTrees ~= nil then target.techTrees = overrideData.techTrees end
    if overrideData.blip ~= nil then target.blip = overrideData.blip end
    if overrideData.prop ~= nil then target.prop = overrideData.prop end
    if overrideData.coords ~= nil then
        if type(overrideData.coords) == 'table' and not overrideData.coords.x then
            -- Already a vector3
            target.coords = overrideData.coords
        else
            target.coords = vector3(overrideData.coords.x or 0, overrideData.coords.y or 0, overrideData.coords.z or 0)
        end
    end
    if overrideData.heading ~= nil then target.heading = overrideData.heading end
    if overrideData.owner ~= nil then target.owner = overrideData.owner end
    if overrideData.CraftingBehavior ~= nil then target.CraftingBehavior = overrideData.CraftingBehavior end
    if overrideData.sharedTech ~= nil then target.sharedTech = overrideData.sharedTech end
    if overrideData.job ~= nil then target.job = overrideData.job end
    if overrideData.gang ~= nil then target.gang = overrideData.gang end
end

--- Load station overrides from database and merge into Config.Stations / PlacedWorkbenches
function LoadStationOverrides()
    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'override' })
    if not rows then return end

    local staticCount, placedCount = 0, 0
    for _, row in ipairs(rows) do
        local overrideData = json.decode(row.data)
        if overrideData then
            local stationKey = row.key
            StationOverrides[stationKey] = overrideData

            -- Apply to Config.Stations if it matches a static station key
            if Config.Stations and Config.Stations[stationKey] then
                ApplyStationOverride(Config.Stations[stationKey], overrideData)
                staticCount = staticCount + 1
            end

            -- Apply to PlacedWorkbenches if it matches placed_NNN pattern
            local placedId = stationKey:match('^placed_(%d+)$')
            if placedId then
                placedId = tonumber(placedId)
                if PlacedWorkbenches[placedId] then
                    ApplyStationOverride(PlacedWorkbenches[placedId], overrideData)
                    -- PlacedWorkbenches store prop as a model string + separate enabled flag
                    if type(PlacedWorkbenches[placedId].prop) == 'table' then
                        PlacedWorkbenches[placedId].propEnabled = PlacedWorkbenches[placedId].prop.enabled
                        PlacedWorkbenches[placedId].prop = PlacedWorkbenches[placedId].prop.model
                    end
                    placedCount = placedCount + 1
                end
            end
        end
    end

    print(('[SD-CRAFTING] Loaded %d station overrides (%d static, %d placed)'):format(#rows, staticCount, placedCount))
end

--- Get station config by ID, checking Config.Stations first then AdminStations
---@param stationId string Station identifier
---@return table|nil station Station configuration or nil if not found
function GetStationConfig(stationId)
    if Config.Stations and Config.Stations[stationId] then
        return Config.Stations[stationId]
    end
    if AdminStations[stationId] then
        return AdminStations[stationId]
    end
    return nil
end

--- Save player crafting queue to database
---@param identifier string Player identifier
---@param queueData table Queue data including queue items, stationId, workbenchType, coords
---@param sync boolean|nil If true, use synchronous query (for shutdown)
local function SavePlayerCraftingQueue(identifier, queueData, sync)
    if not identifier then return end

    if not queueData or not queueData.queue or #queueData.queue == 0 then
        -- Remove queue if empty
        if sync then
            MySQL.query.await('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
        else
            MySQL.query('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
        end
        PlayerCraftingQueues[identifier] = nil
        return
    end

    local coordsJson = queueData.coords and json.encode({
        x = queueData.coords.x,
        y = queueData.coords.y,
        z = queueData.coords.z
    }) or nil

    -- Save current time in seconds for offline time calculation
    local savedAt = os.time()

    local query = [[
        INSERT INTO sd_crafting_queues (identifier, queue_data, station_id, workbench_type, coords, saved_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            queue_data = VALUES(queue_data),
            station_id = VALUES(station_id),
            workbench_type = VALUES(workbench_type),
            coords = VALUES(coords),
            saved_at = VALUES(saved_at),
            updated_at = CURRENT_TIMESTAMP
    ]]

    local params = {
        identifier,
        json.encode(queueData.queue),
        queueData.stationId,
        queueData.workbenchType,
        coordsJson,
        savedAt
    }

    if sync then
        MySQL.query.await(query, params)
    else
        MySQL.query(query, params)
    end

    debugPrint('Saved crafting queue for player:', identifier, '- Items:', #queueData.queue, '- SavedAt:', savedAt)
end

--- Process completed crafts from offline time and add items to stash
---@param identifier string Player identifier
---@param stationId string Station identifier
---@param completedItems table Array of completed queue items
local function ProcessOfflineCompletedCrafts(identifier, stationId, completedItems)
    if not completedItems or #completedItems == 0 then return end

    local stagingKey = identifier -- Use player identifier as staging key for offline completions

    for _, item in ipairs(completedItems) do
        -- Clean up craft token from PendingCrafts ledger if present
        if item.craftToken and PendingCrafts[item.craftToken] then
            PendingCrafts[item.craftToken] = nil
        end

        local recipe = item.recipe
        local quantity = item.quantity
        -- Calculate actual output amount
        local outputCount = quantity * (recipe.outputAmount or 1)

        if recipe and recipe.name then
            local itemLabel = Inventory.GetItemLabel(recipe.name) or recipe.name
            local success = AddToStaging(stationId, stagingKey, recipe.name, itemLabel, outputCount, nil, nil)

            if success then
                debugPrint('Added offline-completed craft to stash:', outputCount, 'x', recipe.name, 'for player:', identifier)
            else
                -- If stash is full, log it but we can't give to player since they're offline
                debugPrint('WARNING: Could not add offline-completed craft to stash (full?):', outputCount, 'x', recipe.name)
            end
        end
    end

    -- Broadcast staged items update for when player opens the station
    BroadcastStagedItemsUpdate(stationId, nil)
end

--- Load player crafting queue from database with offline time calculation
---@param identifier string Player identifier
---@return table|nil queueData Queue data or nil if none exists
---@return table|nil completedItems Items that completed while offline (already added to stash)
local function LoadPlayerCraftingQueue(identifier)
    if not identifier then return nil, nil end

    local result = MySQL.query.await('SELECT * FROM sd_crafting_queues WHERE identifier = ?', { identifier })
    if result and result[1] then
        local row = result[1]
        local queue = json.decode(row.queue_data) or {}
        local savedAt = row.saved_at or 0
        local currentTime = os.time()
        local elapsedSeconds = currentTime - savedAt

        local queueData = {
            queue = {},
            stationId = row.station_id,
            workbenchType = row.workbench_type,
            coords = row.coords and json.decode(row.coords) or nil
        }

        -- Convert coords to vector3 if present
        if queueData.coords then
            queueData.coords = vector3(queueData.coords.x, queueData.coords.y, queueData.coords.z)
        end

        local completedItems = {}

        -- Process queue with offline time calculation if enabled
        -- Apply elapsed time to complete crafts that finished while the player was offline
        if ShouldServerProcessQueues() and elapsedSeconds > 0 then
            local remainingElapsed = elapsedSeconds

            debugPrint('Processing offline time for player:', identifier, '- Elapsed:', elapsedSeconds, 'seconds')

            for _, item in ipairs(queue) do
                if remainingElapsed > 0 then
                    -- Subtract elapsed time from remaining time
                    local newRemainingTime = (item.remainingTime or 0) - remainingElapsed

                    if newRemainingTime <= 0 then
                        -- This item completed while offline
                        debugPrint('Offline processing: Item completed -', item.recipe and item.recipe.id or 'unknown', 'newRemainingTime:', newRemainingTime)
                        completedItems[#completedItems + 1] = item
                        -- Reduce elapsed time by how much this item consumed
                        remainingElapsed = -newRemainingTime
                    else
                        -- This item still has time remaining
                        item.remainingTime = newRemainingTime
                        queueData.queue[#queueData.queue + 1] = item
                        remainingElapsed = 0 -- All elapsed time consumed
                    end
                else
                    -- No more elapsed time to subtract, keep item as-is
                    queueData.queue[#queueData.queue + 1] = item
                end
            end

            -- Process completed items - add to stash
            if #completedItems > 0 and queueData.stationId then
                ProcessOfflineCompletedCrafts(identifier, queueData.stationId, completedItems)
            end
        else
            -- No offline tick down, restore queue as-is
            queueData.queue = queue
        end

        debugPrint('Loaded crafting queue for player:', identifier,
            '- Remaining items:', #queueData.queue,
            '- Completed offline:', #completedItems)

        return queueData, completedItems
    end

    return nil, nil
end

--- Delete player crafting queue from database (after completion)
---@param identifier string Player identifier
local function DeletePlayerCraftingQueue(identifier)
    if not identifier then return end
    MySQL.query('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
    PlayerCraftingQueues[identifier] = nil
end

--- Save a shared crafting queue to database
---@param stationId string Station identifier
---@param queue table Queue items array
---@param sync boolean|nil If true, use synchronous query (for shutdown)
local function SaveSharedCraftingQueue(stationId, queue, sync)
    if not stationId then return end

    local identifier = 'shared_' .. stationId

    if not queue or #queue == 0 then
        -- Remove queue if empty
        if sync then
            MySQL.query.await('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
        else
            MySQL.query('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
        end
        return
    end

    -- Get workbench type and coords from station config or placed workbenches
    local workbenchType = nil
    local coords = nil

    local placedId = stationId:match('^placed_(%d+)$')
    if placedId then
        local numericId = tonumber(placedId)
        if numericId and PlacedWorkbenches[numericId] then
            workbenchType = PlacedWorkbenches[numericId].type
            coords = PlacedWorkbenches[numericId].coords
        end
    else
        local station = GetStationConfig(stationId)
        if station then
            workbenchType = station.type
            coords = station.coords
        end
    end

    local coordsJson = coords and json.encode({
        x = coords.x,
        y = coords.y,
        z = coords.z
    }) or nil

    local savedAt = os.time()

    local query = [[
        INSERT INTO sd_crafting_queues (identifier, queue_data, station_id, workbench_type, coords, saved_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            queue_data = VALUES(queue_data),
            station_id = VALUES(station_id),
            workbench_type = VALUES(workbench_type),
            coords = VALUES(coords),
            saved_at = VALUES(saved_at),
            updated_at = CURRENT_TIMESTAMP
    ]]

    local params = {
        identifier,
        json.encode(queue),
        stationId,
        workbenchType,
        coordsJson,
        savedAt
    }

    if sync then
        MySQL.query.await(query, params)
    else
        MySQL.query(query, params)
    end

    debugPrint('Saved shared crafting queue for station:', stationId, '- Items:', #queue)
end

--- Mark a shared queue as dirty (needs saving)
---@param stationId string Station identifier
local function MarkSharedQueueDirty(stationId)
    if stationId then
        DirtySharedQueues[stationId] = true
    end
end

--- Mark a player queue as dirty (needs saving)
---@param identifier string Player identifier
local function MarkPlayerQueueDirty(identifier)
    if identifier then
        DirtyPlayerQueues[identifier] = true
    end
end

--- Save all dirty queues to database
local function SaveDirtyQueues()
    local sharedCount = 0
    local playerCount = 0

    for stationId in pairs(DirtySharedQueues) do
        if SharedQueues[stationId] then
            SaveSharedCraftingQueue(stationId, SharedQueues[stationId])
            sharedCount = sharedCount + 1
        end
        DirtySharedQueues[stationId] = nil
    end

    for identifier in pairs(DirtyPlayerQueues) do
        if PlayerCraftingQueues[identifier] then
            SavePlayerCraftingQueue(identifier, PlayerCraftingQueues[identifier])
            playerCount = playerCount + 1
        end
        DirtyPlayerQueues[identifier] = nil
    end

    if Config.Debug and (sharedCount > 0 or playerCount > 0) then
        print('[SD-CRAFTING] Periodic save: ' .. sharedCount .. ' shared queues, ' .. playerCount .. ' player queues')
    end
end

--- Start the periodic queue save thread (if enabled in config)
local function StartQueueSaveThread()
    if not Config.PeriodicQueueSave or not Config.PeriodicQueueSave.enabled then
        debugPrint('Periodic queue save disabled - queues will only save on disconnect/shutdown')
        return
    end

    if QueueSaveThreadActive then return end
    QueueSaveThreadActive = true

    local saveInterval = (Config.PeriodicQueueSave.interval or 10) * 1000

    CreateThread(function()
        while QueueSaveThreadActive do
            Wait(saveInterval)
            SaveDirtyQueues()
        end
    end)

    debugPrint('Periodic queue save thread started (interval: ' .. (Config.PeriodicQueueSave.interval or 10) .. 's)')
end

--- Process offline time for a crafting queue, completing items that would have finished
---@param queue table Array of queue items to process
---@param elapsedSeconds number Time elapsed since queue was saved
---@param stationId string Station identifier
---@param stagingKey string Staging key for completed items
---@param identifier string Owner identifier for craft token registration
---@return table processedQueue Remaining queue items after offline completion
---@return number completedCount Number of items completed during offline time
local function ProcessQueueOfflineTime(queue, elapsedSeconds, stationId, stagingKey, identifier)
    local remainingElapsed = elapsedSeconds
    local processedQueue = {}
    local completedCount = 0

    for _, item in ipairs(queue) do
        local itemTime = item.remainingTime or 0

        if remainingElapsed >= itemTime then
            CompleteCraftServerSide(item, stationId, stagingKey, identifier)
            completedCount = completedCount + 1
            remainingElapsed = remainingElapsed - itemTime
            debugPrint('Queue item completed offline:', item.recipe and item.recipe.id or 'unknown')
        else
            item.remainingTime = itemTime - remainingElapsed
            remainingElapsed = 0
            table.insert(processedQueue, item)
        end
    end

    -- Re-register craft tokens for remaining items (PendingCrafts is in-memory, lost on restart)
    for _, item in ipairs(processedQueue) do
        if not item.craftToken then
            item.craftToken = GenerateCraftToken()
        end
        local ownerIdent = item.ownerIdentifier or identifier
        local craftTime = item.recipe and item.recipe.craftTime and (item.recipe.craftTime * (item.quantity or 1)) or 0
        RegisterCraftToken(item.craftToken, ownerIdent, item.recipe and item.recipe.id or '', item.quantity or 1, stationId, craftTime)
    end

    return processedQueue, completedCount
end

--- Load all shared crafting queues from database
--- Called during server initialization
local function LoadSharedCraftingQueues()
    local result = MySQL.query.await("SELECT * FROM sd_crafting_queues WHERE identifier LIKE 'shared_%'")
    if not result then return end

    local count = 0
    local totalCompletedCount = 0
    for _, row in ipairs(result) do
        local stationId = row.station_id
        local identifier = row.identifier
        if stationId then
            local queue = json.decode(row.queue_data) or {}
            local savedAt = row.saved_at or 0
            local currentTime = os.time()
            local elapsedSeconds = currentTime - savedAt
            local stagingKey = 'shared'

            -- Process offline time if enabled
            if ShouldServerProcessQueues() and elapsedSeconds > 0 and #queue > 0 then
                debugPrint('Processing offline time for shared queue:', stationId, '- Elapsed:', elapsedSeconds, 'seconds')
                local processedQueue, stationCompletedCount = ProcessQueueOfflineTime(queue, elapsedSeconds, stationId, stagingKey, identifier)
                totalCompletedCount = totalCompletedCount + stationCompletedCount

                -- Set lastProgressSync so GetAdjustedSharedQueue can interpolate from restore time
                local now = GetGameTimer()
                for _, item in ipairs(processedQueue) do
                    item.lastProgressSync = now
                end

                SharedQueues[stationId] = processedQueue

                -- Update the database with processed queue to prevent duplicate completions on restart
                if #processedQueue > 0 then
                    MySQL.query('UPDATE sd_crafting_queues SET queue_data = ?, saved_at = ? WHERE identifier = ?', {
                        json.encode(processedQueue), os.time(), identifier
                    })
                else
                    MySQL.query('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
                end

                if #processedQueue > 0 then
                    count = count + 1
                    AddToServerProcessing(identifier, processedQueue, stationId, stagingKey, stationCompletedCount)
                end
            else
                -- No offline processing needed — just restore tokens and set sync time
                local now = GetGameTimer()
                for _, item in ipairs(queue) do
                    if not item.craftToken then
                        item.craftToken = GenerateCraftToken()
                    end
                    item.lastProgressSync = now
                    local ownerIdent = item.ownerIdentifier or identifier
                    local craftTime = item.recipe and item.recipe.craftTime and (item.recipe.craftTime * (item.quantity or 1)) or 0
                    RegisterCraftToken(item.craftToken, ownerIdent, item.recipe and item.recipe.id or '', item.quantity or 1, stationId, craftTime)
                end

                SharedQueues[stationId] = queue

                if #queue > 0 then
                    count = count + 1
                    AddToServerProcessing(identifier, queue, stationId, stagingKey, 0)
                end
            end
        end
    end

    debugPrint('Loaded', count, 'shared crafting queues from database, completed', totalCompletedCount, 'offline crafts')
end

--- Save all shared crafting queues (for server shutdown)
---@param sync boolean|nil If true, use synchronous queries
local function SaveAllSharedCraftingQueues(sync)
    local count = 0
    for stationId, queue in pairs(SharedQueues) do
        if queue and #queue > 0 then
            SaveSharedCraftingQueue(stationId, queue, sync)
            count = count + 1
        end
    end
    debugPrint('Saved', count, 'shared crafting queues')
end

--- Load all player crafting queues from database for server-side processing
--- Called during server initialization to resume server-side queue processing
local function LoadAllPlayerCraftingQueuesForServerProcessing()
    if not ShouldServerProcessQueues() then return end

    local result = MySQL.query.await("SELECT * FROM sd_crafting_queues WHERE identifier NOT LIKE 'shared_%'")
    if not result then return end

    local count = 0
    local totalCompletedCount = 0

    for _, row in ipairs(result) do
        local identifier = row.identifier
        local stationId = row.station_id
        if identifier and stationId then
            local queue = json.decode(row.queue_data) or {}
            local savedAt = row.saved_at or 0
            local elapsedSeconds = os.time() - savedAt
            local stagingKey = identifier

            if #queue > 0 then
                local processedQueue, playerCompletedCount

                -- Only apply elapsed time if TickDownQueueWhenOffline is enabled (server was down, time passed)
                -- TickDownQueueWhenOffline is false, so queue was frozen during server downtime
                if Config.TickDownQueueWhenOffline and elapsedSeconds > 0 then
                    debugPrint('Processing offline time for player queue:', identifier, '- Elapsed:', elapsedSeconds, 'seconds')
                    processedQueue, playerCompletedCount = ProcessQueueOfflineTime(queue, elapsedSeconds, stationId, stagingKey, identifier)
                    totalCompletedCount = totalCompletedCount + playerCompletedCount
                else
                    processedQueue = queue
                    playerCompletedCount = 0
                    -- Re-register craft tokens for items (PendingCrafts is in-memory, lost on restart)
                    for _, item in ipairs(processedQueue) do
                        if not item.craftToken then
                            item.craftToken = GenerateCraftToken()
                        end
                        local ownerIdent = item.ownerIdentifier or identifier
                        local craftTime = item.recipe and item.recipe.craftTime and (item.recipe.craftTime * (item.quantity or 1)) or 0
                        RegisterCraftToken(item.craftToken, ownerIdent, item.recipe and item.recipe.id or '', item.quantity or 1, stationId, craftTime)
                    end
                end

                if #processedQueue > 0 then
                    count = count + 1
                    AddToServerProcessing(identifier, processedQueue, stationId, stagingKey, playerCompletedCount)

                    MySQL.query('UPDATE sd_crafting_queues SET queue_data = ?, saved_at = ? WHERE identifier = ?', {
                        json.encode(processedQueue), os.time(), identifier
                    })
                else
                    -- Queue is empty, but track completed count for player notification
                    if playerCompletedCount > 0 then
                        ServerProcessedQueues[identifier] = {
                            queue = {},
                            stationId = stationId,
                            stagingKey = stagingKey,
                            isShared = false,
                            offlineCompletedCount = playerCompletedCount
                        }
                    end
                    MySQL.query('DELETE FROM sd_crafting_queues WHERE identifier = ?', { identifier })
                end
            end
        end
    end

    debugPrint('Loaded', count, 'player crafting queues for server processing, completed', totalCompletedCount, 'offline crafts')
end

--- Save all player crafting queues (for server shutdown)
--- Uses synchronous queries to ensure saves complete before shutdown
local function SaveAllPlayerCraftingQueues()
    local count = 0
    for identifier, queueData in pairs(PlayerCraftingQueues) do
        SavePlayerCraftingQueue(identifier, queueData, true) -- sync = true for shutdown
        count = count + 1
    end
    debugPrint('Saved', count, 'player crafting queues on shutdown')

    -- Also save shared queues
    SaveAllSharedCraftingQueues(true)
end

--- Save all server-processed queues (for server shutdown)
--- Uses synchronous queries to ensure saves complete before shutdown
local function SaveAllServerProcessedQueues()
    local count = 0
    for identifier, data in pairs(ServerProcessedQueues) do
        if data.queue and #data.queue > 0 then
            local queueData = {
                queue = data.queue,
                stationId = data.stationId,
                workbenchType = data.workbenchType
            }

            -- Determine if this is a shared or player queue
            if identifier:match('^shared_') then
                SaveSharedCraftingQueue(data.stationId, data.queue, true)
            else
                SavePlayerCraftingQueue(identifier, queueData, true)
            end
            count = count + 1
        end
    end
    debugPrint('Saved', count, 'server-processed queues on shutdown')
end

--- Complete a craft server-side without requiring player source
--- Used for offline player crafts and shared queue processing
---@param queueItem table The queue item to complete (may contain craftToken)
---@param stationId string Station identifier
---@param stagingKey string Staging key for adding items
---@param identifier string Player identifier or shared identifier
---@return boolean success Whether the craft was completed successfully
function CompleteCraftServerSide(queueItem, stationId, stagingKey, identifier)
    debugPrint('CompleteCraftServerSide: stationId=' .. tostring(stationId) .. ', stagingKey=' .. tostring(stagingKey) .. ', identifier=' .. tostring(identifier))
    debugPrint('CompleteCraftServerSide: recipe.name=' .. tostring(queueItem.recipe and queueItem.recipe.name) .. ', quantity=' .. tostring(queueItem.quantity) .. ', outputAmount=' .. tostring(queueItem.recipe and queueItem.recipe.outputAmount))

    -- Consume craft token if present (clean up PendingCrafts ledger for server-processed items)
    if queueItem.craftToken and PendingCrafts[queueItem.craftToken] then
        PendingCrafts[queueItem.craftToken] = nil
    end

    local recipe = queueItem.recipe
    local quantity = queueItem.quantity or 1
    -- Calculate actual output amount
    local outputCount = quantity * (recipe.outputAmount or 1)

    if not recipe or not recipe.name then
        debugPrint('CompleteCraftServerSide: FAILED - recipe or recipe.name is nil')
        return false
    end

    local itemLabel = Inventory.GetItemLabel(recipe.name) or recipe.name
    debugPrint('CompleteCraftServerSide: Calling AddToStaging - stationId=' .. tostring(stationId) .. ', item=' .. tostring(recipe.name) .. ', count=' .. outputCount)
    local success = AddToStaging(stationId, stagingKey, recipe.name, itemLabel, outputCount, nil, nil)

    if success then
        debugPrint('CompleteCraftServerSide: SUCCESS - added', outputCount, 'x', recipe.name, 'to staging')

        SaveCraftingHistory(stationId, identifier, queueItem.ownerName or 'Offline', recipe.id or recipe.name, recipe.label or recipe.name, quantity, recipe.name, recipe.label or recipe.name, recipe.outputAmount or 1, recipe.ingredients)

        -- Broadcast staged items update
        BroadcastStagedItemsUpdate(stationId, nil)

        -- Notify player if online
        local isSharedIdentifier = identifier:match('^shared_')
        if not isSharedIdentifier then
            -- Try to find player by identifier and notify them
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdent = GetIdentifier(tonumber(playerId))
                if playerIdent == identifier then
                    TriggerClientEvent('sd-crafting:client:notify', tonumber(playerId), {
                        title = 'Crafting Complete',
                        description = 'Crafted ' .. outputCount .. 'x ' .. itemLabel .. ' (added to crafting stash)',
                        type = 'success'
                    })
                    break
                end
            end
        end
    else
        debugPrint('WARNING: Server-side craft could not add to stash:', outputCount, 'x', recipe.name)
    end

    return success
end

--- Process all server-side queues (tick down time and complete crafts)
local function ProcessServerQueues()
    if not ShouldServerProcessQueues() then return end

    for identifier, data in pairs(ServerProcessedQueues) do
        local queue = data.queue
        local stationId = data.stationId
        local stagingKey = data.stagingKey

        if queue and #queue > 0 then
            local firstItem = queue[1]
            if firstItem then
                -- Tick down remaining time
                firstItem.remainingTime = (firstItem.remainingTime or 0) - 1
                debugPrintVerbose('ServerQueue tick -', identifier, 'recipe:', firstItem.recipe and firstItem.recipe.id or 'unknown', 'remainingTime:', firstItem.remainingTime)

                -- Check if craft is complete
                if firstItem.remainingTime <= 0 then
                    -- Complete the craft
                    debugPrint('ProcessServerQueues: Item timer reached 0 for', identifier, '- recipe:', firstItem.recipe and firstItem.recipe.name or 'unknown', 'stationId:', stationId)
                    local craftSuccess = CompleteCraftServerSide(firstItem, stationId, stagingKey, identifier)
                    debugPrint('ProcessServerQueues: CompleteCraftServerSide returned', tostring(craftSuccess))

                    -- Remove completed item from queue
                    table.remove(queue, 1)

                    -- Track how many items completed while offline for player notification on reconnect
                    data.offlineCompletedCount = (data.offlineCompletedCount or 0) + 1

                    -- For shared queues, save to DB and broadcast update to any players at the station
                    local isShared = identifier:match('^shared_')
                    if isShared then
                        DirtySharedQueues[stationId] = true
                        BroadcastQueueUpdate(stationId)
                    end

                    debugPrint('ProcessServerQueues: Item completed for', identifier, '- remaining items:', #queue)

                    -- If queue is empty, clean up
                    if #queue == 0 then
                        local completedCount = data.offlineCompletedCount or 0

                        if isShared then
                            -- Shared queue: save empty state to DB and remove from processing
                            SaveSharedCraftingQueue(stationId, queue)
                            ServerProcessedQueues[identifier] = nil
                        else
                            -- Personal queue: clear from database
                            DeletePlayerCraftingQueue(identifier)

                            -- Keep entry with empty queue so getSavedQueue can report completedCount on reconnect
                            if completedCount > 0 then
                                data.queue = {}
                                debugPrint('Server queue fully completed for:', identifier, '- Total offline completions:', completedCount)
                            else
                                ServerProcessedQueues[identifier] = nil
                            end
                        end
                    end
                end
            end
        else
            -- Empty queue, remove from processing
            ServerProcessedQueues[identifier] = nil
        end
    end
end

--- Add a queue to server-side processing
---@param identifier string Player identifier or shared identifier
---@param queue table Queue items array
---@param stationId string Station identifier
---@param stagingKey string Staging key for adding items
---@param completedCount number|nil Number of items that completed offline during server startup
function AddToServerProcessing(identifier, queue, stationId, stagingKey, completedCount)
    if not ShouldServerProcessQueues() then
        debugPrint('AddToServerProcessing: SKIPPED - ShouldServerProcessQueues() returned false')
        return
    end
    if not queue or #queue == 0 then
        debugPrint('AddToServerProcessing: SKIPPED - queue is empty or nil')
        return
    end

    local firstItem = queue[1]
    debugPrint('AddToServerProcessing:', identifier, '- stationId:', stationId, 'stagingKey:', stagingKey,
        'items:', #queue, 'firstItem.remainingTime:', firstItem and firstItem.remainingTime,
        'recipe:', firstItem and firstItem.recipe and firstItem.recipe.name)

    ServerProcessedQueues[identifier] = {
        queue = queue,
        stationId = stationId,
        stagingKey = stagingKey,
        isShared = identifier:match('^shared_') ~= nil,
        offlineCompletedCount = completedCount or 0
    }
end

--- Remove a queue from server-side processing (when player comes online and takes over)
---@param identifier string Player identifier or shared identifier
local function RemoveFromServerProcessing(identifier)
    if ServerProcessedQueues[identifier] then
        ServerProcessedQueues[identifier] = nil
        debugPrint('Removed queue from server processing:', identifier)
    end
end

--- Start the server-side queue processing loop
local function StartServerQueueProcessing()
    if ServerQueueProcessingActive then return end
    ServerQueueProcessingActive = true

    CreateThread(function()
        while ServerQueueProcessingActive do
            Wait(1000) -- Process every second
            ProcessServerQueues()
        end
    end)

    debugPrint('StartServerQueueProcessing: Server-side queue processing loop STARTED')
end

--- Get all workbench types from config for per-workbench leveling
---@return table types Array of workbench type strings
function GetAllWorkbenchTypes()
    local types = {}
    local typeSet = {}

    if Config.Stations then
        for _, station in pairs(Config.Stations) do
            local wbType = station.type or 'basic'
            if not typeSet[wbType] then
                typeSet[wbType] = true
                table.insert(types, wbType)
            end
        end
    end

    for _, station in pairs(AdminStations) do
        local wbType = station.type or 'basic'
        if not typeSet[wbType] then
            typeSet[wbType] = true
            table.insert(types, wbType)
        end
    end

    if Config.PlaceableWorkbenches then
        for _, wb in pairs(Config.PlaceableWorkbenches) do
            local wbType = wb.type or 'basic'
            if not typeSet[wbType] then
                typeSet[wbType] = true
                table.insert(types, wbType)
            end
        end
    end

    for typeName in pairs(AdminTypes) do
        if not typeSet[typeName] then
            typeSet[typeName] = true
            types[#types + 1] = typeName
        end
    end

    if #types == 0 then
        types = { 'basic' }
    end

    return types
end

--- Create default player data structure based on config settings
---@return table data Default player data with leveling and tech tree fields
local function GetDefaultPlayerData()
    local data = {}

    if Config.Leveling and Config.Leveling.perWorkbenchType then
        data.workbench_levels = {}
        local workbenchTypes = GetAllWorkbenchTypes()
        for _, wbType in ipairs(workbenchTypes) do
            data.workbench_levels[wbType] = { xp = 0, level = 1 }
        end
    else
        data.xp = 0
        data.level = 1
    end

    if TechTrees and TechTrees.perWorkbenchType then
        data.workbench_tech = {}
        local workbenchTypes = GetAllWorkbenchTypes()
        for _, wbType in ipairs(workbenchTypes) do
            data.workbench_tech[wbType] = {
                tech_points = 0,
                unlocked_nodes = {}
            }
        end
    else
        data.tech_points = 0
        data.unlocked_nodes = {}
    end

    return data
end

--- Load player data from database (with caching)
---@param source number Player server ID
---@return table data Player data with leveling and tech tree information
local function LoadPlayerData(source)
    local identifier = GetIdentifier(source)
    if not identifier then return GetDefaultPlayerData() end

    if PlayerData[identifier] then
        return PlayerData[identifier]
    end

    local result = MySQL.query.await('SELECT data FROM sd_crafting_players WHERE identifier = ?', { identifier })

    if result and result[1] then
        local data = json.decode(result[1].data) or {}
        local perWorkbenchLeveling = Config.Leveling and Config.Leveling.perWorkbenchType
        local perWorkbenchTech = TechTrees and TechTrees.perWorkbenchType
        local workbenchTypes = GetAllWorkbenchTypes()

        local loadedData = {}

        if perWorkbenchLeveling then
            local workbench_levels = data.workbench_levels or {}

            if not data.workbench_levels and (data.xp or data.level) then
                for _, wbType in ipairs(workbenchTypes) do
                    workbench_levels[wbType] = {
                        xp = data.xp or 0,
                        level = data.level or 1
                    }
                end
            end

            for _, wbType in ipairs(workbenchTypes) do
                if not workbench_levels[wbType] then
                    workbench_levels[wbType] = { xp = 0, level = 1 }
                end
            end

            loadedData.workbench_levels = workbench_levels
        else
            local xp = data.xp or 0
            local level = data.level or 1

            if data.workbench_levels and not data.xp then
                local highestXP = 0
                for _, wbData in pairs(data.workbench_levels) do
                    if wbData.xp and wbData.xp > highestXP then
                        highestXP = wbData.xp
                    end
                end
                xp = highestXP
                level = GetLevelFromXP(xp, nil)
            end

            loadedData.xp = xp
            loadedData.level = level
        end

        if perWorkbenchTech then
            local workbench_tech = data.workbench_tech or {}

            if not data.workbench_tech and (data.tech_points or data.unlocked_nodes) then
                for _, wbType in ipairs(workbenchTypes) do
                    workbench_tech[wbType] = {
                        tech_points = data.tech_points or 0,
                        unlocked_nodes = data.unlocked_nodes or {}
                    }
                end
            end

            for _, wbType in ipairs(workbenchTypes) do
                if not workbench_tech[wbType] then
                    workbench_tech[wbType] = {
                        tech_points = 0,
                        unlocked_nodes = {}
                    }
                end
            end

            loadedData.workbench_tech = workbench_tech
        else
            local tech_points = data.tech_points or 0
            local unlocked_nodes = data.unlocked_nodes or {}

            if data.workbench_tech and not data.tech_points then
                local highestPoints = 0
                local allNodes = {}
                local nodeSet = {}
                for _, wbData in pairs(data.workbench_tech) do
                    if wbData.tech_points and wbData.tech_points > highestPoints then
                        highestPoints = wbData.tech_points
                    end
                    for _, nodeKey in ipairs(wbData.unlocked_nodes or {}) do
                        if not nodeSet[nodeKey] then
                            nodeSet[nodeKey] = true
                            table.insert(allNodes, nodeKey)
                        end
                    end
                end
                tech_points = highestPoints
                unlocked_nodes = allNodes
            end

            loadedData.tech_points = tech_points
            loadedData.unlocked_nodes = unlocked_nodes
        end

        PlayerData[identifier] = loadedData
    else
        local defaultData = GetDefaultPlayerData()
        MySQL.insert('INSERT INTO sd_crafting_players (identifier, data) VALUES (?, ?)',
            { identifier, json.encode(defaultData) })
        PlayerData[identifier] = defaultData
    end

    return PlayerData[identifier]
end

--- Save player data to database
---@param identifier string Player identifier
---@return boolean success Whether save was successful
function SavePlayerData(identifier)
    if not identifier or not PlayerData[identifier] then return false end
    MySQL.update('UPDATE sd_crafting_players SET data = ? WHERE identifier = ?',
        { json.encode(PlayerData[identifier]), identifier })
    return true
end

--- Get level configuration for a specific workbench type
---@param workbenchType string|nil Workbench type to get config for
---@return table config Table with levels and maxLevel fields
local function GetLevelConfig(workbenchType)
    if not Config.Leveling then
        return { levels = { [1] = 0 }, maxLevel = 1 }
    end

    if Config.Leveling.perWorkbenchType and workbenchType then
        local typeConfig = Config.Leveling.workbenchTypes and Config.Leveling.workbenchTypes[workbenchType]
        if typeConfig then
            return {
                levels = typeConfig.levels or Config.Leveling.levels,
                maxLevel = typeConfig.maxLevel or Config.Leveling.maxLevel or 10
            }
        end

        if AdminTypes[workbenchType] and AdminTypes[workbenchType].levels then
            return {
                levels = AdminTypes[workbenchType].levels,
                maxLevel = AdminTypes[workbenchType].maxLevel or Config.Leveling.maxLevel or 10
            }
        end
    end

    return {
        levels = Config.Leveling.levels or { [1] = 0 },
        maxLevel = Config.Leveling.maxLevel or 10
    }
end

--- Calculate level from XP (optionally for a specific workbench type)
---@param xp number Current XP amount
---@param workbenchType string|nil Workbench type for per-workbench leveling
---@return number level Calculated level
local function GetLevelFromXP(xp, workbenchType)
    if not Config.Leveling or not Config.Leveling.enabled then
        return 1
    end

    local levelConfig = GetLevelConfig(workbenchType)
    local level = 1

    for lvl, requiredXp in pairs(levelConfig.levels) do
        if xp >= requiredXp and lvl > level then
            level = lvl
        end
    end

    return math.min(level, levelConfig.maxLevel)
end

--- Recalculate levels for all cached players after level config changes for a workbench type
--- Called from admin.lua when XP thresholds are modified
---@param workbenchType string The workbench type whose config changed
function RecalcPlayerLevelsForType(workbenchType)
    if not Config.Leveling or not Config.Leveling.enabled then return end
    local perWorkbench = Config.Leveling.perWorkbenchType
    local updated = 0

    for identifier, data in pairs(PlayerData) do
        local changed = false
        if perWorkbench and data.workbench_levels then
            local wbData = data.workbench_levels[workbenchType]
            if wbData then
                local newLevel = GetLevelFromXP(wbData.xp, workbenchType)
                if newLevel ~= wbData.level then
                    wbData.level = newLevel
                    changed = true
                end
            end
        elseif not perWorkbench and data.xp then
            local newLevel = GetLevelFromXP(data.xp, workbenchType)
            if newLevel ~= data.level then
                data.level = newLevel
                changed = true
            end
        end
        if changed then
            SavePlayerData(identifier)
            updated = updated + 1
        end
    end

    if updated > 0 then
        debugPrint('Recalculated levels for', updated, 'players after', workbenchType, 'config change')
    end
end

--- Get XP required for next level (optionally for a specific workbench type)
---@param currentLevel number Current level
---@param workbenchType string|nil Workbench type for per-workbench leveling
---@return number xp XP required for next level
local function GetXPForNextLevel(currentLevel, workbenchType)
    if not Config.Leveling or not Config.Leveling.enabled then
        return 0
    end

    local levelConfig = GetLevelConfig(workbenchType)
    local nextLevel = currentLevel + 1

    if nextLevel > levelConfig.maxLevel then
        return levelConfig.levels[levelConfig.maxLevel] or 0
    end

    return levelConfig.levels[nextLevel] or 0
end

--- Get XP required for current level (optionally for a specific workbench type)
---@param currentLevel number Current level
---@param workbenchType string|nil Workbench type for per-workbench leveling
---@return number xp XP required for current level
local function GetXPForCurrentLevel(currentLevel, workbenchType)
    if not Config.Leveling or not Config.Leveling.enabled then
        return 0
    end

    local levelConfig = GetLevelConfig(workbenchType)
    return levelConfig.levels[currentLevel] or 0
end

--- Load player level data (wrapper for compatibility)
---@param source number Player server ID
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return table data Table with xp, level, and optionally workbenchType
local function LoadPlayerLevel(source, workbenchType)
    local data = LoadPlayerData(source)
    local perWorkbench = Config.Leveling and Config.Leveling.perWorkbenchType

    if perWorkbench and data.workbench_levels then
        local wbType = workbenchType or 'basic'
        local wbData = data.workbench_levels[wbType] or { xp = 0, level = 1 }
        return { xp = wbData.xp, level = wbData.level, workbenchType = wbType }
    else
        return { xp = data.xp or 0, level = data.level or 1 }
    end
end

--- Save player level data (wrapper for compatibility)
---@param source number Player server ID
---@param xp number XP to save
---@param level number Level to save
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return boolean success Whether save was successful
local function SavePlayerLevel(source, xp, level, workbenchType)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    local data = LoadPlayerData(source)
    local perWorkbench = Config.Leveling and Config.Leveling.perWorkbenchType

    if perWorkbench and data.workbench_levels then
        local wbType = workbenchType or 'basic'
        if not data.workbench_levels[wbType] then
            data.workbench_levels[wbType] = { xp = 0, level = 1 }
        end
        data.workbench_levels[wbType].xp = xp
        data.workbench_levels[wbType].level = level
    else
        data.xp = xp
        data.level = level
    end

    return SavePlayerData(identifier)
end

--- Award XP to player
---@param source number Player server ID
---@param amount number XP amount to award
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return table|nil result Table with xp, level, leveledUp data or nil if leveling disabled
local function AwardXP(source, amount, workbenchType)
    if not Config.Leveling or not Config.Leveling.enabled then
        return nil
    end

    local identifier = GetIdentifier(source)
    if not identifier then return nil end

    local data = LoadPlayerData(source)
    local perWorkbench = Config.Leveling and Config.Leveling.perWorkbenchType

    local oldLevel, newXP, newLevel, wbType, levelConfig

    if perWorkbench and data.workbench_levels then
        wbType = workbenchType or 'basic'
        levelConfig = GetLevelConfig(wbType)

        if not data.workbench_levels[wbType] then
            data.workbench_levels[wbType] = { xp = 0, level = 1 }
        end

        oldLevel = data.workbench_levels[wbType].level
        newXP = data.workbench_levels[wbType].xp + amount
        newLevel = GetLevelFromXP(newXP, wbType)

        data.workbench_levels[wbType].xp = newXP
        data.workbench_levels[wbType].level = newLevel

        debugPrint('Player', source, 'gained', amount, 'XP for', wbType, 'workbench. Total:', newXP, 'Level:', newLevel, '/', levelConfig.maxLevel)
    else
        wbType = nil
        levelConfig = GetLevelConfig(nil)

        oldLevel = data.level
        newXP = data.xp + amount
        newLevel = GetLevelFromXP(newXP, nil)

        data.xp = newXP
        data.level = newLevel

        debugPrint('Player', source, 'gained', amount, 'XP. Total:', newXP, 'Level:', newLevel)
    end

    SavePlayerData(identifier)

    local leveledUp = newLevel > oldLevel

    Logger.Log('xp_gained', source, {
        amount = amount,
        source = wbType and ('Crafting (' .. wbType .. ')') or 'Crafting',
        totalXp = newXP,
        level = newLevel
    })

    if leveledUp then
        Logger.Log('level_up', source, {
            level = newLevel,
            totalXp = newXP
        })
    end

    return {
        xp = newXP,
        level = newLevel,
        xpGained = amount,
        leveledUp = leveledUp,
        oldLevel = oldLevel,
        xpForNextLevel = GetXPForNextLevel(newLevel, wbType),
        xpForCurrentLevel = GetXPForCurrentLevel(newLevel, wbType),
        maxLevel = levelConfig.maxLevel,
        workbenchType = perWorkbench and wbType or nil -- Return actual type used (wbType), not input parameter
    }
end

--- Get tech trees config for a station
---@param stationId string|nil Station identifier
---@return table|nil techTreeIds Array of tech tree IDs for this station
local function GetTechTreesConfigForStation(stationId)
    if not stationId then return nil end

    -- Check if it's a placed workbench
    local placedId = stationId:match('^placed_(%d+)$')
    if placedId then
        local numericId = tonumber(placedId)
        if numericId and PlacedWorkbenches[numericId] then
            -- Use override if set, otherwise fall back to config
            if PlacedWorkbenches[numericId].techTrees then
                return PlacedWorkbenches[numericId].techTrees
            end
            local item = PlacedWorkbenches[numericId].item
            if item and Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[item] then
                return Config.PlaceableWorkbenches[item].techTrees
            end
        end
        return nil
    end

    -- Check static and admin stations
    local station = GetStationConfig(stationId)
    if station then
        return station.techTrees
    end

    return nil
end

--- Get tech trees filtered by an array of tree IDs
---@param techTreeIds table|nil Array of tech tree IDs to include
---@return table|nil trees The filtered Trees table
local function GetTechTrees(techTreeIds)
    if not TechTrees or not TechTrees.enabled then
        return nil
    end

    if not TechTrees.Trees then
        return nil
    end

    -- If no specific trees requested, return nil (no tech trees for this station)
    if not techTreeIds or #techTreeIds == 0 then
        return nil
    end

    -- Filter trees to only include requested ones
    local filteredTrees = {}
    for _, treeId in ipairs(techTreeIds) do
        if TechTrees.Trees[treeId] then
            filteredTrees[treeId] = TechTrees.Trees[treeId]
        end
    end

    -- Return nil if no trees matched
    if not next(filteredTrees) then
        return nil
    end

    return filteredTrees
end

--- Check if shared tech is enabled for a station (placed workbench or admin station)
---@param stationId string|nil Station identifier
---@return boolean isShared Whether this station uses shared tech
---@return string|nil techRef The persistent techId (placed) or station key (admin/static) if shared
local function IsSharedTechWorkbench(stationId)
    if not stationId then return false, nil end
    if not TechTrees or not TechTrees.enabled then return false, nil end

    local globalSharedTech = TechTrees.sharedPlacedWorkbench and TechTrees.sharedPlacedWorkbench.enabled

    -- Check placed workbenches
    local placedId = stationId:match('^placed_(%d+)$')
    if placedId then
        local numericId = tonumber(placedId)
        if numericId and PlacedWorkbenches[numericId] then
            local wb = PlacedWorkbenches[numericId]
            local isShared = false
            -- Per-station override takes priority, then fall back to global config
            if wb.sharedTech ~= nil then
                isShared = wb.sharedTech
            else
                isShared = globalSharedTech
            end
            if isShared then
                return true, wb.techId or ('placed_' .. numericId)
            end
        end
        return false, nil
    end

    -- Check admin stations
    if AdminStations[stationId] then
        local station = AdminStations[stationId]
        if station.sharedTech then return true, stationId end
        return false, nil
    end

    -- Check static stations
    if Config.Stations and Config.Stations[stationId] then
        local station = Config.Stations[stationId]
        if station.sharedTech then return true, stationId end
        return false, nil
    end

    return false, nil
end

--- Load shared workbench tech data from database
---@param techRef string The persistent techId or station key
---@return table techData Table with tech_points and unlocked_nodes
function LoadSharedWorkbenchTech(techRef)
    if SharedWorkbenchTech[techRef] then
        return SharedWorkbenchTech[techRef]
    end

    -- Load from database using techRef directly as the station_id key
    local result = MySQL.query.await(
        "SELECT data FROM sd_crafting_workbenches WHERE type = 'tech' AND station_id = ?",
        { tostring(techRef) }
    )

    local techData = { tech_points = 0, unlocked_nodes = {} }

    if result and result[1] and result[1].data then
        local decoded = json.decode(result[1].data)
        if decoded then
            techData.tech_points = decoded.tech_points or 0
            techData.unlocked_nodes = decoded.unlocked_nodes or {}
        end
    end

    SharedWorkbenchTech[techRef] = techData
    return techData
end

--- Save shared workbench tech data to database
---@param techRef string The persistent techId or station key
---@return boolean success Whether save was successful
function SaveSharedWorkbenchTech(techRef)
    local techData = SharedWorkbenchTech[techRef]
    if not techData then return false end

    local dbKey = tostring(techRef)
    local dataJson = json.encode(techData)

    local existing = MySQL.query.await(
        "SELECT id FROM sd_crafting_workbenches WHERE type = 'tech' AND station_id = ?",
        { dbKey }
    )

    if existing and existing[1] then
        MySQL.update(
            "UPDATE sd_crafting_workbenches SET data = ? WHERE type = 'tech' AND station_id = ?",
            { dataJson, dbKey }
        )
    else
        MySQL.insert(
            "INSERT INTO sd_crafting_workbenches (type, station_id, identifier, data) VALUES ('tech', ?, 'shared', ?)",
            { dbKey, dataJson }
        )
    end

    return true
end

--- Get tech points for a station (handles both shared workbench and player-based)
---@param source number Player server ID
---@param stationId string|nil Station identifier
---@param workbenchType string|nil Workbench type
---@return number points Current tech points
local function GetTechPoints(source, stationId, workbenchType)
    local isShared, workbenchId = IsSharedTechWorkbench(stationId)

    if isShared then
        local techData = LoadSharedWorkbenchTech(workbenchId)
        return techData.tech_points or 0
    else
        return LoadPlayerTechPoints(source, workbenchType)
    end
end

--- Award tech points (handles both shared workbench and player-based)
---@param source number Player server ID
---@param amount number Tech points to award
---@param stationId string|nil Station identifier
---@param workbenchType string|nil Workbench type
---@return table|nil result Table with points and gained data
local function AwardTechPointsToStation(source, amount, stationId, workbenchType)
    if not TechTrees or not TechTrees.enabled then return nil end

    local isShared, workbenchId = IsSharedTechWorkbench(stationId)

    if isShared then
        local techData = LoadSharedWorkbenchTech(workbenchId)
        local newPoints = (techData.tech_points or 0) + amount
        techData.tech_points = newPoints
        SaveSharedWorkbenchTech(workbenchId)

        debugPrint('Workbench', workbenchId, 'gained', amount, 'shared Tech Points. Total:', newPoints)

        return {
            points = newPoints,
            gained = amount,
            workbenchType = workbenchType,
            isShared = true
        }
    else
        return AwardTechPoints(source, amount, workbenchType)
    end
end

--- Get unlocked nodes lookup for a station (handles both shared and player-based)
---@param source number Player server ID
---@param stationId string|nil Station identifier
---@param workbenchType string|nil Workbench type
---@return table lookup Lookup table of unlocked node keys
local function GetUnlockedNodesForStation(source, stationId, workbenchType)
    local isShared, workbenchId = IsSharedTechWorkbench(stationId)

    if isShared then
        local techData = LoadSharedWorkbenchTech(workbenchId)
        local lookup = {}
        for _, nodeKey in ipairs(techData.unlocked_nodes or {}) do
            lookup[nodeKey] = true
        end
        return lookup
    else
        return GetUnlockedNodesLookup(source, workbenchType)
    end
end

--- Load player tech points (wrapper for compatibility)
---@param source number Player server ID
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return number points Current tech points
local function LoadPlayerTechPoints(source, workbenchType)
    local data = LoadPlayerData(source)
    local perWorkbenchTech = TechTrees and TechTrees.perWorkbenchType

    if perWorkbenchTech and data.workbench_tech then
        local wbType = workbenchType or 'basic'
        local wbData = data.workbench_tech[wbType] or { tech_points = 0 }
        return wbData.tech_points
    else
        return data.tech_points or 0
    end
end

--- Save player tech points (wrapper for compatibility)
---@param source number Player server ID
---@param points number Tech points to save
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return boolean success Whether save was successful
local function SavePlayerTechPoints(source, points, workbenchType)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    local data = LoadPlayerData(source)
    local perWorkbenchTech = TechTrees and TechTrees.perWorkbenchType

    if perWorkbenchTech and data.workbench_tech then
        local wbType = workbenchType or 'basic'
        if not data.workbench_tech[wbType] then
            data.workbench_tech[wbType] = { tech_points = 0, unlocked_nodes = {} }
        end
        data.workbench_tech[wbType].tech_points = points
    else
        data.tech_points = points
    end

    return SavePlayerData(identifier)
end

--- Award tech points to player
---@param source number Player server ID
---@param amount number Tech points to award
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return table|nil result Table with points and gained data or nil if tech trees disabled
function AwardTechPoints(source, amount, workbenchType)
    if not TechTrees or not TechTrees.enabled then return nil end

    local identifier = GetIdentifier(source)
    if not identifier then return nil end

    local data = LoadPlayerData(source)
    local perWorkbenchTech = TechTrees.perWorkbenchType
    local newPoints

    if perWorkbenchTech and data.workbench_tech then
        local wbType = workbenchType or 'basic'
        if not data.workbench_tech[wbType] then
            data.workbench_tech[wbType] = { tech_points = 0, unlocked_nodes = {} }
        end
        newPoints = data.workbench_tech[wbType].tech_points + amount
        data.workbench_tech[wbType].tech_points = newPoints

        debugPrint('Player', source, 'gained', amount, 'Tech Points for', wbType, 'workbench. Total:', newPoints)
    else
        newPoints = (data.tech_points or 0) + amount
        data.tech_points = newPoints

        debugPrint('Player', source, 'gained', amount, 'Tech Points. Total:', newPoints)
    end

    SavePlayerData(identifier)

    return {
        points = newPoints,
        gained = amount,
        workbenchType = perWorkbenchTech and workbenchType or nil
    }
end

--- Load player's unlocked tech tree nodes (wrapper for compatibility)
---@param source number Player server ID
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return table lookup Lookup table of unlocked node keys
local function LoadPlayerUnlockedNodes(source, workbenchType)
    local data = LoadPlayerData(source)
    local perWorkbenchTech = TechTrees and TechTrees.perWorkbenchType

    local unlocked_nodes
    if perWorkbenchTech and data.workbench_tech then
        local wbType = workbenchType or 'basic'
        local wbData = data.workbench_tech[wbType] or { unlocked_nodes = {} }
        unlocked_nodes = wbData.unlocked_nodes or {}
    else
        unlocked_nodes = data.unlocked_nodes or {}
    end

    local lookup = {}
    for _, nodeKey in ipairs(unlocked_nodes) do
        lookup[nodeKey] = true
    end
    return lookup
end

--- Check if a specific node is unlocked for a player
---@param source number Player server ID
---@param treeId string Tech tree identifier
---@param nodeId string Node identifier
---@param workbenchType string|nil Workbench type (optional, only used when perWorkbenchType is enabled)
---@return boolean unlocked Whether the node is unlocked
local function IsNodeUnlocked(source, treeId, nodeId, workbenchType)
    local unlocks = LoadPlayerUnlockedNodes(source, workbenchType)
    return unlocks[treeId .. ':' .. nodeId] == true
end

--- Check if a recipe requires tech tree unlock and get the node info
---@param recipeId string Recipe identifier
---@param stationId string|nil Station identifier
---@return boolean requires Whether recipe requires unlock
---@return string|nil treeId Tree ID if requires unlock
---@return string|nil nodeId Node ID if requires unlock
local function RecipeRequiresTechUnlock(recipeId, stationId)
    if not TechTrees or not TechTrees.enabled then
        return false, nil, nil
    end

    local techTreeIds = GetTechTreesConfigForStation(stationId)
    local trees = GetTechTrees(techTreeIds)
    if not trees then
        return false, nil, nil
    end

    for treeId, tree in pairs(trees) do
        for _, node in ipairs(tree.nodes) do
            if node.recipeId == recipeId then
                return true, treeId, node.id
            end
        end
    end

    return false, nil, nil
end

--- Check if player can craft based on tech tree (returns true if no tech tree requirement or if unlocked)
---@param source number Player server ID
---@param recipeId string Recipe identifier
---@param stationId string|nil Station identifier
---@param workbenchType string|nil Workbench type (for player data lookup)
---@return boolean canCraft Whether player can craft the recipe
local function CanCraftWithTechTree(source, recipeId, stationId, workbenchType)
    local requiresUnlock, treeId, nodeId = RecipeRequiresTechUnlock(recipeId, stationId)
    if not requiresUnlock then return true end

    local nodeKey = treeId .. ':' .. nodeId
    local isShared, workbenchId = IsSharedTechWorkbench(stationId)

    if isShared then
        local techData = LoadSharedWorkbenchTech(workbenchId)
        for _, unlockedKey in ipairs(techData.unlocked_nodes or {}) do
            if unlockedKey == nodeKey then
                return true
            end
        end
        return false
    end

    return IsNodeUnlocked(source, treeId, nodeId, workbenchType)
end

--- Get player tech points callback
---@param source number Player server ID
---@param data table|nil Optional data with workbenchType field
---@return table result Table with points, enabled, and optional workbench data
lib.callback.register('sd-crafting:server:getPlayerTechPoints', function(source, data)
    if not TechTrees or not TechTrees.enabled then
        return { points = 0, enabled = false }
    end

    local workbenchType = data and data.workbenchType or nil
    local perWorkbenchTech = TechTrees.perWorkbenchType

    local points = LoadPlayerTechPoints(source, workbenchType)

    local result = {
        points = points,
        enabled = true,
        perWorkbenchType = perWorkbenchTech
    }

    if perWorkbenchTech then
        result.workbenchType = workbenchType
        local fullData = LoadPlayerData(source)
        if fullData.workbench_tech then
            result.allWorkbenchTech = {}
            for wbType, wbData in pairs(fullData.workbench_tech) do
                result.allWorkbenchTech[wbType] = {
                    points = wbData.tech_points or 0
                }
            end
        end
    end

    return result
end)

--- Get player's unlocked tech tree nodes callback
---@param source number Player server ID
---@param data table|nil Optional data with workbenchType field
---@return table lookup Lookup table of unlocked node keys
lib.callback.register('sd-crafting:server:getUnlockedNodes', function(source, data)
    if not TechTrees or not TechTrees.enabled then
        return {}
    end

    local workbenchType = data and data.workbenchType or nil
    local stationId = data and data.stationId or nil

    -- Check if this is a shared placed workbench
    local isShared, workbenchId = IsSharedTechWorkbench(stationId)

    if isShared then
        local techData = LoadSharedWorkbenchTech(workbenchId)
        local lookup = {}
        for _, nodeKey in ipairs(techData.unlocked_nodes or {}) do
            lookup[nodeKey] = true
        end
        return lookup
    else
        return LoadPlayerUnlockedNodes(source, workbenchType)
    end
end)

--- Get tech tree configuration callback
---@param source number Player server ID
---@param data table|nil Optional data with stationId field
---@return table config Table with enabled and trees
lib.callback.register('sd-crafting:server:getTechTreeConfig', function(source, data)
    if not TechTrees or not TechTrees.enabled then
        return { enabled = false }
    end

    local stationId = data and data.stationId or nil
    local techTreeIds = GetTechTreesConfigForStation(stationId)
    local trees = GetTechTrees(techTreeIds)

    return {
        enabled = trees ~= nil,
        trees = trees
    }
end)

--- Unlock a tech tree node callback
---@param source number Player server ID
---@param data table Data with treeId, nodeId, workbenchType, and stationId
---@return boolean success Whether unlock was successful
---@return string|table message Error message or result data
lib.callback.register('sd-crafting:server:unlockTechNode', function(source, data)
    local treeId = data.treeId
    local nodeId = data.nodeId
    local workbenchType = data.workbenchType
    local stationId = data.stationId

    if not TechTrees or not TechTrees.enabled then
        return false, 'Tech tree is disabled'
    end

    local techTreeIds = GetTechTreesConfigForStation(stationId)
    local trees = GetTechTrees(techTreeIds)
    if not trees then return false, 'No tech trees available' end

    local tree = trees[treeId]
    if not tree then return false, 'Tree not found' end

    local node = nil
    for _, n in ipairs(tree.nodes) do
        if n.id == nodeId then
            node = n
            break
        end
    end

    if not node then return false, 'Node not found' end

    -- Check if this is a shared placed workbench
    local isShared, workbenchId = IsSharedTechWorkbench(stationId)
    local nodeKey = treeId .. ':' .. nodeId

    if isShared then
        -- Shared workbench tech
        local techData = LoadSharedWorkbenchTech(workbenchId)

        -- Check if already unlocked
        local unlockedLookup = {}
        for _, key in ipairs(techData.unlocked_nodes or {}) do
            unlockedLookup[key] = true
        end

        if unlockedLookup[nodeKey] then
            return false, 'Already unlocked'
        end

        -- Check prerequisites
        for _, prereqId in ipairs(node.prerequisites or {}) do
            if not unlockedLookup[treeId .. ':' .. prereqId] then
                return false, 'Prerequisites not met'
            end
        end

        -- Check points
        local currentPoints = techData.tech_points or 0
        if currentPoints < node.cost then
            return false, 'Not enough Tech Points'
        end

        -- Unlock the node
        techData.tech_points = currentPoints - node.cost
        table.insert(techData.unlocked_nodes, nodeKey)
        SaveSharedWorkbenchTech(workbenchId)

        Logger.Log('techtree_unlocked', source, {
            node = node.label or nodeId,
            tree = tree.label or treeId,
            cost = node.cost,
            station = stationId,
            stationLabel = stationId,
            workbenchType = workbenchType or 'shared'
        })

        debugPrint('Shared workbench', workbenchId, 'unlocked tech node:', treeId, ':', nodeId)

        -- Broadcast tech tree update to other players at this station
        if OpenStations[stationId] then
            local unlockedLookupForBroadcast = {}
            for _, key in ipairs(techData.unlocked_nodes) do
                unlockedLookupForBroadcast[key] = true
            end

            for playerSource, _ in pairs(OpenStations[stationId]) do
                if playerSource ~= source then
                    TriggerClientEvent('sd-crafting:client:syncTechTree', playerSource, {
                        techPoints = techData.tech_points,
                        unlockedNodes = unlockedLookupForBroadcast,
                        workbenchType = workbenchType
                    })
                end
            end
        end

        return true, {
            newPoints = currentPoints - node.cost,
            unlockedNode = { treeId = treeId, nodeId = nodeId },
            workbenchType = workbenchType,
            isShared = true
        }
    else
        -- Player-based tech (original logic)
        if IsNodeUnlocked(source, treeId, nodeId, workbenchType) then
            return false, 'Already unlocked'
        end

        for _, prereqId in ipairs(node.prerequisites or {}) do
            if not IsNodeUnlocked(source, treeId, prereqId, workbenchType) then
                return false, 'Prerequisites not met'
            end
        end

        local currentPoints = LoadPlayerTechPoints(source, workbenchType)
        if currentPoints < node.cost then
            return false, 'Not enough Tech Points'
        end

        local identifier = GetIdentifier(source)
        local playerData = LoadPlayerData(source)
        local perWorkbenchTech = TechTrees.perWorkbenchType

        if perWorkbenchTech and playerData.workbench_tech then
            local wbType = workbenchType or 'basic'
            if not playerData.workbench_tech[wbType] then
                playerData.workbench_tech[wbType] = { tech_points = 0, unlocked_nodes = {} }
            end
            playerData.workbench_tech[wbType].tech_points = currentPoints - node.cost
            table.insert(playerData.workbench_tech[wbType].unlocked_nodes, nodeKey)
        else
            playerData.tech_points = currentPoints - node.cost
            table.insert(playerData.unlocked_nodes, nodeKey)
        end

        SavePlayerData(identifier)

        Logger.Log('techtree_unlocked', source, {
            node = node.label or nodeId,
            tree = tree.label or treeId,
            cost = node.cost,
            station = stationId,
            stationLabel = stationId,
            workbenchType = workbenchType or 'global'
        })

        local typeMsg = perWorkbenchTech and workbenchType or 'global'
        debugPrint('Player', source, 'unlocked tech node:', treeId, ':', nodeId, '(', typeMsg, ')')

        return true, {
            newPoints = currentPoints - node.cost,
            unlockedNode = { treeId = treeId, nodeId = nodeId },
            workbenchType = perWorkbenchTech and workbenchType or nil
        }
    end
end)

--- Get player level callback
---@param source number Player server ID
---@param data table|nil Optional data with workbenchType field
---@return table result Table with xp, level, enabled, maxLevel, and xp thresholds
lib.callback.register('sd-crafting:server:getPlayerLevel', function(source, data)
    if not Config.Leveling or not Config.Leveling.enabled then
        return { xp = 0, level = 1, enabled = false }
    end

    local workbenchType = data and data.workbenchType or nil
    local perWorkbench = Config.Leveling.perWorkbenchType

    local playerData = LoadPlayerLevel(source, workbenchType)
    local levelConfig = GetLevelConfig(workbenchType)
    local xpForNextLevel = GetXPForNextLevel(playerData.level, workbenchType)
    local xpForCurrentLevel = GetXPForCurrentLevel(playerData.level, workbenchType)

    local result = {
        xp = playerData.xp,
        level = playerData.level,
        enabled = true,
        maxLevel = levelConfig.maxLevel,
        xpForNextLevel = xpForNextLevel,
        xpForCurrentLevel = xpForCurrentLevel,
        perWorkbenchType = perWorkbench
    }

    if perWorkbench then
        result.workbenchType = workbenchType
        local fullData = LoadPlayerData(source)
        if fullData.workbench_levels then
            result.allWorkbenchLevels = {}
            for wbType, wbData in pairs(fullData.workbench_levels) do
                local wbLevelConfig = GetLevelConfig(wbType)
                result.allWorkbenchLevels[wbType] = {
                    xp = wbData.xp,
                    level = wbData.level,
                    maxLevel = wbLevelConfig.maxLevel,
                    xpForNextLevel = GetXPForNextLevel(wbData.level, wbType),
                    xpForCurrentLevel = GetXPForCurrentLevel(wbData.level, wbType)
                }
            end
        end
    end

    return result
end)

--- Get player inventory items callback with slot information
---@param source number Player server ID
---@return table data Object containing items array and total slots
lib.callback.register('sd-crafting:server:getPlayerItems', function(source)
    local items = Inventory.GetPlayerItems(source)
    local totalSlots = Inventory.GetInventorySlots(source)
    local supportsSlots = Inventory.SupportsSlots()
    local result = {}

    for _, item in ipairs(items) do
        -- Get durability from metadata for any item that has it
        local durability = nil
        if item.metadata and item.metadata.durability then
            durability = item.metadata.durability
        end

        result[#result + 1] = {
            item = item.name,
            label = item.label or item.name,
            count = item.count or 1,
            slot = item.slot, -- Include slot information
            image = nil, -- Client will handle image paths
            durability = durability,
            metadata = item.metadata
        }
    end

    return {
        items = result,
        totalSlots = totalSlots,
        supportsSlots = supportsSlots
    }
end)

--- Get all recipes that require blueprints
---@return table blueprintRecipes Table mapping blueprint item to recipe data
local function GetBlueprintRecipes()
    local blueprintRecipes = {}
    for workbenchType, recipes in pairs(Recipes) do
        for _, recipe in ipairs(recipes) do
            if recipe.blueprint then
                blueprintRecipes[recipe.blueprint] = recipe
            end
        end
    end
    return blueprintRecipes
end

--- Get all blueprint item names as a lookup table
---@return table blueprintItems Table with blueprint item names as keys
local function GetBlueprintItemNames()
    local blueprintItems = {}
    for workbenchType, recipes in pairs(Recipes) do
        for _, recipe in ipairs(recipes) do
            if recipe.blueprint then
                blueprintItems[recipe.blueprint] = true
            end
        end
    end
    return blueprintItems
end

--- Initialize ox_inventory durability display for blueprint items
--- Sets up blueprint items to display durability bar in ox_inventory UI
local function InitializeBlueprintDurabilityDisplay()
    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability
    if not durabilityConfig or not durabilityConfig.enabled then return end
    if not Inventory.IsOxInventory() then return end

    local blueprintItems = GetBlueprintItemNames()
    local defaultDurability = durabilityConfig.defaultDurability or 100
    local count = 0

    -- Register each blueprint item to show durability bar in ox_inventory
    for blueprintItem, _ in pairs(blueprintItems) do
        local itemData = exports.ox_inventory:Items(blueprintItem)
        if itemData then
            exports.ox_inventory:Items(blueprintItem, {
                durability = defaultDurability
            })
            count = count + 1
        end
    end

    debugPrint(('Registered ox_inventory durability display for %d blueprint items'):format(count))
end

-- Initialize blueprint durability display on resource start
CreateThread(function()
    Wait(1000) -- Wait for ox_inventory to be fully loaded
    InitializeBlueprintDurabilityDisplay()
end)

-- Load crafting queues from database on resource start and start server-side processing
CreateThread(function()
    Wait(500) -- Wait for database to be ready

    debugPrint('Resource init: TickDownQueueWhenOffline=' .. tostring(Config.TickDownQueueWhenOffline)
        .. ', CancelCraftOnLeave=' .. tostring(Config.CancelCraftOnLeave))

    LoadSharedCraftingQueues()
    LoadAllPlayerCraftingQueuesForServerProcessing()

    -- Start the periodic queue save thread
    StartQueueSaveThread()

    -- Start the server-side queue processing loop if enabled
    if ShouldServerProcessQueues() then
        StartServerQueueProcessing()
    else
        debugPrint('Resource init: Server queue processing NOT started (both configs disabled)')
    end
end)

--- Deep merge two tables, with overrides taking precedence
--- Used to merge station-specific CraftingBehavior with global defaults
---@param defaults table The default values
---@param overrides table|nil The override values (can be nil)
---@return table merged The merged table
local function DeepMergeCraftingBehavior(defaults, overrides)
    if not overrides then return defaults end
    if not defaults then return overrides end

    local result = {}

    -- Copy all defaults first
    for k, v in pairs(defaults) do
        if type(v) == 'table' then
            result[k] = {}
            for k2, v2 in pairs(v) do
                result[k][k2] = v2
            end
        else
            result[k] = v
        end
    end

    -- Apply overrides
    for k, v in pairs(overrides) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            -- Merge sub-tables
            for k2, v2 in pairs(v) do
                result[k][k2] = v2
            end
        else
            result[k] = v
        end
    end

    return result
end

--- Get the effective CraftingBehavior for a station
--- Returns station-specific overrides merged with global defaults
--- Priority: Station/Placeable config > Global CraftingBehavior defaults
---@param stationId string Station identifier
---@return table craftingBehavior The effective CraftingBehavior settings
local function GetEffectiveCraftingBehavior(stationId)
    local globalBehavior = Config.CraftingBehavior or {}
    local stationBehavior = nil

    if stationId and stationId:find('^placed_') then
        -- Placed workbench - check per-workbench override first, then type config
        local placedId = tonumber(stationId:sub(8))
        if placedId and PlacedWorkbenches[placedId] then
            if PlacedWorkbenches[placedId].CraftingBehavior then
                stationBehavior = PlacedWorkbenches[placedId].CraftingBehavior
            else
                local workbenchItem = PlacedWorkbenches[placedId].item
                if workbenchItem and Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[workbenchItem] then
                    stationBehavior = Config.PlaceableWorkbenches[workbenchItem].CraftingBehavior
                end
            end
        end
    elseif stationId then
        -- Static or admin station - get config from GetStationConfig
        local station = GetStationConfig(stationId)
        if station then
            stationBehavior = station.CraftingBehavior
        end
    end

    -- Merge station-specific overrides with global defaults
    return DeepMergeCraftingBehavior(globalBehavior, stationBehavior)
end

--- Check if per-workbench (shared) staging inventory is enabled for a station.
--- Per-station CraftingBehavior.sharedStaging overrides the global Config.InventoryPanel.perWorkbench setting.
---@param stationId string Station identifier
---@return boolean enabled Whether per-workbench inventory is enabled for this station
local function IsPerWorkbenchEnabled(stationId)
    -- Check per-station override first
    if stationId then
        local stationOverride = nil
        if stationId:find('^placed_') then
            local placedId = tonumber(stationId:sub(8))
            if placedId and PlacedWorkbenches[placedId] and PlacedWorkbenches[placedId].CraftingBehavior then
                stationOverride = PlacedWorkbenches[placedId].CraftingBehavior.sharedStaging
            end
        else
            local station = GetStationConfig(stationId)
            if station and station.CraftingBehavior then
                stationOverride = station.CraftingBehavior.sharedStaging
            end
        end
        if stationOverride ~= nil then return stationOverride end
    end

    -- Fall back to global config
    if not Config.InventoryPanel or not Config.InventoryPanel.perWorkbench then
        return false
    end

    local perWorkbench = Config.InventoryPanel.perWorkbench

    -- Handle legacy boolean config
    if type(perWorkbench) == 'boolean' then
        return perWorkbench
    end

    -- Check if this is a placed workbench
    if stationId and stationId:find('^placed_') then
        return perWorkbench.placed or false
    else
        return perWorkbench.static or false
    end
end

--- Get the staging key for a player (either their identifier or 'shared' for per-workbench)
---@param source number Player server ID
---@param stationId string Station identifier
---@return string stagingKey The staging key to use
function GetStagingKey(source, stationId)
    if IsPerWorkbenchEnabled(stationId) then
        return 'shared'
    end
    return GetIdentifier(source) or 'player_' .. source
end

--- Load staged items from database into memory
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@return table items Loaded items
local function LoadStagedItemsFromDatabase(stationId, stagingKey)
    local result = MySQL.query.await(
        "SELECT data FROM sd_crafting_workbenches WHERE type = 'staged' AND station_id = ? AND identifier = ?",
        { stationId, stagingKey }
    )

    if result and result[1] and result[1].data then
        local items = json.decode(result[1].data) or {}
        if not StagedItems[stationId] then
            StagedItems[stationId] = {}
        end
        StagedItems[stationId][stagingKey] = items
        return items
    end

    return {}
end

--- Get staged items for a station (loads from database if not in memory)
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@return table items Staged items
local function GetStagedItemsForStation(stationId, stagingKey)
    if StagedItems[stationId] and StagedItems[stationId][stagingKey] then
        return StagedItems[stationId][stagingKey]
    end

    return LoadStagedItemsFromDatabase(stationId, stagingKey)
end

--- Get all data needed to open the crafting UI in a single callback
---@param source number Player server ID
---@param data table Data with stationId and workbenchType
---@return table result All UI data consolidated
lib.callback.register('sd-crafting:server:getCraftingUIData', function(source, data)
    local stationId = data.stationId
    local workbenchType = data.workbenchType

    local result = {}

    local attached = {}
    local attachedWithLabels = {}
    local attachedLookup = {}
    local blueprintRecipes = GetBlueprintRecipes()

    if StationBlueprints[stationId] then
        for blueprintItem, _ in pairs(StationBlueprints[stationId]) do
            if not attachedLookup[blueprintItem] then
                table.insert(attached, blueprintItem)
                attachedLookup[blueprintItem] = true

                -- Get label from the blueprint item itself and the recipe it unlocks
                local blueprintLabel = Inventory.GetItemLabel(blueprintItem) or FormatItemName(blueprintItem)
                local recipe = blueprintRecipes[blueprintItem]
                if recipe then
                    local recipeLabel = recipe.label or Inventory.GetItemLabel(recipe.name) or FormatItemName(recipe.name)
                    table.insert(attachedWithLabels, {
                        item = blueprintItem,
                        label = blueprintLabel,
                        recipeId = recipe.id,
                        recipeLabel = recipeLabel
                    })
                else
                    table.insert(attachedWithLabels, {
                        item = blueprintItem,
                        label = blueprintLabel,
                        recipeId = blueprintItem,
                        recipeLabel = FormatItemName(blueprintItem)
                    })
                end
            end
        end
    end

    if StagedItems[stationId] then
        local stagingKey = IsPerWorkbenchEnabled(stationId) and 'shared' or (GetIdentifier(source) or 'player_' .. source)
        local stagedItemsList = StagedItems[stationId][stagingKey] or {}

        for _, item in ipairs(stagedItemsList) do
            if item.item and IsBlueprint(item.item) and not attachedLookup[item.item] then
                table.insert(attached, item.item)
                attachedLookup[item.item] = true

                -- Get label from the blueprint item itself and the recipe it unlocks
                local blueprintLabel = Inventory.GetItemLabel(item.item) or FormatItemName(item.item)
                local recipe = blueprintRecipes[item.item]
                if recipe then
                    local recipeLabel = recipe.label or Inventory.GetItemLabel(recipe.name) or FormatItemName(recipe.name)
                    table.insert(attachedWithLabels, {
                        item = item.item,
                        label = blueprintLabel,
                        recipeId = recipe.id,
                        recipeLabel = recipeLabel
                    })
                else
                    table.insert(attachedWithLabels, {
                        item = item.item,
                        label = blueprintLabel,
                        recipeId = item.item,
                        recipeLabel = FormatItemName(item.item)
                    })
                end
            end
        end
    end
    result.attachedBlueprints = attached
    result.attachedWithLabels = attachedWithLabels

    local playerBlueprints = {}
    local blueprintRecipes = GetBlueprintRecipes()
    for blueprintItem, recipe in pairs(blueprintRecipes) do
        local count = Inventory.GetItemCount(source, blueprintItem)
        if count > 0 then
            -- Get the actual blueprint item label from the inventory system
            local blueprintLabel = Inventory.GetItemLabel(blueprintItem) or FormatItemName(blueprintItem)
            local inventoryLabel = Inventory.GetItemLabel(recipe.name)
            -- Use recipe.label first, then inventory label if it's not just the raw item name, otherwise format the name nicely
            local recipeLabel = recipe.label or (inventoryLabel ~= recipe.name and inventoryLabel) or FormatItemName(recipe.name)
            table.insert(playerBlueprints, {
                item = blueprintItem,
                label = blueprintLabel,
                count = count,
                recipeId = recipe.id,
                recipeLabel = recipeLabel
            })
        end
    end
    result.playerBlueprints = playerBlueprints

    if not Config.Leveling or not Config.Leveling.enabled then
        result.playerLevel = { xp = 0, level = 1, enabled = false }
    else
        local perWorkbench = Config.Leveling.perWorkbenchType
        local playerLevelData = LoadPlayerLevel(source, workbenchType)
        local levelConfig = GetLevelConfig(workbenchType)
        local xpForNextLevel = GetXPForNextLevel(playerLevelData.level, workbenchType)
        local xpForCurrentLevel = GetXPForCurrentLevel(playerLevelData.level, workbenchType)

        local levelResult = {
            xp = playerLevelData.xp,
            level = playerLevelData.level,
            enabled = true,
            maxLevel = levelConfig.maxLevel,
            xpForNextLevel = xpForNextLevel,
            xpForCurrentLevel = xpForCurrentLevel,
            perWorkbenchType = perWorkbench
        }

        if perWorkbench then
            levelResult.workbenchType = workbenchType
            local fullData = LoadPlayerData(source)
            if fullData.workbench_levels then
                levelResult.allWorkbenchLevels = {}
                for wbType, wbData in pairs(fullData.workbench_levels) do
                    local wbLevelConfig = GetLevelConfig(wbType)
                    levelResult.allWorkbenchLevels[wbType] = {
                        xp = wbData.xp,
                        level = wbData.level,
                        maxLevel = wbLevelConfig.maxLevel,
                        xpForNextLevel = GetXPForNextLevel(wbData.level, wbType),
                        xpForCurrentLevel = GetXPForCurrentLevel(wbData.level, wbType)
                    }
                end
            end
        end
        result.playerLevel = levelResult
    end

    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability
    local toolsConfig = Config.Tools
    result.craftingInventoryConfig = {
        enabled = Config.InventoryPanel and Config.InventoryPanel.enabled or false,
        perWorkbench = IsPerWorkbenchEnabled(stationId),
        maxSlots = Config.InventoryPanel and Config.InventoryPanel.maxSlots or 20,
        maxWeight = Config.InventoryPanel and Config.InventoryPanel.maxWeight or 0,
        returnOnClose = Config.InventoryPanel and Config.InventoryPanel.returnOnClose or false,
        blueprintDurabilityEnabled = durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() or false,
        defaultDurabilityLoss = durabilityConfig and durabilityConfig.defaultLoss or 10,
        defaultDurability = durabilityConfig and durabilityConfig.defaultDurability or 100,
        toolsEnabled = toolsConfig and toolsConfig.enabled or false,
        toolsDurabilityEnabled = toolsConfig and toolsConfig.durability and toolsConfig.durability.enabled and Inventory.IsOxInventory() or false,
        toolsDefaultDurability = toolsConfig and toolsConfig.durability and toolsConfig.durability.defaultDurability or 100,
        toolsDefaultLoss = toolsConfig and toolsConfig.durability and toolsConfig.durability.defaultLoss or 10
    }

    if not TechTrees or not TechTrees.enabled then
        result.techPoints = { points = 0, enabled = false }
        result.unlockedNodes = {}
        result.techTreeConfig = { enabled = false }
    else
        local perWorkbenchTech = TechTrees.perWorkbenchType
        local isShared, workbenchId = IsSharedTechWorkbench(stationId)

        local points, unlockedNodes
        if isShared then
            -- Use shared workbench tech data
            local techData = LoadSharedWorkbenchTech(workbenchId)
            points = techData.tech_points or 0

            unlockedNodes = {}
            for _, nodeKey in ipairs(techData.unlocked_nodes or {}) do
                unlockedNodes[nodeKey] = true
            end
        else
            -- Use player tech data
            points = LoadPlayerTechPoints(source, workbenchType)
            unlockedNodes = LoadPlayerUnlockedNodes(source, workbenchType)
        end

        local techPointsResult = {
            points = points,
            enabled = true,
            perWorkbenchType = perWorkbenchTech,
            isShared = isShared
        }

        if perWorkbenchTech then
            techPointsResult.workbenchType = workbenchType
            if not isShared then
                local fullData = LoadPlayerData(source)
                if fullData.workbench_tech then
                    techPointsResult.allWorkbenchTech = {}
                    for wbType, wbData in pairs(fullData.workbench_tech) do
                        techPointsResult.allWorkbenchTech[wbType] = {
                            points = wbData.tech_points or 0
                        }
                    end
                end
            end
        end
        result.techPoints = techPointsResult

        result.unlockedNodes = unlockedNodes

        local techTreeIds = GetTechTreesConfigForStation(stationId)
        local trees = GetTechTrees(techTreeIds)
        result.techTreeConfig = {
            enabled = trees ~= nil,
            trees = trees,
            isShared = isShared
        }
    end

    local stagedItems = {}
    local stagedWeight = 0
    if result.craftingInventoryConfig.enabled then
        local stagingKey = GetStagingKey(source, stationId)
        local items = GetStagedItemsForStation(stationId, stagingKey)

        for _, item in ipairs(items) do
            if item and item.count > 0 then
                local itemWeight = Inventory.GetItemWeight(item.item) or 0
                local stackWeight = itemWeight * item.count
                stagedWeight = stagedWeight + stackWeight

                table.insert(stagedItems, {
                    item = item.item,
                    label = item.label or Inventory.GetItemLabel(item.item) or item.item,
                    count = item.count,
                    slot = item.slot,
                    weight = itemWeight,
                    durability = item.durability
                })
            end
        end
    end
    result.stagedItems = stagedItems
    result.stagedWeight = stagedWeight

    local playerItems = Inventory.GetPlayerItems(source)
    local inventory = {}
    local inventoryWeight = 0
    for _, item in ipairs(playerItems) do
        local itemWeight = Inventory.GetItemWeight(item.name) or 0
        inventoryWeight = inventoryWeight + (itemWeight * (item.count or 1))

        -- Get durability from metadata for any item that has it
        local durability = nil
        if item.metadata and item.metadata.durability then
            durability = item.metadata.durability
        end

        inventory[#inventory + 1] = {
            item = item.name,
            label = item.label or item.name,
            count = item.count or 1,
            slot = item.slot, -- Include slot information
            image = nil,
            durability = durability
        }
    end
    result.inventory = inventory
    result.inventoryWeight = inventoryWeight
    result.inventoryMaxWeight = Inventory.GetPlayerMaxWeight(source) or Config.MaxInventoryWeight
    result.totalSlots = Inventory.GetInventorySlots(source)
    result.supportsSlots = Inventory.SupportsSlots()

    -- Send list of valid blueprint item names (items that are actually associated with recipes)
    local validBlueprintItems = {}
    for blueprintItem, _ in pairs(blueprintRecipes) do
        validBlueprintItems[#validBlueprintItems + 1] = blueprintItem
    end
    result.validBlueprintItems = validBlueprintItems

    -- Include effective CraftingBehavior for this station (merged with global defaults)
    result.craftingBehavior = GetEffectiveCraftingBehavior(stationId)

    return result
end)

--- Check if player has access to a workbench based on job/gang requirements
---@param source number Player server ID
---@param data table Data with job and gang config
---@return table result Table with hasAccess and optional reason/required fields
lib.callback.register('sd-crafting:server:checkWorkbenchAccess', function(source, data)
    local jobConfig = data.job
    local gangConfig = data.gang

    if not jobConfig and not gangConfig then
        return { hasAccess = true }
    end

    local playerJob = GetPlayerJob(source)
    local playerGang = GetPlayerGang(source)

    --- Normalize job/gang config into an array of { name, minGrade } entries
    --- Supports: array of tables, single table with name field, or plain string
    ---@param config any The job or gang config value
    ---@return table entries Array of { name = string, minGrade = number }
    local function normalizeEntries(config)
        if type(config) ~= 'table' then
            return { { name = tostring(config), minGrade = 0 } }
        end
        -- Array of entries (has numeric key [1])
        if config[1] ~= nil then
            local entries = {}
            for _, entry in ipairs(config) do
                if type(entry) == 'table' and entry.name then
                    entries[#entries + 1] = { name = entry.name, minGrade = entry.minGrade or 0 }
                elseif type(entry) == 'string' then
                    entries[#entries + 1] = { name = entry, minGrade = 0 }
                end
            end
            return entries
        end
        -- Single table with name field
        if config.name then
            return { { name = config.name, minGrade = config.minGrade or 0 } }
        end
        return {}
    end

    if jobConfig then
        local jobEntries = normalizeEntries(jobConfig)
        local playerGrade = Job.GetJobGrade(source)
        local jobMatched = false

        for _, entry in ipairs(jobEntries) do
            if playerJob == entry.name then
                if entry.minGrade > 0 and playerGrade < entry.minGrade then
                    return { hasAccess = false, reason = 'grade', requiredJob = entry.name, requiredGrade = entry.minGrade }
                end
                jobMatched = true
                break
            end
        end

        if not jobMatched then
            local jobNames = {}
            for _, entry in ipairs(jobEntries) do jobNames[#jobNames + 1] = entry.name end
            return { hasAccess = false, reason = 'job', requiredJob = table.concat(jobNames, ', ') }
        end
    end

    if gangConfig then
        local gangEntries = normalizeEntries(gangConfig)
        local playerGangGrade = GetPlayerGangGrade(source)
        local gangMatched = false

        for _, entry in ipairs(gangEntries) do
            if playerGang == entry.name then
                if entry.minGrade > 0 and playerGangGrade < entry.minGrade then
                    return { hasAccess = false, reason = 'gangGrade', requiredGang = entry.name, requiredGrade = entry.minGrade }
                end
                gangMatched = true
                break
            end
        end

        if not gangMatched then
            local gangNames = {}
            for _, entry in ipairs(gangEntries) do gangNames[#gangNames + 1] = entry.name end
            return { hasAccess = false, reason = 'gang', requiredGang = table.concat(gangNames, ', ') }
        end
    end

    return { hasAccess = true }
end)

--- Refund all items in a personal crafting queue to the station's staging inventory on disconnect
---@param source number Player server ID (still valid at time of playerDropped)
---@param identifier string Player identifier
---@param queueData table The player's crafting queue data
local function CancelAndRefundQueueOnLeave(source, identifier, queueData)
    local queue = queueData.queue
    local stationId = queueData.stationId
    if not queue or #queue == 0 or not stationId then return end

    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    if not useStaging then
        debugPrint('CancelCraftOnLeave: staging disabled, skipping refund for', identifier)
        return
    end

    local stagingKey = GetStagingKey(source, stationId)
    local cancelledCount = 0

    for _, queueItem in ipairs(queue) do
        local recipe = queueItem.recipe
        if recipe and recipe.ingredients then
            local quantity = queueItem.quantity or 1
            for _, ingredient in ipairs(recipe.ingredients) do
                local refundAmount = ingredient.amount * quantity
                local itemLabel = ingredient.label or Inventory.GetItemLabel(ingredient.item) or ingredient.item
                AddToStaging(stationId, stagingKey, ingredient.item, itemLabel, refundAmount)
            end
            cancelledCount = cancelledCount + 1
        end
    end

    BroadcastStagedItemsUpdate(stationId, nil)
    debugPrint('CancelCraftOnLeave: Cancelled', cancelledCount, 'craft(s) for', identifier, 'at station', stationId)
end

--- Cancel and refund all shared queue items owned by the disconnecting player across all stations
---@param source number Player server ID (still valid at time of playerDropped)
---@param identifier string Player identifier (for debug logging)
local function CancelAndRefundSharedQueueItemsOnLeave(source, identifier)
    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    if not useStaging then
        debugPrint('CancelCraftOnLeave: staging disabled, skipping shared queue refund for', identifier)
        return
    end

    for stationId, queue in pairs(SharedQueues) do
        if not queue or #queue == 0 then goto nextStation end

        local removedCount = 0
        local removedFirst = false
        local stagingKey = GetStagingKey(source, stationId)
        local i = 1

        while i <= #queue do
            local item = queue[i]
            if item.owner == source then
                local recipe = item.recipe
                if recipe and recipe.ingredients then
                    local quantity = item.quantity or 1
                    for _, ingredient in ipairs(recipe.ingredients) do
                        local refundAmount = ingredient.amount * quantity
                        local itemLabel = ingredient.label or Inventory.GetItemLabel(ingredient.item) or ingredient.item
                        AddToStaging(stationId, stagingKey, ingredient.item, itemLabel, refundAmount)
                    end
                end
                if i == 1 then removedFirst = true end
                table.remove(queue, i)
                removedCount = removedCount + 1
                -- Don't increment i — the next item has shifted into this position
            else
                i = i + 1
            end
        end

        if removedCount > 0 then
            -- Reset timing on the new first item so interpolation starts from now
            if removedFirst and #queue > 0 then
                queue[1].lastProgressSync = GetGameTimer()
            end
            BroadcastQueueUpdate(stationId, source)
            SaveSharedCraftingQueue(stationId, queue)
            BroadcastStagedItemsUpdate(stationId, nil)
            debugPrint('CancelCraftOnLeave: Cancelled', removedCount, 'shared queue craft(s) for', identifier, 'at station', stationId)
        end

        ::nextStation::
    end
end

--- Handle player disconnect logic for crafting queues
--- Extracted so it can be called from both playerDropped and the craftsimrelog command
---@param source number Player server ID
function HandlePlayerCraftingDisconnect(source)
    local identifier = GetIdentifier(source)
    if identifier then
        local queueData = PlayerCraftingQueues[identifier]
        local hasQueue = queueData and queueData.queue and #queueData.queue > 0
        debugPrint('playerDropped: CancelCraftOnLeave =', Config.CancelCraftOnLeave, '| hasQueue =', hasQueue, '| queueSize =', (queueData and queueData.queue and #queueData.queue or 0))

        if Config.CancelCraftOnLeave and hasQueue then
            -- Cancel queue and refund all ingredients to staging instead of saving
            CancelAndRefundQueueOnLeave(source, identifier, queueData)
            PlayerCraftingQueues[identifier] = nil
            DirtyPlayerQueues[identifier] = nil
            ServerProcessedQueues[identifier] = nil
            DeletePlayerCraftingQueue(identifier)
            -- Clear any pending craft tokens for this player to prevent ghost completions
            for token, craftData in pairs(PendingCrafts) do
                if craftData.identifier == identifier then
                    PendingCrafts[token] = nil
                end
            end
        elseif hasQueue then
            -- Default behavior: save queue for resumption on next login
            SavePlayerCraftingQueue(identifier, queueData)

            -- Try to get stationId from queue items as fallback if outer stationId is nil
            local stationId = queueData.stationId
            if not stationId and queueData.queue and #queueData.queue > 0 then
                stationId = queueData.queue[1].stationId
                debugPrint('playerDropped: queueData.stationId was nil, fell back to item stationId:', stationId)
            end

            debugPrint('playerDropped: identifier=' .. tostring(identifier) .. ', stationId=' .. tostring(stationId) .. ', queueSize=' .. #queueData.queue)

            -- Hand off to server-side processing so the queue actively ticks down
            -- while the player is offline (crafts complete and output goes to staging)
            if stationId then
                local stagingKey = GetStagingKey(source, stationId)
                debugPrint('playerDropped: Adding personal queue to server processing - stationId:', stationId, 'stagingKey:', stagingKey)
                AddToServerProcessing(identifier, queueData.queue, stationId, stagingKey, 0)
            end
        end

        -- Handle shared crafting queues where this player owns the active (first) item
        if Config.CancelCraftOnLeave then
            CancelAndRefundSharedQueueItemsOnLeave(source, identifier)
        else
            -- Hand off shared queues to server-side processing so crafts continue
            -- while the owner is offline (prevents blocking other players' crafts)
            for stationId, queue in pairs(SharedQueues) do
                if queue and #queue > 0 and queue[1].owner == source then
                    local sharedIdentifier = 'shared_' .. stationId
                    if not ServerProcessedQueues[sharedIdentifier] then
                        local stagingKey = GetStagingKey(source, stationId)
                        debugPrint('playerDropped: Adding SHARED queue to server processing - stationId:', stationId, 'stagingKey:', stagingKey, 'items:', #queue, 'remainingTime:', queue[1].remainingTime)
                        AddToServerProcessing(sharedIdentifier, queue, stationId, stagingKey, 0)
                    end
                end
            end
        end

        PlayerData[identifier] = nil
        -- Clean up all per-station completion timestamps for this player
        local prefix = identifier .. ':'
        for key in pairs(CraftCompletionTimestamps) do
            if key:sub(1, #prefix) == prefix then
                CraftCompletionTimestamps[key] = nil
            end
        end
        debugPrint('playerDropped: Cleaned up data for', identifier)
    end
    for stationId, players in pairs(OpenStations) do
        players[source] = nil
    end
end

--- Clear cache and save crafting queue when player drops
AddEventHandler('playerDropped', function()
    HandlePlayerCraftingDisconnect(source)
end)

--- Save all crafting queues when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Stop the periodic save thread
    QueueSaveThreadActive = false
    -- Save any pending dirty queues first
    SaveDirtyQueues()
    SaveAllServerProcessedQueues()
    SaveAllPlayerCraftingQueues()
end)

--- Save all crafting queues on txAdmin scheduled restart
AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    debugPrint('txAdmin scheduled restart detected, saving all crafting queues...')
    QueueSaveThreadActive = false
    SaveDirtyQueues()
    SaveAllServerProcessedQueues()
    SaveAllPlayerCraftingQueues()
end)

--- Save all crafting queues on txAdmin server shutdown
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    debugPrint('txAdmin server shutdown detected, saving all crafting queues...')
    QueueSaveThreadActive = false
    SaveDirtyQueues()
    SaveAllServerProcessedQueues()
    SaveAllPlayerCraftingQueues()
end)

--- Get all recipes as a flat list (iterates through all workbench types)
---@return table allRecipes Array of all recipes with workbenchType added
local function GetAllRecipes()
    local allRecipes = {}
    for workbenchType, recipes in pairs(Recipes) do
        for _, recipe in ipairs(recipes) do
            local recipeCopy = {}
            for k, v in pairs(recipe) do
                recipeCopy[k] = v
            end
            recipeCopy.workbenchType = workbenchType
            allRecipes[#allRecipes + 1] = recipeCopy
        end
    end
    return allRecipes
end

--- Get recipes for a specific workbench type (includes 'all' recipes)
---@param workbenchType string Workbench type to get recipes for
---@return table recipes Array of recipes for the workbench type
local function GetRecipesForWorkbenchType(workbenchType)
    local result = {}

    if Recipes['all'] then
        for _, recipe in ipairs(Recipes['all']) do
            local recipeCopy = {}
            for k, v in pairs(recipe) do
                recipeCopy[k] = v
            end
            recipeCopy.workbenchType = 'all'
            result[#result + 1] = recipeCopy
        end
    end

    if workbenchType and Recipes[workbenchType] then
        for _, recipe in ipairs(Recipes[workbenchType]) do
            local recipeCopy = {}
            for k, v in pairs(recipe) do
                recipeCopy[k] = v
            end
            recipeCopy.workbenchType = workbenchType
            result[#result + 1] = recipeCopy
        end
    end

    return result
end

--- Get recipe by ID (searches all workbench types)
---@param recipeId string Recipe identifier
---@return table|nil recipe Recipe data with workbenchType added or nil if not found
function GetRecipeById(recipeId)
    for workbenchType, recipes in pairs(Recipes) do
        for _, recipe in ipairs(recipes) do
            if recipe.id == recipeId then
                local recipeCopy = {}
                for k, v in pairs(recipe) do
                    recipeCopy[k] = v
                end
                recipeCopy.workbenchType = workbenchType
                return recipeCopy
            end
        end
    end
    return nil
end

--- Check if a blueprint is attached to a station (checks both StationBlueprints and staged items)
---@param stationId string Station identifier
---@param blueprintItem string Blueprint item name
---@param source number|nil Player source for checking staged items
---@return boolean attached Whether the blueprint is attached
local function IsBlueprintAttached(stationId, blueprintItem, source)
    if StationBlueprints[stationId] and StationBlueprints[stationId][blueprintItem] then
        return true
    end

    if source and StagedItems[stationId] then
        local stagingKey = IsPerWorkbenchEnabled(stationId) and 'shared' or (GetIdentifier(source) or 'player_' .. source)
        local stagedItems = StagedItems[stationId][stagingKey] or {}

        for _, item in ipairs(stagedItems) do
            if item.item == blueprintItem then
                return true
            end
        end
    end

    return false
end

--- Check if a blueprint is currently in use by any item in the crafting queue
--- This prevents removing blueprints while recipes that require them are being crafted
---@param stationId string Station identifier
---@param blueprintItem string Blueprint item name
---@return boolean inUse Whether the blueprint is in use by a queued recipe
---@return string|nil recipeLabel The label of the recipe using the blueprint (if in use)
local function IsBlueprintInQueue(stationId, blueprintItem)
    if not stationId or not blueprintItem then return false, nil end

    -- Check shared queue for this station
    if SharedQueues[stationId] then
        for _, queueItem in ipairs(SharedQueues[stationId]) do
            if queueItem.recipe and queueItem.recipe.blueprint == blueprintItem then
                local label = queueItem.recipe.label or Inventory.GetItemLabel(queueItem.recipe.name) or FormatItemName(queueItem.recipe.name)
                return true, label
            end
        end
    end

    -- Check all player queues that are for this station
    for identifier, playerQueue in pairs(PlayerCraftingQueues) do
        if playerQueue.stationId == stationId and playerQueue.queue then
            for _, queueItem in ipairs(playerQueue.queue) do
                if queueItem.recipe and queueItem.recipe.blueprint == blueprintItem then
                    local label = queueItem.recipe.label or Inventory.GetItemLabel(queueItem.recipe.name) or FormatItemName(queueItem.recipe.name)
                    return true, label
                end
            end
        end
    end

    -- Check server-processed queues (for offline processing)
    for identifier, serverQueue in pairs(ServerProcessedQueues) do
        if serverQueue.stationId == stationId and serverQueue.queue then
            for _, queueItem in ipairs(serverQueue.queue) do
                if queueItem.recipe and queueItem.recipe.blueprint == blueprintItem then
                    local label = queueItem.recipe.label or Inventory.GetItemLabel(queueItem.recipe.name) or FormatItemName(queueItem.recipe.name)
                    return true, label
                end
            end
        end
    end

    return false, nil
end

--- Get attached blueprints for a station (checks both StationBlueprints and staged items)
---@param source number Player server ID
---@param stationId string Station identifier
---@return table attached Array of attached blueprint item names (strings for backwards compatibility)
---@return table attachedWithLabels Array of attached blueprint objects with labels
lib.callback.register('sd-crafting:server:getAttachedBlueprints', function(source, stationId)
    local attached = {}
    local attachedWithLabels = {}
    local attachedLookup = {}
    local blueprintRecipes = GetBlueprintRecipes()

    if StationBlueprints[stationId] then
        for blueprintItem, _ in pairs(StationBlueprints[stationId]) do
            if not attachedLookup[blueprintItem] then
                table.insert(attached, blueprintItem)
                attachedLookup[blueprintItem] = true

                -- Get label from the blueprint item itself and the recipe it unlocks
                local blueprintLabel = Inventory.GetItemLabel(blueprintItem) or FormatItemName(blueprintItem)
                local recipe = blueprintRecipes[blueprintItem]
                if recipe then
                    local recipeLabel = recipe.label or Inventory.GetItemLabel(recipe.name) or FormatItemName(recipe.name)
                    table.insert(attachedWithLabels, {
                        item = blueprintItem,
                        label = blueprintLabel,
                        recipeId = recipe.id,
                        recipeLabel = recipeLabel
                    })
                else
                    table.insert(attachedWithLabels, {
                        item = blueprintItem,
                        label = blueprintLabel,
                        recipeId = blueprintItem,
                        recipeLabel = FormatItemName(blueprintItem)
                    })
                end
            end
        end
    end

    if StagedItems[stationId] then
        local stagingKey = IsPerWorkbenchEnabled(stationId) and 'shared' or (GetIdentifier(source) or 'player_' .. source)
        local stagedItems = StagedItems[stationId][stagingKey] or {}

        for _, item in ipairs(stagedItems) do
            if item.item and IsBlueprint(item.item) and not attachedLookup[item.item] then
                table.insert(attached, item.item)
                attachedLookup[item.item] = true

                -- Get label from the blueprint item itself and the recipe it unlocks
                local blueprintLabel = Inventory.GetItemLabel(item.item) or FormatItemName(item.item)
                local recipe = blueprintRecipes[item.item]
                if recipe then
                    local recipeLabel = recipe.label or Inventory.GetItemLabel(recipe.name) or FormatItemName(recipe.name)
                    table.insert(attachedWithLabels, {
                        item = item.item,
                        label = blueprintLabel,
                        recipeId = recipe.id,
                        recipeLabel = recipeLabel
                    })
                else
                    table.insert(attachedWithLabels, {
                        item = item.item,
                        label = blueprintLabel,
                        recipeId = item.item,
                        recipeLabel = FormatItemName(item.item)
                    })
                end
            end
        end
    end

    return attached, attachedWithLabels
end)

--- Get player's blueprint items from inventory
---@param source number Player server ID
---@return table playerBlueprints Array of blueprint data with item, label, count, recipeId, recipeLabel
lib.callback.register('sd-crafting:server:getPlayerBlueprints', function(source)
    local playerBlueprints = {}
    local blueprintRecipes = GetBlueprintRecipes()

    for blueprintItem, recipe in pairs(blueprintRecipes) do
        local count = Inventory.GetItemCount(source, blueprintItem)
        if count > 0 then
            -- Get the actual blueprint item label from the inventory system
            local blueprintLabel = Inventory.GetItemLabel(blueprintItem) or FormatItemName(blueprintItem)
            local inventoryLabel = Inventory.GetItemLabel(recipe.name)
            -- Use recipe.label first, then inventory label if it's not just the raw item name, otherwise format the name nicely
            local recipeLabel = recipe.label or (inventoryLabel ~= recipe.name and inventoryLabel) or FormatItemName(recipe.name)
            table.insert(playerBlueprints, {
                item = blueprintItem,
                label = blueprintLabel,
                count = count,
                recipeId = recipe.id,
                recipeLabel = recipeLabel
            })
        end
    end

    return playerBlueprints
end)

--- Attach a blueprint to a station
---@param source number Player server ID
---@param data table Data with stationId and blueprintItem
---@return boolean success Whether attachment was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:attachBlueprint', function(source, data)
    local stationId = data.stationId
    local blueprintItem = data.blueprintItem

    if not stationId or not blueprintItem then return false end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    local count = Inventory.GetItemCount(source, blueprintItem)
    if count < 1 then
        return false, 'You do not have this blueprint'
    end

    if IsBlueprintAttached(stationId, blueprintItem, source) then
        return false, 'This blueprint is already attached to this station'
    end

    -- Get blueprint durability from metadata before removing (ox_inventory only)
    local durability = nil
    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability
    if durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() then
        local items = Inventory.GetItemsWithMetadata(source, blueprintItem)
        if items and items[1] then
            local metadata = items[1].metadata or {}
            durability = metadata.durability or durabilityConfig.defaultDurability or 100
            -- Remove from specific slot to preserve correct item
            local removed = Inventory.RemoveItemFromSlot(source, blueprintItem, 1, items[1].slot)
            if not removed then
                return false, 'Failed to remove blueprint from inventory'
            end
        else
            return false, 'Blueprint not found in inventory'
        end
    else
        local removed = Inventory.RemoveItem(source, blueprintItem, 1)
        if not removed then
            return false, 'Failed to remove blueprint from inventory'
        end
    end

    if not StationBlueprints[stationId] then
        StationBlueprints[stationId] = {}
    end

    -- Store durability value if durability system is enabled, otherwise store true
    if durability then
        StationBlueprints[stationId][blueprintItem] = { durability = durability }
    else
        StationBlueprints[stationId][blueprintItem] = true
    end

    debugPrint('Player', source, 'attached blueprint', blueprintItem, 'to station', stationId, durability and ('(durability: ' .. durability .. ')') or '')

    return true, 'Blueprint attached successfully'
end)

--- Detach a blueprint from a station (give it back to player)
---@param source number Player server ID
---@param data table Data with stationId and blueprintItem
---@return boolean success Whether detachment was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:detachBlueprint', function(source, data)
    local stationId = data.stationId
    local blueprintItem = data.blueprintItem

    if not stationId or not blueprintItem then return false end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    -- Check if blueprint is in use by the crafting queue
    local inQueue, craftingItem = IsBlueprintInQueue(stationId, blueprintItem)
    if inQueue then
        return false, 'blueprint_in_queue', craftingItem
    end

    if not IsBlueprintAttached(stationId, blueprintItem, source) then
        return false, 'This blueprint is not attached to this station'
    end

    -- Get stored durability and add item with metadata if applicable
    local blueprintData = StationBlueprints[stationId][blueprintItem]
    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability
    local added = false

    if durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() and type(blueprintData) == 'table' and blueprintData.durability then
        -- Add item with durability metadata
        added = Inventory.AddItemWithMetadata(source, blueprintItem, 1, { durability = blueprintData.durability })
    else
        added = Inventory.AddItem(source, blueprintItem, 1)
    end

    if not added then
        return false, 'Failed to add blueprint to inventory'
    end

    StationBlueprints[stationId][blueprintItem] = nil

    local durabilityStr = type(blueprintData) == 'table' and blueprintData.durability and ('(durability: ' .. blueprintData.durability .. ')') or ''
    debugPrint('Player', source, 'detached blueprint', blueprintItem, 'from station', stationId, durabilityStr)

    return true, 'Blueprint detached successfully'
end)

--- Save staged items to database (uses unified workbenches table)
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
local function SaveStagedItemsToDatabase(stationId, stagingKey)
    local identifier = stagingKey or 'shared'
    local items = GetStagedItemsForStation(stationId, stagingKey)

    local existing = MySQL.query.await(
        "SELECT id FROM sd_crafting_workbenches WHERE type = 'staged' AND station_id = ? AND identifier = ?",
        { stationId, identifier }
    )

    if existing and existing[1] then
        if #items > 0 then
            MySQL.update(
                "UPDATE sd_crafting_workbenches SET data = ? WHERE type = 'staged' AND station_id = ? AND identifier = ?",
                { json.encode(items), stationId, identifier }
            )
        else
            MySQL.query(
                "DELETE FROM sd_crafting_workbenches WHERE type = 'staged' AND station_id = ? AND identifier = ?",
                { stationId, identifier }
            )
        end
    elseif #items > 0 then
        MySQL.insert(
            "INSERT INTO sd_crafting_workbenches (type, station_id, identifier, data) VALUES ('staged', ?, ?, ?)",
            { stationId, identifier, json.encode(items) }
        )
    end
end

--- Get count of a specific item in staged inventory
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param itemName string Item name to count
---@return number count Total count of the item
local function GetStagedItemCount(stationId, stagingKey, itemName)
    local items = GetStagedItemsForStation(stationId, stagingKey)
    local total = 0
    for _, item in ipairs(items) do
        if item.item == itemName then
            total = total + item.count
        end
    end
    return total
end

--- Deep compare two tables for equality (used for metadata comparison)
---@param t1 table|nil First table
---@param t2 table|nil Second table
---@return boolean equal Whether tables are deeply equal
local function DeepEqual(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= 'table' then return t1 == t2 end

    -- Check all keys in t1 exist in t2 with same value
    for k, v in pairs(t1) do
        if not DeepEqual(v, t2[k]) then return false end
    end
    -- Check t2 doesn't have extra keys
    for k in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
end

--- Get total slot count used in staged inventory
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@return number count Number of slots used
local function GetStagedSlotCount(stationId, stagingKey)
    local items = GetStagedItemsForStation(stationId, stagingKey)
    local count = 0
    for _, item in ipairs(items) do
        if item and item.count > 0 then
            count = count + 1
        end
    end
    return count
end

--- Add item to staging
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param itemName string Item name
---@param itemLabel string Item label
---@param count number Amount to add
---@param targetSlot number|nil Optional target slot
---@param durability number|nil Optional durability for blueprints
---@param metadata table|nil Optional metadata to apply when item is moved to inventory
---@return boolean success Whether item was added
---@return string|nil error Error message if failed
function AddToStaging(stationId, stagingKey, itemName, itemLabel, count, targetSlot, durability, metadata)
    local items = GetStagedItemsForStation(stationId, stagingKey)

    if not StagedItems[stationId] then
        StagedItems[stationId] = {}
    end
    if not StagedItems[stationId][stagingKey] then
        StagedItems[stationId][stagingKey] = items
    end

    items = StagedItems[stationId][stagingKey]
    local maxSlots = Config.InventoryPanel and Config.InventoryPanel.maxSlots or 20

    local isBlueprint = IsBlueprint(itemName)

    -- Helper to check if durabilities match (both nil, or both same value)
    local function durabilityMatches(dur1, dur2)
        if dur1 == nil and dur2 == nil then return true end
        if dur1 == nil or dur2 == nil then return false end
        return dur1 == dur2
    end

    -- Check if item is stackable (weapons, etc. are not)
    local isStackable = Inventory.IsItemStackable(itemName)

    -- Check if targetSlot already has an item
    if targetSlot ~= nil then
        for _, item in ipairs(items) do
            if item.slot == targetSlot then
                -- Slot is occupied - only merge if same item type and NOT a blueprint
                -- Blueprints never stack - each one needs its own slot
                -- Items with different durabilities should NOT stack
                -- Non-stackable items (like weapons) should NOT stack
                if item.item == itemName and not isBlueprint and isStackable and durabilityMatches(durability, item.durability) then
                    item.count = item.count + count
                    item.label = itemLabel or item.label
                    SaveStagedItemsToDatabase(stationId, stagingKey)
                    return true
                else
                    -- Different item in target slot OR blueprint OR different durability OR non-stackable - find next empty slot instead
                    targetSlot = nil
                    break
                end
            end
        end
    end

    -- If no targetSlot specified, try to find an existing stack of the same item to merge with
    -- But only if the item is stackable (weapons, etc. are not)
    if targetSlot == nil and isStackable then
        for _, item in ipairs(items) do
            if item.item == itemName then
                -- For blueprints, don't auto-stack (each needs its own slot with unique durability)
                if isBlueprint then
                    -- Skip stacking for blueprints - continue to create new slot
                -- Items with different durabilities should NOT stack
                elseif not durabilityMatches(durability, item.durability) then
                    -- Different durability - don't stack, continue searching
                elseif metadata == nil and item.metadata == nil then
                    -- Neither has metadata, durability matches - stack normally
                    item.count = item.count + count
                    item.label = itemLabel or item.label
                    SaveStagedItemsToDatabase(stationId, stagingKey)
                    return true
                elseif metadata ~= nil and item.metadata ~= nil then
                    -- Both have metadata - only stack if metadata matches exactly
                    local metadataMatches = DeepEqual(metadata, item.metadata)
                    if metadataMatches then
                        item.count = item.count + count
                        item.label = itemLabel or item.label
                        SaveStagedItemsToDatabase(stationId, stagingKey)
                        return true
                    end
                end
                -- If one has metadata and other doesn't, don't stack (continue searching)
            end
        end
    end

    -- For non-stackable items with count > 1, create individual slot entries
    local itemsToCreate = 1
    local countPerItem = count
    if not isStackable and count > 1 then
        itemsToCreate = count
        countPerItem = 1
    end

    -- Check if there are enough slots available
    local currentSlotCount = GetStagedSlotCount(stationId, stagingKey)
    if currentSlotCount + itemsToCreate > maxSlots then
        return false, 'Crafting inventory is full'
    end

    -- Build used slots map once for finding empty slots
    local usedSlots = {}
    for _, item in ipairs(items) do
        if item.slot then usedSlots[item.slot] = true end
    end

    --- Find the next available slot starting from a given index
    ---@param startFrom number Slot index to start searching from
    ---@return number slot The next available slot
    local function findNextSlot(startFrom)
        local s = startFrom
        while usedSlots[s] do
            s = s + 1
        end
        return s
    end

    local nextSlot = targetSlot or 0
    for i = 1, itemsToCreate do
        local slotToUse = findNextSlot(nextSlot)
        usedSlots[slotToUse] = true

        local newItem = {
            item = itemName,
            label = itemLabel or itemName,
            count = countPerItem,
            slot = slotToUse
        }
        if durability then
            newItem.durability = durability
        end
        if metadata then
            newItem.metadata = metadata
        end
        table.insert(items, newItem)

        nextSlot = slotToUse + 1
    end

    SaveStagedItemsToDatabase(stationId, stagingKey)
    return true
end

--- Get durability of a staged blueprint
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param blueprintItem string Blueprint item name
---@param sourceSlot number|nil Optional slot to get durability from specifically
---@return number|nil durability The blueprint's durability or nil if not found
local function GetStagedBlueprintDurability(stationId, stagingKey, blueprintItem, sourceSlot)
    local items = GetStagedItemsForStation(stationId, stagingKey)
    for _, item in ipairs(items) do
        if item.item == blueprintItem and (not sourceSlot or item.slot == sourceSlot) then
            return item.durability
        end
    end
    return nil
end

--- Update durability of a staged blueprint
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param blueprintItem string Blueprint item name
---@param newDurability number New durability value
---@return boolean success Whether the update was successful
local function UpdateStagedBlueprintDurability(stationId, stagingKey, blueprintItem, newDurability)
    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false
    end

    local items = StagedItems[stationId][stagingKey]
    for _, item in ipairs(items) do
        if item.item == blueprintItem then
            item.durability = newDurability
            SaveStagedItemsToDatabase(stationId, stagingKey)
            return true
        end
    end
    return false
end

--- Remove a staged blueprint completely (when durability depletes)
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param blueprintItem string Blueprint item name
---@return boolean success Whether the removal was successful
local function RemoveStagedBlueprint(stationId, stagingKey, blueprintItem)
    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false
    end

    local items = StagedItems[stationId][stagingKey]
    for i, item in ipairs(items) do
        if item.item == blueprintItem then
            table.remove(items, i)
            SaveStagedItemsToDatabase(stationId, stagingKey)
            return true
        end
    end
    return false
end

--- Check if a blueprint exists in staging
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param blueprintItem string Blueprint item name
---@return boolean exists Whether the blueprint exists in staging
local function IsBlueprintInStaging(stationId, stagingKey, blueprintItem)
    local items = GetStagedItemsForStation(stationId, stagingKey)
    for _, item in ipairs(items) do
        if item.item == blueprintItem then
            return true
        end
    end
    return false
end

--- Get staged tool data (count, durability, and total available durability across all stacks)
--- Prioritizes finding a tool that already has durability set (count=1 with durability)
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param toolItem string Tool item name
---@param defaultDurability number|nil Default durability for fresh items
---@return number count Total count of tool in staging
---@return number|nil durability Durability of the best matching tool (prefers one with durability already set)
---@return number|nil slotIndex Slot index of the tool with durability (for updating)
---@return number totalDurability Total durability available across all tools in staging
local function GetStagedToolData(stationId, stagingKey, toolItem, defaultDurability)
    local items = GetStagedItemsForStation(stationId, stagingKey)
    local totalCount = 0
    local activeTool = nil -- The single item (count=1) that's currently being used
    local totalDurability = 0
    defaultDurability = defaultDurability or 100

    -- First pass: count total, find the active tool (count=1), and calculate total durability
    for _, item in ipairs(items) do
        if item.item == toolItem then
            local itemCount = item.count or 1
            totalCount = totalCount + itemCount

            -- Calculate durability contribution - each item in the stack has the same durability
            local itemDurability = item.durability or defaultDurability
            totalDurability = totalDurability + (itemCount * itemDurability)

            -- Find the "active" tool - a single item (count=1) that's already being used
            -- This is the tool we split off from a stack when crafting started
            if itemCount == 1 and item.durability then
                activeTool = item
            end
        end
    end

    -- Determine the best durability to return (the one we'll use for next craft)
    local bestDurability = nil
    local bestSlot = nil

    if activeTool then
        -- We have an active tool that's already been split off and is in use
        bestDurability = activeTool.durability
        bestSlot = activeTool.slot
    else
        -- No active tool - find any tool (will be split when used)
        for _, item in ipairs(items) do
            if item.item == toolItem then
                bestDurability = item.durability -- May be nil, will use default
                bestSlot = item.slot
                break
            end
        end
    end

    return totalCount, bestDurability, bestSlot, totalDurability
end

--- Validate required tools for a recipe
---@param source number Player server ID
---@param recipe table The recipe with tools field
---@param stationId string Station identifier
---@param quantity number Craft quantity
---@return boolean valid Whether all tools are available
---@return string|nil error Error message if validation fails
local function ValidateRequiredTools(source, recipe, stationId, quantity)
    if not recipe.tools or not Config.Tools or not Config.Tools.enabled then
        return true
    end

    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    local stagingKey = useStaging and GetStagingKey(source, stationId) or nil

    for _, tool in ipairs(recipe.tools) do
        local availableCount
        local toolDurability
        local totalAvailableDurability
        local defaultDur = Config.Tools.durability and Config.Tools.durability.defaultDurability or 100

        if useStaging then
            availableCount, toolDurability, _, totalAvailableDurability = GetStagedToolData(stationId, stagingKey, tool.item, defaultDur)
        else
            availableCount = Inventory.GetItemCount(source, tool.item)
            -- For non-staging, assume each tool has default durability
            totalAvailableDurability = availableCount * defaultDur
        end

        local requiredAmount = tool.amount or 1
        if availableCount < requiredAmount then
            local toolLabel = Inventory.GetItemLabel(tool.item) or tool.item
            return false, 'Missing tool: ' .. toolLabel .. ' (' .. availableCount .. '/' .. requiredAmount .. ')'
        end

        -- For durability tools, check if there's enough TOTAL durability across all tools for all crafts
        if tool.consumptionType == 'durability' and Config.Tools.durability and Config.Tools.durability.enabled and Inventory.IsOxInventory() then
            local durabilityLoss = tool.durabilityLoss or Config.Tools.durability.defaultLoss or 10
            local totalDurabilityNeeded = durabilityLoss * quantity

            if totalAvailableDurability < totalDurabilityNeeded then
                local toolLabel = Inventory.GetItemLabel(tool.item) or tool.item
                local maxCrafts = math.floor(totalAvailableDurability / durabilityLoss)
                return false, toolLabel .. ' durability too low (can craft max ' .. maxCrafts .. ')'
            end
        end

        -- For consume type, check if there's enough to consume for all crafts
        if tool.consumptionType == 'consume' then
            local totalNeeded = requiredAmount * quantity
            if availableCount < totalNeeded then
                local toolLabel = Inventory.GetItemLabel(tool.item) or tool.item
                return false, 'Not enough ' .. toolLabel .. ' (' .. availableCount .. '/' .. totalNeeded .. ')'
            end
        end
    end

    return true
end

--- Find the next available slot in staging
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@return number|nil nextSlot The next available slot, or nil if full
local function FindNextAvailableSlot(stationId, stagingKey)
    local maxSlots = Config.InventoryPanel and Config.InventoryPanel.maxSlots or 20
    local items = GetStagedItemsForStation(stationId, stagingKey)
    local usedSlots = {}

    for _, item in ipairs(items) do
        if item.slot then
            usedSlots[item.slot] = true
        end
    end

    for i = 1, maxSlots do
        if not usedSlots[i] then
            return i
        end
    end

    return nil
end

--- Update durability of a staged tool, splitting from stack if needed
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param toolItem string Tool item name
---@param newDurability number New durability value
---@return boolean success Whether the update was successful
local function UpdateStagedToolDurability(stationId, stagingKey, toolItem, newDurability)
    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false
    end

    local items = StagedItems[stationId][stagingKey]

    -- First, look for a SINGLE item (count=1) that already has durability set (the "in use" tool)
    -- This prevents matching stacks that happen to have durability metadata
    for _, item in ipairs(items) do
        if item.item == toolItem and item.durability and item.count == 1 then
            item.durability = newDurability
            SaveStagedItemsToDatabase(stationId, stagingKey)
            return true
        end
    end

    -- No single "in use" tool found - need to split from a stack or use a single item without durability
    for i, item in ipairs(items) do
        if item.item == toolItem then
            if item.count == 1 then
                -- Single item without durability set, just set durability
                item.durability = newDurability
                SaveStagedItemsToDatabase(stationId, stagingKey)
                return true
            else
                -- Stack of items (count > 1) - split 1 off with the new durability
                local nextSlot = FindNextAvailableSlot(stationId, stagingKey)
                if not nextSlot then
                    -- No room to split - this is problematic
                    -- Log warning but don't corrupt the stack
                    debugPrint('WARNING: No slot available to split tool stack for', toolItem)
                    return false
                end

                -- Split: reduce original stack count
                item.count = item.count - 1

                -- If the original stack is now empty, remove it
                if item.count <= 0 then
                    for j = #items, 1, -1 do
                        if items[j] == item then
                            table.remove(items, j)
                            break
                        end
                    end
                end

                -- Create new single item with the new durability
                local newItem = {
                    item = item.item,
                    label = item.label,
                    count = 1,
                    slot = nextSlot,
                    durability = newDurability,
                    image = item.image
                }
                table.insert(items, newItem)

                debugPrint('Split tool stack:', toolItem, '- 1 item moved to slot', nextSlot, 'with durability', newDurability)

                SaveStagedItemsToDatabase(stationId, stagingKey)
                return true
            end
        end
    end

    return false
end

--- Remove a staged tool completely
--- Remove a staged tool - prioritizes the "active" tool (count=1 with durability)
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param toolItem string Tool item name
---@param amount number Amount to remove (default 1)
---@param preferWithDurability boolean If true, prefer removing the active tool (count=1 with durability)
---@return boolean success Whether the removal was successful
local function RemoveStagedTool(stationId, stagingKey, toolItem, amount, preferWithDurability)
    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false
    end

    amount = amount or 1
    local items = StagedItems[stationId][stagingKey]
    local remaining = amount

    -- If preferWithDurability, first try to remove the "active" tool (count=1 with durability)
    -- This is the tool that was split off from a stack and is currently in use
    if preferWithDurability and remaining > 0 then
        for i = #items, 1, -1 do
            if items[i].item == toolItem and items[i].durability and items[i].count == 1 then
                table.remove(items, i)
                remaining = remaining - 1
                if remaining <= 0 then break end
            end
        end
    end

    -- Then try stacks that have durability set (from ox_inventory)
    if preferWithDurability and remaining > 0 then
        for i = #items, 1, -1 do
            if items[i].item == toolItem and items[i].durability and items[i].count > 1 and remaining > 0 then
                if items[i].count <= remaining then
                    remaining = remaining - items[i].count
                    table.remove(items, i)
                else
                    items[i].count = items[i].count - remaining
                    remaining = 0
                end
            end
        end
    end

    -- Finally, remove from any remaining items (stacks without durability)
    for i = #items, 1, -1 do
        if items[i].item == toolItem and remaining > 0 then
            if items[i].count <= remaining then
                remaining = remaining - items[i].count
                table.remove(items, i)
            else
                items[i].count = items[i].count - remaining
                remaining = 0
            end
        end
    end

    SaveStagedItemsToDatabase(stationId, stagingKey)
    return remaining == 0
end

--- Apply tool consumption after successful craft
---@param source number Player server ID
---@param recipe table The recipe with tools field
---@param stationId string Station identifier
---@param successfulCrafts number Number of successful crafts
---@return table|nil toolResults Results of tool consumption (broken tools, durability changes)
local function ApplyToolConsumption(source, recipe, stationId, successfulCrafts)
    if not recipe.tools or not Config.Tools or not Config.Tools.enabled then
        return nil
    end

    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    local stagingKey = useStaging and GetStagingKey(source, stationId) or nil

    local results = {
        toolsBroken = {},
        durabilityReduced = {},
        toolsConsumed = {}
    }

    for _, tool in ipairs(recipe.tools) do
        local consumptionType = tool.consumptionType or 'none'

        if consumptionType == 'none' then
            -- Tool is not consumed, do nothing
        elseif consumptionType == 'durability' then
            -- Only apply durability if ox_inventory and durability is enabled
            if Config.Tools.durability and Config.Tools.durability.enabled and Inventory.IsOxInventory() then
                local durabilityLoss = tool.durabilityLoss or Config.Tools.durability.defaultLoss or 10
                local defaultDurability = Config.Tools.durability.defaultDurability or 100
                local toolLabel = Inventory.GetItemLabel(tool.item) or tool.item
                local remainingCrafts = successfulCrafts
                local totalToolsBroken = 0
                local finalDurability = nil

                -- Process crafts, potentially using multiple tools if they break mid-batch
                while remainingCrafts > 0 do
                    -- Get current tool data (prioritizes tools with durability already set)
                    local toolCount, currentDurability, _, _ = GetStagedToolData(stationId, stagingKey, tool.item, defaultDurability)

                    if toolCount <= 0 then
                        -- No more tools available (shouldn't happen if validation passed, but safety check)
                        debugPrint('No more', tool.item, 'available mid-batch')
                        break
                    end

                    currentDurability = currentDurability or defaultDurability

                    -- Calculate how many crafts this tool can handle
                    local craftsWithThisTool = math.floor(currentDurability / durabilityLoss)

                    if craftsWithThisTool >= remainingCrafts then
                        -- This tool can handle all remaining crafts
                        local totalLoss = durabilityLoss * remainingCrafts
                        local newDurability = currentDurability - totalLoss

                        if newDurability <= 0 then
                            -- Tool breaks exactly at the end
                            if useStaging then
                                RemoveStagedTool(stationId, stagingKey, tool.item, 1, true)
                            else
                                Inventory.RemoveItem(source, tool.item, 1)
                            end
                            totalToolsBroken = totalToolsBroken + 1
                            finalDurability = nil

                            debugPrint('Tool', tool.item, 'broke after completing remaining', remainingCrafts, 'crafts')
                        else
                            -- Tool survives with remaining durability
                            if useStaging then
                                UpdateStagedToolDurability(stationId, stagingKey, tool.item, newDurability)
                            end
                            finalDurability = newDurability

                            debugPrint('Tool', tool.item, 'durability reduced:', currentDurability, '->', newDurability)
                        end
                        remainingCrafts = 0
                    else
                        -- Tool will break before completing all remaining crafts
                        -- Use this tool until it breaks, then continue with next
                        if useStaging then
                            RemoveStagedTool(stationId, stagingKey, tool.item, 1, true)
                        else
                            Inventory.RemoveItem(source, tool.item, 1)
                        end
                        totalToolsBroken = totalToolsBroken + 1
                        remainingCrafts = remainingCrafts - craftsWithThisTool

                        debugPrint('Tool', tool.item, 'broke after', craftsWithThisTool, 'crafts,', remainingCrafts, 'remaining')
                    end
                end

                -- Record results
                if totalToolsBroken > 0 then
                    table.insert(results.toolsBroken, {
                        item = tool.item,
                        label = toolLabel,
                        count = totalToolsBroken
                    })
                end

                if finalDurability then
                    table.insert(results.durabilityReduced, {
                        item = tool.item,
                        label = toolLabel,
                        newDurability = finalDurability,
                        loss = durabilityLoss * successfulCrafts
                    })
                end
            end
            -- If durability not enabled/supported, tool acts as 'none' (not consumed)

        elseif consumptionType == 'chance' then
            -- Roll for each successful craft - multiple tools can break
            local consumeChance = tool.consumeChance or 25
            local toolLabel = Inventory.GetItemLabel(tool.item) or tool.item
            local toolsBrokenCount = 0
            local toolAmount = tool.amount or 1

            -- Get available tool count
            local availableCount
            if useStaging then
                availableCount = GetStagedToolData(stationId, stagingKey, tool.item, 100)
            else
                availableCount = Inventory.GetItemCount(source, tool.item)
            end

            -- Roll for each craft - each failed roll breaks one tool
            for i = 1, successfulCrafts do
                local roll = math.random(1, 100)
                if roll <= consumeChance then
                    -- Tool breaks - remove it
                    local canBreak = (availableCount - toolsBrokenCount) >= toolAmount
                    if canBreak then
                        if useStaging then
                            RemoveStagedTool(stationId, stagingKey, tool.item, toolAmount)
                        else
                            Inventory.RemoveItem(source, tool.item, toolAmount)
                        end
                        toolsBrokenCount = toolsBrokenCount + 1
                    end
                end
            end

            if toolsBrokenCount > 0 then
                table.insert(results.toolsBroken, {
                    item = tool.item,
                    label = toolLabel,
                    reason = 'chance',
                    count = toolsBrokenCount
                })

                debugPrint('Tool', tool.item, 'broke x' .. toolsBrokenCount .. ' from chance consumption (' .. consumeChance .. '% chance)')
            end

        elseif consumptionType == 'consume' then
            -- Always consumed like an ingredient
            local consumeAmount = (tool.amount or 1) * successfulCrafts

            if useStaging then
                RemoveStagedTool(stationId, stagingKey, tool.item, consumeAmount)
            else
                Inventory.RemoveItem(source, tool.item, consumeAmount)
            end

            local toolLabel = Inventory.GetItemLabel(tool.item) or tool.item
            table.insert(results.toolsConsumed, {
                item = tool.item,
                label = toolLabel,
                amount = consumeAmount
            })

            debugPrint('Tool', tool.item, 'consumed x', consumeAmount)
        end
    end

    -- Broadcast staging update if tools were modified
    if useStaging and (#results.toolsBroken > 0 or #results.durabilityReduced > 0 or #results.toolsConsumed > 0) then
        BroadcastStagedItemsUpdate(stationId, nil)
    end

    return results
end

--- Remove item from staging
---@param stationId string Station identifier
---@param stagingKey string Player identifier or 'shared'
---@param itemName string Item name to remove
---@param count number Amount to remove
---@param sourceSlot number|nil Optional slot to remove from specifically
---@return boolean success Whether all items were removed
function RemoveFromStaging(stationId, stagingKey, itemName, count, sourceSlot)
    local items = GetStagedItemsForStation(stationId, stagingKey)

    if not items or #items == 0 then
        return false
    end

    if not StagedItems[stationId] then
        StagedItems[stationId] = {}
    end
    StagedItems[stationId][stagingKey] = items

    items = StagedItems[stationId][stagingKey]
    local remaining = count

    -- If sourceSlot is provided, only remove from that specific slot
    if sourceSlot then
        for i = #items, 1, -1 do
            if items[i].item == itemName and items[i].slot == sourceSlot and remaining > 0 then
                if items[i].count <= remaining then
                    remaining = remaining - items[i].count
                    table.remove(items, i)
                else
                    items[i].count = items[i].count - remaining
                    remaining = 0
                end
                break
            end
        end
    else
        -- Original behavior: remove from any matching slots
        for i = #items, 1, -1 do
            if items[i].item == itemName and remaining > 0 then
                if items[i].count <= remaining then
                    remaining = remaining - items[i].count
                    table.remove(items, i)
                else
                    items[i].count = items[i].count - remaining
                    remaining = 0
                end
            end
        end
    end

    SaveStagedItemsToDatabase(stationId, stagingKey)
    return remaining == 0
end

--- Broadcast staged items update to all players at a station (except the source player)
---@param stationId string Station identifier
---@param excludeSource number Player to exclude from broadcast
function BroadcastStagedItemsUpdate(stationId, excludeSource)
    if not IsPerWorkbenchEnabled(stationId) then
        return
    end

    local players = OpenStations[stationId]
    if not players then return end

    local stagingKey = 'shared'
    local items = GetStagedItemsForStation(stationId, stagingKey)
    local totalWeight = 0

    local result = {}
    for _, item in ipairs(items) do
        if item and item.count > 0 then
            local itemWeight = Inventory.GetItemWeight(item.item) or 0
            local stackWeight = itemWeight * item.count
            totalWeight = totalWeight + stackWeight

            table.insert(result, {
                item = item.item,
                label = item.label or Inventory.GetItemLabel(item.item) or item.item,
                count = item.count,
                slot = item.slot,
                weight = itemWeight,
                durability = item.durability
            })
        end
    end

    for playerSource, _ in pairs(players) do
        if playerSource ~= excludeSource then
            TriggerClientEvent('sd-crafting:client:syncStagedItems', playerSource, stationId, result, totalWeight)
        end
    end

    local count = 0
    for _ in pairs(players) do count = count + 1 end
    debugPrint('Broadcasted staged items update for station', stationId, 'to', count - 1, 'other players')
end

--- Register player as having a station open
---@param source number Player server ID
---@param stationId string Station identifier
RegisterNetEvent('sd-crafting:server:openStation', function(stationId)
    local source = source
    if not stationId then return end

    if not OpenStations[stationId] then
        OpenStations[stationId] = {}
    end
    OpenStations[stationId][source] = true

    Logger.Log('station_opened', source, {
        station = stationId,
        stationLabel = stationId
    })

    debugPrint('Player', source, 'opened station', stationId)
end)

--- Unregister player from having a station open
---@param source number Player server ID
---@param stationId string Station identifier
RegisterNetEvent('sd-crafting:server:closeStation', function(stationId)
    local source = source
    if not stationId then return end

    if OpenStations[stationId] then
        OpenStations[stationId][source] = nil
    end

    Logger.Log('station_closed', source, {
        station = stationId,
        stationLabel = stationId
    })

    debugPrint('Player', source, 'closed station', stationId)
end)

--- Register player as having a shop open
---@param source number Player server ID
---@param shopId string Shop identifier
RegisterNetEvent('sd-crafting:server:openShop', function(shopId)
    local source = source
    if not shopId then return end

    local isNear = IsPlayerNearShop(source, shopId)
    if not isNear then
        debugPrint('Security: Player', source, 'tried to open shop', shopId, 'but is too far')
        return
    end

    if not OpenShops[shopId] then
        OpenShops[shopId] = {}
    end
    OpenShops[shopId][source] = true

    debugPrint('Player', source, 'opened shop', shopId)
end)

--- Unregister player from having a shop open
---@param source number Player server ID
---@param shopId string Shop identifier
RegisterNetEvent('sd-crafting:server:closeShop', function(shopId)
    local source = source
    if not shopId then return end

    if OpenShops[shopId] then
        OpenShops[shopId][source] = nil
    end

    debugPrint('Player', source, 'closed shop', shopId)
end)

--- Get staged items for a station
---@param source number Player server ID
---@param stationId string Station identifier
---@return table items Array of staged items with item, label, count, slot, weight
---@return number totalWeight Total weight of staged items
lib.callback.register('sd-crafting:server:getStagedItems', function(source, stationId)
    local stagingKey = GetStagingKey(source, stationId)
    local items = GetStagedItemsForStation(stationId, stagingKey)

    local result = {}
    local totalWeight = 0

    for _, item in ipairs(items) do
        if item and item.count > 0 then
            local itemWeight = Inventory.GetItemWeight(item.item) or 0
            local stackWeight = itemWeight * item.count
            totalWeight = totalWeight + stackWeight

            table.insert(result, {
                item = item.item,
                label = item.label or Inventory.GetItemLabel(item.item) or item.item,
                count = item.count,
                slot = item.slot,  -- Include slot position for UI
                weight = itemWeight,  -- Weight per item
                durability = item.durability
            })
        end
    end

    return result, totalWeight
end)

--- Move staged item to a different slot
---@param source number Player server ID
---@param data table Data with stationId, sourceSlot, and newSlot
---@return boolean success Whether move was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:moveStagedSlot', function(source, data)
    local stationId = data.stationId
    local sourceSlot = data.sourceSlot
    local newSlot = data.newSlot

    if not stationId or sourceSlot == nil or newSlot == nil then
        return false, 'Invalid request'
    end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    local stagingKey = GetStagingKey(source, stationId)

    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false, 'No staged items found'
    end

    local items = StagedItems[stationId][stagingKey]

    -- Find item at source slot
    local sourceItem = nil
    local targetItem = nil
    for _, item in ipairs(items) do
        if item.slot == sourceSlot then
            sourceItem = item
        elseif item.slot == newSlot then
            targetItem = item
        end
    end

    if not sourceItem then
        return false, 'Item not found in source slot'
    end

    -- If target slot has an item, swap slots
    if targetItem then
        targetItem.slot = sourceSlot
    end

    sourceItem.slot = newSlot
    SaveStagedItemsToDatabase(stationId, stagingKey)

    debugPrint('Moved item from slot', sourceSlot, 'to slot', newSlot, 'at station', stationId)

    BroadcastStagedItemsUpdate(stationId, source)

    return true, 'Item moved successfully'
end)

--- Merge two staged stacks of the same item
---@param source number Player server ID
---@param data table Data with stationId, sourceSlot, and targetSlot
---@return boolean success Whether merge was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:mergeStagedStacks', function(source, data)
    local stationId = data.stationId
    local sourceSlot = data.sourceSlot
    local targetSlot = data.targetSlot

    if not stationId or sourceSlot == nil or targetSlot == nil then
        return false, 'Invalid request'
    end

    if sourceSlot == targetSlot then
        return true, 'Same slot'
    end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    local stagingKey = GetStagingKey(source, stationId)

    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false, 'No staged items found'
    end

    local items = StagedItems[stationId][stagingKey]

    -- Find items at both slots
    local sourceItem = nil
    local targetItem = nil
    local sourceIndex = nil
    for i, item in ipairs(items) do
        if item.slot == sourceSlot then
            sourceItem = item
            sourceIndex = i
        elseif item.slot == targetSlot then
            targetItem = item
        end
    end

    if not sourceItem then
        return false, 'Source item not found'
    end

    if not targetItem then
        return false, 'Target item not found'
    end

    -- Items must be the same type to merge
    if sourceItem.item ~= targetItem.item then
        return false, 'Cannot merge different item types'
    end

    -- Don't allow merging non-stackable items (like weapons)
    if not Inventory.IsItemStackable(sourceItem.item) then
        return false, 'item_not_stackable'
    end

    -- Don't merge items with different durabilities
    local sourceDur = sourceItem.durability
    local targetDur = targetItem.durability
    if (sourceDur == nil) ~= (targetDur == nil) or (sourceDur and targetDur and sourceDur ~= targetDur) then
        return false, 'Cannot merge items with different durability'
    end

    -- Merge: add source count to target (durability is same or both nil)
    targetItem.count = targetItem.count + sourceItem.count

    -- Remove source item
    table.remove(items, sourceIndex)

    SaveStagedItemsToDatabase(stationId, stagingKey)

    debugPrint('Merged stacks from slot', sourceSlot, 'to slot', targetSlot, 'at station', stationId)

    BroadcastStagedItemsUpdate(stationId, source)

    return true, 'Stacks merged successfully'
end)

--- Split a staged stack into two stacks
---@param source number Player server ID
---@param data table Data with stationId, sourceSlot, targetSlot, and amount
---@return boolean success Whether split was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:splitStagedStack', function(source, data)
    local stationId = data.stationId
    local sourceSlot = data.sourceSlot
    local targetSlot = data.targetSlot
    local amount = data.amount

    if not stationId or sourceSlot == nil or targetSlot == nil or not amount then
        return false, 'Invalid request'
    end

    if sourceSlot == targetSlot then
        return true, 'Same slot'
    end

    if amount <= 0 then
        return false, 'Invalid amount'
    end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    local stagingKey = GetStagingKey(source, stationId)

    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false, 'No staged items found'
    end

    local items = StagedItems[stationId][stagingKey]
    local maxSlots = Config.InventoryPanel and Config.InventoryPanel.maxSlots or 20

    -- Find source item and target slot occupant
    local sourceItem = nil
    local targetItem = nil
    for _, item in ipairs(items) do
        if item.slot == sourceSlot then
            sourceItem = item
        elseif item.slot == targetSlot then
            targetItem = item
        end
    end

    if not sourceItem then
        return false, 'Source item not found'
    end

    if amount >= sourceItem.count then
        return false, 'Cannot split entire stack'
    end

    -- If target slot has an item, it must be the same type to merge
    if targetItem then
        if targetItem.item ~= sourceItem.item then
            return false, 'Cannot split onto different item type'
        end
        -- Don't merge items with different durabilities
        local sourceDur = sourceItem.durability
        local targetDur = targetItem.durability
        if (sourceDur == nil) ~= (targetDur == nil) or (sourceDur and targetDur and sourceDur ~= targetDur) then
            return false, 'Cannot merge items with different durability'
        end
        -- Merge partial amount into target stack
        targetItem.count = targetItem.count + amount
        sourceItem.count = sourceItem.count - amount
    else
        -- Check if we have room for a new stack
        if GetStagedSlotCount(stationId, stagingKey) >= maxSlots then
            return false, 'Crafting inventory is full'
        end
        -- Create new stack at target slot
        local newItem = {
            item = sourceItem.item,
            label = sourceItem.label,
            count = amount,
            slot = targetSlot,
            durability = sourceItem.durability
        }
        table.insert(items, newItem)
        sourceItem.count = sourceItem.count - amount
    end

    SaveStagedItemsToDatabase(stationId, stagingKey)

    debugPrint('Split stack from slot', sourceSlot, 'to slot', targetSlot, 'amount', amount, 'at station', stationId)

    BroadcastStagedItemsUpdate(stationId, source)

    return true, 'Stack split successfully'
end)

--- Stage item callback (move from player inventory to staging)
---@param source number Player server ID
---@param data table Data with stationId, item, count, optional slot (target), and optional sourceSlot (player inventory)
---@return boolean success Whether staging was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:stageItem', function(source, data)
    local stationId = data.stationId
    local itemName = data.item
    local count = data.count or 1
    local targetSlot = data.slot
    local sourceSlot = data.sourceSlot -- Slot in player inventory to take item from

    if not stationId or not itemName then return false, 'Invalid request' end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    if not Config.InventoryPanel or not Config.InventoryPanel.enabled then
        return false, 'Staging is not enabled'
    end

    local stagingKey = GetStagingKey(source, stationId)

    local playerCount = Inventory.GetItemCount(source, itemName)
    if playerCount < count then
        return false, 'You do not have enough of this item'
    end

    local maxWeight = Config.InventoryPanel.maxWeight or 0
    if maxWeight > 0 then
        local currentWeight = 0
        local stagedItems = GetStagedItemsForStation(stationId, stagingKey)
        for _, item in ipairs(stagedItems) do
            if item and item.count > 0 then
                local itemWeight = Inventory.GetItemWeight(item.item) or 0
                currentWeight = currentWeight + (itemWeight * item.count)
            end
        end

        local addingWeight = (Inventory.GetItemWeight(itemName) or 0) * count
        local newTotalWeight = currentWeight + addingWeight

        if newTotalWeight > maxWeight then
            return false, 'staging_full', count
        end
    end

    local itemLabel = Inventory.GetItemLabel(itemName) or itemName
    local isBlueprint = IsBlueprint(itemName)

    -- Blueprints can only be moved one at a time (no stacking in staging)
    if isBlueprint and count > 1 then
        count = 1
    end

    -- Capture durability and metadata from the item before removing
    local durability = nil
    local itemMetadata = nil
    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability

    -- Try to get item with metadata from ox_inventory
    if Inventory.IsOxInventory() then
        local items = Inventory.GetItemsWithMetadata(source, itemName)

        -- If sourceSlot is specified, find that specific item
        local targetItem = nil
        if sourceSlot and items then
            for _, item in ipairs(items) do
                if item.slot == sourceSlot then
                    targetItem = item
                    break
                end
            end
        elseif items and items[1] then
            targetItem = items[1]
        end

        if targetItem then
            local metadata = targetItem.metadata or {}

            -- Capture durability for all items that have it (not just blueprints)
            if metadata.durability then
                durability = metadata.durability
            elseif isBlueprint and durabilityConfig and durabilityConfig.enabled then
                -- Default durability for blueprints without existing durability
                durability = durabilityConfig.defaultDurability or 100
            end

            -- Capture full metadata if it has any meaningful content (not just empty or only durability for blueprints)
            local hasNonDurabilityMetadata = false
            for k, v in pairs(metadata) do
                if k ~= 'durability' or not isBlueprint then
                    hasNonDurabilityMetadata = true
                    break
                end
            end
            if hasNonDurabilityMetadata or (not isBlueprint and next(metadata)) then
                itemMetadata = metadata
            end

            -- Remove from specific slot to preserve correct item
            local removed = Inventory.RemoveItemFromSlot(source, itemName, count, targetItem.slot)
            if not removed then
                return false, 'Failed to remove item from inventory'
            end
        else
            -- No item found with metadata, use defaults
            if isBlueprint and durabilityConfig and durabilityConfig.enabled then
                durability = durabilityConfig.defaultDurability or 100
            end
            local removed = Inventory.RemoveItem(source, itemName, count)
            if not removed then
                return false, 'Failed to remove item from inventory'
            end
        end
    else
        -- Non-ox inventory - If sourceSlot is provided, remove from specific slot
        local removed
        if sourceSlot and Inventory.SupportsSlots() then
            removed = Inventory.RemoveItemFromSlotAll(source, itemName, count, sourceSlot)
        else
            removed = Inventory.RemoveItem(source, itemName, count)
        end
        if not removed then
            return false, 'Failed to remove item from inventory'
        end
    end

    local success, err = AddToStaging(stationId, stagingKey, itemName, itemLabel, count, targetSlot, durability, itemMetadata)
    if not success then
        -- Refund the item with original metadata
        if itemMetadata and Inventory.IsOxInventory() then
            -- Refund with full metadata (includes durability if present)
            Inventory.AddItemWithMetadata(source, itemName, count, itemMetadata)
        elseif isBlueprint and durability and durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() then
            -- Blueprint without other metadata, just restore durability
            Inventory.AddItemWithMetadata(source, itemName, count, { durability = durability })
        else
            Inventory.AddItem(source, itemName, count)
        end
        return false, err or 'Failed to add item to crafting inventory'
    end

    local durabilityStr = durability and (' (durability: ' .. durability .. ')') or ''
    debugPrint('Player', source, 'staged', count, 'x', itemName, 'at station', stationId, 'slot', targetSlot or 'auto', durabilityStr)

    BroadcastStagedItemsUpdate(stationId, source)

    return true, 'Item added to crafting inventory'
end)

--- Unstage item callback (move from staging back to player inventory)
---@param source number Player server ID
---@param data table Data with stationId, item, count, and optional sourceSlot
---@return boolean success Whether unstaging was successful
---@return string message Success or error message
lib.callback.register('sd-crafting:server:unstageItem', function(source, data)
    local stationId = data.stationId
    local itemName = data.item
    local count = data.count or 1
    local sourceSlot = data.sourceSlot

    if not stationId or not itemName then return false, 'Invalid request' end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    -- Check if item is a blueprint that's in use by the crafting queue
    if IsBlueprint(itemName) then
        local inQueue, craftingItem = IsBlueprintInQueue(stationId, itemName)
        if inQueue then
            return false, 'blueprint_in_queue', craftingItem
        end
    end

    local stagingKey = GetStagingKey(source, stationId)

    -- If sourceSlot is provided, check count in that specific slot
    local stagedCount
    if sourceSlot then
        local items = GetStagedItemsForStation(stationId, stagingKey)
        for _, item in ipairs(items or {}) do
            if item.item == itemName and item.slot == sourceSlot then
                stagedCount = item.count
                break
            end
        end
        stagedCount = stagedCount or 0
    else
        stagedCount = GetStagedItemCount(stationId, stagingKey, itemName)
    end

    if stagedCount < count then
        count = stagedCount
    end

    if count <= 0 then
        return false, 'Item not found in crafting inventory'
    end

    -- Check if player can carry the item
    if not Inventory.CanCarryItem(source, itemName, count) then
        return false, 'inventory_full', count
    end

    -- Get metadata and durability from staged item to restore it
    local added = false
    local stagedMetadata = nil
    local stagedDurability = nil

    -- Get the staged item to retrieve its metadata and durability
    local items = GetStagedItemsForStation(stationId, stagingKey)
    for _, item in ipairs(items or {}) do
        if item.item == itemName and (not sourceSlot or item.slot == sourceSlot) then
            stagedMetadata = item.metadata
            stagedDurability = item.durability
            break
        end
    end

    -- Build final metadata (merge durability if present)
    local finalMetadata = nil
    if stagedMetadata or stagedDurability then
        if stagedMetadata and stagedDurability then
            -- Both metadata and durability - merge them
            finalMetadata = {}
            for k, v in pairs(stagedMetadata) do
                finalMetadata[k] = v
            end
            finalMetadata.durability = stagedDurability
        elseif stagedDurability then
            -- Only durability
            finalMetadata = { durability = stagedDurability }
        else
            -- Only metadata
            finalMetadata = stagedMetadata
        end
    end

    if finalMetadata and Inventory.IsOxInventory() then
        added = Inventory.AddItemWithMetadata(source, itemName, count, finalMetadata)
    else
        added = Inventory.AddItem(source, itemName, count)
    end

    if not added then
        return false, 'Failed to add item to inventory'
    end

    RemoveFromStaging(stationId, stagingKey, itemName, count, sourceSlot)

    debugPrint('Player', source, 'unstaged', count, 'x', itemName, 'from station', stationId, 'slot', sourceSlot or 'any')

    BroadcastStagedItemsUpdate(stationId, source)

    return true, 'Item returned to inventory'
end)

--- Initialize durability on blueprints in player inventory that don't have it yet
--- Called when crafting UI opens to ensure all blueprints show durability bar
---@param source number Player server ID
---@return number count Number of blueprints initialized
lib.callback.register('sd-crafting:server:initBlueprintDurability', function(source)
    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability
    if not durabilityConfig or not durabilityConfig.enabled then
        return 0
    end

    if not Inventory.IsOxInventory() then
        return 0
    end

    local defaultDurability = durabilityConfig.defaultDurability or 100
    local items = Inventory.GetItemsWithMetadata(source)
    if not items then return 0 end

    local count = 0
    for _, item in ipairs(items) do
        if item.name and IsBlueprint(item.name) then
            local metadata = item.metadata or {}
            -- Check if durability is missing or nil
            if metadata.durability == nil then
                -- Add default durability to this blueprint
                metadata.durability = defaultDurability
                local success = Inventory.SetSlotMetadata(source, item.slot, metadata)
                if success then
                    count = count + 1
                    debugPrint('Initialized durability for blueprint', item.name, 'in slot', item.slot, 'for player', source)
                end
            end
        end
    end

    return count
end)

--- Move item from staging inventory to player inventory at a specific slot
---@param source number Player server ID
---@param data table Data with itemName, count, stationId, targetSlot
---@return boolean success Whether the move succeeded
---@return string|nil message Error message if failed
lib.callback.register('sd-crafting:server:moveToInventorySlot', function(source, data)
    local itemName = data.itemName
    local count = data.count or 1
    local stationId = data.stationId
    local targetSlot = data.targetSlot
    local sourceSlot = data.sourceSlot

    if not itemName or not stationId then
        return false, 'Invalid request'
    end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    -- Check if item is a blueprint that's in use by the crafting queue
    if IsBlueprint(itemName) then
        local inQueue, craftingItem = IsBlueprintInQueue(stationId, itemName)
        if inQueue then
            return false, 'blueprint_in_queue', craftingItem
        end
    end

    local stagingKey = GetStagingKey(source, stationId)

    -- Check if item exists in staging
    if not StagedItems[stationId] or not StagedItems[stationId][stagingKey] then
        return false, 'No staged items found'
    end

    local stagedItem = nil
    local stagedIndex = nil
    for i, item in ipairs(StagedItems[stationId][stagingKey]) do
        if item.item == itemName and (not sourceSlot or item.slot == sourceSlot) then
            stagedItem = item
            stagedIndex = i
            break
        end
    end

    if not stagedItem then
        return false, 'Item not found in staging'
    end

    local actualCount = math.min(count, stagedItem.count)

    -- Check if player can carry the item
    if not Inventory.CanCarryItem(source, itemName, actualCount) then
        return false, 'inventory_full', actualCount
    end

    -- Build metadata for the item (include durability for blueprints)
    local itemMetadata = stagedItem.metadata
    if stagedItem.durability then
        -- Blueprint has durability - merge it into metadata
        if itemMetadata then
            itemMetadata = {}
            for k, v in pairs(stagedItem.metadata) do
                itemMetadata[k] = v
            end
            itemMetadata.durability = stagedItem.durability
        else
            itemMetadata = { durability = stagedItem.durability }
        end
    end

    -- Add item to player inventory at specific slot
    local success = Inventory.AddItemToSlot(source, itemName, actualCount, targetSlot, itemMetadata)
    if not success then
        return false, 'Failed to add item to inventory'
    end

    -- Remove from staging
    if actualCount >= stagedItem.count then
        table.remove(StagedItems[stationId][stagingKey], stagedIndex)
    else
        stagedItem.count = stagedItem.count - actualCount
    end

    -- Save staging to database
    SaveStagedItemsToDatabase(stationId, stagingKey)

    debugPrint(('Moved %dx %s from staging to inventory slot %s'):format(actualCount, itemName, targetSlot or 'auto'))

    BroadcastStagedItemsUpdate(stationId, source)

    return true
end)

--- Return all staged items to player (when closing UI if configured)
---@param source number Player server ID
---@param stationId string Station identifier
---@return boolean success Whether operation succeeded
lib.callback.register('sd-crafting:server:returnAllStagedItems', function(source, stationId)
    if not Config.InventoryPanel or not Config.InventoryPanel.returnOnClose then
        return true -- Nothing to do
    end

    if not stationId then return false end

    local isNear = IsPlayerNearStation(source, stationId)
    if not isNear then
        debugPrint('Security: Player', source, 'tried to return staged items but is too far from station', stationId)
        return false
    end

    local stagingKey = GetStagingKey(source, stationId)
    local items = GetStagedItemsForStation(stationId, stagingKey)
    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability

    for _, item in ipairs(items) do
        if item and item.count > 0 then
            -- For blueprints with durability, add with metadata
            local isBlueprint = item.item and IsBlueprint(item.item)
            if isBlueprint and durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() and item.durability then
                Inventory.AddItemWithMetadata(source, item.item, item.count, { durability = item.durability })
            else
                Inventory.AddItem(source, item.item, item.count)
            end
        end
    end

    if StagedItems[stationId] then
        StagedItems[stationId][stagingKey] = {}
        SaveStagedItemsToDatabase(stationId, stagingKey)
    end

    return true
end)

--- Get crafting inventory config for NUI
---@param source number Player server ID
---@param stationId string Station identifier
---@return table config Crafting inventory configuration
lib.callback.register('sd-crafting:server:getCraftingInventoryConfig', function(source, stationId)
    return {
        enabled = Config.InventoryPanel and Config.InventoryPanel.enabled or false,
        perWorkbench = IsPerWorkbenchEnabled(stationId),
        maxSlots = Config.InventoryPanel and Config.InventoryPanel.maxSlots or 20,
        maxWeight = Config.InventoryPanel and Config.InventoryPanel.maxWeight or 0,
        returnOnClose = Config.InventoryPanel and Config.InventoryPanel.returnOnClose or false
    }
end)

--- Get weight of staged items for a station
---@param source number Player server ID
---@param stationId string Station identifier
---@return number totalWeight Total weight of staged items
lib.callback.register('sd-crafting:server:getStagedWeight', function(source, stationId)
    local stagingKey = GetStagingKey(source, stationId)
    local items = GetStagedItemsForStation(stationId, stagingKey)

    local totalWeight = 0
    for _, item in ipairs(items) do
        if item and item.count > 0 then
            local itemWeight = Inventory.GetItemWeight(item.item) or 0
            totalWeight = totalWeight + (itemWeight * item.count)
        end
    end

    return totalWeight
end)

--- Get total weight of multiple items (by name and count)
---@param source number Player server ID
---@param items table Array of items with name and count
---@return number weight Total weight of all items
lib.callback.register('sd-crafting:server:getItemsWeight', function(source, items)
    if not items or type(items) ~= 'table' then return 0 end
    return Inventory.GetMultipleItemsWeight(items)
end)

--- Get weight of a single item type
---@param source number Player server ID
---@param itemName string Item name
---@return number weight Weight of the item
lib.callback.register('sd-crafting:server:getItemWeight', function(source, itemName)
    if not itemName then return 0 end
    return Inventory.GetItemWeight(itemName)
end)

--- Check if player can craft a recipe (including blueprint and level check)
---@param source number Player server ID
---@param data table Data with recipeId, quantity, stationId, and workbenchType
---@return boolean canCraft Whether player can craft
---@return string|nil message Error message if cannot craft
lib.callback.register('sd-crafting:server:canCraft', function(source, data)
    local recipeId = data.recipeId
    local quantity = data.quantity or 1
    local stationId = data.stationId
    local workbenchType = data.workbenchType

    if not stationId then return false, 'Invalid request' end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false, accessError
    end

    local recipe = GetRecipeById(recipeId)
    if not recipe then return false end

    if recipe.levelRequired and Config.Leveling and Config.Leveling.enabled then
        local playerData = LoadPlayerLevel(source, workbenchType)
        if playerData.level < recipe.levelRequired then
            local levelMsg = 'Level ' .. recipe.levelRequired .. ' required'
            if Config.Leveling.perWorkbenchType and workbenchType then
                levelMsg = levelMsg .. ' (for ' .. workbenchType .. ' workbench)'
            end
            return false, levelMsg
        end
    end

    if recipe.blueprint and Config.Blueprints and Config.Blueprints.enabled then
        if not IsBlueprintAttached(stationId, recipe.blueprint, source) then
            return false, 'Blueprint not attached to this station'
        end
    end

    if not CanCraftWithTechTree(source, recipeId, stationId, workbenchType) then
        return false, 'Recipe locked - unlock in Tech Tree first'
    end

    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    local stagingKey = useStaging and GetStagingKey(source, stationId) or nil

    for _, ingredient in ipairs(recipe.ingredients) do
        local requiredAmount = ingredient.amount * quantity
        local availableCount

        if useStaging then
            availableCount = GetStagedItemCount(stationId, stagingKey, ingredient.item)
        else
            availableCount = Inventory.GetItemCount(source, ingredient.item)
        end

        if availableCount < requiredAmount then
            local itemLabel = ingredient.label or Inventory.GetItemLabel(ingredient.item) or ingredient.item
            return false, 'Missing ' .. itemLabel .. ' (' .. availableCount .. '/' .. requiredAmount .. ')'
        end
    end

    -- Validate required tools
    local toolsValid, toolError = ValidateRequiredTools(source, recipe, stationId, quantity)
    if not toolsValid then
        return false, toolError
    end

    if recipe.cost and recipe.cost > 0 then
        local totalCost = recipe.cost * quantity
        local playerCash = Money.GetPlayerAccountFunds(source, 'cash')
        if playerCash < totalCost then
            return false, 'Not enough cash ($' .. playerCash .. '/$' .. totalCost .. ')'
        end
    end

    return true
end)

--- Remove items for crafting (from staging or inventory)
---@param source number Player server ID
---@param data table Data with recipeId, quantity, and stationId
---@return boolean success Whether items were removed
---@return string|nil craftToken Unique token to validate craft completion/refund
lib.callback.register('sd-crafting:server:removeItems', function(source, data)
    local recipeId = data.recipeId
    local quantity = data.quantity or 1
    local stationId = data.stationId

    if not stationId then return false end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false
    end

    local recipe = GetRecipeById(recipeId)
    if not recipe then return false end

    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    local stagingKey = useStaging and GetStagingKey(source, stationId) or nil

    for _, ingredient in ipairs(recipe.ingredients) do
        local requiredAmount = ingredient.amount * quantity
        local success

        if useStaging and stationId then
            success = RemoveFromStaging(stationId, stagingKey, ingredient.item, requiredAmount)
        else
            success = Inventory.RemoveItem(source, ingredient.item, requiredAmount)
        end

        if not success then
            return false
        end
    end

    if recipe.cost and recipe.cost > 0 then
        local totalCost = recipe.cost * quantity
        Money.RemoveMoney(source, 'cash', totalCost)
        debugPrint('Removed $' .. totalCost .. ' from player', source, 'for recipe:', recipeId)
    end

    -- Format ingredients for logging
    local materialsTaken = {}
    for _, ing in ipairs(recipe.ingredients or {}) do
        local ingLabel = ing.label or Inventory.GetItemLabel(ing.item) or ing.item
        table.insert(materialsTaken, (ing.amount * quantity) .. 'x ' .. ingLabel)
    end

    Logger.Log('craft_started', source, {
        station = stationId,
        stationLabel = stationId,
        recipe = recipeId,
        recipeLabel = recipe.name or recipeId,
        quantity = quantity,
        outputAmount = recipe.outputAmount or 1,
        materials = table.concat(materialsTaken, ', ')
    })

    local location = useStaging and 'staging at ' .. (stationId or 'unknown') or 'inventory'
    debugPrint('Removed items for recipe:', recipeId, 'x', quantity, 'from', location)

    if useStaging and stationId then
        BroadcastStagedItemsUpdate(stationId, source)
    end

    -- Generate a one-time-use craft token bound to this player and recipe
    local craftToken = GenerateCraftToken()
    local identifier = GetIdentifier(source)
    local craftTime = recipe.craftTime and (recipe.craftTime * quantity) or 0
    RegisterCraftToken(craftToken, identifier, recipeId, quantity, stationId, craftTime)
    debugPrint('removeItems: Generated craftToken:', craftToken, 'craftTime:', craftTime, 'for recipe:', recipeId, 'x', quantity)

    return true, craftToken
end)

--- Refund items (when cancelling from queue)
---@param source number Player server ID
---@param data table Data with recipeId, quantity, stationId, and craftToken
---@return boolean success Whether items were refunded
lib.callback.register('sd-crafting:server:refundItems', function(source, data)
    local recipeId = data.recipeId
    local quantity = data.quantity or 1
    local stationId = data.stationId

    if not stationId then return false end

    -- Validate and consume craft token to prevent double refunds and refund+complete exploits
    local identifier = GetIdentifier(source)
    debugPrint('refundItems: Refunding recipe:', data.recipeId, 'quantity:', data.quantity, 'craftToken:', data.craftToken, 'stationId:', data.stationId)
    local stationBehavior = GetEffectiveCraftingBehavior(stationId)
    local isSharedCrafting = stationBehavior and stationBehavior.sharedCrafting
    local tokenValid, tokenError = ValidateAndConsumeCraftToken(data.craftToken, identifier, recipeId, false, isSharedCrafting)
    if not tokenValid then
        print('[SD-CRAFTING] SECURITY: refundItems rejected for player', source, '(' .. (identifier or 'unknown') .. '):', tokenError)
        return false
    end

    local hasAccess, accessError = ValidateStationAccess(source, stationId)
    if not hasAccess then
        return false
    end

    local recipe = GetRecipeById(recipeId)
    if not recipe then return false end

    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    local stagingKey = useStaging and GetStagingKey(source, stationId) or nil

    for _, ingredient in ipairs(recipe.ingredients) do
        local refundAmount = ingredient.amount * quantity
        local itemLabel = ingredient.label or Inventory.GetItemLabel(ingredient.item) or ingredient.item

        if useStaging and stationId then
            AddToStaging(stationId, stagingKey, ingredient.item, itemLabel, refundAmount)
        else
            Inventory.AddItem(source, ingredient.item, refundAmount)
        end
    end

    if recipe.cost and recipe.cost > 0 then
        local totalCost = recipe.cost * quantity
        Money.AddMoney(source, 'cash', totalCost)
        debugPrint('Refunded $' .. totalCost .. ' to player', source, 'for recipe:', recipeId)
    end

    -- Format ingredients for logging
    local materialsRefunded = {}
    for _, ing in ipairs(recipe.ingredients or {}) do
        local ingLabel = ing.label or Inventory.GetItemLabel(ing.item) or ing.item
        table.insert(materialsRefunded, (ing.amount * quantity) .. 'x ' .. ingLabel)
    end

    Logger.Log('craft_cancelled', source, {
        station = stationId,
        stationLabel = stationId,
        recipe = recipeId,
        recipeLabel = recipe.name or recipeId,
        quantity = quantity,
        outputAmount = recipe.outputAmount or 1,
        materials = table.concat(materialsRefunded, ', ')
    })

    local location = useStaging and 'staging at ' .. (stationId or 'unknown') or 'inventory'
    debugPrint('Refunded items for recipe:', recipeId, 'x', quantity, 'to', location)

    if useStaging and stationId then
        BroadcastStagedItemsUpdate(stationId, source)
    end

    return true
end)

--- Complete crafting - give the crafted item and handle blueprint destruction
---@param source number Player server ID
---@param data table Data with recipeId, quantity, stationId, workbenchType, and craftToken
---@return boolean success Whether crafting completed
---@return table|nil resultData Data with levelData, techPointsData, blueprintDestroyed
lib.callback.register('sd-crafting:server:completeCraft', function(source, data)
    local recipeId = data.recipeId
    local quantity = data.quantity or 1
    local stationId = data.stationId
    local workbenchType = data.workbenchType

    -- Fallback: get workbench type from station if not provided
    if not workbenchType and stationId then
        local placedId = stationId:match('^placed_(%d+)$')
        if placedId then
            local numericId = tonumber(placedId)
            if numericId and PlacedWorkbenches[numericId] then
                workbenchType = PlacedWorkbenches[numericId].type
            end
        else
            local station = GetStationConfig(stationId)
            if station then
                workbenchType = station.type
            end
        end
    end

    if not stationId then
        debugPrint('completeCraft: ERROR - stationId is nil')
        return false
    end

    -- Validate craft token first (without consuming) to prevent completion without ingredient removal
    -- Token is consumed later only after all checks pass, so refunds remain possible on failure
    local identifier = GetIdentifier(source)
    debugPrint('completeCraft: Received request - source:', source, 'identifier:', identifier, 'recipeId:', data.recipeId, 'craftToken:', data.craftToken)
    local stationBehavior = GetEffectiveCraftingBehavior(stationId)
    local isSharedCrafting = stationBehavior and stationBehavior.sharedCrafting
    local tokenValid, tokenError = ValidateCraftToken(data.craftToken, identifier, recipeId, true, isSharedCrafting)
    if not tokenValid then
        print('[SD-CRAFTING] SECURITY: completeCraft rejected for player', source, '(' .. (identifier or 'unknown') .. '):', tokenError)
        return false
    end

    -- Skip access validation when UI is closed - the validated craft token already proves
    -- ingredients were legitimately removed at a valid station. This covers all background
    -- crafting modes (allowCraftingAnywhere, allowCraftingNearby, cancelCraftOnClose=false)
    local isUiOpen = data.isUiOpen
    local anywhereConfig = stationBehavior and stationBehavior.allowCraftingAnywhere
    if isUiOpen then
        local hasAccess, accessError = ValidateStationAccess(source, stationId)
        if not hasAccess then
            return false
        end
    end

    local recipe = GetRecipeById(recipeId)
    if not recipe then
        debugPrint('completeCraft: ERROR - Recipe not found:', data.recipeId)
        return false
    end

    -- Validate blueprint durability before crafting
    if recipe.blueprint and Config.Blueprints and Config.Blueprints.enabled then
        local durabilityConfig = Config.Blueprints.durability
        if durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() then
            local stagingKey = GetStagingKey(source, stationId)
            local durabilityLoss = recipe.blueprintDurabilityLoss or durabilityConfig.defaultLoss or 10
            local totalDurabilityNeeded = durabilityLoss * quantity

            -- Check staged blueprint first
            local isInStaging = IsBlueprintInStaging(stationId, stagingKey, recipe.blueprint)
            if isInStaging then
                local stagedDurability = GetStagedBlueprintDurability(stationId, stagingKey, recipe.blueprint)
                local currentDurability = stagedDurability or durabilityConfig.defaultDurability or 100
                local maxCrafts = math.floor(currentDurability / durabilityLoss)

                if quantity > maxCrafts then
                    return false, { error = 'blueprint_durability', maxCrafts = maxCrafts, currentDurability = currentDurability }
                end
            elseif StationBlueprints[stationId] and StationBlueprints[stationId][recipe.blueprint] then
                -- Check attached blueprint
                local blueprintData = StationBlueprints[stationId][recipe.blueprint]
                local currentDurability = 100

                if type(blueprintData) == 'table' and blueprintData.durability then
                    currentDurability = blueprintData.durability
                elseif blueprintData == true then
                    currentDurability = durabilityConfig.defaultDurability or 100
                end

                local maxCrafts = math.floor(currentDurability / durabilityLoss)

                if quantity > maxCrafts then
                    return false, { error = 'blueprint_durability', maxCrafts = maxCrafts, currentDurability = currentDurability }
                end
            end
        end
    end

    -- All validations passed - consume the craft token now (one-time use)
    -- This is done after all checks so the token remains available for refund if a check fails
    -- Capture pending data before consumption (ConsumeCraftToken deletes it)
    local pendingData = PendingCrafts[data.craftToken]
    debugPrint('completeCraft: pendingData:', pendingData and ('craftTime=' .. (pendingData.craftTime or 'nil') .. ' startedAt=' .. (pendingData.startedAt or 'nil')) or 'NIL')
    ConsumeCraftToken(data.craftToken, identifier)

    -- Enforce minimum craft time since last completion (prevents queue speed exploit)
    -- Uses per-station per-player keys so parallel crafting on different stations isn't blocked
    local isRestoredToken = pendingData and pendingData.startedAt == 0
    local completionKey = identifier .. ':' .. stationId
    debugPrint('completeCraft: isRestoredToken:', isRestoredToken, 'lastCompletion:', CraftCompletionTimestamps[completionKey] or 'none')
    if not isRestoredToken then
        local lastCompletion = CraftCompletionTimestamps[completionKey]
        if lastCompletion then
            local sinceLastCompletion = os.time() - lastCompletion
            local minCraftTime = (pendingData and pendingData.craftTime or 0) - 3 -- 3s tolerance for latency
            if minCraftTime > 0 and sinceLastCompletion < minCraftTime then
                local waitTime = minCraftTime - sinceLastCompletion
                debugPrint('Enforcing server-side craft time: waiting', waitTime, 'seconds for player', source)
                Wait(waitTime * 1000)
            end
        end
    end

    -- Calculate actual output amount (outputAmount defaults to 1 if not specified)
    local outputAmount = recipe.outputAmount or 1
    local successfulCrafts = quantity
    local failedCrafts = 0

    -- Check fail chance - if recipe has a failChance, roll to see if crafting fails
    local failChance = recipe.failChance or 0
    if failChance > 0 then
        local treatAsWhole = Config.FailChance and Config.FailChance.treatQuantityAsWhole
        if treatAsWhole == nil then treatAsWhole = true end -- Default to true if not configured

        if treatAsWhole then
            -- One roll for the entire batch - all succeed or all fail
            local roll = math.random(1, 100)
            if roll <= failChance then
                -- Crafting failed - materials are already consumed, no items given
                Logger.Log('craft_failed', source, {
                    station = stationId,
                    stationLabel = stationId,
                    recipe = recipeId,
                    recipeLabel = recipe.name or recipeId,
                    quantity = quantity,
                    reason = 'Failed quality check (whole batch) - ' .. failChance .. '% chance'
                })
                debugPrint('Crafting failed (whole batch) for recipe:', recipeId, '- rolled', roll, 'vs fail chance', failChance)
                return true, { failed = true, failedCrafts = quantity, successfulCrafts = 0, failChance = failChance }
            end
        else
            -- Roll for each item individually - some may succeed, some may fail
            successfulCrafts = 0
            failedCrafts = 0
            for i = 1, quantity do
                local roll = math.random(1, 100)
                if roll <= failChance then
                    failedCrafts = failedCrafts + 1
                else
                    successfulCrafts = successfulCrafts + 1
                end
            end

            debugPrint('Crafting results (per-item) for recipe:', recipeId, '- successful:', successfulCrafts, 'failed:', failedCrafts)

            -- If all failed, return early
            if successfulCrafts == 0 then
                Logger.Log('craft_failed', source, {
                    station = stationId,
                    stationLabel = stationId,
                    recipe = recipeId,
                    recipeLabel = recipe.name or recipeId,
                    quantity = quantity,
                    reason = 'Failed quality check (all ' .. failedCrafts .. ' items failed) - ' .. failChance .. '% chance per item'
                })
                return true, { failed = true, failedCrafts = failedCrafts, successfulCrafts = 0, failChance = failChance }
            end
        end
    end

    local success = false
    local addedToStash = false
    local totalOutputCount = successfulCrafts * outputAmount

    -- Check if we should add to crafting stash instead of player inventory
    -- If allowCraftingAnywhere is enabled and UI is closed, force stash output (player may not be near workbench)
    -- If UI is open, follow the normal AddOutputToStash config setting
    local forceStashForAnywhere = anywhereConfig and anywhereConfig.enabled and not isUiOpen
    local shouldAddToStash = Config.AddOutputToStash or forceStashForAnywhere
    if shouldAddToStash and stationId then
        local stagingKey = GetStagingKey(source, stationId)
        local itemLabel = Inventory.GetItemLabel(recipe.name) or recipe.name
        success = AddToStaging(stationId, stagingKey, recipe.name, itemLabel, totalOutputCount, nil, nil, recipe.metadata)
        if success then
            addedToStash = true
            -- Broadcast the staged items update so the UI reflects the change
            BroadcastStagedItemsUpdate(stationId, source)
        end
    end

    -- Fall back to player inventory if stash failed or not enabled
    if not success then
        if recipe.metadata then
            success = Inventory.AddItemWithMetadata(source, recipe.name, totalOutputCount, recipe.metadata)
        else
            success = Inventory.AddItem(source, recipe.name, totalOutputCount)
        end
    end

    if success then
        if addedToStash then
            debugPrint('Added', totalOutputCount, 'x', recipe.name, 'to crafting stash for player:', source)
        else
            debugPrint('Gave', totalOutputCount, 'x', recipe.name, 'to player:', source)
        end

        -- Format ingredients for logging
        local materialsUsed = {}
        for _, ing in ipairs(recipe.ingredients or {}) do
            local ingLabel = ing.label or Inventory.GetItemLabel(ing.item) or ing.item
            table.insert(materialsUsed, (ing.amount * successfulCrafts) .. 'x ' .. ingLabel)
        end

        Logger.Log('craft_completed', source, {
            station = stationId,
            stationLabel = stationId,
            recipe = recipeId,
            recipeLabel = recipe.name or recipeId,
            quantity = successfulCrafts,
            outputAmount = outputAmount,
            itemList = totalOutputCount .. 'x ' .. (recipe.name or recipeId),
            materials = table.concat(materialsUsed, ', ')
        })

        SaveCraftingHistory(stationId, GetIdentifier(source), GetPlayerFullName(source), recipeId, recipe.label or recipe.name or recipeId, successfulCrafts, recipe.name, recipe.label or recipe.name, outputAmount, recipe.ingredients)

        local resultData = { blueprintDestroyed = false }

        -- Include partial failure info if some crafts failed
        if failedCrafts > 0 then
            resultData.partialFailure = true
            resultData.failedCrafts = failedCrafts
            resultData.successfulCrafts = successfulCrafts
        end

        -- Award XP only for successful crafts
        if Config.Leveling and Config.Leveling.enabled then
            local xpAmount = 0
            if recipe.xpReward then
                xpAmount = recipe.xpReward * successfulCrafts
            elseif Config.Leveling.defaultXpReward then
                local defaultXp = Config.Leveling.defaultXpReward
                if type(defaultXp) == 'table' then
                    if defaultXp.enabled then
                        xpAmount = (defaultXp.amount or 10) * successfulCrafts
                    end
                else
                    xpAmount = (defaultXp or 10) * successfulCrafts
                end
            end

            if xpAmount > 0 then
                local levelData = AwardXP(source, xpAmount, workbenchType)
                if levelData then
                    resultData.levelData = levelData
                end
            end
        end

        -- Award tech points only for successful crafts
        if TechTrees and TechTrees.enabled then
            local techPointAmount = 0
            if recipe.techPointsReward then
                techPointAmount = recipe.techPointsReward * successfulCrafts
            elseif TechTrees.defaultTechPointsPerCraft then
                local defaultTech = TechTrees.defaultTechPointsPerCraft
                if type(defaultTech) == 'table' then
                    if defaultTech.enabled then
                        techPointAmount = (defaultTech.amount or 1) * successfulCrafts
                    end
                else
                    techPointAmount = (defaultTech or 1) * successfulCrafts
                end
            end

            if techPointAmount > 0 then
                local techData = AwardTechPointsToStation(source, techPointAmount, stationId, workbenchType)
                if techData then
                    resultData.techPointsData = techData
                end
            end
        end

        -- Apply tool consumption after successful craft
        local toolResults = ApplyToolConsumption(source, recipe, stationId, successfulCrafts)
        if toolResults then
            resultData.toolResults = toolResults
        end

        if recipe.blueprint and Config.Blueprints and Config.Blueprints.enabled then
            local durabilityConfig = Config.Blueprints.durability
            local stagingKey = GetStagingKey(source, stationId)

            -- Use durability system if enabled and ox_inventory is active
            if durabilityConfig and durabilityConfig.enabled and Inventory.IsOxInventory() then
                -- Check if blueprint is in staging first (most common case)
                local isInStaging = IsBlueprintInStaging(stationId, stagingKey, recipe.blueprint)

                if isInStaging then
                    -- Blueprint is in staging inventory
                    -- Get current durability (use default if not set - for legacy items)
                    local stagedDurability = GetStagedBlueprintDurability(stationId, stagingKey, recipe.blueprint)
                    local currentDurability = stagedDurability or durabilityConfig.defaultDurability or 100

                    local durabilityLoss = recipe.blueprintDurabilityLoss or durabilityConfig.defaultLoss or 10
                    local totalLoss = durabilityLoss * quantity
                    local newDurability = currentDurability - totalLoss

                    if newDurability <= 0 then
                        -- Blueprint durability depleted - remove from staging
                        RemoveStagedBlueprint(stationId, stagingKey, recipe.blueprint)
                        resultData.blueprintDestroyed = true
                        resultData.blueprintItem = recipe.blueprint
                        resultData.blueprintDurabilityBroke = true

                        -- Broadcast staging update to sync UI
                        BroadcastStagedItemsUpdate(stationId, nil)

                        Logger.Log('blueprint_broken', source, {
                            blueprint = recipe.blueprint,
                            recipe = recipeId,
                            recipeLabel = recipe.name or recipeId,
                            durability = 0
                        })

                        debugPrint('Staged blueprint', recipe.blueprint, 'durability depleted and removed at station', stationId)
                    else
                        -- Update durability on staged item
                        UpdateStagedBlueprintDurability(stationId, stagingKey, recipe.blueprint, newDurability)
                        resultData.blueprintDurabilityReduced = true
                        resultData.blueprintNewDurability = newDurability
                        resultData.blueprintDurabilityLoss = totalLoss

                        -- Broadcast staging update to sync UI with new durability
                        BroadcastStagedItemsUpdate(stationId, nil)

                        Logger.Log('blueprint_used', source, {
                            blueprint = recipe.blueprint,
                            recipe = recipeId,
                            recipeLabel = recipe.name or recipeId,
                            durability = newDurability .. '/' .. (durabilityConfig.defaultDurability or 100)
                        })

                        debugPrint('Staged blueprint', recipe.blueprint, 'durability reduced:', currentDurability, '->', newDurability, 'at station', stationId)
                    end
                elseif StationBlueprints[stationId] and StationBlueprints[stationId][recipe.blueprint] then
                    -- Fallback: Blueprint is in StationBlueprints (attached via old method)
                    local blueprintData = StationBlueprints[stationId][recipe.blueprint]
                    local currentDurability = 100

                    -- Get current durability (handle legacy boolean format)
                    if type(blueprintData) == 'table' and blueprintData.durability then
                        currentDurability = blueprintData.durability
                    elseif blueprintData == true then
                        currentDurability = durabilityConfig.defaultDurability or 100
                    end

                    -- Calculate durability loss (per craft, multiplied by quantity)
                    local durabilityLoss = recipe.blueprintDurabilityLoss or durabilityConfig.defaultLoss or 10
                    local totalLoss = durabilityLoss * quantity
                    local newDurability = currentDurability - totalLoss

                    if newDurability <= 0 then
                        -- Blueprint is destroyed
                        StationBlueprints[stationId][recipe.blueprint] = nil
                        resultData.blueprintDestroyed = true
                        resultData.blueprintItem = recipe.blueprint
                        resultData.blueprintDurabilityBroke = true

                        Logger.Log('blueprint_broken', source, {
                            blueprint = recipe.blueprint,
                            recipe = recipeId,
                            recipeLabel = recipe.name or recipeId,
                            durability = 0
                        })

                        debugPrint('Blueprint', recipe.blueprint, 'durability depleted and destroyed at station', stationId)
                    else
                        -- Update durability
                        StationBlueprints[stationId][recipe.blueprint] = { durability = newDurability }
                        resultData.blueprintDurabilityReduced = true
                        resultData.blueprintNewDurability = newDurability
                        resultData.blueprintDurabilityLoss = totalLoss

                        Logger.Log('blueprint_used', source, {
                            blueprint = recipe.blueprint,
                            recipe = recipeId,
                            recipeLabel = recipe.name or recipeId,
                            durability = newDurability .. '/' .. (durabilityConfig.defaultDurability or 100)
                        })

                        debugPrint('Blueprint', recipe.blueprint, 'durability reduced:', currentDurability, '->', newDurability, 'at station', stationId)
                    end
                end
            else
                -- Legacy random destruction system
                local destroyConfig = Config.Blueprints.destroyOnCraft
                if destroyConfig and destroyConfig.enabled then
                    local roll = math.random(1, 100)
                    if roll <= destroyConfig.chance then
                        -- Check staged items first
                        if IsBlueprintInStaging(stationId, stagingKey, recipe.blueprint) then
                            RemoveStagedBlueprint(stationId, stagingKey, recipe.blueprint)
                            BroadcastStagedItemsUpdate(stationId, nil)
                            resultData.blueprintDestroyed = true
                            resultData.blueprintItem = recipe.blueprint

                            Logger.Log('blueprint_broken', source, {
                                blueprint = recipe.blueprint,
                                recipe = recipeId,
                                recipeLabel = recipe.name or recipeId,
                                durability = 0
                            })

                            debugPrint('Staged blueprint', recipe.blueprint, 'randomly destroyed at station', stationId)
                        elseif StationBlueprints[stationId] and StationBlueprints[stationId][recipe.blueprint] then
                            StationBlueprints[stationId][recipe.blueprint] = nil

                            Logger.Log('blueprint_broken', source, {
                                blueprint = recipe.blueprint,
                                recipe = recipeId,
                                recipeLabel = recipe.name or recipeId,
                                durability = 0
                            })

                            debugPrint('Blueprint', recipe.blueprint, 'destroyed at station', stationId)

                            resultData.blueprintDestroyed = true
                            resultData.blueprintItem = recipe.blueprint
                        end
                    end
                end
            end
        end

        -- Track completion time for server-side craft timing enforcement (per-station per-player)
        CraftCompletionTimestamps[completionKey] = os.time()
        debugPrint('completeCraft: Updated CraftCompletionTimestamps for', completionKey, 'to', CraftCompletionTimestamps[completionKey])

        return true, resultData
    end

    debugPrint('completeCraft: WARNING - Failed to give items to player:', source, 'recipe:', recipeId, 'amount:', totalOutputCount)
    return false
end)

--- Event for external scripts to open crafting UI
---@param stationId string Station identifier
RegisterNetEvent('sd-crafting:server:openCrafting', function(stationId)
    local source = source
    TriggerClientEvent('sd-crafting:client:openCrafting', source, stationId)
end)

--- Get shop item by ID
---@param shopId string Shop identifier
---@param itemId string Item identifier
---@return table|nil item The shop item or nil if not found
local function GetShopItem(shopId, itemId)
    local shop = Config.Shops and Config.Shops[shopId]
    if not shop or not shop.items then return nil end

    for _, item in ipairs(shop.items) do
        if item.id == itemId then
            return item
        end
    end
    return nil
end

--- Handle shop purchase
---@param shopId string Shop identifier
---@param itemId string Item identifier
---@param quantity number Quantity to purchase
RegisterNetEvent('sd-crafting:server:purchaseShopItem', function(shopId, itemId, quantity)
    local source = source
    quantity = math.max(1, math.floor(quantity or 1))

    local hasAccess, accessError = ValidateShopAccess(source, shopId)
    if not hasAccess then
        Logger.Log('shop_purchase_failed', source, {
            shopItem = itemId,
            quantity = quantity,
            reason = accessError or 'Access denied'
        })
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Shop',
            description = accessError or 'Access denied',
            type = 'error'
        })
        return
    end

    local shop = Config.Shops and Config.Shops[shopId]
    if not shop then
        Logger.Log('shop_purchase_failed', source, {
            shopItem = itemId,
            quantity = quantity,
            reason = 'Invalid shop'
        })
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Shop',
            description = 'Invalid shop',
            type = 'error'
        })
        return
    end

    local item = GetShopItem(shopId, itemId)
    if not item then
        Logger.Log('shop_purchase_failed', source, {
            shopItem = itemId,
            quantity = quantity,
            reason = 'Item not found'
        })
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Shop',
            description = 'Item not found',
            type = 'error'
        })
        return
    end

    local totalPrice = item.price * quantity
    local currency = item.currency or 'cash'
    local itemToGive = item.item or item.id

    local paymentSuccess = false

    if currency == 'cash' or currency == 'bank' or currency == 'money' then
        local cashFunds = Money.GetPlayerAccountFunds(source, 'cash')
        local bankFunds = Money.GetPlayerAccountFunds(source, 'bank')

        if cashFunds >= totalPrice then
            Money.RemoveMoney(source, 'cash', totalPrice)
            paymentSuccess = true
        elseif bankFunds >= totalPrice then
            Money.RemoveMoney(source, 'bank', totalPrice)
            paymentSuccess = true
        elseif (cashFunds + bankFunds) >= totalPrice then
            Money.RemoveMoney(source, 'cash', cashFunds)
            Money.RemoveMoney(source, 'bank', totalPrice - cashFunds)
            paymentSuccess = true
        end

        if not paymentSuccess then
            Logger.Log('shop_purchase_failed', source, {
                shopItem = item.label or itemId,
                quantity = quantity,
                cost = totalPrice,
                payType = currency,
                reason = 'Not enough money'
            })
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Shop',
                description = 'Not enough money',
                type = 'error'
            })
            return
        end
    else
        local itemCount = Inventory.GetItemCount(source, currency)
        if itemCount >= totalPrice then
            paymentSuccess = Inventory.RemoveItem(source, currency, totalPrice)
        end

        if not paymentSuccess then
            Logger.Log('shop_purchase_failed', source, {
                shopItem = item.label or itemId,
                quantity = quantity,
                cost = totalPrice,
                payType = currency,
                reason = 'Not enough ' .. currency
            })
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Shop',
                description = 'Not enough ' .. currency,
                type = 'error'
            })
            return
        end
    end

    local success = Inventory.AddItem(source, itemToGive, quantity)

    if success then
        local newBalance = 0
        if currency == 'cash' or currency == 'bank' or currency == 'money' then
            newBalance = Money.GetPlayerAccountFunds(source, 'cash') + Money.GetPlayerAccountFunds(source, 'bank')
        else
            newBalance = Inventory.GetItemCount(source, currency)
        end

        Logger.Log('shop_purchase', source, {
            shopItem = item.label or itemId,
            quantity = quantity,
            cost = totalPrice,
            payType = currency,
            balance = newBalance
        })

        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Shop',
            description = 'Purchased ' .. quantity .. 'x ' .. item.label,
            type = 'success'
        })

        debugPrint('Player', source, 'purchased', quantity, 'x', itemToGive, 'for', totalPrice, currency)
    else
        if currency == 'cash' or currency == 'bank' or currency == 'money' then
            Money.AddMoney(source, 'cash', totalPrice)
        else
            Inventory.AddItem(source, currency, totalPrice)
        end

        Logger.Log('shop_purchase_failed', source, {
            shopItem = item.label or itemId,
            quantity = quantity,
            cost = totalPrice,
            payType = currency,
            reason = 'Failed to give item - inventory full'
        })

        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Shop',
            description = 'Failed to give item - payment refunded',
            type = 'error'
        })
    end
end)

--- Save a placed workbench to database
---@param owner string Player identifier
---@param item string Workbench item name
---@param workbenchType string Workbench type
---@param prop string Prop model name
---@param coords vector3 Placement coordinates
---@param heading number Placement heading
---@param techId string|nil Persistent tech ID for shared tech data (reused across pickup/placement)
---@return number|nil id Database ID of placed workbench
local function SavePlacedWorkbench(owner, item, workbenchType, prop, coords, heading, techId)
    local data = {
        item = item,
        workbench_type = workbenchType,
        prop = prop,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
        techId = techId
    }

    local id = MySQL.insert.await(
        "INSERT INTO sd_crafting_workbenches (type, station_id, identifier, data) VALUES ('placed', NULL, ?, ?)",
        { owner, json.encode(data) }
    )

    if id then
        PlacedWorkbenches[id] = {
            id = id,
            owner = owner,
            item = item,
            type = workbenchType,
            prop = prop,
            coords = coords,
            heading = heading,
            permissions = {},
            techId = techId
        }
    end

    return id
end

--- Delete a placed workbench from database
--- Preserves shared tech data when the workbench has a persistent techId (survives pickup/placement)
---@param id number Workbench database ID
function DeletePlacedWorkbench(id)
    local wb = PlacedWorkbenches[id]
    MySQL.query.await('DELETE FROM sd_crafting_workbenches WHERE id = ?', { id })
    MySQL.query('DELETE FROM sd_crafting_permissions WHERE workbench_id = ?', { id })

    if wb and wb.techId then
        -- Workbench has persistent techId: keep tech data in DB for reconnection on re-placement
        -- Only evict from memory cache (will be reloaded when the bench is placed again)
        SharedWorkbenchTech[wb.techId] = nil
    else
        -- Legacy workbench without techId: clean up tech data entirely
        MySQL.query("DELETE FROM sd_crafting_workbenches WHERE type = 'tech' AND station_id = ?", { 'placed_' .. id })
        SharedWorkbenchTech[id] = nil
    end

    PlacedWorkbenches[id] = nil
end

--- Broadcast history update to all players with access to the workbench
---@param workbenchId number Workbench database ID
---@param history table The updated history array
local function BroadcastHistoryUpdate(workbenchId, history)
    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return end

    local playersToNotify = {}

    for _, playerId in ipairs(GetPlayers()) do
        local playerIdent = GetIdentifier(tonumber(playerId))
        if playerIdent then
            local hasAccess = not workbench.owner or workbench.owner == playerIdent
            if not hasAccess and workbench.permissions then
                for _, perm in ipairs(workbench.permissions) do
                    if perm.identifier == playerIdent then
                        hasAccess = true
                        break
                    end
                end
            end
            if hasAccess then
                table.insert(playersToNotify, tonumber(playerId))
            end
        end
    end

    for _, playerId in ipairs(playersToNotify) do
        TriggerClientEvent('sd-crafting:client:historyUpdated', playerId, workbenchId, history)
    end
end

--- Save a crafting history entry to the workbench
---@param stationId string Station identifier (e.g., 'placed_123')
---@param identifier string Player identifier (citizenid)
---@param playerName string Player's character name
---@param recipeId string The recipe ID
---@param recipeName string Display name of the recipe
---@param quantity number Number of items crafted
---@param outputItem string|nil Output item name
---@param outputLabel string|nil Output item display label
---@param outputAmount number|nil Output amount per craft
---@param ingredients table|nil Array of ingredient data {item, label, amount}
function SaveCraftingHistory(stationId, identifier, playerName, recipeId, recipeName, quantity, outputItem, outputLabel, outputAmount, ingredients)
    local placedId = stationId and stationId:match('^placed_(%d+)$')
    if not placedId then return end

    local workbenchId = tonumber(placedId)
    if not workbenchId or not PlacedWorkbenches[workbenchId] then return end

    local result = MySQL.query.await(
        "SELECT history FROM sd_crafting_workbenches WHERE id = ?",
        { workbenchId }
    )

    local history = {}
    if result and result[1] and result[1].history then
        history = json.decode(result[1].history) or {}
    end

    local ingredientsUsed = {}
    if ingredients then
        for _, ing in ipairs(ingredients) do
            table.insert(ingredientsUsed, {
                item = ing.item,
                label = ing.label or Inventory.GetItemLabel(ing.item) or ing.item,
                amount = (ing.amount or 1) * quantity
            })
        end
    end

    local resolvedOutputLabel = Inventory.GetItemLabel(outputItem) or outputLabel or recipeName or outputItem or recipeId

    table.insert(history, 1, {
        identifier = identifier,
        player_name = playerName or 'Unknown',
        recipe_id = recipeId,
        recipe_name = recipeName or recipeId,
        quantity = quantity,
        output_item = outputItem or recipeId,
        output_label = resolvedOutputLabel,
        output_amount = (outputAmount or 1) * quantity,
        ingredients = ingredientsUsed,
        crafted_at = os.date('%Y-%m-%d %H:%M:%S')
    })

    local maxEntries = Config.History and Config.History.maxEntries or 100
    while #history > maxEntries do
        table.remove(history)
    end

    MySQL.query('UPDATE sd_crafting_workbenches SET history = ? WHERE id = ?', {
        json.encode(history),
        workbenchId
    })

    BroadcastHistoryUpdate(workbenchId, history)
end

--- Get crafting history for a placed workbench
---@param workbenchId number Workbench database ID
---@param identifier string Player identifier requesting history
---@return table|nil history Array of history entries or nil if not authorized
local function GetWorkbenchHistory(workbenchId, identifier)
    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return nil end

    local hasAccess = not workbench.owner or workbench.owner == identifier
    if not hasAccess and workbench.permissions then
        for _, perm in ipairs(workbench.permissions) do
            if perm.identifier == identifier then
                hasAccess = true
                break
            end
        end
    end

    if not hasAccess then return nil end

    local result = MySQL.query.await(
        "SELECT history FROM sd_crafting_workbenches WHERE id = ?",
        { workbenchId }
    )

    if result and result[1] and result[1].history then
        return json.decode(result[1].history) or {}
    end

    return {}
end

--- Get all placed workbenches (for client sync)
---@return table workbenches Array of placed workbench data
local function GetAllPlacedWorkbenches()
    local result = {}
    for id, data in pairs(PlacedWorkbenches) do
        local resolvedPropEnabled = true
        if data.propEnabled ~= nil then resolvedPropEnabled = data.propEnabled end
        result[#result + 1] = {
            id = data.id,
            owner = data.owner,
            item = data.item,
            type = data.type,
            prop = data.prop,
            propEnabled = resolvedPropEnabled,
            coords = data.coords and { x = data.coords.x, y = data.coords.y, z = data.coords.z } or nil,
            heading = data.heading,
            label = data.label,
            recipes = data.recipes,
            techTrees = data.techTrees,
            blip = data.blip,
            radius = data.radius,
        }
    end
    return result
end

--- Get all placed workbenches for client sync
---@param source number Player server ID
---@return table workbenches Array of placed workbench data
lib.callback.register('sd-crafting:server:getPlacedWorkbenches', function(source)
    return GetAllPlacedWorkbenches()
end)

--- Place a workbench at specified coordinates
---@param source number Player server ID
---@param itemName string Workbench item name
---@param coords vector3 Placement coordinates
---@param heading number Placement heading
---@return boolean success Whether placement was successful
---@return number|nil id Workbench database ID if successful
lib.callback.register('sd-crafting:server:placeWorkbench', function(source, itemName, coords, heading)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    local playerCoords = GetPlayerCoords(source)
    if not playerCoords or not coords then
        return false
    end

    local distance = GetDistance(playerCoords, coords)
    if distance > MAX_INTERACTION_DISTANCE then
        debugPrint('Security: Player', source, 'tried to place workbench too far away - distance:', distance)
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = 'Invalid placement location',
            type = 'error'
        })
        return false
    end

    local workbenchData = Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[itemName]
    if not workbenchData then return false end

    local hasItem = Inventory.GetItemCount(source, itemName)
    if hasItem < 1 then
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = 'You don\'t have this workbench!',
            type = 'error'
        })
        return false
    end

    -- Try to find an item with existing techId metadata (for shared tech persistence across pickup/placement)
    local existingTechId = nil
    local removeSlot = nil
    local items = Inventory.GetItemsWithMetadata and Inventory.GetItemsWithMetadata(source, itemName)
    if items then
        for _, item in ipairs(items) do
            if item.metadata and item.metadata.techId then
                existingTechId = item.metadata.techId
                removeSlot = item.slot
                break
            end
        end
    end

    -- Remove the specific item (slot-targeted if we found one with techId, generic otherwise)
    local removed
    if removeSlot and Inventory.RemoveItemFromSlot then
        removed = Inventory.RemoveItemFromSlot(source, itemName, 1, removeSlot)
    end
    if not removed then
        removed = Inventory.RemoveItem(source, itemName, 1)
    end

    if not removed then
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = 'Failed to remove workbench from inventory',
            type = 'error'
        })
        return false
    end

    -- Use existing techId from item metadata, or generate a new one for shared workbenches
    local techId = existingTechId or GenerateTechId()

    local id = SavePlacedWorkbench(identifier, itemName, workbenchData.type, workbenchData.prop, coords, heading, techId)

    if id then
        TriggerClientEvent('sd-crafting:client:spawnPlacedWorkbench', -1, {
            id = id,
            owner = identifier,
            item = itemName,
            type = workbenchData.type,
            prop = workbenchData.prop,
            coords = coords,
            heading = heading
        })

        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = workbenchData.label .. ' placed successfully!',
            type = 'success'
        })

        debugPrint(('Player %s placed workbench %s at %.2f, %.2f, %.2f'):format(source, itemName, coords.x, coords.y, coords.z))

        return true, id
    end

    Inventory.AddItem(source, itemName, 1)
    return false
end)

--- Pickup an owned workbench
---@param source number Player server ID
---@param workbenchId number Workbench database ID
---@return boolean success Whether pickup was successful
lib.callback.register('sd-crafting:server:pickupWorkbench', function(source, workbenchId)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return false end

    local playerCoords = GetPlayerCoords(source)
    if not playerCoords or not workbench.coords then
        return false
    end

    local distance = GetDistance(playerCoords, workbench.coords)
    if distance > MAX_INTERACTION_DISTANCE then
        debugPrint('Security: Player', source, 'tried to pickup workbench too far away - distance:', distance)
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = 'Too far from workbench',
            type = 'error'
        })
        return false
    end

    if workbench.owner ~= identifier then
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = 'You don\'t own this workbench!',
            type = 'error'
        })
        return false
    end

    -- Add item back with techId metadata so shared tech data persists across pickup/placement
    local metadata = workbench.techId and { techId = workbench.techId } or nil
    local added
    if metadata and Inventory.AddItemWithMetadata then
        added = Inventory.AddItemWithMetadata(source, workbench.item, 1, metadata)
    else
        added = Inventory.AddItem(source, workbench.item, 1)
    end
    if not added then
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Workbench',
            description = 'Not enough inventory space!',
            type = 'error'
        })
        return false
    end

    DeletePlacedWorkbench(workbenchId)

    TriggerClientEvent('sd-crafting:client:removePlacedWorkbench', -1, workbenchId)

    TriggerClientEvent('sd-crafting:client:notify', source, {
        title = 'Workbench',
        description = 'Workbench picked up!',
        type = 'success'
    })

    return true
end)

--- Get shared queue with remainingTime interpolated for time elapsed since last progress sync
--- Prevents observers from seeing stale remainingTime values between sync intervals
---@param stationId string Station identifier
---@return table adjustedQueue Queue with interpolated remainingTime values
function GetAdjustedSharedQueue(stationId)
    local queue = SharedQueues[stationId] or {}

    -- If the server is actively processing this shared queue (owner offline),
    -- the server's remainingTime is already accurate — skip interpolation
    local sharedIdentifier = 'shared_' .. stationId
    if ServerProcessedQueues[sharedIdentifier] then
        return queue
    end

    local now = GetGameTimer()
    local adjusted = {}
    for i, item in ipairs(queue) do
        if i == 1 and item.lastProgressSync then
            local elapsed = math.floor((now - item.lastProgressSync) / 1000)
            if elapsed > 0 then
                local copy = {}
                for k, v in pairs(item) do
                    copy[k] = v
                end
                copy.remainingTime = math.max(0, item.remainingTime - elapsed)
                adjusted[i] = copy
            else
                adjusted[i] = item
            end
        else
            adjusted[i] = item
        end
    end
    return adjusted
end

--- Broadcast shared queue update to all players at a station
---@param stationId string Station identifier
---@param excludeSource number|nil Optional player source to exclude from broadcast (e.g., the player who triggered the update)
function BroadcastQueueUpdate(stationId, excludeSource)
    if not OpenStations[stationId] then return end
    local queue = GetAdjustedSharedQueue(stationId)
    for playerSource, _ in pairs(OpenStations[stationId]) do
        -- Skip the player who triggered the update to avoid race conditions
        if playerSource ~= excludeSource then
            TriggerClientEvent('sd-crafting:client:syncSharedQueue', playerSource, stationId, queue)
        end
    end
end

--- Get shared queue for a station
---@param source number Player server ID
---@param stationId string Station identifier
---@return table queue The shared queue for this station
lib.callback.register('sd-crafting:server:getSharedQueue', function(source, stationId)
    local behavior = GetEffectiveCraftingBehavior(stationId)
    if not behavior.sharedCrafting then
        return {}
    end

    -- If the server was processing this queue (owner was offline), hand it back to the client
    -- so they don't double-tick. The client will resume from the server's current remainingTime.
    local sharedIdentifier = 'shared_' .. stationId
    if ServerProcessedQueues[sharedIdentifier] then
        local queue = SharedQueues[stationId] or {}
        if #queue > 0 then
            local identifier = GetIdentifier(source)
            local isOwner = queue[1].ownerIdentifier == identifier
            -- Update the owner source ID to the player's new source (changes on reconnect)
            if isOwner then
                queue[1].owner = source
                queue[1].lastProgressSync = GetGameTimer()
                ServerProcessedQueues[sharedIdentifier] = nil
                debugPrint('getSharedQueue: Player', identifier, 'took over server-processed shared queue at', stationId)
            end
        end
    end

    return GetAdjustedSharedQueue(stationId)
end)

--- Add item to shared queue
---@param source number Player server ID
---@param stationId string Station identifier
---@param queueItem table Queue item data (id, recipe, quantity, totalTime)
---@return boolean success Whether the item was added
---@return table|nil queue Updated queue if successful
lib.callback.register('sd-crafting:server:addToSharedQueue', function(source, stationId, queueItem)
    local behavior = GetEffectiveCraftingBehavior(stationId)
    if not behavior.sharedCrafting then
        return false, nil
    end

    if not SharedQueues[stationId] then
        SharedQueues[stationId] = {}
    end

    -- Add owner info to queue item
    queueItem.owner = source
    queueItem.ownerIdentifier = GetIdentifier(source)
    queueItem.ownerName = GetPlayerFullName(source) or GetPlayerName(source) or 'Unknown'

    -- Set initial sync timestamp so GetAdjustedSharedQueue can interpolate remainingTime
    -- immediately, rather than returning the stale original value for the first 10 seconds
    -- before the first periodic sync from ProcessQueue
    queueItem.lastProgressSync = GetGameTimer()

    table.insert(SharedQueues[stationId], queueItem)

    -- Broadcast to all players at this station (exclude source to avoid race condition)
    BroadcastQueueUpdate(stationId, source)

    -- Save shared queue to database for persistence
    SaveSharedCraftingQueue(stationId, SharedQueues[stationId])

    return true, GetAdjustedSharedQueue(stationId)
end)

--- Remove item from shared queue
---@param source number Player server ID
---@param stationId string Station identifier
---@param queueItemId string Queue item ID to remove
---@return boolean success Whether the item was removed
---@return table|nil queue Updated queue if successful
lib.callback.register('sd-crafting:server:removeFromSharedQueue', function(source, stationId, queueItemId)
    local behavior = GetEffectiveCraftingBehavior(stationId)
    if not behavior.sharedCrafting then
        return false, nil
    end

    if not SharedQueues[stationId] then
        return false, nil
    end

    for i, item in ipairs(SharedQueues[stationId]) do
        if item.id == queueItemId then
            -- Only owner can remove their items (unless it's the first item being processed)
            if item.owner ~= source and i ~= 1 then
                return false, GetAdjustedSharedQueue(stationId)
            end
            table.remove(SharedQueues[stationId], i)
            -- If the removed item was at position 1, reset lastProgressSync on the new first item
            -- so GetAdjustedSharedQueue interpolates from now, not from when it was originally added
            if i == 1 and #SharedQueues[stationId] > 0 then
                SharedQueues[stationId][1].lastProgressSync = GetGameTimer()
            end
            -- Broadcast to other players (exclude source to avoid race condition)
            BroadcastQueueUpdate(stationId, source)
            -- Save shared queue to database for persistence
            SaveSharedCraftingQueue(stationId, SharedQueues[stationId])
            return true, GetAdjustedSharedQueue(stationId)
        end
    end

    return false, GetAdjustedSharedQueue(stationId)
end)

--- Update shared queue item (for progress sync)
---@param source number Player server ID
---@param stationId string Station identifier
---@param queueItemId string Queue item ID to update
---@param updates table Fields to update (remainingTime, etc.)
lib.callback.register('sd-crafting:server:updateSharedQueueItem', function(source, stationId, queueItemId, updates)
    local behavior = GetEffectiveCraftingBehavior(stationId)
    if not behavior.sharedCrafting then
        return false
    end

    if not SharedQueues[stationId] then
        return false
    end

    for _, item in ipairs(SharedQueues[stationId]) do
        if item.id == queueItemId then
            for key, value in pairs(updates) do
                item[key] = value
            end
            item.lastProgressSync = GetGameTimer()
            -- Exclude the source player from broadcast to avoid race condition with their local countdown
            BroadcastQueueUpdate(stationId, source)
            -- Mark queue as dirty for periodic save (avoids saving every second)
            MarkSharedQueueDirty(stationId)
            return true
        end
    end

    return false
end)

--- Complete and remove first item from shared queue
---@param source number Player server ID
---@param stationId string Station identifier
---@return boolean success Whether the item was removed
lib.callback.register('sd-crafting:server:completeSharedQueueItem', function(source, stationId)
    local behavior = GetEffectiveCraftingBehavior(stationId)
    if not behavior.sharedCrafting then
        return false
    end

    if not SharedQueues[stationId] or #SharedQueues[stationId] == 0 then
        return false
    end

    -- Remove first item (completed)
    table.remove(SharedQueues[stationId], 1)
    -- Reset lastProgressSync on the newly promoted first item so GetAdjustedSharedQueue
    -- interpolates from now (when it became active), not from when it was originally added.
    -- Without this, elapsed time includes the entire wait in queue, making remainingTime appear as 0.
    if #SharedQueues[stationId] > 0 then
        SharedQueues[stationId][1].lastProgressSync = GetGameTimer()
    end
    -- Broadcast to other players (exclude source to avoid race condition)
    BroadcastQueueUpdate(stationId, source)
    -- Save shared queue to database for persistence
    SaveSharedCraftingQueue(stationId, SharedQueues[stationId])

    return true
end)

--- Check if shared crafting is enabled for a specific station
---@param source number Player server ID
---@param stationId string Station identifier
---@return boolean enabled Whether shared crafting is enabled for this station type
lib.callback.register('sd-crafting:server:isSharedCraftingEnabled', function(source, stationId)
    local behavior = GetEffectiveCraftingBehavior(stationId)
    if not behavior.sharedCrafting then
        return false
    end

    local sharedCrafting = behavior.sharedCrafting

    -- Handle legacy boolean config
    if type(sharedCrafting) == 'boolean' then
        return sharedCrafting
    end

    -- Check if this is a placed workbench
    if stationId and stationId:find('^placed_') then
        return sharedCrafting.placed or false
    else
        return sharedCrafting.static or false
    end
end)

--- Check if a player has permission to use a placed workbench
---@param source number Player server ID
---@param workbenchId number Workbench database ID
---@return boolean hasPermission Whether the player can use the workbench
---@return boolean isOwner Whether the player is the owner
lib.callback.register('sd-crafting:server:checkWorkbenchPermission', function(source, workbenchId)
    if not Config.Permissions or not Config.Permissions.enabled then
        return true, false
    end

    local identifier = GetIdentifier(source)
    if not identifier then return false, false end

    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return false, false end

    -- No owner = public workbench, anyone can access
    if not workbench.owner then
        return true, false
    end

    -- Owner always has access
    if workbench.owner == identifier then
        return true, true
    end

    -- Check permissions list
    if workbench.permissions then
        for _, perm in ipairs(workbench.permissions) do
            if perm.identifier == identifier then
                return true, false
            end
        end
    end

    return false, false
end)

--- Get workbench permissions list with player names
---@param source number Player server ID
---@param workbenchId number Workbench database ID
---@return table|nil permissions Array of { identifier, name } or nil if not owner
lib.callback.register('sd-crafting:server:getWorkbenchPermissions', function(source, workbenchId)
    local identifier = GetIdentifier(source)
    if not identifier then return nil end

    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return nil end

    -- Only owner can view permissions
    if workbench.owner ~= identifier then
        return nil
    end

    local result = {}

    -- Return stored permissions with names
    if workbench.permissions then
        for _, perm in ipairs(workbench.permissions) do
            table.insert(result, { identifier = perm.identifier, name = perm.name })
        end
    end

    return result
end)

--- Add a player to workbench permissions by their source ID
---@param source number Player server ID (requester)
---@param workbenchId number Workbench database ID
---@param targetSource number Target player source ID to add
---@return boolean success Whether the player was added
---@return string|nil message Error or success message
lib.callback.register('sd-crafting:server:addWorkbenchPermission', function(source, workbenchId, targetSource)
    local identifier = GetIdentifier(source)
    if not identifier then return false, 'Invalid request' end

    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return false, 'Workbench not found' end

    -- Only owner can modify permissions
    if workbench.owner ~= identifier then
        return false, 'Only the owner can modify permissions'
    end

    -- Validate target source
    local targetId = tonumber(targetSource)
    if not targetId then return false, 'Invalid player source ID' end

    local targetIdentifier = GetIdentifier(targetId)
    if not targetIdentifier then return false, 'Player not found' end

    -- Can't add owner
    if targetIdentifier == workbench.owner then
        return false, 'Owner already has access'
    end

    -- Check if already added
    if workbench.permissions then
        for _, perm in ipairs(workbench.permissions) do
            if perm.identifier == targetIdentifier then
                return false, 'Player already has access'
            end
        end
    else
        workbench.permissions = {}
    end

    local targetName = GetPlayerFullName(targetId) or 'Unknown'

    -- Add to permissions (as object with identifier and name)
    table.insert(workbench.permissions, {
        identifier = targetIdentifier,
        name = targetName
    })

    -- Save to database with name
    MySQL.insert('INSERT INTO sd_crafting_permissions (workbench_id, identifier, name) VALUES (?, ?, ?)', { workbenchId, targetIdentifier, targetName })

    return true, targetName
end)

--- Remove a player from workbench permissions
---@param source number Player server ID (requester)
---@param workbenchId number Workbench database ID
---@param targetIdentifier string Target player identifier to remove
---@return boolean success Whether the player was removed
---@return string|nil message Error message if failed
lib.callback.register('sd-crafting:server:removeWorkbenchPermission', function(source, workbenchId, targetIdentifier)
    local identifier = GetIdentifier(source)
    if not identifier then return false, 'Invalid request' end

    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return false, 'Workbench not found' end

    -- Only owner can modify permissions
    if workbench.owner ~= identifier then
        return false, 'Only the owner can modify permissions'
    end

    -- Find and remove from permissions
    if workbench.permissions then
        for i, perm in ipairs(workbench.permissions) do
            if perm.identifier == targetIdentifier then
                table.remove(workbench.permissions, i)
                -- Delete from database
                MySQL.query('DELETE FROM sd_crafting_permissions WHERE workbench_id = ? AND identifier = ?', { workbenchId, targetIdentifier })
                return true
            end
        end
    end

    return false, 'Player not found in permissions'
end)

--- Get workbench crafting history
---@param source number Player server ID
---@param workbenchId number Workbench database ID
---@return table|nil history Array of history entries or nil if not authorized
lib.callback.register('sd-crafting:server:getWorkbenchHistory', function(source, workbenchId)
    local identifier = GetIdentifier(source)
    if not identifier then return nil end

    return GetWorkbenchHistory(workbenchId, identifier)
end)

--- Delete a history entry from a placed workbench
---@param source number Player server ID
---@param workbenchId number Workbench database ID
---@param entryIndex number Index of entry to delete (1-based)
---@return boolean success Whether deletion was successful
lib.callback.register('sd-crafting:server:deleteHistoryEntry', function(source, workbenchId, entryIndex)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    local workbench = PlacedWorkbenches[workbenchId]
    if not workbench then return false end

    local ownerOnlyDelete = Config.History and Config.History.ownerOnlyDelete
    local isPublic = not workbench.owner
    local isOwner = not isPublic and workbench.owner == identifier
    local hasPermission = isPublic

    if not isPublic and not isOwner and workbench.permissions then
        for _, perm in ipairs(workbench.permissions) do
            if perm.identifier == identifier then
                hasPermission = true
                break
            end
        end
    end

    if ownerOnlyDelete and not isOwner and not isPublic then return false end
    if not ownerOnlyDelete and not isOwner and not hasPermission then return false end

    local result = MySQL.query.await(
        "SELECT history FROM sd_crafting_workbenches WHERE id = ?",
        { workbenchId }
    )

    if not result or not result[1] or not result[1].history then return false end

    local history = json.decode(result[1].history) or {}
    if entryIndex < 1 or entryIndex > #history then return false end

    table.remove(history, entryIndex)

    MySQL.query('UPDATE sd_crafting_workbenches SET history = ? WHERE id = ?', {
        json.encode(history),
        workbenchId
    })

    BroadcastHistoryUpdate(workbenchId, history)

    return true
end)

--- Start workbench placement mode for a player
---@param source number Player server ID
---@param itemName string Workbench item name
---@param workbenchData table Workbench configuration data
local function StartWorkbenchPlacement(source, itemName, workbenchData)
    TriggerClientEvent('sd-crafting:client:startWorkbenchPlacement', source, itemName, workbenchData)
end

--- Register placeable workbench items as usable
if Config.PlaceableWorkbenches then
    print('hi')
    for itemName, workbenchData in pairs(Config.PlaceableWorkbenches) do
        Inventory.RegisterUsableItem(itemName, function(source, item, inventory, slot, data)
            StartWorkbenchPlacement(source, itemName, workbenchData)
        end)

        debugPrint(('Registered usable item: %s (Type: %s)'):format(itemName, workbenchData.type or 'unknown'))
    end
end

--- Command to check blueprint durability in player's inventory
lib.addCommand('checkblueprints', {
    help = 'Check durability of all blueprints in your inventory (ox_inventory only)',
    params = {},
    restricted = false
}, function(source, args, raw)
    if not Inventory.IsOxInventory() then
        if source == 0 then
            print('[SD-CRAFTING] Blueprint durability check requires ox_inventory')
        else
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Blueprints',
                description = 'Durability system requires ox_inventory',
                type = 'error'
            })
        end
        return
    end

    local durabilityConfig = Config.Blueprints and Config.Blueprints.durability
    if not durabilityConfig or not durabilityConfig.enabled then
        if source == 0 then
            print('[SD-CRAFTING] Blueprint durability system is disabled')
        else
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Blueprints',
                description = 'Durability system is disabled in config',
                type = 'error'
            })
        end
        return
    end

    local items = exports.ox_inventory:GetInventoryItems(source, false)
    if not items then
        if source == 0 then
            print('[SD-CRAFTING] Could not retrieve inventory')
        else
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Blueprints',
                description = 'Could not retrieve inventory',
                type = 'error'
            })
        end
        return
    end

    local blueprints = {}
    local stagedBlueprints = {}

    -- Check player inventory
    for _, item in pairs(items) do
        if item.name and IsBlueprint(item.name) then
            local metadata = item.metadata or {}
            local durability = metadata.durability or durabilityConfig.defaultDurability or 100
            table.insert(blueprints, {
                name = item.name,
                label = Inventory.GetItemLabel(item.name) or item.name,
                slot = item.slot,
                durability = durability,
                location = 'inventory'
            })
        end
    end

    -- Check all staging areas for this player's blueprints
    local identifier = GetIdentifier(source)
    for stationId, stationData in pairs(StagedItems) do
        for stagingKey, stagedItemsList in pairs(stationData) do
            -- Check if this staging belongs to the player (or is shared)
            if stagingKey == identifier or stagingKey == 'shared' or stagingKey == ('player_' .. source) then
                for _, item in ipairs(stagedItemsList) do
                    if item.item and IsBlueprint(item.item) then
                        local durability = item.durability
                        local hasStoredDurability = durability ~= nil
                        durability = durability or durabilityConfig.defaultDurability or 100
                        table.insert(stagedBlueprints, {
                            name = item.item,
                            label = Inventory.GetItemLabel(item.item) or item.item,
                            durability = durability,
                            stationId = stationId,
                            location = 'staged',
                            legacy = not hasStoredDurability -- Mark if durability wasn't stored
                        })
                    end
                end
            end
        end
    end

    local totalCount = #blueprints + #stagedBlueprints

    if totalCount == 0 then
        if source == 0 then
            print('[SD-CRAFTING] No blueprints found')
        else
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Blueprints',
                description = 'No blueprints found in inventory or crafting stations',
                type = 'inform'
            })
        end
        return
    end

    -- Print results
    print('[SD-CRAFTING] Blueprint durability for player ' .. source .. ':')
    print('-------------------------------------------')

    if #blueprints > 0 then
        print('  INVENTORY:')
        for _, bp in ipairs(blueprints) do
            print(string.format('    [Slot %d] %s: %d%% durability', bp.slot, bp.label, bp.durability))
        end
    end

    if #stagedBlueprints > 0 then
        print('  CRAFTING INVENTORY:')
        for _, bp in ipairs(stagedBlueprints) do
            print(string.format('    [%s] %s: %d%% durability', bp.stationId, bp.label, bp.durability))
        end
    end

    print('-------------------------------------------')

    -- Also notify the player
    if source ~= 0 then
        local msg = 'Found ' .. totalCount .. ' blueprint(s). Check server console for details.'
        TriggerClientEvent('sd-crafting:client:notify', source, {
            title = 'Blueprints',
            description = msg,
            type = 'success'
        })
    end
end)

--- Admin command to add tech points to a player or shared station
--- Usage: /addtechpoints [stationId] [amount] [playerId]
--- stationId: 'placed_27', 'station_name', etc. Use 'player' for player-based tech.
--- amount: Number of tech points to add (can be negative to remove)
--- playerId: Server ID of the target player (defaults to self)
lib.addCommand('addtechpoints', {
    help = 'Add tech points to a station or player (e.g. /addtechpoints placed_27 100)',
    params = {
        { name = 'stationId', type = 'string', help = 'Station ID (placed_27, station_name, or "player")' },
        { name = 'amount', type = 'number', help = 'Tech points to add (negative to remove)' },
        { name = 'playerId', type = 'number', help = 'Target player server ID (default: self)', optional = true },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local stationId = args.stationId
    local amount = args.amount
    local targetSource = args.playerId or source

    if not TechTrees or not TechTrees.enabled then
        if source == 0 then
            print('[SD-CRAFTING] Tech trees are disabled')
        else
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Tech Points',
                description = 'Tech trees are disabled',
                type = 'error'
            })
        end
        return
    end

    if not amount or amount == 0 then
        if source == 0 then
            print('[SD-CRAFTING] Amount must be a non-zero number')
        else
            TriggerClientEvent('sd-crafting:client:notify', source, {
                title = 'Tech Points',
                description = 'Amount must be a non-zero number',
                type = 'error'
            })
        end
        return
    end

    -- Handle shared station tech (placed workbenches, admin stations, static stations)
    if stationId ~= 'player' then
        local isShared, techRef = IsSharedTechWorkbench(stationId)

        if isShared and techRef then
            local techData = LoadSharedWorkbenchTech(techRef)
            local newPoints = math.max(0, (techData.tech_points or 0) + amount)
            techData.tech_points = newPoints
            SaveSharedWorkbenchTech(techRef)

            local msg = ('Added %d tech points to %s (total: %d)'):format(amount, stationId, newPoints)
            print(('[SD-CRAFTING] %s'):format(msg))
            if source ~= 0 then
                TriggerClientEvent('sd-crafting:client:notify', source, {
                    title = 'Tech Points',
                    description = msg,
                    type = 'success'
                })
            end

            -- Sync to any players currently viewing this station
            if OpenStations[stationId] then
                for playerSource, _ in pairs(OpenStations[stationId]) do
                    TriggerClientEvent('sd-crafting:client:syncTechTree', playerSource, {
                        techPoints = newPoints,
                        workbenchType = nil
                    })
                end
            end
            return
        end

        -- Not shared — check if it's a valid placed workbench and apply directly to its tech data
        local placedId = stationId:match('^placed_(%d+)$')
        if placedId then
            local numericId = tonumber(placedId)
            local wb = numericId and PlacedWorkbenches[numericId]
            if not wb then
                local msg = ('Placed workbench %s not found'):format(stationId)
                if source == 0 then print('[SD-CRAFTING] ' .. msg) else
                    TriggerClientEvent('sd-crafting:client:notify', source, { title = 'Tech Points', description = msg, type = 'error' })
                end
                return
            end

            -- Apply tech points directly using the workbench's techId (or fallback key)
            local techKey = wb.techId or ('placed_' .. numericId)
            local techData = LoadSharedWorkbenchTech(techKey)
            local newPoints = math.max(0, (techData.tech_points or 0) + amount)
            techData.tech_points = newPoints
            SaveSharedWorkbenchTech(techKey)

            local msg = ('Added %d tech points to %s (total: %d)'):format(amount, stationId, newPoints)
            print(('[SD-CRAFTING] %s'):format(msg))
            if source ~= 0 then
                TriggerClientEvent('sd-crafting:client:notify', source, { title = 'Tech Points', description = msg, type = 'success' })
            end

            if OpenStations[stationId] then
                for playerSource, _ in pairs(OpenStations[stationId]) do
                    TriggerClientEvent('sd-crafting:client:syncTechTree', playerSource, {
                        techPoints = newPoints,
                        workbenchType = wb.type
                    })
                end
            end
            return
        end

        -- Check static/admin stations that aren't shared — fall through to player-based
        local msg = ('Station %s not found or not shared. Use "player" for player-based tech.'):format(stationId)
        if source == 0 then print('[SD-CRAFTING] ' .. msg) else
            TriggerClientEvent('sd-crafting:client:notify', source, { title = 'Tech Points', description = msg, type = 'error' })
        end
        return
    end

    -- Player-based tech points
    if targetSource == 0 then
        print('[SD-CRAFTING] Cannot add player tech points to console. Specify a player ID.')
        return
    end

    local identifier = GetIdentifier(targetSource)
    if not identifier then
        local msg = ('Player %d not found'):format(targetSource)
        if source == 0 then print('[SD-CRAFTING] ' .. msg) else
            TriggerClientEvent('sd-crafting:client:notify', source, { title = 'Tech Points', description = msg, type = 'error' })
        end
        return
    end

    local data = LoadPlayerData(targetSource)
    local perWorkbenchTech = TechTrees and TechTrees.perWorkbenchType

    if perWorkbenchTech and data.workbench_tech then
        -- Add to all workbench types
        for wbType, wbData in pairs(data.workbench_tech) do
            wbData.tech_points = math.max(0, (wbData.tech_points or 0) + amount)
        end
    else
        data.tech_points = math.max(0, (data.tech_points or 0) + amount)
    end

    SavePlayerData(identifier)

    local newPoints = perWorkbenchTech and 'all types' or tostring(data.tech_points or 0)
    local msg = ('Added %d tech points to player %d (total: %s)'):format(amount, targetSource, newPoints)
    print(('[SD-CRAFTING] %s'):format(msg))
    if source ~= 0 then
        TriggerClientEvent('sd-crafting:client:notify', source, { title = 'Tech Points', description = msg, type = 'success' })
    end
end)

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

--- Pre-cache all item labels and weights on resource start
local function InitializeItemCache()
    local items = GetAllRecipeItems()
    local count = 0

    for _, itemName in ipairs(items) do
        -- Cache label
        Inventory.GetItemLabel(itemName)
        -- Cache weight
        Inventory.GetItemWeight(itemName)
        count = count + 1
    end

    debugPrint(('Server pre-cached %d items (labels & weights)'):format(count))
end

--- Initialize item cache on resource start
CreateThread(function()
    Wait(2000) -- Wait for inventory system to be ready
    InitializeItemCache()
end)

--- Save player crafting queue to server memory for persistence
---@param source number Player server ID
---@param queueData table Queue data including queue items, stationId, workbenchType, coords
lib.callback.register('sd-crafting:server:savePlayerQueue', function(source, queueData)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    if queueData and queueData.queue and #queueData.queue > 0 then
        PlayerCraftingQueues[identifier] = queueData
        -- Mark queue as dirty for periodic save (avoids saving every update)
        MarkPlayerQueueDirty(identifier)
        return true
    else
        PlayerCraftingQueues[identifier] = nil
        DeletePlayerCraftingQueue(identifier)
        return true
    end
end)

--- Ensure all items in a queue have valid craft tokens registered in PendingCrafts
--- Re-registers existing tokens or generates new ones for legacy items without tokens
---@param queue table Queue items array
---@param identifier string Player persistent identifier
---@param stationId string Station identifier
local function EnsureQueueTokensRegistered(queue, identifier, stationId)
    for _, item in ipairs(queue) do
        if not item.craftToken then
            item.craftToken = GenerateCraftToken()
        end
        -- Re-register if not already in PendingCrafts (e.g. after server restart)
        if not PendingCrafts[item.craftToken] then
            local craftTime = item.recipe and item.recipe.craftTime and (item.recipe.craftTime * (item.quantity or 1)) or 0
            RegisterCraftToken(item.craftToken, identifier, item.recipe and item.recipe.id or '', item.quantity or 1, stationId, craftTime)
            -- Set startedAt to 0 so time validation passes for restored items
            PendingCrafts[item.craftToken].startedAt = 0
            debugPrint('EnsureQueueTokensRegistered: Re-registered token:', item.craftToken, 'as restored (startedAt=0)')
        end
    end
end

--- Get saved crafting queue for player (called on player load)
---@param source number Player server ID
---@return table|nil queueData Saved queue data or nil
---@return number completedCount Number of items completed while offline
lib.callback.register('sd-crafting:server:getSavedQueue', function(source)
    local identifier = GetIdentifier(source)
    if not identifier then return nil, 0 end

    -- Check if queue is being processed server-side (most up-to-date state)
    if ServerProcessedQueues[identifier] then
        local serverData = ServerProcessedQueues[identifier]
        local offlineCompletedCount = serverData.offlineCompletedCount or 0
        debugPrint('getSavedQueue: Found server-processed queue for', identifier, '- items:', #serverData.queue, 'offlineCompleted:', offlineCompletedCount)
        -- Remove from server processing - player is taking over
        RemoveFromServerProcessing(identifier)

        if serverData.queue and #serverData.queue > 0 then
            -- Ensure tokens are registered for restored items
            EnsureQueueTokensRegistered(serverData.queue, identifier, serverData.stationId)

            local queueData = {
                queue = serverData.queue,
                stationId = serverData.stationId,
                fromCache = true
            }
            PlayerCraftingQueues[identifier] = queueData

            debugPrint('Player', identifier, 'took over queue from server processing -', #serverData.queue, 'items, offline completed:', offlineCompletedCount)

            return queueData, offlineCompletedCount
        else
            -- Queue is empty but there may be offline completions to report
            if Config.Debug and offlineCompletedCount > 0 then
                print('[SD-CRAFTING] Player', identifier, 'has', offlineCompletedCount, 'offline completed crafts (queue empty)')
            end
            return nil, offlineCompletedCount
        end
    end

    -- Check memory cache (only if not fresh from database with offline calculation)
    if PlayerCraftingQueues[identifier] and PlayerCraftingQueues[identifier].fromCache then
        -- Ensure tokens are registered (may have been lost on server restart)
        local cached = PlayerCraftingQueues[identifier]
        if cached.queue and #cached.queue > 0 then
            EnsureQueueTokensRegistered(cached.queue, identifier, cached.stationId)
        end
        return cached, 0
    end

    -- Check database and process offline time
    local savedQueue, completedItems = LoadPlayerCraftingQueue(identifier)
    local completedCount = completedItems and #completedItems or 0

    if savedQueue and savedQueue.queue and #savedQueue.queue > 0 then
        -- Ensure tokens are registered for items loaded from database
        EnsureQueueTokensRegistered(savedQueue.queue, identifier, savedQueue.stationId)
        savedQueue.fromCache = true -- Mark as cached to avoid reprocessing
        PlayerCraftingQueues[identifier] = savedQueue
        return savedQueue, completedCount
    elseif completedCount > 0 then
        -- All items completed while offline, clear the queue from database
        DeletePlayerCraftingQueue(identifier)
        return nil, completedCount
    end

    return nil, 0
end)

--- Clear player crafting queue after completion
---@param source number Player server ID
lib.callback.register('sd-crafting:server:clearSavedQueue', function(source)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    DeletePlayerCraftingQueue(identifier)
    return true
end)


--- Check for updates on resource start
CheckVersion('sd-versions/sd-crafting')
