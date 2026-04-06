local Config = require('configs/config') -- Main configuration from configs/config.lua
local Recipes = require('configs/recipes') -- Recipe definitions from configs/recipes.lua
local TechTrees = require('configs/techtrees') -- Tech tree definitions from configs/techtrees.lua

local cachedOnlineLookup = nil -- Cached online player lookup table
local onlineLookupExpiry = 0 -- Expiry timestamp for online lookup cache
local ONLINE_LOOKUP_TTL = 3000 -- How long to cache online player lookup (ms)
local cachedRecipeResponse = nil -- Cached recipe response for admin:getRecipes
local cachedStationResponse = nil -- Cached station response for admin:getStations
local stationCacheExpiry = 0 -- Expiry timestamp for station cache (TTL fallback for volatile fields)
local STATION_CACHE_TTL = 5000 -- Fallback TTL for station cache to refresh ownerOnline/queueCount (ms)
local cachedTypesResponse = nil -- Cached workbench types for admin:getWorkbenchTypes
local cachedLevelConfig = nil -- Cached level config for admin:getLevelConfig
local cachedTechTreeResponse = nil -- Cached tech tree response for admin:getTechTrees
local cachedAdminRecipes = nil -- Cached admin recipes for getAdminRecipes (player connect)
local cachedAdminTechTrees = nil -- Cached admin tech trees for getAdminTechTrees (player connect)
local adminRecipeDbKeys = nil -- Lazy-loaded in-memory set of recipe IDs with rows in sd_crafting_admin

--- Normalize a job/gang value: empty tables become nil (no restriction)
--- For override persistence, pass asOverride=true to get false instead of nil
---@param val any The job or gang value from the client
---@param asOverride? boolean If true, returns false for empty (persists in JSON as explicit clear)
---@return any normalized nil/false if empty, otherwise the original value
local function NormalizeJobGang(val, asOverride)
    if type(val) == 'table' and next(val) == nil then
        return asOverride and false or nil
    end
    return val
end

--- Check if a player has admin permission (ACE check for craftadmin command)
---@param source number Player server ID
---@return boolean isAdmin Whether the player has admin permission
local function IsAdmin(source)
    return IsPlayerAceAllowed(source, 'command.craftadmin')
end

--- Insert or update a row in sd_crafting_admin (async, fire-and-forget)
---@param category string Row category (recipe, table, type, station, override, techtree)
---@param key string Unique key within category
---@param data string|nil JSON-encoded data string (nil stores NULL)
local function AdminUpsert(category, key, data)
    MySQL.query.await('INSERT INTO sd_crafting_admin (category, `key`, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
        category, key, data
    })
end

--- Delete a row from sd_crafting_admin by category and key (async)
---@param category string Row category
---@param key string Unique key within category
local function AdminDelete(category, key)
    MySQL.query('DELETE FROM sd_crafting_admin WHERE category = ? AND `key` = ?', {
        category, key
    })
end

--- Insert a row only if it doesn't already exist (async, fire-and-forget)
---@param category string Row category
---@param key string Unique key within category
---@param data string|nil JSON-encoded data string
local function AdminInsertIgnore(category, key, data)
    MySQL.query('INSERT IGNORE INTO sd_crafting_admin (category, `key`, data) VALUES (?, ?, ?)', {
        category, key, data
    })
end

--- Build a lookup table of online player identifiers to their source IDs and names
---@return table<string, { source: number, name: string }> onlineLookup
local function BuildOnlinePlayerLookup()
    local lookup = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        local ident = GetIdentifier(pid)
        if ident then
            lookup[ident] = {
                source = pid,
                name = GetPlayerName(pid) or 'Unknown',
                charName = GetPlayerFullName(pid) or nil,
            }
        end
    end
    return lookup
end

--- Get cached online player lookup (rebuilds if cache expired)
---@return table<string, { source: number, name: string, charName: string|nil }> onlineLookup
local function GetOnlinePlayerLookup()
    local now = GetGameTimer()
    if cachedOnlineLookup and now < onlineLookupExpiry then
        return cachedOnlineLookup
    end
    cachedOnlineLookup = BuildOnlinePlayerLookup()
    onlineLookupExpiry = now + ONLINE_LOOKUP_TTL
    return cachedOnlineLookup
end

--- Find the server source ID for an online player by identifier (uses cached lookup)
---@param identifier string Player identifier
---@return number|nil source Player source ID or nil if offline
local function FindOnlineSource(identifier)
    local lookup = GetOnlinePlayerLookup()
    local entry = lookup[identifier]
    return entry and entry.source or nil
end

--- Send the current personal queue to a player's client so it can sync
---@param identifier string Player identifier
---@param targetSource number Player source ID
local function SyncPersonalQueueToClient(identifier, targetSource)
    local qData = ServerProcessedQueues[identifier] or PlayerCraftingQueues[identifier]
    local queue = (qData and qData.queue) or {}
    TriggerClientEvent('sd-crafting:client:adminSyncPersonalQueue', targetSource, queue)
end

--- Refund recipe ingredients to staging inventory or player inventory (matches normal refund logic)
---@param targetSource number Player source ID (online)
---@param stationId string|nil Station ID for staging lookup
---@param recipe table Recipe with ingredients array
---@param quantity number Quantity multiplier
local function AdminRefundIngredients(targetSource, stationId, recipe, quantity)
    local useStaging = Config.InventoryPanel and Config.InventoryPanel.enabled
    local stagingKey = useStaging and stationId and GetStagingKey(targetSource, stationId) or nil

    for _, ingredient in ipairs(recipe.ingredients or {}) do
        local refundAmount = ingredient.amount * quantity
        if useStaging and stationId and stagingKey then
            local itemLabel = ingredient.label or Inventory.GetItemLabel(ingredient.item) or ingredient.item
            AddToStaging(stationId, stagingKey, ingredient.item, itemLabel, refundAmount)
        else
            Inventory.AddItem(targetSource, ingredient.item, refundAmount)
        end
    end

    if recipe.cost and recipe.cost > 0 then
        Money.AddMoney(targetSource, 'cash', recipe.cost * quantity)
    end

    if useStaging and stationId then
        BroadcastStagedItemsUpdate(stationId)
    end
end

--- Give crafted output to staging inventory or player inventory (matches normal completion logic)
---@param targetSource number Player source ID (online)
---@param stationId string|nil Station ID for staging lookup
---@param recipe table Recipe with name, outputAmount, metadata
---@param quantity number Quantity multiplier
local function AdminGiveOutput(targetSource, stationId, recipe, quantity)
    local outputAmount = (recipe.outputAmount or 1) * quantity
    local itemName = recipe.name or recipe.id
    local shouldAddToStash = Config.AddOutputToStash
    local success = false

    if shouldAddToStash and stationId then
        local stagingKey = GetStagingKey(targetSource, stationId)
        local itemLabel = Inventory.GetItemLabel(itemName) or itemName
        success = AddToStaging(stationId, stagingKey, itemName, itemLabel, outputAmount, nil, nil, recipe.metadata)
        if success then
            BroadcastStagedItemsUpdate(stationId)
        end
    end

    if not success then
        if recipe.metadata then
            Inventory.AddItemWithMetadata(targetSource, itemName, outputAmount, recipe.metadata)
        else
            Inventory.AddItem(targetSource, itemName, outputAmount)
        end
    end
end

--- Ensure a player's data is loaded into the in-memory cache (loads from DB if needed)
---@param identifier string Player identifier
---@return table|nil data Player data or nil if not found
local function EnsurePlayerDataLoaded(identifier)
    if PlayerData[identifier] then
        return PlayerData[identifier]
    end

    -- Load from database
    local result = MySQL.query.await('SELECT data FROM sd_crafting_players WHERE identifier = ?', { identifier })
    if result and result[1] then
        local data = json.decode(result[1].data) or {}
        -- Apply defaults for missing fields
        if not data.xp then data.xp = 0 end
        if not data.level then data.level = 1 end
        if not data.tech_points then data.tech_points = 0 end
        if not data.unlocked_nodes then data.unlocked_nodes = {} end
        if not data.workbench_levels then data.workbench_levels = {} end
        PlayerData[identifier] = data
        return data
    end

    return nil
end

--- Invalidate the cached recipe response (call after any recipe mutation)
local function InvalidateRecipeCache()
    cachedRecipeResponse = nil
    cachedAdminRecipes = nil
end

--- Invalidate the cached station response (call after any station mutation)
local function InvalidateStationCache()
    cachedStationResponse = nil
    stationCacheExpiry = 0
end

--- Invalidate the cached workbench types response (call after type or station mutations)
local function InvalidateTypesCache()
    cachedTypesResponse = nil
end

--- Invalidate the cached level config (call after type level config changes)
local function InvalidateLevelConfigCache()
    cachedLevelConfig = nil
end

--- Invalidate the cached tech tree response (call after any tech tree mutation)
local function InvalidateTechTreeCache()
    cachedTechTreeResponse = nil
    cachedAdminTechTrees = nil
end

--- Get the in-memory set of recipe IDs that have rows in sd_crafting_admin (lazy-loaded from DB)
---@return table<string, boolean> set
local function GetAdminRecipeDbKeys()
    if adminRecipeDbKeys then return adminRecipeDbKeys end
    adminRecipeDbKeys = {}
    local rows = MySQL.query.await("SELECT `key` FROM sd_crafting_admin WHERE category = 'recipe'")
    if rows then
        for _, row in ipairs(rows) do
            adminRecipeDbKeys[row.key] = true
        end
    end
    return adminRecipeDbKeys
end

--- Admin command to place a workbench (uses object_gizmo or raycast based on Config.useGizmo)
local placeCmd = Config.Commands and Config.Commands.placeWorkbench or 'placeworkbench'
lib.addCommand(placeCmd, {
    help = 'Place a workbench prop and get config coordinates',
    params = {
        {
            name = 'model',
            type = 'string',
            help = 'Prop model name (default: prop_tool_bench02)',
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local model = args.model or 'prop_tool_bench02'
    TriggerClientEvent('sd-crafting:client:placeWorkbench', source, model)
end)

--- Admin command to open the crafting admin panel
local adminCmd = Config.Commands and Config.Commands.craftAdmin or 'craftadmin'
lib.addCommand(adminCmd, {
    help = 'Open the crafting admin panel',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('sd-crafting:client:openAdmin', source)
end)

--- Admin command to simulate a disconnect+reconnect cycle for testing queue persistence
--- Runs the real disconnect logic then triggers LoadSavedQueue on the client
lib.addCommand('craftsimrelog', {
    help = 'Simulate leaving and rejoining to test craft queue persistence',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    print('[SD-CRAFTING] craftsimrelog: Simulating disconnect for player', source)

    -- Close the crafting UI and clear client state first
    TriggerClientEvent('sd-crafting:client:forceClose', source)

    -- Run the real disconnect logic (same function playerDropped calls)
    HandlePlayerCraftingDisconnect(source)

    print('[SD-CRAFTING] craftsimrelog: Disconnect complete. Server processing queues. Reconnect in 2s...')

    -- Simulate reconnect after a short delay
    SetTimeout(2000, function()
        print('[SD-CRAFTING] craftsimrelog: Simulating reconnect for player', source)
        TriggerClientEvent('sd-crafting:client:simulateReconnect', source)
    end)
end)

--- Get paginated players with crafting data for admin panel (server-side search + pagination)
---@param source number Player server ID requesting
---@param data table|nil Pagination options { page?: number, limit?: number, search?: string }
---@return table|nil result { players: table[], total: number, page: number, totalPages: number } or nil if not admin
lib.callback.register('sd-crafting:server:admin:getPlayers', function(source, data)
    if not IsAdmin(source) then return nil end

    local page = (data and data.page) or 1
    local limit = (data and data.limit) or 50
    local search = data and data.search or ''
    local offset = (page - 1) * limit

    local onlineLookup = GetOnlinePlayerLookup()

    -- Build WHERE clause for search
    local whereClause = ''
    local params = {}
    if search ~= '' then
        local searchLower = search:lower()
        -- Find online players matching by name, charName, or serverId
        local matchedIdentifiers = {}
        for ident, info in pairs(onlineLookup) do
            if (info.name and info.name:lower():find(searchLower, 1, true))
                or (info.charName and info.charName:lower():find(searchLower, 1, true))
                or tostring(info.source) == search then
                matchedIdentifiers[#matchedIdentifiers + 1] = ident
            end
        end

        whereClause = ' WHERE identifier LIKE ?'
        params[#params + 1] = '%' .. search .. '%'

        if #matchedIdentifiers > 0 then
            local placeholders = {}
            for _, ident in ipairs(matchedIdentifiers) do
                placeholders[#placeholders + 1] = '?'
                params[#params + 1] = ident
            end
            whereClause = whereClause .. ' OR identifier IN (' .. table.concat(placeholders, ', ') .. ')'
        end
    end

    -- Count total matching rows
    local countResult = MySQL.query.await('SELECT COUNT(*) as total FROM sd_crafting_players' .. whereClause, params)
    local total = countResult and countResult[1] and countResult[1].total or 0
    local totalPages = math.ceil(total / limit)
    if totalPages < 1 then totalPages = 1 end

    -- Fetch current page (copy params and append limit/offset)
    local selectParams = {}
    for _, v in ipairs(params) do selectParams[#selectParams + 1] = v end
    selectParams[#selectParams + 1] = limit
    selectParams[#selectParams + 1] = offset

    local dbPlayers = MySQL.query.await(
        'SELECT identifier, data, updated_at FROM sd_crafting_players' .. whereClause .. ' ORDER BY updated_at DESC LIMIT ? OFFSET ?',
        selectParams
    )

    local players = {}
    if dbPlayers then
        for _, row in ipairs(dbPlayers) do
            local identifier = row.identifier
            local rowData = json.decode(row.data) or {}

            -- Use in-memory cache if available (more up-to-date)
            if PlayerData[identifier] then
                rowData = PlayerData[identifier]
            end

            local online = onlineLookup[identifier]
            local hasQueue = PlayerCraftingQueues[identifier] and #(PlayerCraftingQueues[identifier].queue or {}) > 0

            players[#players + 1] = {
                identifier = identifier,
                xp = rowData.xp or 0,
                level = rowData.level or 1,
                tech_points = rowData.tech_points or 0,
                workbench_levels = rowData.workbench_levels or {},
                workbench_tech = rowData.workbench_tech or {},
                unlocked_nodes = rowData.unlocked_nodes or {},
                online = online ~= nil,
                playerName = online and online.name or nil,
                charName = online and online.charName or nil,
                serverId = online and online.source or nil,
                hasQueue = hasQueue,
                lastSeen = row.updated_at,
            }
        end
    end

    return {
        players = players,
        total = total,
        page = page,
        totalPages = totalPages,
    }
end)

--- Get detailed data for a specific player by identifier (loads from DB if not cached)
---@param source number Player server ID requesting
---@param identifier string Player identifier to look up
---@return table|nil playerDetail Full player data or nil if not found/not admin
lib.callback.register('sd-crafting:server:admin:getPlayerDetail', function(source, identifier)
    if not IsAdmin(source) then return nil end
    if not identifier then return nil end

    local data = EnsurePlayerDataLoaded(identifier)
    if not data then return nil end

    -- Gather online info
    local onlineLookup = GetOnlinePlayerLookup()
    local online = onlineLookup[identifier]

    -- Gather queue data for this player (prefer server-processed data for accurate remainingTime)
    local queueData = nil
    local queueSource = ServerProcessedQueues[identifier] or PlayerCraftingQueues[identifier]
    if queueSource then
        local q = queueSource
        local queueItems = {}
        for _, item in ipairs(q.queue or {}) do
            table.insert(queueItems, {
                id = item.id,
                recipeId = item.recipeId,
                recipeName = item.recipeName or item.recipeId,
                quantity = item.quantity or 1,
                startTime = item.startTime,
                totalTime = item.totalTime,
                remainingTime = item.remainingTime,
                stationId = item.stationId or q.stationId,
                workbenchType = item.workbenchType or q.workbenchType,
            })
        end
        queueData = {
            queue = queueItems,
            stationId = q.stationId,
            workbenchType = q.workbenchType,
        }
    end

    -- Count owned stations and collect shared workbench tech for accessible benches (owner or permission)
    local ownedStations = 0
    local accessibleStationTech = {}
    local seenWorkbenches = {}
    for _, wb in pairs(PlacedWorkbenches) do
        local isOwner = wb.owner == identifier
        local hasPermission = false
        if not isOwner and wb.permissions then
            for _, perm in ipairs(wb.permissions) do
                if perm.identifier == identifier then
                    hasPermission = true
                    break
                end
            end
        end
        if isOwner then ownedStations = ownedStations + 1 end
        if (isOwner or hasPermission) and not seenWorkbenches[wb.id] then
            seenWorkbenches[wb.id] = true
            -- Resolve sharedTech for this bench
            local isShared
            if wb.sharedTech ~= nil then
                isShared = wb.sharedTech
            else
                isShared = TechTrees and TechTrees.sharedPlacedWorkbench and TechTrees.sharedPlacedWorkbench.enabled or false
            end
            if isShared then
                local techData = LoadSharedWorkbenchTech(wb.id)
                if techData then
                    table.insert(accessibleStationTech, {
                        workbenchId = wb.id,
                        stationKey = 'placed_' .. wb.id,
                        type = wb.type or 'basic',
                        tech_points = techData.tech_points or 0,
                        unlocked_nodes = techData.unlocked_nodes or {},
                        isOwner = isOwner,
                        label = wb.label or (wb.item and Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[wb.item] and Config.PlaceableWorkbenches[wb.item].label) or ('Placed #' .. wb.id),
                    })
                end
            end
        end
    end

    return {
        identifier = identifier,
        xp = data.xp or 0,
        level = data.level or 1,
        tech_points = data.tech_points or 0,
        workbench_levels = data.workbench_levels or {},
        workbench_tech = data.workbench_tech or {},
        unlocked_nodes = data.unlocked_nodes or {},
        accessible_station_tech = accessibleStationTech,
        queue = queueData,
        online = online ~= nil,
        playerName = online and online.name or nil,
        charName = online and online.charName or nil,
        serverId = online and online.source or nil,
        ownedStations = ownedStations,
    }
end)

--- Get level XP thresholds for all workbench types (used by admin panel for XP↔Level sync)
---@param source number Player server ID requesting
---@return table|nil levelConfigs Map of workbench type name to { levels, maxLevel }
lib.callback.register('sd-crafting:server:admin:getLevelConfig', function(source)
    if not IsAdmin(source) then return nil end
    if cachedLevelConfig then return cachedLevelConfig end

    local result = {}
    local allTypes = GetAllWorkbenchTypes()

    for _, wbType in ipairs(allTypes) do
        local typeConfig = Config.Leveling and Config.Leveling.workbenchTypes and Config.Leveling.workbenchTypes[wbType]
        if typeConfig then
            result[wbType] = {
                levels = typeConfig.levels or (Config.Leveling and Config.Leveling.levels) or { [1] = 0 },
                maxLevel = typeConfig.maxLevel or (Config.Leveling and Config.Leveling.maxLevel) or 10,
            }
        elseif AdminTypes[wbType] and AdminTypes[wbType].levels then
            result[wbType] = {
                levels = AdminTypes[wbType].levels,
                maxLevel = AdminTypes[wbType].maxLevel or (Config.Leveling and Config.Leveling.maxLevel) or 10,
            }
        else
            result[wbType] = {
                levels = (Config.Leveling and Config.Leveling.levels) or { [1] = 0 },
                maxLevel = (Config.Leveling and Config.Leveling.maxLevel) or 10,
            }
        end
    end

    cachedLevelConfig = result
    return result
end)

--- Update a player's level, XP, and tech points from admin panel
---@param source number Player server ID requesting
---@param data table Contains identifier, xp, level, workbenchType (optional), tech_points (optional), workbench_tech_points (optional table of { type, points })
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updatePlayer', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier then return false end

    local identifier = data.identifier

    -- Ensure data is loaded from DB if not in cache
    if not EnsurePlayerDataLoaded(identifier) then return false end

    local perWorkbench = Config.Leveling and Config.Leveling.perWorkbenchType

    if perWorkbench and data.workbenchType and PlayerData[identifier].workbench_levels then
        if not PlayerData[identifier].workbench_levels[data.workbenchType] then
            PlayerData[identifier].workbench_levels[data.workbenchType] = { xp = 0, level = 1 }
        end
        PlayerData[identifier].workbench_levels[data.workbenchType].xp = data.xp or 0
        PlayerData[identifier].workbench_levels[data.workbenchType].level = data.level or 1
    else
        PlayerData[identifier].xp = data.xp or 0
        PlayerData[identifier].level = data.level or 1
    end

    return SavePlayerData(identifier)
end)

--- Reset a player's crafting data to defaults
---@param source number Player server ID requesting
---@param identifier string Player identifier to reset
---@return boolean success Whether the reset was successful
lib.callback.register('sd-crafting:server:admin:resetPlayer', function(source, identifier)
    if not IsAdmin(source) then return false end
    if not identifier then return false end

    -- Ensure data is loaded so we have a cache entry to update
    if not EnsurePlayerDataLoaded(identifier) then
        -- Player exists in DB but not cached - check DB
        local result = MySQL.query.await('SELECT identifier FROM sd_crafting_players WHERE identifier = ?', { identifier })
        if not result or not result[1] then return false end
    end

    PlayerData[identifier] = {
        xp = 0,
        level = 1,
        tech_points = 0,
        unlocked_nodes = {},
        workbench_levels = {},
    }

    return SavePlayerData(identifier)
end)

--- Toggle a tech tree node for a player (unlock/lock)
---@param source number Player server ID requesting
---@param data table Contains identifier and nodeId
---@return boolean success Whether the toggle was successful
---@return boolean|nil isUnlocked New unlocked state of the node
lib.callback.register('sd-crafting:server:admin:toggleBlueprint', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier or not data.nodeId then return false end

    local identifier = data.identifier
    if not EnsurePlayerDataLoaded(identifier) then return false end

    if not PlayerData[identifier].unlocked_nodes then
        PlayerData[identifier].unlocked_nodes = {}
    end

    local isUnlocked
    if PlayerData[identifier].unlocked_nodes[data.nodeId] then
        PlayerData[identifier].unlocked_nodes[data.nodeId] = nil
        isUnlocked = false
    else
        PlayerData[identifier].unlocked_nodes[data.nodeId] = true
        isUnlocked = true
    end

    SavePlayerData(identifier)
    return true, isUnlocked
end)

--- Get all active crafting queues across all players for admin panel
---@param source number Player server ID requesting
---@return table|nil queues Array of queue entries or nil if not admin
--- Reset a player's personal tech tree progress (unlocked_nodes + per-type workbench_tech unlocked_nodes)
---@param source number Player server ID requesting
---@param identifier string Player identifier to reset
---@return boolean success Whether the reset was successful
lib.callback.register('sd-crafting:server:admin:resetPersonalTechNodes', function(source, identifier)
    if not IsAdmin(source) then return false end
    if not identifier then return false end
    if not EnsurePlayerDataLoaded(identifier) then return false end

    -- Clear global unlocked nodes
    PlayerData[identifier].unlocked_nodes = {}

    -- Clear per-type workbench tech unlocked nodes (keep tech_points intact)
    if PlayerData[identifier].workbench_tech then
        for wbType, techData in pairs(PlayerData[identifier].workbench_tech) do
            techData.unlocked_nodes = {}
        end
    end

    debugPrint('Admin reset personal tech nodes for', identifier)
    return SavePlayerData(identifier)
end)

--- Reset a player's personal tech nodes for a specific workbench type only
---@param source number Player server ID requesting
---@param data table Contains identifier and workbenchType fields
---@return boolean success Whether the reset was successful
lib.callback.register('sd-crafting:server:admin:resetPersonalTypeTechNodes', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier or not data.workbenchType then return false end

    local identifier = data.identifier
    if not EnsurePlayerDataLoaded(identifier) then return false end

    if PlayerData[identifier].workbench_tech and PlayerData[identifier].workbench_tech[data.workbenchType] then
        PlayerData[identifier].workbench_tech[data.workbenchType].unlocked_nodes = {}
    end

    debugPrint('Admin reset personal tech nodes for', identifier, 'type', data.workbenchType)
    return SavePlayerData(identifier)
end)

--- Reset shared tech tree progress for a specific placed workbench
---@param source number Player server ID requesting
---@param data table Contains stationKey field
---@return boolean success Whether the reset was successful
lib.callback.register('sd-crafting:server:admin:resetStationTechNodes', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.stationKey then return false end

    local stationKey = data.stationKey
    local placedId = stationKey:match('^placed_(%d+)$')
    local storageKey = placedId and tonumber(placedId) or stationKey

    local techData = LoadSharedWorkbenchTech(storageKey)
    if not techData then return false end

    -- Clear unlocked nodes (keep tech_points intact)
    techData.unlocked_nodes = {}

    debugPrint('Admin reset station tech nodes for', stationKey)
    return SaveSharedWorkbenchTech(storageKey)
end)

lib.callback.register('sd-crafting:server:admin:getQueues', function(source)
    if not IsAdmin(source) then return nil end

    local onlineLookup = GetOnlinePlayerLookup()
    local queues = {}

    -- Build set of identifiers being server-processed (have more accurate remainingTime)
    local serverProcessed = {}
    for identifier, _ in pairs(ServerProcessedQueues) do
        serverProcessed[identifier] = true
    end

    -- Personal player queues (skip if server-processed queue exists with fresher data)
    for identifier, qData in pairs(PlayerCraftingQueues) do
        if serverProcessed[identifier] then goto nextPlayer end
        local online = onlineLookup[identifier]
        local ownerName = online and (online.charName or online.name) or nil
        for _, item in ipairs(qData.queue or {}) do
            local recipe = item.recipe or GetRecipeById(item.recipeId or '')
            local recipeName = recipe and (recipe.label or Inventory.GetItemLabel(recipe.name) or recipe.name or recipe.id) or (item.recipeName or item.recipeId)
            local ingredients = {}
            if recipe and recipe.ingredients then
                for _, ing in ipairs(recipe.ingredients) do
                    ingredients[#ingredients + 1] = {
                        item = ing.item,
                        label = ing.label or Inventory.GetItemLabel(ing.item) or ing.item,
                        amount = ing.amount,
                    }
                end
            end
            table.insert(queues, {
                type = 'personal',
                identifier = identifier,
                ownerName = ownerName,
                id = item.id,
                recipeId = recipe and recipe.id or item.recipeId,
                recipeName = recipeName,
                recipeLabel = recipeName,
                outputAmount = recipe and recipe.outputAmount or 1,
                ingredients = ingredients,
                quantity = item.quantity or 1,
                startTime = item.startTime,
                totalTime = item.totalTime,
                remainingTime = item.remainingTime,
                stationId = item.stationId or qData.stationId,
                workbenchType = item.workbenchType or qData.workbenchType,
                craftToken = item.craftToken,
            })
        end
        ::nextPlayer::
    end

    -- Server-processed queues (actively ticking down while player is offline)
    for identifier, serverData in pairs(ServerProcessedQueues) do
        local online = onlineLookup[identifier]
        local ownerName = online and (online.charName or online.name) or nil
        for _, item in ipairs(serverData.queue or {}) do
            local recipe = item.recipe or GetRecipeById(item.recipeId or '')
            local recipeName = recipe and (recipe.label or Inventory.GetItemLabel(recipe.name) or recipe.name or recipe.id) or (item.recipeName or item.recipeId)
            local ingredients = {}
            if recipe and recipe.ingredients then
                for _, ing in ipairs(recipe.ingredients) do
                    ingredients[#ingredients + 1] = {
                        item = ing.item,
                        label = ing.label or Inventory.GetItemLabel(ing.item) or ing.item,
                        amount = ing.amount,
                    }
                end
            end
            table.insert(queues, {
                type = 'personal',
                identifier = identifier,
                ownerName = ownerName,
                id = item.id,
                recipeId = recipe and recipe.id or item.recipeId,
                recipeName = recipeName,
                recipeLabel = recipeName,
                outputAmount = recipe and recipe.outputAmount or 1,
                ingredients = ingredients,
                quantity = item.quantity or 1,
                startTime = item.startTime,
                totalTime = item.totalTime,
                remainingTime = item.remainingTime,
                stationId = item.stationId or serverData.stationId,
                workbenchType = item.workbenchType,
                craftToken = item.craftToken,
            })
        end
    end

    -- Shared queues
    for stationId, stationQueue in pairs(SharedQueues) do
        for _, item in ipairs(stationQueue) do
            local recipe = item.recipe or GetRecipeById(item.recipeId or '')
            local recipeName = recipe and (recipe.label or Inventory.GetItemLabel(recipe.name) or recipe.name or recipe.id) or 'unknown'
            local ingredients = {}
            if recipe and recipe.ingredients then
                for _, ing in ipairs(recipe.ingredients) do
                    ingredients[#ingredients + 1] = {
                        item = ing.item,
                        label = ing.label or Inventory.GetItemLabel(ing.item) or ing.item,
                        amount = ing.amount,
                    }
                end
            end
            table.insert(queues, {
                type = 'shared',
                identifier = item.owner,
                ownerName = item.ownerName,
                id = item.id,
                recipeId = recipe and recipe.id or 'unknown',
                recipeName = recipeName,
                recipeLabel = recipeName,
                outputAmount = recipe and recipe.outputAmount or 1,
                ingredients = ingredients,
                quantity = item.quantity or 1,
                startTime = item.startTime,
                totalTime = item.totalTime,
                remainingTime = item.remainingTime,
                stationId = stationId,
            })
        end
    end

    return queues
end)

--- Admin cancel a queue item and refund ingredients to the player
---@param source number Player server ID requesting
---@param data table Contains identifier, itemId, type ('personal' or 'shared'), stationId
---@return boolean success Whether the cancellation was successful
lib.callback.register('sd-crafting:server:admin:cancelQueue', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier or not data.itemId then return false end

    local identifier = data.identifier
    local itemId = data.itemId

    if data.type == 'shared' and data.stationId then
        -- Handle shared queue cancellation
        local stationQueue = SharedQueues[data.stationId]
        if not stationQueue then return false end

        for i, item in ipairs(stationQueue) do
            if item.id == itemId then
                local recipe = item.recipe or GetRecipeById(item.recipeId or '')
                if recipe then
                    local targetSource = FindOnlineSource(item.owner)
                    if targetSource then
                        AdminRefundIngredients(targetSource, data.stationId, recipe, item.quantity or 1)
                        TriggerClientEvent('sd-crafting:client:adminRefreshInventory', targetSource)
                    end
                end
                table.remove(stationQueue, i)
                DirtySharedQueues[data.stationId] = true
                BroadcastQueueUpdate(data.stationId)
                return true
            end
        end
        return false
    else
        -- Handle personal queue cancellation
        local qData = PlayerCraftingQueues[identifier]
        if not qData or not qData.queue then return false end

        for i, item in ipairs(qData.queue) do
            if item.id == itemId then
                local recipe = item.recipe or GetRecipeById(item.recipeId or '')
                local itemStation = item.stationId or qData.stationId
                if recipe then
                    local targetSource = FindOnlineSource(identifier)
                    if targetSource then
                        AdminRefundIngredients(targetSource, itemStation, recipe, item.quantity or 1)
                        TriggerClientEvent('sd-crafting:client:adminRefreshInventory', targetSource)
                    end
                end
                table.remove(qData.queue, i)
                DirtyPlayerQueues[identifier] = true
                local playerSource = FindOnlineSource(identifier)
                if playerSource then
                    SyncPersonalQueueToClient(identifier, playerSource)
                end
                return true
            end
        end
        return false
    end
end)

--- Admin force-complete a queue item (give output immediately, player must be online)
---@param source number Player server ID requesting
---@param data table Contains identifier, itemId, type ('personal' or 'shared'), stationId
---@return boolean success Whether the force-completion was successful
lib.callback.register('sd-crafting:server:admin:forceCompleteQueue', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier or not data.itemId then return false end

    local identifier = data.identifier
    local itemId = data.itemId

    if data.type == 'shared' and data.stationId then
        local stationQueue = SharedQueues[data.stationId]
        if not stationQueue then return false end

        for i, item in ipairs(stationQueue) do
            if item.id == itemId then
                local targetSource = FindOnlineSource(item.owner)
                if not targetSource then return false end

                local recipe = item.recipe or GetRecipeById(item.recipeId or '')
                if recipe then
                    AdminGiveOutput(targetSource, data.stationId, recipe, item.quantity or 1)
                    TriggerClientEvent('sd-crafting:client:adminRefreshInventory', targetSource)
                end
                table.remove(stationQueue, i)
                DirtySharedQueues[data.stationId] = true
                BroadcastQueueUpdate(data.stationId)
                return true
            end
        end
        return false
    else
        local targetSource = FindOnlineSource(identifier)
        if not targetSource then return false end

        local qData = PlayerCraftingQueues[identifier]
        if not qData or not qData.queue then return false end

        for i, item in ipairs(qData.queue) do
            if item.id == itemId then
                local recipe = item.recipe or GetRecipeById(item.recipeId or '')
                local itemStation = item.stationId or qData.stationId
                if recipe then
                    AdminGiveOutput(targetSource, itemStation, recipe, item.quantity or 1)
                    TriggerClientEvent('sd-crafting:client:adminRefreshInventory', targetSource)
                end
                table.remove(qData.queue, i)
                DirtyPlayerQueues[identifier] = true
                SyncPersonalQueueToClient(identifier, targetSource)
                return true
            end
        end
        return false
    end
end)

--- Admin remove a queue item without refunding
---@param source number Player server ID requesting
---@param data table Contains identifier, itemId, type ('personal' or 'shared'), stationId
---@return boolean success Whether the removal was successful
lib.callback.register('sd-crafting:server:admin:removeQueue', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier or not data.itemId then return false end

    if data.type == 'shared' and data.stationId then
        local stationQueue = SharedQueues[data.stationId]
        if not stationQueue then return false end

        for i, item in ipairs(stationQueue) do
            if item.id == data.itemId then
                table.remove(stationQueue, i)
                DirtySharedQueues[data.stationId] = true
                BroadcastQueueUpdate(data.stationId)
                return true
            end
        end
        return false
    else
        local qData = PlayerCraftingQueues[data.identifier]
        if not qData or not qData.queue then return false end

        for i, item in ipairs(qData.queue) do
            if item.id == data.itemId then
                table.remove(qData.queue, i)
                DirtyPlayerQueues[data.identifier] = true
                local playerSource = FindOnlineSource(data.identifier)
                if playerSource then
                    SyncPersonalQueueToClient(data.identifier, playerSource)
                end
                return true
            end
        end
        return false
    end
end)

--- Resolve the effective sharedCrafting boolean for a station
---@param stationKey string Station identifier (e.g. 'placed_42', 'my_station', 'admin_station_...')
---@return boolean isShared Whether shared crafting is enabled for this station
local function IsSharedCraftingForStation(stationKey)
    local globalBehavior = Config.CraftingBehavior and Config.CraftingBehavior.sharedCrafting
    local stationBehavior = nil

    if stationKey and stationKey:find('^placed_') then
        local placedId = tonumber(stationKey:sub(8))
        if placedId and PlacedWorkbenches[placedId] then
            -- Check placed workbench override first
            if PlacedWorkbenches[placedId].CraftingBehavior and PlacedWorkbenches[placedId].CraftingBehavior.sharedCrafting ~= nil then
                stationBehavior = PlacedWorkbenches[placedId].CraftingBehavior.sharedCrafting
            else
                -- Fall back to placeable workbench type config
                local item = PlacedWorkbenches[placedId].item
                if item and Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[item] and Config.PlaceableWorkbenches[item].CraftingBehavior then
                    stationBehavior = Config.PlaceableWorkbenches[item].CraftingBehavior.sharedCrafting
                end
            end
        end
        -- Resolve: station override > global > false (explicit if/else to handle false correctly)
        local resolved
        if stationBehavior ~= nil then
            resolved = stationBehavior
        else
            resolved = globalBehavior
        end
        if type(resolved) == 'boolean' then return resolved end
        if type(resolved) == 'table' then return resolved.placed or false end
        return false
    else
        -- Static or admin station
        local station = (Config.Stations and Config.Stations[stationKey]) or AdminStations[stationKey]
        if station and station.CraftingBehavior and station.CraftingBehavior.sharedCrafting ~= nil then
            stationBehavior = station.CraftingBehavior.sharedCrafting
        end
        local resolved
        if stationBehavior ~= nil then
            resolved = stationBehavior
        else
            resolved = globalBehavior
        end
        if type(resolved) == 'boolean' then return resolved end
        if type(resolved) == 'table' then return resolved.static or false end
        return false
    end
end

--- Resolve the effective sharedStaging boolean for a station
---@param stationKey string Station identifier
---@return boolean isShared Whether shared staging inventory is enabled for this station
local function IsSharedStagingForStation(stationKey)
    local globalBehavior = Config.InventoryPanel and Config.InventoryPanel.perWorkbench
    local stationBehavior = nil

    if stationKey and stationKey:find('^placed_') then
        local placedId = tonumber(stationKey:sub(8))
        if placedId and PlacedWorkbenches[placedId] then
            if PlacedWorkbenches[placedId].CraftingBehavior and PlacedWorkbenches[placedId].CraftingBehavior.sharedStaging ~= nil then
                stationBehavior = PlacedWorkbenches[placedId].CraftingBehavior.sharedStaging
            else
                local item = PlacedWorkbenches[placedId].item
                if item and Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[item] and Config.PlaceableWorkbenches[item].CraftingBehavior then
                    stationBehavior = Config.PlaceableWorkbenches[item].CraftingBehavior.sharedStaging
                end
            end
        end
        if stationBehavior ~= nil then return stationBehavior end
        if type(globalBehavior) == 'boolean' then return globalBehavior end
        if type(globalBehavior) == 'table' then return globalBehavior.placed or false end
        return false
    else
        local station = (Config.Stations and Config.Stations[stationKey]) or AdminStations[stationKey]
        if station and station.CraftingBehavior and station.CraftingBehavior.sharedStaging ~= nil then
            stationBehavior = station.CraftingBehavior.sharedStaging
        end
        if stationBehavior ~= nil then return stationBehavior end
        if type(globalBehavior) == 'boolean' then return globalBehavior end
        if type(globalBehavior) == 'table' then return globalBehavior.static or false end
        return false
    end
end

--- Get all known workbench types with source info and station usage
---@param source number Player server ID requesting
---@return table|nil types Array of type objects { name, source, stations } or nil if not admin
lib.callback.register('sd-crafting:server:admin:getWorkbenchTypes', function(source)
    if not IsAdmin(source) then return nil end
    if cachedTypesResponse then return cachedTypesResponse end

    local typeMap = {} -- { [typeName] = { name, source, stations = { {key, label} } } }

    --- Helper to ensure a type entry exists in the map
    ---@param name string Type name
    ---@param src string Source identifier ('config' or 'admin')
    local function ensureType(name, src)
        if not typeMap[name] then
            typeMap[name] = { name = name, source = src, stations = {} }
        end
    end

    if Config.Leveling and Config.Leveling.workbenchTypes then
        for typeName, _ in pairs(Config.Leveling.workbenchTypes) do
            ensureType(typeName, 'config')
        end
    end

    for typeName, _ in pairs(AdminTypes) do
        if not typeMap[typeName] then
            ensureType(typeName, 'admin')
        end
    end

    if Config.Stations then
        for key, station in pairs(Config.Stations) do
            local wbType = station.type or 'basic'
            ensureType(wbType, 'config')
            table.insert(typeMap[wbType].stations, { key = key, label = station.label or key })
        end
    end

    for key, station in pairs(AdminStations) do
        local wbType = station.type or 'basic'
        ensureType(wbType, typeMap[wbType] and typeMap[wbType].source or 'config')
        table.insert(typeMap[wbType].stations, { key = key, label = station.label or key })
    end

    if Config.PlaceableWorkbenches then
        for itemName, wb in pairs(Config.PlaceableWorkbenches) do
            local wbType = wb.type or 'basic'
            ensureType(wbType, 'config')
        end
    end

    for id, wb in pairs(PlacedWorkbenches) do
        local wbType = wb.type or 'basic'
        ensureType(wbType, typeMap[wbType] and typeMap[wbType].source or 'config')
        table.insert(typeMap[wbType].stations, { key = 'placed_' .. id, label = wb.label or wb.item or ('Placed #' .. id) })
    end

    local types = {}
    for _, typeData in pairs(typeMap) do
        table.insert(types, typeData)
    end

    table.sort(types, function(a, b) return a.name < b.name end)

    if #types == 0 then
        types = { { name = 'basic', source = 'config', stations = {} } }
    end

    cachedTypesResponse = types
    return types
end)

--- Create a new admin workbench type and persist to database
---@param source number Player server ID requesting
---@param data table Contains typeName field
---@return table|boolean result Success status
lib.callback.register('sd-crafting:server:admin:createType', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.typeName or data.typeName == '' then return false end

    local typeName = data.typeName

    if AdminTypes[typeName] then return { success = false, error = 'Type already exists' } end
    if Config.Leveling and Config.Leveling.workbenchTypes and Config.Leveling.workbenchTypes[typeName] then
        return { success = false, error = 'Type already defined in config' }
    end

    AdminTypes[typeName] = {}
    AdminInsertIgnore('type', typeName, '{}')

    InvalidateTypesCache()
    InvalidateLevelConfigCache()
    debugPrint('Admin created workbench type:', typeName)
    return { success = true }
end)

--- Rename an admin-created workbench type and update all stations using it
---@param source number Player server ID requesting
---@param data table Contains oldName and newName fields
---@return table|boolean result Success status
lib.callback.register('sd-crafting:server:admin:updateType', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.oldName or not data.newName or data.newName == '' then return false end
    if data.oldName == data.newName then return { success = true } end

    local oldName = data.oldName
    local newName = data.newName

    if not AdminTypes[oldName] then
        return { success = false, error = 'Can only rename admin-created types' }
    end

    if AdminTypes[newName] or (Config.Leveling and Config.Leveling.workbenchTypes and Config.Leveling.workbenchTypes[newName]) then
        return { success = false, error = 'Target type name already exists' }
    end

    local oldData = AdminTypes[oldName] or {}
    AdminTypes[oldName] = nil
    AdminTypes[newName] = oldData

    AdminDelete('type', oldName)
    AdminUpsert('type', newName, json.encode(oldData))

    for key, station in pairs(AdminStations) do
        if station.type == oldName then
            station.type = newName
            AdminUpsert('station', key, json.encode(station))
        end
    end

    InvalidateTypesCache()
    InvalidateLevelConfigCache()
    InvalidateStationCache()
    debugPrint('Admin renamed workbench type:', oldName, '->', newName)
    return { success = true }
end)

--- Delete an admin-created workbench type from the database
---@param source number Player server ID requesting
---@param data table Contains typeName field
---@return table|boolean result Success status
lib.callback.register('sd-crafting:server:admin:deleteType', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.typeName or data.typeName == '' then return false end

    local typeName = data.typeName

    if not AdminTypes[typeName] then
        return { success = false, error = 'Can only delete admin-created types' }
    end

    local stationsUsing = 0
    for _, station in pairs(AdminStations) do
        if station.type == typeName then stationsUsing = stationsUsing + 1 end
    end
    if Config.Stations then
        for _, station in pairs(Config.Stations) do
            if station.type == typeName then stationsUsing = stationsUsing + 1 end
        end
    end
    for _, wb in pairs(PlacedWorkbenches) do
        if wb.type == typeName then stationsUsing = stationsUsing + 1 end
    end

    if stationsUsing > 0 then
        return { success = false, error = stationsUsing .. ' station(s) still use this type' }
    end

    AdminTypes[typeName] = nil
    AdminDelete('type', typeName)

    InvalidateTypesCache()
    InvalidateLevelConfigCache()
    debugPrint('Admin deleted workbench type:', typeName)
    return { success = true }
end)

--- Update level configuration for an admin-created workbench type
---@param source number Player server ID requesting
---@param data table Contains typeName, levels (table of level→xp), and maxLevel
---@return table|boolean result Success status
lib.callback.register('sd-crafting:server:admin:updateTypeLevelConfig', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.typeName or not data.levels or not data.maxLevel then return false end

    local typeName = data.typeName

    if not AdminTypes[typeName] then
        return { success = false, error = 'Can only configure levels for admin-created types' }
    end

    -- Normalize level keys from JSON string keys ("1","2") to numeric keys (1,2)
    local normalizedLevels = {}
    for k, v in pairs(data.levels) do
        normalizedLevels[tonumber(k)] = v
    end
    AdminTypes[typeName] = { levels = normalizedLevels, maxLevel = data.maxLevel }
    AdminUpsert('type', typeName, json.encode(AdminTypes[typeName]))

    InvalidateLevelConfigCache()
    RecalcPlayerLevelsForType(typeName)
    debugPrint('Admin updated level config for type:', typeName, 'maxLevel:', data.maxLevel)
    return { success = true }
end)

--- Get all placed workbenches for admin panel
---@param source number Player server ID requesting
---@return table|nil stations Array of workbench data or nil if not admin
lib.callback.register('sd-crafting:server:admin:getStations', function(source)
    if not IsAdmin(source) then return nil end
    if cachedStationResponse and GetGameTimer() < stationCacheExpiry then return cachedStationResponse end

    local onlineLookup = GetOnlinePlayerLookup()
    local stations = {}

    -- Placed workbenches
    for id, wb in pairs(PlacedWorkbenches) do
        local ownerOnline = onlineLookup[wb.owner]
        local sharedQueueCount = 0
        if SharedQueues[tostring(id)] then
            sharedQueueCount = #SharedQueues[tostring(id)]
        end
        local workbenchConfig = Config.PlaceableWorkbenches and Config.PlaceableWorkbenches[wb.item]
        -- Resolve sharedTech: explicit per-bench override takes priority, otherwise fall back to global config
        local resolvedSharedTech
        if wb.sharedTech ~= nil then
            resolvedSharedTech = wb.sharedTech
        else
            resolvedSharedTech = TechTrees and TechTrees.sharedPlacedWorkbench and TechTrees.sharedPlacedWorkbench.enabled or false
        end
        -- Resolve propEnabled: explicit override takes priority, otherwise default to true
        local resolvedPropEnabled = true
        if wb.propEnabled ~= nil then resolvedPropEnabled = wb.propEnabled end
        table.insert(stations, {
            id = id,
            stationKey = 'placed_' .. id,
            isStatic = false,
            isPlaced = true,
            owner = wb.owner,
            ownerName = ownerOnline and ownerOnline.charName or ownerOnline and ownerOnline.name or nil,
            ownerOnline = ownerOnline ~= nil,
            item = wb.item,
            type = wb.type,
            prop = wb.prop and { model = wb.prop, enabled = resolvedPropEnabled } or nil,
            coords = wb.coords and { x = wb.coords.x, y = wb.coords.y, z = wb.coords.z } or nil,
            heading = wb.heading,
            sharedQueueCount = sharedQueueCount,
            sharedCrafting = IsSharedCraftingForStation('placed_' .. id),
            sharedStaging = IsSharedStagingForStation('placed_' .. id),
            sharedTech = resolvedSharedTech,
            label = wb.label or (workbenchConfig and workbenchConfig.label) or wb.item,
            radius = wb.radius,
            recipes = wb.recipes or (workbenchConfig and workbenchConfig.recipes),
            techTrees = wb.techTrees or (workbenchConfig and workbenchConfig.techTrees),
            blip = wb.blip,
            job = wb.job or (workbenchConfig and workbenchConfig.job),
            gang = wb.gang or (workbenchConfig and workbenchConfig.gang),
        })
    end

    -- Static stations from config
    if Config.Stations then
        for key, station in pairs(Config.Stations) do
            local sharedQueueCount = 0
            if SharedQueues[key] then
                sharedQueueCount = #SharedQueues[key]
            end
            table.insert(stations, {
                id = key,
                stationKey = key,
                isStatic = true,
                owner = station.owner or 'config',
                item = station.label or key,
                type = station.type or 'unknown',
                prop = station.prop and { model = station.prop.model, enabled = station.prop.enabled, spawnRadius = station.prop.spawnRadius } or nil,
                coords = station.coords and { x = station.coords.x, y = station.coords.y, z = station.coords.z } or nil,
                heading = station.heading or 0,
                sharedQueueCount = sharedQueueCount,
                sharedCrafting = IsSharedCraftingForStation(key),
                sharedStaging = IsSharedStagingForStation(key),
                sharedTech = station.sharedTech or false,
                label = station.label,
                radius = station.radius,
                recipes = station.recipes,
                techTrees = station.techTrees,
                blip = station.blip,
                job = station.job,
                gang = station.gang,
            })
        end
    end

    -- Admin-created stations from database
    for key, station in pairs(AdminStations) do
        local sharedQueueCount = 0
        if SharedQueues[key] then
            sharedQueueCount = #SharedQueues[key]
        end
        table.insert(stations, {
            id = key,
            stationKey = key,
            isStatic = false,
            isAdmin = true,
            owner = station.owner or 'admin',
            item = station.label or key,
            type = station.type or 'basic',
            prop = station.prop or nil,
            coords = station.coords and { x = station.coords.x, y = station.coords.y, z = station.coords.z } or nil,
            heading = station.heading or 0,
            sharedQueueCount = sharedQueueCount,
            sharedCrafting = IsSharedCraftingForStation(key),
            sharedStaging = IsSharedStagingForStation(key),
            sharedTech = station.sharedTech or false,
            label = station.label,
            radius = station.radius,
            recipes = station.recipes,
            techTrees = station.techTrees,
            blip = station.blip,
            job = station.job,
            gang = station.gang,
        })
    end

    cachedStationResponse = stations
    stationCacheExpiry = GetGameTimer() + STATION_CACHE_TTL
    return stations
end)

--- Get shared tech points for a station (used by admin panel station edit form)
---@param source number Player server ID requesting
---@param stationKey string The station key to look up
---@return table|nil techData Table with tech_points or nil
lib.callback.register('sd-crafting:server:admin:getStationTech', function(source, stationKey)
    if not IsAdmin(source) then return nil end
    if not stationKey then return nil end

    -- Determine the storage key for SharedWorkbenchTech
    local placedId = stationKey:match('^placed_(%d+)$')
    local storageKey = placedId and tonumber(placedId) or stationKey

    local techData = LoadSharedWorkbenchTech(storageKey)
    return { tech_points = techData.tech_points or 0 }
end)

--- Update shared tech points for a station (used by admin panel station edit form)
---@param source number Player server ID requesting
---@param data table Contains stationKey and tech_points
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updateStationTech', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.stationKey or data.tech_points == nil then return false end

    local stationKey = data.stationKey
    local placedId = stationKey:match('^placed_(%d+)$')
    local storageKey = placedId and tonumber(placedId) or stationKey

    local techData = LoadSharedWorkbenchTech(storageKey)
    techData.tech_points = data.tech_points
    return SaveSharedWorkbenchTech(storageKey)
end)

--- Get all players with access to a per-player (non-shared) placed station and their tech points
---@param source number Player server ID requesting
---@param stationKey string The station key (e.g. 'placed_5')
---@return table|nil playersTech Array of { identifier, name, tech_points, isOwner } or nil
lib.callback.register('sd-crafting:server:admin:getStationPlayersTech', function(source, stationKey)
    if not IsAdmin(source) then return nil end
    if not stationKey then return nil end

    local placedId = stationKey:match('^placed_(%d+)$')
    if not placedId then return {} end

    local numericId = tonumber(placedId)
    local workbench = PlacedWorkbenches[numericId]
    if not workbench then return {} end

    local wbType = workbench.type or 'basic'
    local result = {}
    local onlineLookup = GetOnlinePlayerLookup()

    --- Helper to get a player's per-type tech points
    ---@param identifier string Player identifier
    ---@return number techPoints The player's tech points for this workbench type
    local function getPlayerTP(identifier)
        local data = EnsurePlayerDataLoaded(identifier)
        if not data then return 0 end
        if data.workbench_tech and data.workbench_tech[wbType] then
            return data.workbench_tech[wbType].tech_points or 0
        end
        return data.tech_points or 0
    end

    -- Add owner
    local ownerOnline = onlineLookup[workbench.owner]
    table.insert(result, {
        identifier = workbench.owner,
        name = ownerOnline and (ownerOnline.charName or ownerOnline.name) or workbench.ownerName or workbench.owner,
        tech_points = getPlayerTP(workbench.owner),
        isOwner = true,
    })

    -- Add permission holders
    if workbench.permissions then
        for _, perm in ipairs(workbench.permissions) do
            local permOnline = onlineLookup[perm.identifier]
            table.insert(result, {
                identifier = perm.identifier,
                name = permOnline and (permOnline.charName or permOnline.name) or perm.name or perm.identifier,
                tech_points = getPlayerTP(perm.identifier),
                isOwner = false,
            })
        end
    end

    return result
end)

--- Update a specific player's per-type tech points (used by station player tech list)
---@param source number Player server ID requesting
---@param data table Contains identifier, workbenchType, and tech_points
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updatePlayerTechPoints', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.identifier or not data.workbenchType or data.tech_points == nil then return false end

    local identifier = data.identifier
    if not EnsurePlayerDataLoaded(identifier) then return false end

    local perWorkbenchTech = TechTrees and TechTrees.perWorkbenchType
    if perWorkbenchTech then
        if not PlayerData[identifier].workbench_tech then
            PlayerData[identifier].workbench_tech = {}
        end
        if not PlayerData[identifier].workbench_tech[data.workbenchType] then
            PlayerData[identifier].workbench_tech[data.workbenchType] = { tech_points = 0, unlocked_nodes = {} }
        end
        PlayerData[identifier].workbench_tech[data.workbenchType].tech_points = data.tech_points
    else
        PlayerData[identifier].tech_points = data.tech_points
    end

    return SavePlayerData(identifier)
end)

--- Admin delete a placed workbench or admin station
---@param source number Player server ID requesting
---@param workbenchId number|string Workbench ID (numeric for placed, string key for admin)
---@return boolean success Whether the deletion was successful
lib.callback.register('sd-crafting:server:admin:deleteStation', function(source, workbenchId)
    if not IsAdmin(source) then return false end
    if not workbenchId then return false end

    -- Check if it's an admin-created station (string key)
    if type(workbenchId) == 'string' and AdminStations[workbenchId] then
        AdminStations[workbenchId] = nil
        AdminDelete('station', workbenchId)
        TriggerClientEvent('sd-crafting:client:removeAdminStation', -1, workbenchId)
        InvalidateStationCache()
        InvalidateTypesCache()
        debugPrint('Admin deleted admin station', workbenchId)
        return true
    end

    -- Otherwise handle as placed workbench
    if not PlacedWorkbenches[workbenchId] then return false end

    DeletePlacedWorkbench(workbenchId)

    -- Notify all clients to remove the prop
    TriggerClientEvent('sd-crafting:client:removePlacedWorkbench', -1, workbenchId)

    InvalidateStationCache()
    InvalidateTypesCache()
    return true
end)

--- Admin get station coordinates for teleport (authoritative server-side lookup)
--- Checks placed workbenches first, then falls back to static Config.Stations
---@param source number Player server ID requesting
---@param workbenchId number|string Workbench ID (numeric for placed, string key for static)
---@return table|nil coords Station coordinates or nil if not found/not admin
lib.callback.register('sd-crafting:server:admin:getStationCoords', function(source, workbenchId)
    if not IsAdmin(source) then return nil end
    if not workbenchId then return nil end

    -- Check placed workbenches first
    if PlacedWorkbenches[workbenchId] then
        return PlacedWorkbenches[workbenchId].coords
    end

    -- Fallback to static stations from config
    if Config.Stations and Config.Stations[workbenchId] then
        local station = Config.Stations[workbenchId]
        if station.coords then
            return { x = station.coords.x, y = station.coords.y, z = station.coords.z }
        end
    end

    -- Fallback to admin stations
    if AdminStations[workbenchId] then
        local station = AdminStations[workbenchId]
        if station.coords then
            return { x = station.coords.x, y = station.coords.y, z = station.coords.z }
        end
    end

    return nil
end)

--- Get all recipes from all tables for admin panel
---@param source number Player server ID requesting
---@return table|nil recipes Table of recipe tables or nil if not admin
lib.callback.register('sd-crafting:server:admin:getRecipes', function(source)
    if not IsAdmin(source) then return nil end
    if cachedRecipeResponse then return cachedRecipeResponse end

    local result = {}
    for tableName, recipes in pairs(Recipes) do
        result[tableName] = { source = AdminTableNames[tableName] and 'admin' or 'config', recipes = {} }
        for _, recipe in ipairs(recipes) do
            -- Resolve ingredient labels for admin panel display
            local resolvedIngredients = {}
            if recipe.ingredients then
                for _, ing in ipairs(recipe.ingredients) do
                    resolvedIngredients[#resolvedIngredients + 1] = {
                        item = ing.item,
                        label = ing.label or Inventory.GetItemLabel(ing.item) or ing.item,
                        amount = ing.amount,
                    }
                end
            end

            -- Resolve tool labels for admin panel display
            local resolvedTools = nil
            if recipe.tools then
                resolvedTools = {}
                for _, tool in ipairs(recipe.tools) do
                    resolvedTools[#resolvedTools + 1] = {
                        item = tool.item,
                        label = tool.label or Inventory.GetItemLabel(tool.item) or tool.item,
                        amount = tool.amount,
                        consumptionType = tool.consumptionType,
                        durabilityLoss = tool.durabilityLoss,
                        consumeChance = tool.consumeChance,
                    }
                end
            end

            table.insert(result[tableName].recipes, {
                id = recipe.id,
                name = recipe.name,
                label = recipe.label or Inventory.GetItemLabel(recipe.name) or recipe.name,
                craftTime = recipe.craftTime,
                ingredients = resolvedIngredients,
                tools = resolvedTools,
                image = recipe.image,
                category = recipe.category,
                levelRequired = recipe.levelRequired,
                xpReward = recipe.xpReward,
                techPointsReward = recipe.techPointsReward,
                outputAmount = recipe.outputAmount,
                failChance = recipe.failChance,
                blueprint = recipe.blueprint,
                blueprintDurabilityLoss = recipe.blueprintDurabilityLoss,
                cost = recipe.cost,
                enabled = recipe.enabled ~= false,
                metadata = recipe.metadata,
                showMetadata = recipe.showMetadata,
            })
        end
    end

    cachedRecipeResponse = result
    return result
end)

--- Admin update a recipe (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Contains tableName, recipeId, and fields to update
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updateRecipe', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.tableName or not data.recipeId then return false end

    local recipes = Recipes[data.tableName]
    if not recipes then return false end

    for _, recipe in ipairs(recipes) do
        if recipe.id == data.recipeId then
            if data.name ~= nil then recipe.name = data.name end
            if data.label ~= nil then recipe.label = data.label ~= '' and data.label or nil end
            if data.category ~= nil then recipe.category = data.category end
            if data.craftTime ~= nil then recipe.craftTime = data.craftTime end
            if data.levelRequired ~= nil then recipe.levelRequired = data.levelRequired end
            if data.xpReward ~= nil then recipe.xpReward = data.xpReward end
            if data.techPointsReward ~= nil then recipe.techPointsReward = data.techPointsReward end
            if data.outputAmount ~= nil then recipe.outputAmount = data.outputAmount end
            if data.failChance ~= nil then recipe.failChance = data.failChance end
            if data.cost ~= nil then recipe.cost = data.cost end
            if data.blueprint ~= nil then
                recipe.blueprint = data.blueprint ~= '' and data.blueprint or nil
                RefreshBlueprintCache()
            end
            if data.blueprintDurabilityLoss ~= nil then recipe.blueprintDurabilityLoss = data.blueprintDurabilityLoss end
            if data.image ~= nil then recipe.image = data.image ~= '' and data.image or nil end
            if data.ingredients ~= nil then
                -- Normalize empty ingredient labels to nil so auto-fetch works
                for _, ing in ipairs(data.ingredients) do
                    if ing.label == '' then ing.label = nil end
                end
                recipe.ingredients = data.ingredients
            end
            if data.tools ~= nil then recipe.tools = data.tools end
            if data.enabled ~= nil then recipe.enabled = data.enabled end
            if data.metadata ~= nil then recipe.metadata = data.metadata end
            if data.showMetadata ~= nil then recipe.showMetadata = data.showMetadata end

            local dbRecipe = {}
            for k, v in pairs(recipe) do dbRecipe[k] = v end
            dbRecipe._table_name = data.tableName
            AdminUpsert('recipe', recipe.id, json.encode(dbRecipe))
            GetAdminRecipeDbKeys()[recipe.id] = true

            TriggerClientEvent('sd-crafting:client:syncAdminRecipe', -1, data.tableName, recipe)

            InvalidateRecipeCache()
            return true
        end
    end

    return false
end)

--- Admin create a new recipe (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Contains tableName and recipe object
---@return table|false result Contains success and id, or false if failed
lib.callback.register('sd-crafting:server:admin:createRecipe', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.tableName or not data.recipe then return false end

    local recipe = data.recipe
    recipe.id = recipe.id or ('admin_' .. os.time() .. '_' .. math.random(10000, 99999))
    recipe.enabled = recipe.enabled ~= false
    recipe.craftTime = recipe.craftTime or 5
    recipe.ingredients = recipe.ingredients or {}

    -- Normalize empty strings to nil so auto-fetch (Inventory.GetItemLabel) works
    if recipe.label == '' then recipe.label = nil end
    if recipe.image == '' then recipe.image = nil end
    if recipe.blueprint == '' then recipe.blueprint = nil end
    for _, ing in ipairs(recipe.ingredients) do
        if ing.label == '' then ing.label = nil end
    end

    if not Recipes[data.tableName] then
        Recipes[data.tableName] = {}
    end

    table.insert(Recipes[data.tableName], recipe)

    if recipe.blueprint then
        RefreshBlueprintCache()
    end

    local dbRecipe = {}
    for k, v in pairs(recipe) do dbRecipe[k] = v end
    dbRecipe._table_name = data.tableName
    AdminUpsert('recipe', recipe.id, json.encode(dbRecipe))
    GetAdminRecipeDbKeys()[recipe.id] = true

    TriggerClientEvent('sd-crafting:client:syncAdminRecipe', -1, data.tableName, recipe)

    InvalidateRecipeCache()
    debugPrint('Admin created recipe', recipe.id, 'in table', data.tableName)
    return { success = true, id = recipe.id }
end)

--- Admin create a recipe table (persistent, saved to database even when empty)
---@param source number Player server ID requesting
---@param data table Contains tableName
---@return boolean success Whether the creation was successful
lib.callback.register('sd-crafting:server:admin:createTable', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.tableName or data.tableName == '' then return false end

    if not Recipes[data.tableName] then
        Recipes[data.tableName] = {}
    end

    AdminTableNames[data.tableName] = true
    AdminInsertIgnore('table', data.tableName, '{}')

    InvalidateRecipeCache()
    debugPrint('Admin created recipe table', data.tableName)
    return true
end)

--- Admin delete a recipe table and all its recipes (admin-created tables only)
---@param source number Player server ID requesting
---@param data table Contains tableName
---@return table result Contains success and optional error message
lib.callback.register('sd-crafting:server:admin:deleteTable', function(source, data)
    if not IsAdmin(source) then return { success = false, error = 'Not authorized' } end
    if not data or not data.tableName or data.tableName == '' then return { success = false, error = 'Invalid table name' } end

    -- Only allow deleting admin-created tables (use in-memory set instead of DB query)
    if not AdminTableNames[data.tableName] then
        return { success = false, error = 'Cannot delete config-defined tables' }
    end

    -- Delete all admin recipes in this table from DB (cascade via _table_name JSON field)
    -- Must be .await so recipe rows are gone before the table entry is removed
    MySQL.query.await("DELETE FROM sd_crafting_admin WHERE category = 'recipe' AND JSON_UNQUOTE(JSON_EXTRACT(data, '$._table_name')) = ?", { data.tableName })

    -- Delete the table entry from DB
    AdminDelete('table', data.tableName)
    AdminTableNames[data.tableName] = nil

    -- Remove from runtime
    Recipes[data.tableName] = nil

    RefreshBlueprintCache()
    InvalidateRecipeCache()
    adminRecipeDbKeys = nil -- Reset lazy set since bulk delete removed rows

    debugPrint('Admin deleted recipe table', data.tableName)
    return { success = true }
end)

--- Admin delete a recipe (persistent, saved to database as tombstone or deleted)
---@param source number Player server ID requesting
---@param data table Contains tableName and recipeId
---@return boolean success Whether the deletion was successful
lib.callback.register('sd-crafting:server:admin:deleteRecipe', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.tableName or not data.recipeId then return false end

    local recipes = Recipes[data.tableName]
    if not recipes then return false end

    for i, recipe in ipairs(recipes) do
        if recipe.id == data.recipeId then
            table.remove(recipes, i)
            RefreshBlueprintCache()

            -- Check if this recipe has a row in DB (in-memory lookup, no DB query)
            local dbKeys = GetAdminRecipeDbKeys()
            if dbKeys[data.recipeId] then
                -- Recipe has DB row: delete from DB entirely
                AdminDelete('recipe', data.recipeId)
                dbKeys[data.recipeId] = nil
            else
                -- Config-defined recipe with no DB row: insert tombstone so it stays deleted after restart
                local tombstone = { deleted = true, _table_name = data.tableName }
                AdminUpsert('recipe', data.recipeId, json.encode(tombstone))
                dbKeys[data.recipeId] = true
            end

            TriggerClientEvent('sd-crafting:client:removeAdminRecipe', -1, data.tableName, data.recipeId)

            InvalidateRecipeCache()
            debugPrint('Admin deleted recipe', data.recipeId, 'from table', data.tableName)
            return true
        end
    end

    return false
end)

--- Return all admin-created/modified recipes grouped by table for client-side sync
---@param source number Player server ID requesting
---@return table adminRecipes Map of tableName -> array of recipe objects (admin-only entries)
lib.callback.register('sd-crafting:server:getAdminRecipes', function(source)
    if cachedAdminRecipes then return cachedAdminRecipes end

    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'recipe' })
    if not rows then return {} end

    local result = {}
    for _, row in ipairs(rows) do
        local recipeData = json.decode(row.data)
        if recipeData and not recipeData.deleted then
            local tableName = recipeData._table_name
            recipeData._table_name = nil
            if tableName then
                if not result[tableName] then
                    result[tableName] = {}
                end
                table.insert(result[tableName], recipeData)
            end
        end
    end

    -- Also include empty admin tables so the client knows they exist (in-memory set)
    for tableName in pairs(AdminTableNames) do
        if not result[tableName] then
            result[tableName] = {}
        end
    end

    cachedAdminRecipes = result
    return result
end)

--- Admin create a new station (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Station config: label, type, coords, heading, radius, recipes, techTrees, prop, blip, owner
---@return table|false result Contains success and stationKey, or false if failed
lib.callback.register('sd-crafting:server:admin:createStation', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.label or not data.coords then return false end

    local stationKey = 'admin_station_' .. os.time() .. '_' .. math.random(10000, 99999)

    local craftingBehavior = nil
    if data.sharedCrafting ~= nil or data.sharedStaging ~= nil then
        craftingBehavior = {}
        if data.sharedCrafting ~= nil then craftingBehavior.sharedCrafting = data.sharedCrafting end
        if data.sharedStaging ~= nil then craftingBehavior.sharedStaging = data.sharedStaging end
    end

    local stationConfig = {
        label = data.label,
        type = data.type or 'basic',
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        heading = data.heading or 0,
        radius = data.radius or 2.0,
        recipes = data.recipes or { 'all' },
        techTrees = data.techTrees,
        owner = data.owner ~= '' and data.owner or nil,
        prop = data.prop,
        blip = data.blip,
        CraftingBehavior = craftingBehavior,
        sharedTech = data.sharedTech or false,
        job = NormalizeJobGang(data.job),
        gang = NormalizeJobGang(data.gang),
    }

    AdminStations[stationKey] = stationConfig

    -- Save to DB with coords as plain table for JSON serialization
    local dbData = {
        label = stationConfig.label,
        type = stationConfig.type,
        coords = { x = stationConfig.coords.x, y = stationConfig.coords.y, z = stationConfig.coords.z },
        heading = stationConfig.heading,
        radius = stationConfig.radius,
        recipes = stationConfig.recipes,
        techTrees = stationConfig.techTrees,
        owner = stationConfig.owner,
        prop = stationConfig.prop,
        blip = stationConfig.blip,
        CraftingBehavior = craftingBehavior,
        sharedTech = stationConfig.sharedTech,
        job = stationConfig.job,
        gang = stationConfig.gang,
    }

    AdminUpsert('station', stationKey, json.encode(dbData))

    -- Broadcast to all clients to spawn the station
    TriggerClientEvent('sd-crafting:client:spawnAdminStation', -1, stationKey, dbData)

    InvalidateStationCache()
    InvalidateTypesCache()
    debugPrint('Admin created station', stationKey, 'at', stationConfig.coords)
    return { success = true, stationKey = stationKey }
end)

--- Update a static station (from Config.Stations) via override table
---@param stationKey string The Config.Stations key
---@param data table Updated station fields (label, type, radius, recipes, techTrees, blip, prop, coords, heading)
---@return boolean success Whether the update was successful
local function UpdateStaticStationOverride(stationKey, data)
    local station = Config.Stations[stationKey]
    if not station then return false end

    -- Accumulate into override table
    if not StationOverrides[stationKey] then StationOverrides[stationKey] = {} end
    local override = StationOverrides[stationKey]
    if data.label ~= nil then override.label = data.label; station.label = data.label end
    if data.type ~= nil then override.type = data.type; station.type = data.type end
    if data.radius ~= nil then override.radius = data.radius; station.radius = data.radius end
    if data.recipes ~= nil then override.recipes = data.recipes; station.recipes = data.recipes end
    if data.techTrees ~= nil then override.techTrees = data.techTrees; station.techTrees = data.techTrees end
    if data.owner ~= nil then local ownerVal = data.owner ~= '' and data.owner or nil; override.owner = ownerVal; station.owner = ownerVal end
    if data.blip ~= nil then override.blip = data.blip; station.blip = data.blip end
    if data.prop ~= nil then override.prop = data.prop; station.prop = data.prop end
    if data.coords ~= nil then
        local c = vector3(data.coords.x, data.coords.y, data.coords.z)
        override.coords = { x = c.x, y = c.y, z = c.z }
        station.coords = c
    end
    if data.heading ~= nil then override.heading = data.heading; station.heading = data.heading end
    if data.sharedCrafting ~= nil or data.sharedStaging ~= nil then
        local cb = station.CraftingBehavior or {}
        if data.sharedCrafting ~= nil then cb.sharedCrafting = data.sharedCrafting end
        if data.sharedStaging ~= nil then cb.sharedStaging = data.sharedStaging end
        override.CraftingBehavior = cb
        station.CraftingBehavior = cb
    end
    if data.sharedTech ~= nil then override.sharedTech = data.sharedTech; station.sharedTech = data.sharedTech end
    if data.job ~= nil then local v = NormalizeJobGang(data.job, true); override.job = v; station.job = v end
    if data.gang ~= nil then local v = NormalizeJobGang(data.gang, true); override.gang = v; station.gang = v end

    -- Upsert to DB
    AdminUpsert('override', stationKey, json.encode(override))

    -- Build serialized station data for client broadcast
    local broadcastData = {
        label = station.label,
        type = station.type,
        coords = station.coords and { x = station.coords.x, y = station.coords.y, z = station.coords.z } or nil,
        heading = station.heading,
        radius = station.radius,
        recipes = station.recipes,
        techTrees = station.techTrees,
        prop = station.prop,
        blip = station.blip,
        job = station.job,
        gang = station.gang,
        owner = station.owner or false,
    }
    TriggerClientEvent('sd-crafting:client:refreshStaticStation', -1, stationKey, broadcastData)

    InvalidateStationCache()
    InvalidateTypesCache()
    debugPrint('Updated static station override', stationKey)
    return true
end

--- Update a placed workbench via override table
---@param stationKey string The override key (e.g. 'placed_123')
---@param placedId number The numeric workbench ID
---@param data table Updated station fields
---@return boolean success Whether the update was successful
local function UpdatePlacedWorkbenchOverride(stationKey, placedId, data)
    local wb = PlacedWorkbenches[placedId]
    if not wb then return false end

    -- Accumulate into override table
    if not StationOverrides[stationKey] then StationOverrides[stationKey] = {} end
    local override = StationOverrides[stationKey]
    if data.label ~= nil then override.label = data.label; wb.label = data.label end
    if data.type ~= nil then override.type = data.type; wb.type = data.type end
    if data.radius ~= nil then override.radius = data.radius; wb.radius = data.radius end
    if data.recipes ~= nil then override.recipes = data.recipes; wb.recipes = data.recipes end
    if data.techTrees ~= nil then override.techTrees = data.techTrees; wb.techTrees = data.techTrees end
    if data.owner ~= nil then local ownerVal = data.owner ~= '' and data.owner or nil; override.owner = ownerVal; wb.owner = ownerVal end
    if data.blip ~= nil then override.blip = data.blip; wb.blip = data.blip end
    if data.prop ~= nil then
        override.prop = data.prop
        -- PlacedWorkbenches store prop as a model string + separate enabled flag
        wb.prop = type(data.prop) == 'table' and data.prop.model or data.prop
        if type(data.prop) == 'table' and data.prop.enabled ~= nil then
            wb.propEnabled = data.prop.enabled
        end
    end
    if data.coords ~= nil then
        local c = vector3(data.coords.x, data.coords.y, data.coords.z)
        override.coords = { x = c.x, y = c.y, z = c.z }
        wb.coords = c
    end
    if data.heading ~= nil then override.heading = data.heading; wb.heading = data.heading end
    if data.sharedCrafting ~= nil or data.sharedStaging ~= nil then
        local cb = wb.CraftingBehavior or {}
        if data.sharedCrafting ~= nil then cb.sharedCrafting = data.sharedCrafting end
        if data.sharedStaging ~= nil then cb.sharedStaging = data.sharedStaging end
        override.CraftingBehavior = cb
        wb.CraftingBehavior = cb
    end
    if data.sharedTech ~= nil then override.sharedTech = data.sharedTech; wb.sharedTech = data.sharedTech end
    if data.job ~= nil then local v = NormalizeJobGang(data.job, true); override.job = v; wb.job = v end
    if data.gang ~= nil then local v = NormalizeJobGang(data.gang, true); override.gang = v; wb.gang = v end

    -- Upsert to DB
    AdminUpsert('override', stationKey, json.encode(override))

    -- Build workbench data for client broadcast (include all override fields)
    local resolvedPropEnabled = true
    if wb.propEnabled ~= nil then resolvedPropEnabled = wb.propEnabled end
    local broadcastData = {
        id = placedId,
        owner = wb.owner,
        item = wb.item,
        type = wb.type,
        prop = wb.prop,
        propEnabled = resolvedPropEnabled,
        coords = wb.coords and { x = wb.coords.x, y = wb.coords.y, z = wb.coords.z } or nil,
        heading = wb.heading,
        label = wb.label,
        recipes = wb.recipes,
        techTrees = wb.techTrees,
        blip = wb.blip,
        radius = wb.radius,
        job = wb.job,
        gang = wb.gang,
    }
    TriggerClientEvent('sd-crafting:client:refreshPlacedWorkbench', -1, placedId, broadcastData)

    InvalidateStationCache()
    InvalidateTypesCache()
    debugPrint('Updated placed workbench override', stationKey)
    return true
end

--- Admin update an existing station (admin, static, or placed — persistent)
---@param source number Player server ID requesting
---@param data table Contains stationKey and updated station fields
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updateStation', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.stationKey then return false end

    local stationKey = data.stationKey

    -- Route to static station override handler
    if Config.Stations and Config.Stations[stationKey] then
        return UpdateStaticStationOverride(stationKey, data)
    end

    -- Route to placed workbench override handler
    local placedId = stationKey:match('^placed_(%d+)$')
    if placedId then
        placedId = tonumber(placedId)
        if PlacedWorkbenches[placedId] then
            return UpdatePlacedWorkbenchOverride(stationKey, placedId, data)
        end
    end

    -- Fall through to existing admin station path
    if not AdminStations[stationKey] then return false end

    local station = AdminStations[stationKey]
    if data.label ~= nil then station.label = data.label end
    if data.type ~= nil then station.type = data.type end
    if data.coords ~= nil then station.coords = vector3(data.coords.x, data.coords.y, data.coords.z) end
    if data.heading ~= nil then station.heading = data.heading end
    if data.radius ~= nil then station.radius = data.radius end
    if data.recipes ~= nil then station.recipes = data.recipes end
    if data.techTrees ~= nil then station.techTrees = data.techTrees end
    if data.owner ~= nil then station.owner = data.owner ~= '' and data.owner or nil end
    if data.prop ~= nil then station.prop = data.prop end
    if data.blip ~= nil then station.blip = data.blip end
    if data.sharedCrafting ~= nil or data.sharedStaging ~= nil then
        local cb = station.CraftingBehavior or {}
        if data.sharedCrafting ~= nil then cb.sharedCrafting = data.sharedCrafting end
        if data.sharedStaging ~= nil then cb.sharedStaging = data.sharedStaging end
        station.CraftingBehavior = cb
    end
    if data.sharedTech ~= nil then station.sharedTech = data.sharedTech end
    if data.job ~= nil then station.job = NormalizeJobGang(data.job) end
    if data.gang ~= nil then station.gang = NormalizeJobGang(data.gang) end

    -- Save to DB with coords as plain table
    local dbData = {
        label = station.label,
        type = station.type,
        coords = { x = station.coords.x, y = station.coords.y, z = station.coords.z },
        heading = station.heading,
        radius = station.radius,
        recipes = station.recipes,
        techTrees = station.techTrees,
        owner = station.owner,
        prop = station.prop,
        blip = station.blip,
        CraftingBehavior = station.CraftingBehavior,
        sharedTech = station.sharedTech,
        job = station.job,
        gang = station.gang,
    }

    AdminUpsert('station', stationKey, json.encode(dbData))

    TriggerClientEvent('sd-crafting:client:refreshAdminStation', -1, stationKey, dbData)

    InvalidateStationCache()
    InvalidateTypesCache()
    debugPrint('Admin updated station', stationKey)
    return true
end)

--- Admin delete an admin-created station (persistent)
---@param source number Player server ID requesting
---@param stationKey string The station key to delete
---@return boolean success Whether the deletion was successful
lib.callback.register('sd-crafting:server:admin:deleteAdminStation', function(source, stationKey)
    if not IsAdmin(source) then return false end
    if not stationKey or not AdminStations[stationKey] then return false end

    AdminStations[stationKey] = nil

    AdminDelete('station', stationKey)

    TriggerClientEvent('sd-crafting:client:removeAdminStation', -1, stationKey)

    InvalidateStationCache()
    InvalidateTypesCache()
    debugPrint('Admin deleted station', stationKey)
    return true
end)

--- Get all admin stations for client-side spawning on connect
---@param source number Player server ID requesting
---@return table adminStations Table of admin stations with serialized coords
lib.callback.register('sd-crafting:server:getAdminStations', function(source)
    local result = {}
    for stationKey, station in pairs(AdminStations) do
        result[stationKey] = {
            label = station.label,
            type = station.type,
            coords = { x = station.coords.x, y = station.coords.y, z = station.coords.z },
            heading = station.heading,
            radius = station.radius,
            recipes = station.recipes,
            techTrees = station.techTrees,
            owner = station.owner,
            prop = station.prop,
            blip = station.blip,
            job = station.job,
            gang = station.gang,
        }
    end
    return result
end)

--- Get station overrides for client-side application on connect (static stations only)
---@param source number Player server ID requesting
---@return table overrides Table of override data keyed by station key
lib.callback.register('sd-crafting:server:getStationOverrides', function(source)
    local result = {}
    for stationKey, overrideData in pairs(StationOverrides) do
        -- Only return overrides for static stations (placed workbenches are handled via getPlacedWorkbenches)
        if not stationKey:match('^placed_') then
            result[stationKey] = overrideData
        end
    end
    return result
end)

--- Admin get all staged inventories for a workbench (placed or static)
---@param source number Player server ID requesting
---@param data table Contains stationKey (e.g. 'placed_123' or 'workbench')
---@return table|false inventories Array of inventory entries per staging key, or false if not admin
lib.callback.register('sd-crafting:server:admin:getStationInventories', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.stationKey then return false end

    local stationKey = data.stationKey
    local staged = StagedItems[stationKey]
    local result = {}

    if staged then
        for stagingKey, items in pairs(staged) do
            if items and #items > 0 then
                local enriched = {}
                for _, item in ipairs(items) do
                    table.insert(enriched, {
                        item = item.item,
                        label = item.label or (Inventory and Inventory.GetItemLabel and Inventory.GetItemLabel(item.item)) or item.item,
                        count = item.count,
                        slot = item.slot,
                        durability = item.durability,
                        metadata = item.metadata,
                    })
                end
                table.insert(result, {
                    stagingKey = stagingKey,
                    isShared = stagingKey == 'shared',
                    items = enriched,
                    itemCount = #enriched,
                })
            end
        end
    end

    return result
end)

--- Admin remove an item from a station's staged inventory
---@param source number Player server ID requesting
---@param data table Contains stationKey, stagingKey, itemName, count, slot
---@return boolean success Whether the removal was successful
lib.callback.register('sd-crafting:server:admin:removeStationInventoryItem', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.stationKey or not data.stagingKey or not data.itemName then return false end

    local stationKey = data.stationKey
    local success = RemoveFromStaging(stationKey, data.stagingKey, data.itemName, data.count or 1, data.slot)

    if success then
        BroadcastStagedItemsUpdate(stationKey, -1)
        debugPrint('Admin removed', data.count or 1, 'x', data.itemName, 'from station', stationKey, 'key', data.stagingKey)
    end

    return success
end)

--- Admin add an item to a station's staged inventory
---@param source number Player server ID requesting
---@param data table Contains stationKey, stagingKey, itemName, count
---@return table result Contains success boolean and optional error message
lib.callback.register('sd-crafting:server:admin:addStationInventoryItem', function(source, data)
    if not IsAdmin(source) then return { success = false, error = 'Not authorized' } end
    if not data or not data.stationKey or not data.stagingKey or not data.itemName or not data.count then
        return { success = false, error = 'Missing required fields' }
    end

    local stationKey = data.stationKey
    local itemName = data.itemName
    local count = tonumber(data.count) or 1
    if count < 1 then return { success = false, error = 'Count must be at least 1' } end

    local itemLabel = Inventory.GetItemLabel(itemName)
    if not itemLabel then
        return { success = false, error = 'Item not found: ' .. tostring(itemName) }
    end

    local success, err = AddToStaging(stationKey, data.stagingKey, itemName, itemLabel, count)

    if success then
        BroadcastStagedItemsUpdate(stationKey, -1)
        debugPrint('Admin added', count, 'x', itemName, 'to station', stationKey, 'key', data.stagingKey)
    end

    return { success = success or false, error = err }
end)

--- Helper to persist a tech tree to the database (full tree JSON upsert)
---@param treeId string The tree ID
---@param treeData table The full tree data table
local function PersistTechTree(treeId, treeData)
    AdminTechTreeIds[treeId] = true
    AdminUpsert('techtree', treeId, json.encode(treeData))
end

--- Admin get all tech trees with metadata for admin panel
---@param source number Player server ID requesting
---@return table|nil trees Map of treeId -> tree data with source field
lib.callback.register('sd-crafting:server:admin:getTechTrees', function(source)
    if not IsAdmin(source) then return nil end
    if cachedTechTreeResponse then return cachedTechTreeResponse end

    local result = {}
    for treeId, tree in pairs(TechTrees.Trees) do
        result[treeId] = {
            label = tree.label,
            icon = tree.icon,
            color = tree.color,
            nodes = tree.nodes or {},
            source = AdminTechTreeIds[treeId] and 'admin' or 'config',
        }
    end

    cachedTechTreeResponse = result
    return result
end)

--- Admin create a new tech tree (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Contains treeId, label, icon, color
---@return boolean success Whether the creation was successful
lib.callback.register('sd-crafting:server:admin:createTechTree', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.treeId or data.treeId == '' then return false end
    if TechTrees.Trees[data.treeId] then return false end

    local tree = {
        label = data.label or data.treeId,
        icon = data.icon or 'git-branch',
        color = data.color or '#4ADE80',
        nodes = {},
    }

    TechTrees.Trees[data.treeId] = tree
    PersistTechTree(data.treeId, tree)
    TriggerClientEvent('sd-crafting:client:syncAdminTechTree', -1, data.treeId, tree)

    InvalidateTechTreeCache()
    debugPrint('Admin created tech tree', data.treeId)
    return true
end)

--- Admin update a tech tree's metadata (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Contains treeId and optional label, icon, color, nodes
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updateTechTree', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.treeId then return false end

    local tree = TechTrees.Trees[data.treeId]
    if not tree then return false end

    if data.label ~= nil then tree.label = data.label end
    if data.icon ~= nil then tree.icon = data.icon end
    if data.color ~= nil then tree.color = data.color end
    if data.nodes ~= nil then tree.nodes = data.nodes end

    PersistTechTree(data.treeId, tree)
    TriggerClientEvent('sd-crafting:client:syncAdminTechTree', -1, data.treeId, tree)

    InvalidateTechTreeCache()
    debugPrint('Admin updated tech tree', data.treeId)
    return true
end)

--- Admin create a node within a tech tree (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Contains treeId and node object
---@return boolean success Whether the creation was successful
lib.callback.register('sd-crafting:server:admin:createNode', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.treeId or not data.node or not data.node.id then return false end

    local tree = TechTrees.Trees[data.treeId]
    if not tree then return false end
    if not tree.nodes then tree.nodes = {} end

    -- Ensure node ID doesn't already exist
    for _, node in ipairs(tree.nodes) do
        if node.id == data.node.id then return false end
    end

    table.insert(tree.nodes, {
        id = data.node.id,
        recipeId = data.node.recipeId or '',
        cost = data.node.cost or 1,
        prerequisites = data.node.prerequisites or {},
        position = data.node.position or { row = 1, col = 1 },
    })

    PersistTechTree(data.treeId, tree)
    TriggerClientEvent('sd-crafting:client:syncAdminTechTree', -1, data.treeId, tree)

    InvalidateTechTreeCache()
    debugPrint('Admin created node', data.node.id, 'in tech tree', data.treeId)
    return true
end)

--- Admin update a node within a tech tree (persistent, saved to database)
---@param source number Player server ID requesting
---@param data table Contains treeId, nodeId, and fields to update
---@return boolean success Whether the update was successful
lib.callback.register('sd-crafting:server:admin:updateNode', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.treeId or not data.nodeId then return false end

    local tree = TechTrees.Trees[data.treeId]
    if not tree or not tree.nodes then return false end

    for _, node in ipairs(tree.nodes) do
        if node.id == data.nodeId then
            if data.fields then
                if data.fields.recipeId ~= nil then node.recipeId = data.fields.recipeId end
                if data.fields.cost ~= nil then node.cost = data.fields.cost end
                if data.fields.prerequisites ~= nil then node.prerequisites = data.fields.prerequisites end
                if data.fields.position ~= nil then node.position = data.fields.position end
            end

            PersistTechTree(data.treeId, tree)
            TriggerClientEvent('sd-crafting:client:syncAdminTechTree', -1, data.treeId, tree)

            InvalidateTechTreeCache()
            debugPrint('Admin updated node', data.nodeId, 'in tech tree', data.treeId)
            return true
        end
    end

    return false
end)

--- Admin delete a node from a tech tree (persistent, saved to database)
--- Also cleans up references in other nodes' prerequisites
---@param source number Player server ID requesting
---@param data table Contains treeId and nodeId
---@return boolean success Whether the deletion was successful
lib.callback.register('sd-crafting:server:admin:deleteNode', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.treeId or not data.nodeId then return false end

    local tree = TechTrees.Trees[data.treeId]
    if not tree or not tree.nodes then return false end

    -- Remove the node
    local removed = false
    for i, node in ipairs(tree.nodes) do
        if node.id == data.nodeId then
            table.remove(tree.nodes, i)
            removed = true
            break
        end
    end

    if not removed then return false end

    -- Clean up references in other nodes' prerequisites
    for _, node in ipairs(tree.nodes) do
        if node.prerequisites then
            for i = #node.prerequisites, 1, -1 do
                if node.prerequisites[i] == data.nodeId then
                    table.remove(node.prerequisites, i)
                end
            end
        end
    end

    PersistTechTree(data.treeId, tree)
    TriggerClientEvent('sd-crafting:client:syncAdminTechTree', -1, data.treeId, tree)

    InvalidateTechTreeCache()
    debugPrint('Admin deleted node', data.nodeId, 'from tech tree', data.treeId)
    return true
end)

--- Admin delete a tech tree (persistent, saved to database)
--- Config-defined trees get a tombstone; admin-created trees are fully removed
---@param source number Player server ID requesting
---@param data table Contains treeId
---@return boolean success Whether the deletion was successful
lib.callback.register('sd-crafting:server:admin:deleteTechTree', function(source, data)
    if not IsAdmin(source) then return false end
    if not data or not data.treeId then return false end
    if not TechTrees.Trees[data.treeId] then return false end

    TechTrees.Trees[data.treeId] = nil

    -- Check if admin-created (exists in DB) using in-memory set
    if AdminTechTreeIds[data.treeId] then
        -- Check if it was admin-created (not a config override) by checking original config
        local originalConfig = require('configs/techtrees')
        if originalConfig.Trees and originalConfig.Trees[data.treeId] then
            -- Config-defined tree: insert tombstone so it stays deleted after restart
            AdminUpsert('techtree', data.treeId, json.encode({ deleted = true }))
        else
            -- Admin-created tree: delete from DB entirely
            AdminDelete('techtree', data.treeId)
            AdminTechTreeIds[data.treeId] = nil
        end
    else
        -- Config-defined tree with no DB row: insert tombstone
        AdminUpsert('techtree', data.treeId, json.encode({ deleted = true }))
        AdminTechTreeIds[data.treeId] = true
    end

    TriggerClientEvent('sd-crafting:client:removeAdminTechTree', -1, data.treeId)

    InvalidateTechTreeCache()
    debugPrint('Admin deleted tech tree', data.treeId)
    return true
end)

--- Return all admin tech tree rows from database for client-side sync
---@param source number Player server ID requesting
---@return table adminTrees Map of treeId -> tree data (excluding tombstones)
lib.callback.register('sd-crafting:server:getAdminTechTrees', function(source)
    if cachedAdminTechTrees then return cachedAdminTechTrees end

    local rows = MySQL.query.await('SELECT `key`, data FROM sd_crafting_admin WHERE category = ?', { 'techtree' })
    if not rows then return {} end

    local result = {}
    for _, row in ipairs(rows) do
        local treeData = json.decode(row.data)
        if treeData and not treeData.deleted then
            result[row.key] = treeData
        end
    end

    cachedAdminTechTrees = result
    return result
end)
