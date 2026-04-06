local Config = require('configs/config') -- Main configuration from configs/config.lua

local isAdminOpen = false -- Whether the admin panel is currently open
local placementProp = nil -- Prop entity used during admin workbench placement
local isPlacingStation = false -- Whether station placement is currently active

--- Debug print helper - only prints if Config.Debug is enabled
---@param ... any Arguments to print
local function debugPrint(...)
    if Config.Debug then
        print('[sd-crafting:client:admin]', ...)
    end
end

--- Print workbench config output to console after placement
---@param model string The prop model name
---@param x number Rounded X coordinate
---@param y number Rounded Y coordinate
---@param z number Rounded Z coordinate
---@param h number Rounded heading
local function PrintWorkbenchConfig(model, x, y, z, h)
    print('========================================')
    print('WORKBENCH PLACEMENT CONFIG')
    print('========================================')
    print(string.format("['your_workbench_id'] = {"))
    print(string.format("    label = 'Your Workbench',"))
    print(string.format("    coords = vector3(%.2f, %.2f, %.2f),", x, y, z))
    print(string.format("    heading = %.1f,", h))
    print(string.format("    radius = 2.0,"))
    print(string.format("    recipes = { 'all' },"))
    print(string.format("    prop = {"))
    print(string.format("        enabled = true,"))
    print(string.format("        model = '%s',", model))
    print(string.format("        spawnRadius = 50.0,"))
    print(string.format("        offset = vector3(0.0, 0.0, 0.0),"))
    print(string.format("    },"))
    print(string.format("    blip = {"))
    print(string.format("        enabled = true,"))
    print(string.format("        sprite = 566,"))
    print(string.format("        color = 2,"))
    print(string.format("        scale = 0.7,"))
    print(string.format("        label = 'Workbench'"))
    print(string.format("    }"))
    print(string.format("},"))
    print('========================================')
end

--- Notify placement results (config printed + coordinates)
---@param x number Rounded X coordinate
---@param y number Rounded Y coordinate
---@param z number Rounded Z coordinate
---@param h number Rounded heading
local function NotifyPlacementResult(x, y, z, h)
    lib.notify({
        title = Locale.T('notifications.workbench.placementTitle'),
        description = Locale.T('notifications.workbench.configPrinted'),
        type = 'success',
        duration = 5000
    })

    lib.notify({
        title = Locale.T('notifications.workbench.placementTitle'),
        description = Locale.T('notifications.workbench.coordinates', { x = string.format('%.2f', x), y = string.format('%.2f', y), z = string.format('%.2f', z), h = string.format('%.1f', h) }),
        type = 'inform',
        duration = 10000
    })
end

--- Handle admin workbench placement using raycast (when useGizmo is false)
---@param model string The prop model to place
local function PlaceWorkbenchRaycast(model)
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)

    placementProp = CreateObject(model, 1.0, 1.0, 1.0, false, false, false)
    SetEntityHeading(placementProp, heading)
    SetEntityAlpha(placementProp, 200, false)
    SetEntityCollision(placementProp, false, false)
    FreezeEntityPosition(placementProp, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(placementProp) then
        lib.notify({
            title = Locale.T('notifications.workbench.placementTitle'),
            description = Locale.T('notifications.workbench.invalidModel', { model = model }),
            type = 'error'
        })
        placementProp = nil
        return
    end

    local currentHeading = heading
    local raycastDistance = Config.raycastDistance or 10.0

    CreateThread(function()
        local scaleform = SetupPlacementScaleform()

        while placementProp and DoesEntityExist(placementProp) do
            local hit, hitCoords = RayCastGamePlayCamera(raycastDistance)
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

            if hit then
                local success, groundZ = GetGroundZFor_3dCoord(hitCoords.x, hitCoords.y, hitCoords.z + 10.0, false)
                if success then
                    local modelHash = GetEntityModel(placementProp)
                    local minDim, _ = GetModelDimensions(modelHash)
                    local zOffset = -minDim.z

                    SetEntityCoords(placementProp, hitCoords.x, hitCoords.y, groundZ + zOffset, false, false, false, true)
                end
            end

            local isShiftHeld = IsControlPressed(0, 21)
            local rotationStep = isShiftHeld and 1.0 or 5.0

            if IsControlJustPressed(0, 15) then
                currentHeading = (currentHeading + rotationStep) % 360
                SetEntityHeading(placementProp, currentHeading)
            end
            if IsControlJustPressed(0, 14) then
                currentHeading = (currentHeading - rotationStep + 360) % 360
                SetEntityHeading(placementProp, currentHeading)
            end

            if IsControlJustPressed(0, 177) then
                DeleteEntity(placementProp)
                placementProp = nil

                Wait(100)

                lib.notify({
                    title = Locale.T('notifications.workbench.placementTitle'),
                    description = Locale.T('notifications.workbench.cancelled'),
                    type = 'error'
                })
                return
            end

            if IsControlJustPressed(0, 176) then
                local finalCoords = GetEntityCoords(placementProp)
                local finalHeading = GetEntityHeading(placementProp)

                local x = math.floor(finalCoords.x * 100 + 0.5) / 100
                local y = math.floor(finalCoords.y * 100 + 0.5) / 100
                local z = math.floor(finalCoords.z * 100 + 0.5) / 100
                local h = math.floor(finalHeading * 100 + 0.5) / 100

                PrintWorkbenchConfig(model, x, y, z, h)

                DeleteEntity(placementProp)
                placementProp = nil

                Wait(100)

                NotifyPlacementResult(x, y, z, h)
                return
            end

            Wait(0)
        end
    end)
end

--- Handle admin workbench placement using object_gizmo
---@param model string The prop model to place
local function PlaceWorkbenchGizmo(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local forwardX = coords.x + (math.sin(math.rad(-heading)) * 2.0)
    local forwardY = coords.y + (math.cos(math.rad(-heading)) * 2.0)

    placementProp = CreateObject(model, forwardX, forwardY, coords.z, false, false, false)
    SetEntityHeading(placementProp, heading)
    FreezeEntityPosition(placementProp, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(placementProp) then
        lib.notify({
            title = Locale.T('notifications.workbench.placementTitle'),
            description = Locale.T('notifications.workbench.invalidModel', { model = model }),
            type = 'error'
        })
        placementProp = nil
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
        DeleteEntity(placementProp)
        placementProp = nil
        return
    end

    gizmoExport:useGizmo(placementProp)

    CreateThread(function()
        while placementProp and DoesEntityExist(placementProp) do
            if IsControlJustPressed(0, 191) then
                local finalCoords = GetEntityCoords(placementProp)
                local finalHeading = GetEntityHeading(placementProp)

                local x = math.floor(finalCoords.x * 100 + 0.5) / 100
                local y = math.floor(finalCoords.y * 100 + 0.5) / 100
                local z = math.floor(finalCoords.z * 100 + 0.5) / 100
                local h = math.floor(finalHeading * 100 + 0.5) / 100

                PrintWorkbenchConfig(model, x, y, z, h)

                gizmoExport:useGizmo(nil)
                Wait(50)
                SetNuiFocus(false, false)
                SetNuiFocusKeepInput(false)

                DeleteEntity(placementProp)
                placementProp = nil

                Wait(100)

                NotifyPlacementResult(x, y, z, h)

                break
            end

            if IsControlJustPressed(0, 177) then
                gizmoExport:useGizmo(nil)
                Wait(50)
                SetNuiFocus(false, false)
                SetNuiFocusKeepInput(false)

                DeleteEntity(placementProp)
                placementProp = nil

                Wait(100)

                lib.notify({
                    title = Locale.T('notifications.workbench.placementTitle'),
                    description = Locale.T('notifications.workbench.cancelled'),
                    type = 'error'
                })

                break
            end

            Wait(0)
        end
    end)
end

--- Handle admin workbench placement (gizmo or raycast based on Config.useGizmo)
---@param model string The prop model to place
RegisterNetEvent('sd-crafting:client:placeWorkbench', function(model)
    if placementProp and DoesEntityExist(placementProp) then
        DeleteEntity(placementProp)
        placementProp = nil
    end

    lib.requestModel(model)

    if Config.useGizmo == false then
        PlaceWorkbenchRaycast(model)
    else
        PlaceWorkbenchGizmo(model)
    end
end)

--- Handle server trigger to open the admin panel
RegisterNetEvent('sd-crafting:client:openAdmin', function()
    if isAdminOpen then return end
    isAdminOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdmin',
        locale = Config.Locale or 'en',
    })
end)

--- Close the admin panel and release NUI focus
local function CloseAdminUI()
    if not isAdminOpen then return end
    isAdminOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeAdmin',
    })
end

--- Handle NUI request to close the admin panel
---@param _ any Unused data parameter
---@param cb function Callback to signal completion
RegisterNUICallback('admin:close', function(_, cb)
    CloseAdminUI()
    cb('ok')
end)

--- Handle NUI request to get paginated players for admin panel
---@param data table Pagination options { page?: number, limit?: number, search?: string }
---@param cb function Callback to return paginated player data
RegisterNUICallback('admin:getPlayers', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getPlayers', false, data)
    cb(result or {})
end)

--- Handle NUI request to get detailed player data
---@param data table Contains identifier field
---@param cb function Callback to return player detail
RegisterNUICallback('admin:getPlayerDetail', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getPlayerDetail', false, data.identifier)
    cb(result or {})
end)

--- Handle NUI request to update a player's level/XP
---@param data table Contains identifier, xp, level, workbenchType (optional), tech_points (optional)
---@param cb function Callback to return success status
RegisterNUICallback('admin:updatePlayer', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updatePlayer', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to reset a player's data
---@param data table Contains identifier field
---@param cb function Callback to return success status
RegisterNUICallback('admin:resetPlayer', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:resetPlayer', false, data.identifier)
    cb({ success = result or false })
end)

--- Handle NUI request to toggle a tech tree node for a player
---@param data table Contains identifier and nodeId fields
---@param cb function Callback to return success status and new unlocked state
RegisterNUICallback('admin:toggleBlueprint', function(data, cb)
    local success, isUnlocked = lib.callback.await('sd-crafting:server:admin:toggleBlueprint', false, data)
    cb({ success = success or false, isUnlocked = isUnlocked })
end)

--- Handle NUI request to get all active crafting queues
---@param _ any Unused data parameter
---@param cb function Callback to return queue data
RegisterNUICallback('admin:getQueues', function(_, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getQueues', false)
    cb(result or {})
end)

--- Handle NUI request to cancel a queue item with refund
---@param data table Contains identifier, itemId, type, stationId
---@param cb function Callback to return success status
RegisterNUICallback('admin:cancelQueue', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:cancelQueue', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to force-complete a queue item
---@param data table Contains identifier, itemId, type, stationId
---@param cb function Callback to return success status
RegisterNUICallback('admin:forceCompleteQueue', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:forceCompleteQueue', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to remove a queue item without refund
---@param data table Contains identifier, itemId, type, stationId
---@param cb function Callback to return success status
RegisterNUICallback('admin:removeQueue', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:removeQueue', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to get all known workbench types with source and usage info
---@param _ any Unused data parameter
---@param cb function Callback to return workbench type objects
RegisterNUICallback('admin:getWorkbenchTypes', function(_, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getWorkbenchTypes', false)
    cb(result or {})
end)

--- Handle NUI request to get level XP thresholds for all workbench types
---@param _ any Unused data parameter
---@param cb function Callback to return level config per type
RegisterNUICallback('admin:getLevelConfig', function(_, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getLevelConfig', false)
    cb(result or {})
end)

--- Handle NUI request to update level XP thresholds for a workbench type
---@param data table Contains typeName, levels, and maxLevel fields
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateTypeLevelConfig', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateTypeLevelConfig', false, data)
    cb(result or { success = false })
end)

--- Handle NUI request to create a new admin workbench type
---@param data table Contains typeName field
---@param cb function Callback to return success status
RegisterNUICallback('admin:createType', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:createType', false, data)
    cb(result or { success = false })
end)

--- Handle NUI request to rename an admin workbench type
---@param data table Contains oldName and newName fields
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateType', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateType', false, data)
    cb(result or { success = false })
end)

--- Handle NUI request to delete an admin workbench type
---@param data table Contains typeName field
---@param cb function Callback to return success status
RegisterNUICallback('admin:deleteType', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteType', false, data)
    cb(result or { success = false })
end)

--- Handle NUI request to get shared tech points for a station
---@param data table Contains stationKey field
---@param cb function Callback to return tech data
RegisterNUICallback('admin:getStationTech', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getStationTech', false, data.stationKey)
    cb(result or { tech_points = 0 })
end)

--- Handle NUI request to update shared tech points for a station
---@param data table Contains stationKey and tech_points fields
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateStationTech', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateStationTech', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to get all players with access to a per-player station and their tech points
---@param data table Contains stationKey field
---@param cb function Callback to return array of player tech data
RegisterNUICallback('admin:getStationPlayersTech', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getStationPlayersTech', false, data.stationKey)
    cb(result or {})
end)

--- Handle NUI request to update a specific player's per-type tech points
---@param data table Contains identifier, workbenchType, and tech_points fields
---@param cb function Callback to return success status
RegisterNUICallback('admin:updatePlayerTechPoints', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updatePlayerTechPoints', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to reset a player's personal tech tree progress
---@param data table Contains identifier field
---@param cb function Callback to return success status
RegisterNUICallback('admin:resetPersonalTechNodes', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:resetPersonalTechNodes', false, data.identifier)
    cb({ success = result or false })
end)

--- Handle NUI request to reset a player's personal tech nodes for a specific workbench type
---@param data table Contains identifier and workbenchType fields
---@param cb function Callback to return success status
RegisterNUICallback('admin:resetPersonalTypeTechNodes', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:resetPersonalTypeTechNodes', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to reset shared tech tree progress for a station
---@param data table Contains stationKey field
---@param cb function Callback to return success status
RegisterNUICallback('admin:resetStationTechNodes', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:resetStationTechNodes', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to get all placed workbenches
---@param _ any Unused data parameter
---@param cb function Callback to return station data
RegisterNUICallback('admin:getStations', function(_, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getStations', false)
    cb(result or {})
end)

--- Handle NUI request to delete a placed workbench
---@param data table Contains id field (workbench ID)
---@param cb function Callback to return success status
RegisterNUICallback('admin:deleteStation', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteStation', false, data.id)
    cb({ success = result or false })
end)

--- Handle NUI request to teleport admin to a station's coordinates (fetches from server by ID)
---@param data table Contains id field (workbench ID)
---@param cb function Callback to signal completion
RegisterNUICallback('admin:teleportToStation', function(data, cb)
    if data.id then
        local coords = lib.callback.await('sd-crafting:server:admin:getStationCoords', false, data.id)
        if coords then
            SetEntityCoords(PlayerPedId(), coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, false)
        end
    end
    cb('ok')
end)

--- Handle NUI request to get all recipes
---@param _ any Unused data parameter
---@param cb function Callback to return recipe data
RegisterNUICallback('admin:getRecipes', function(_, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getRecipes', false)
    cb(result or {})
end)

--- Handle NUI request to update a recipe at runtime
---@param data table Contains tableName, recipeId, and fields to update
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateRecipe', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateRecipe', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to create a new recipe at runtime
---@param data table Contains tableName and recipe object
---@param cb function Callback to return result with success and id
RegisterNUICallback('admin:createRecipe', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:createRecipe', false, data)
    cb(result or { success = false })
end)

--- Handle NUI request to create a recipe table at runtime
---@param data table Contains tableName
---@param cb function Callback to return success status
RegisterNUICallback('admin:createTable', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:createTable', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to delete a recipe table at runtime
---@param data table Contains tableName
---@param cb function Callback to return result with success and optional error
RegisterNUICallback('admin:deleteTable', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteTable', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

--- Handle NUI request to delete a recipe at runtime
---@param data table Contains tableName and recipeId
---@param cb function Callback to return success status
RegisterNUICallback('admin:deleteRecipe', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteRecipe', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to get staged inventories for a station
---@param data table Contains stationId
---@param cb function Callback to return inventory data
RegisterNUICallback('admin:getStationInventories', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getStationInventories', false, data)
    cb(result or {})
end)

--- Handle NUI request to remove an item from a station's staged inventory
---@param data table Contains stationId, stagingKey, itemName, count, slot
---@param cb function Callback to return success status
RegisterNUICallback('admin:removeStationInventoryItem', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:removeStationInventoryItem', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to add an item to a station's staged inventory
---@param data table Contains stationKey, stagingKey, itemName, count
---@param cb function Callback to return result with success and optional error
RegisterNUICallback('admin:addStationInventoryItem', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:addStationInventoryItem', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

--- Handle NUI request to begin station placement with raycast
---@param data table Contains model, propEnabled, radius
---@param cb function Callback to signal start
RegisterNUICallback('admin:beginStationPlacement', function(data, cb)
    cb('ok')

    if isPlacingStation then return end
    isPlacingStation = true

    local model = data.model or 'prop_tool_bench02'
    local propEnabled = data.propEnabled ~= false
    local radius = tonumber(data.radius) or 2.0

    -- Hide admin panel (keep mounted) and release NUI focus so player can aim
    SendNUIMessage({ action = 'hideAdmin' })
    SetNuiFocus(false, false)

    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    local tempProp = nil

    if propEnabled then
        lib.requestModel(model)

        -- Create semi-transparent preview prop at a dummy position
        tempProp = CreateObject(model, 1.0, 1.0, 1.0, false, false, false)
        SetEntityHeading(tempProp, heading)
        SetEntityAlpha(tempProp, 200, false)
        SetEntityCollision(tempProp, false, false)
        FreezeEntityPosition(tempProp, true)
        SetModelAsNoLongerNeeded(model)

        if not DoesEntityExist(tempProp) then
            lib.notify({
                title = 'Station Placement',
                description = 'Failed to spawn model: ' .. model,
                type = 'error'
            })
            isPlacingStation = false
            SendNUIMessage({ action = 'showAdmin' })
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'adminStationPlacementCancelled' })
            return
        end
    end

    local currentHeading = heading
    local raycastDistance = Config.raycastDistance or 10.0
    local markerPos = nil -- Current marker position for no-prop mode (nil until first raycast hit)

    CreateThread(function()
        local scaleform = SetupPlacementScaleform()

        while isPlacingStation do
            if propEnabled and not DoesEntityExist(tempProp) then break end

            local hit, hitCoords = RayCastGamePlayCamera(raycastDistance)
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

            if hit then
                if propEnabled then
                    local success, groundZ = GetGroundZFor_3dCoord(hitCoords.x, hitCoords.y, hitCoords.z + 10.0, false)
                    if success then
                        local modelHash = GetEntityModel(tempProp)
                        local minDim, _ = GetModelDimensions(modelHash)
                        local zOffset = -minDim.z
                        SetEntityCoords(tempProp, hitCoords.x, hitCoords.y, groundZ + zOffset, false, false, false, true)
                    end
                else
                    markerPos = vector3(hitCoords.x, hitCoords.y, hitCoords.z)
                end
            end

            -- Draw raycast line and placement marker when prop is disabled
            if not propEnabled and markerPos then
                local pedCoords = GetEntityCoords(PlayerPedId())

                -- Line from player to placement point
                DrawLine(pedCoords.x, pedCoords.y, pedCoords.z, markerPos.x, markerPos.y, markerPos.z + 0.5, 255, 255, 255, 150)

                -- Red sphere at the placement point
                DrawMarker(28, markerPos.x, markerPos.y, markerPos.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.6, 0.6, 255, 50, 50, 180, false, true, 2, false, nil, nil, false)

                -- Flat circle on the ground showing the station radius
                DrawMarker(1, markerPos.x, markerPos.y, markerPos.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2, radius * 2, 0.05, 255, 50, 50, 150, false, false, 2, false, nil, nil, false)
            end

            -- Rotation controls (scroll wheel / arrow keys, shift for fine rotation)
            local isShiftHeld = IsControlPressed(0, 21)
            local rotationStep = isShiftHeld and 1.0 or 5.0

            if IsControlJustPressed(0, 15) then -- Scroll up / Right arrow
                currentHeading = (currentHeading + rotationStep) % 360
                if propEnabled then SetEntityHeading(tempProp, currentHeading) end
            end
            if IsControlJustPressed(0, 14) then -- Scroll down / Left arrow
                currentHeading = (currentHeading - rotationStep + 360) % 360
                if propEnabled then SetEntityHeading(tempProp, currentHeading) end
            end

            -- Cancel (Backspace)
            if IsControlJustPressed(0, 177) then
                if propEnabled then DeleteEntity(tempProp) end
                isPlacingStation = false

                Wait(100)

                SendNUIMessage({ action = 'showAdmin' })
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'adminStationPlacementCancelled' })

                lib.notify({
                    title = 'Station Placement',
                    description = 'Placement cancelled',
                    type = 'error'
                })
                return
            end

            -- Confirm (Enter)
            if IsControlJustPressed(0, 176) then
                if not propEnabled and not markerPos then
                    Wait(0)
                    goto continue
                end

                local finalX, finalY, finalZ, finalH

                if propEnabled then
                    local finalCoords = GetEntityCoords(tempProp)
                    finalH = GetEntityHeading(tempProp)
                    finalX = finalCoords.x
                    finalY = finalCoords.y
                    finalZ = finalCoords.z
                else
                    finalX = markerPos.x
                    finalY = markerPos.y
                    finalZ = markerPos.z
                    finalH = currentHeading
                end

                local x = math.floor(finalX * 100 + 0.5) / 100
                local y = math.floor(finalY * 100 + 0.5) / 100
                local z = math.floor(finalZ * 100 + 0.5) / 100
                local h = math.floor(finalH * 100 + 0.5) / 100

                if propEnabled then DeleteEntity(tempProp) end
                isPlacingStation = false

                Wait(100)

                -- Re-enable admin panel and send coordinates back
                SendNUIMessage({ action = 'showAdmin' })
                SetNuiFocus(true, true)
                SendNUIMessage({
                    action = 'adminStationPlaced',
                    coords = { x = x, y = y, z = z },
                    heading = h,
                })

                lib.notify({
                    title = 'Station Placement',
                    description = ('Placed at %.2f, %.2f, %.2f'):format(x, y, z),
                    type = 'success',
                    duration = 5000
                })
                return
            end

            ::continue::
            Wait(0)
        end
    end)
end)

--- Handle NUI request to save a new admin station
---@param data table Station form data
---@param cb function Callback to return result
RegisterNUICallback('admin:saveStation', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:createStation', false, data)
    cb(result or { success = false })
end)

--- Handle NUI request to update an admin station
---@param data table Contains stationKey and updated fields
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateStation', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateStation', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to delete an admin station
---@param data table Contains stationKey
---@param cb function Callback to return success status
RegisterNUICallback('admin:deleteAdminStation', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteAdminStation', false, data.stationKey)
    cb({ success = result or false })
end)

--- Handle NUI request to get all tech trees for admin panel
---@param _ any Unused data parameter
---@param cb function Callback to return tech tree data
RegisterNUICallback('admin:getTechTrees', function(_, cb)
    local result = lib.callback.await('sd-crafting:server:admin:getTechTrees', false)
    cb(result or {})
end)

--- Handle NUI request to create a new tech tree
---@param data table Contains treeId, label, icon, color
---@param cb function Callback to return success status
RegisterNUICallback('admin:createTechTree', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:createTechTree', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to update a tech tree
---@param data table Contains treeId and optional label, icon, color, nodes
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateTechTree', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateTechTree', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to create a node in a tech tree
---@param data table Contains treeId and node object
---@param cb function Callback to return success status
RegisterNUICallback('admin:createNode', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:createNode', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to update a node in a tech tree
---@param data table Contains treeId, nodeId, and fields to update
---@param cb function Callback to return success status
RegisterNUICallback('admin:updateNode', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:updateNode', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to delete a node from a tech tree
---@param data table Contains treeId and nodeId
---@param cb function Callback to return success status
RegisterNUICallback('admin:deleteNode', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteNode', false, data)
    cb({ success = result or false })
end)

--- Handle NUI request to delete a tech tree
---@param data table Contains treeId
---@param cb function Callback to return success status
RegisterNUICallback('admin:deleteTechTree', function(data, cb)
    local result = lib.callback.await('sd-crafting:server:admin:deleteTechTree', false, data)
    cb({ success = result or false })
end)
