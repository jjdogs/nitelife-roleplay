--- Client-side bridge functions for sd-crafting
--- Handles notifications, target system, and inventory images

--- Table of supported inventory systems.
local inventories = {
    { name = "ox_inventory" },
    { name = "tgiann-inventory" },
    { name = "jaksam_inventory" },
    { name = "qs-inventory" },
    { name = "qs-inventory-pro" },
    { name = "origen_inventory" },
    { name = "qb-inventory" },
    { name = "ps-inventory" },
    { name = "lj-inventory" },
    { name = "codem-inventory" }
}

--- Selects and returns the function for retrieving item image paths.
--- @return function Function to get item image path
local SelectInventoryImagePath = function()
    for _, resource in ipairs(inventories) do
        if GetResourceState(resource.name) == 'started' then
            if resource.name == "ox_inventory" then
                return function(item)
                    local itemData = exports.ox_inventory:Items(item)

                    if itemData and itemData.client and itemData.client.image then
                        local imageName = itemData.client.image
                        if imageName:match('^nui://') or imageName:match('^https?://') then
                            return imageName
                        end
                        return string.format("nui://%s/web/images/%s", resource.name, imageName)
                    end

                    if itemData and itemData.image then
                        local imageName = itemData.image
                        if imageName:match('^nui://') or imageName:match('^https?://') then
                            return imageName
                        end
                        return string.format("nui://%s/web/images/%s", resource.name, imageName)
                    end

                    return string.format("nui://%s/web/images/%s.png", resource.name, item)
                end
            elseif resource.name == "tgiann-inventory" then
                -- tgiann-inventory uses a separate resource called 'inventory_images' for images
                local imageResource = GetResourceState('inventory_images') == 'started' and 'inventory_images' or resource.name
                local imagePath = imageResource == 'inventory_images' and 'images' or 'web/images'
                return function(item)
                    local success, itemData = pcall(function()
                        return exports['tgiann-inventory']:Items(item)
                    end)
                    if success and itemData then
                        if itemData.client and itemData.client.image then
                            local imageName = itemData.client.image
                            if imageName:match('^nui://') or imageName:match('^https?://') then
                                return imageName
                            end
                            return string.format("nui://%s/%s/%s", imageResource, imagePath, imageName)
                        end
                        if itemData.image then
                            local imageName = itemData.image
                            if imageName:match('^nui://') or imageName:match('^https?://') then
                                return imageName
                            end
                            return string.format("nui://%s/%s/%s", imageResource, imagePath, imageName)
                        end
                    end
                    return string.format("nui://%s/%s/%s.png", imageResource, imagePath, item)
                end
            elseif resource.name == "jaksam_inventory" then
                return function(item)
                    -- jaksam_inventory has getItemImagePath export
                    local imagePath = exports.jaksam_inventory:getItemImagePath(item)
                    if imagePath then
                        return imagePath
                    end
                    return string.format("nui://%s/web/images/%s.png", resource.name, item)
                end
            elseif resource.name == "codem-inventory" then
                return function(item)
                    return string.format("nui://%s/html/itemimages/%s.png", resource.name, item)
                end
            elseif resource.name == "origen_inventory" then
                return function(item)
                    return string.format("nui://%s/ui/images/%s.png", resource.name, item)
                end
            elseif resource.name == "qb-inventory" or resource.name == "lj-inventory" or
                   resource.name == "ps-inventory" or resource.name == "qs-inventory" or
                   resource.name == "qs-inventory-pro" then
                return function(item)
                    return string.format("nui://%s/html/images/%s.png", resource.name, item)
                end
            end
        end
    end
    return function(item)
        return nil
    end
end

local GetImagePathForItem = SelectInventoryImagePath()

--- Cache for item image paths to avoid repeated string formatting
local ImageCache = {}

--- Gets item image path for the inventory system (with caching).
--- @param item string The item name
--- @return string|nil The image path
GetItemImage = function(item)
    if not item then return nil end

    -- Check cache first
    local cached = ImageCache[item]
    if cached then
        return cached
    end

    -- Generate and cache the image path
    local imagePath = GetImagePathForItem(item)
    ImageCache[item] = imagePath
    return imagePath
end

--- Clears the image cache (useful if inventory resource changes)
ClearImageCache = function()
    ImageCache = {}
end

--- Selects and returns the function for retrieving item labels.
--- @return function Function to get item label
local SelectGetItemLabelFunction = function()
    for _, resource in ipairs(inventories) do
        if GetResourceState(resource.name) == 'started' then
            if resource.name == "ox_inventory" then
                return function(itemName)
                    local item = exports.ox_inventory:Items(itemName)
                    return item and item.label or nil
                end
            elseif resource.name == "tgiann-inventory" then
                return function(itemName)
                    local success, item = pcall(function()
                        return exports['tgiann-inventory']:Items(itemName)
                    end)
                    if success and item then
                        return item.label
                    end
                    -- Fallback to framework items
                    if QBCore and QBCore.Shared and QBCore.Shared.Items then
                        local qbItem = QBCore.Shared.Items[itemName]
                        return qbItem and qbItem.label or nil
                    end
                    return nil
                end
            elseif resource.name == "jaksam_inventory" then
                return function(itemName)
                    local label = exports.jaksam_inventory:getItemLabel(itemName)
                    return label
                end
            elseif resource.name == "qb-inventory" or resource.name == "lj-inventory" or resource.name == "ps-inventory" then
                return function(itemName)
                    if QBCore and QBCore.Shared and QBCore.Shared.Items then
                        local item = QBCore.Shared.Items[itemName]
                        return item and item.label or nil
                    end
                    return nil
                end
            elseif resource.name == "qs-inventory" or resource.name == "qs-inventory-pro" then
                return function(itemName)
                    if QBCore and QBCore.Shared and QBCore.Shared.Items then
                        local item = QBCore.Shared.Items[itemName]
                        return item and item.label or nil
                    end
                    return nil
                end
            elseif resource.name == "codem-inventory" then
                return function(itemName)
                    if QBCore and QBCore.Shared and QBCore.Shared.Items then
                        local item = QBCore.Shared.Items[itemName]
                        return item and item.label or nil
                    end
                    return nil
                end
            end
        end
    end
    -- Framework fallback
    return function(itemName)
        if Framework == 'qb' and QBCore and QBCore.Shared and QBCore.Shared.Items then
            local item = QBCore.Shared.Items[itemName]
            return item and item.label or nil
        end
        return nil
    end
end

local GetItemLabelFunc = SelectGetItemLabelFunction()

--- Cache for item labels to avoid repeated lookups
local ItemLabelCache = {}

--- Gets item label from the inventory system (with caching).
--- @param itemName string The item name
--- @return string|nil The item label or nil if not found
GetItemLabel = function(itemName)
    if not itemName then return nil end

    -- Check cache first
    local cached = ItemLabelCache[itemName]
    if cached ~= nil then
        return cached == false and nil or cached
    end

    -- Get label and cache it
    local label = GetItemLabelFunc(itemName)
    ItemLabelCache[itemName] = label or false
    return label
end

--- Clears the item label cache
ClearItemLabelCache = function()
    ItemLabelCache = {}
end

--- Notification System
local EnableNotifOX = true -- Enable use of ox_lib for notifications if available

--- Selects and returns the most appropriate notification function based on the current game setup.
---@return function A function configured to show notifications using the determined method.
local CreateNotificationFunction = function()
    if lib ~= nil and EnableNotifOX then
        return function(data)
            lib.notify({
                id = math.random(1, 999999),
                title = data.title,
                description = data.description,
                type = data.type or 'inform'
            })
        end
    else
        if Framework == 'esx' then
            return function(data)
                ESX.ShowNotification(data.description)
            end
        elseif Framework == 'qb' then
            return function(data)
                QBCore.Functions.Notify(data.description, data.type or 'info')
            end
        end

        return function(data)
            error(string.format("Notification system not supported. Message was: %s, Type was: %s", data.description, data.type))
        end
    end
end

--- The chosen method for showing notifications, determined at the time of script initialization.
local Notify = CreateNotificationFunction()

--- Display a notification to the user.
---@param data table The notification data {title, description, type}
ShowNotification = function(data)
    Notify(data)
end

--- Target System
Target = {}
local target = nil

--- Initialize the target system by checking available resources and setting the target module.
local Initialize = function()
    local resources = {"ox_target", "qb-target", "qtarget"}
    for _, resource in ipairs(resources) do
        if GetResourceState(resource) == 'started' then
            target = resource
            break
        end
    end

    if not target then
        print("^1[SD-CRAFTING] No target resource found or started.^0")
        return false
    end
    return true
end

Initialize()

--- Converts ox_target style options to qb-target/qtarget style
---@param options table ox_target style options array
---@return table qb-target style options array
local function ConvertOptions(options)
    if target == 'ox_target' then
        return options
    end

    -- Convert ox_target format to qb-target/qtarget format
    local converted = {}
    for _, option in ipairs(options) do
        table.insert(converted, {
            type = option.type or "client",
            event = option.event,
            icon = option.icon,
            label = option.label,
            action = option.onSelect,
            canInteract = option.canInteract,
            distance = option.distance,
            groups = option.groups,
            items = option.items
        })
    end
    return converted
end

--- Add a box zone (accepts ox_target params, works with all targets).
---@param data table Zone data with coords, size, rotation, debug, and options.
---@return number|string Zone ID
Target.addBoxZone = function(data)
    if target == 'ox_target' then
        return exports.ox_target:addBoxZone(data)
    else
        -- qb-target/qtarget use different API
        local name = data.name or ('box_zone_' .. math.random(100000, 999999))
        local size = data.size or vec3(2, 2, 2)
        local heading = data.rotation or 0

        return exports[target]:AddBoxZone(name, data.coords, size.x, size.y, {
            name = name,
            heading = heading,
            debugPoly = data.debug or false,
            minZ = data.coords.z - (size.z / 2),
            maxZ = data.coords.z + (size.z / 2),
        }, {
            options = ConvertOptions(data.options),
            distance = data.distance or 2.5,
        })
    end
end

--- Add a sphere zone (accepts ox_target params, works with all targets).
---@param data table Zone data with coords, radius, debug, and options.
---@return number|string Zone ID
Target.addSphereZone = function(data)
    if target == 'ox_target' then
        return exports.ox_target:addSphereZone(data)
    else
        -- qb-target/qtarget use CircleZone for spheres
        local name = data.name or ('sphere_zone_' .. math.random(100000, 999999))

        return exports[target]:AddCircleZone(name, data.coords, data.radius or 1.0, {
            name = name,
            useZ = true,
            debugPoly = data.debug or false,
        }, {
            options = ConvertOptions(data.options),
            distance = data.distance or 2.5,
        })
    end
end

--- Add a poly zone (accepts ox_target params, works with all targets).
---@param data table Zone data with points, thickness, debug, and options.
---@return number|string Zone ID
Target.addPolyZone = function(data)
    if target == 'ox_target' then
        return exports.ox_target:addPolyZone(data)
    else
        local name = data.name or ('poly_zone_' .. math.random(100000, 999999))

        return exports[target]:AddPolyZone(name, data.points, {
            name = name,
            debugPoly = data.debug or false,
            minZ = data.coords and data.coords.z - (data.thickness or 2) / 2,
            maxZ = data.coords and data.coords.z + (data.thickness or 2) / 2,
        }, {
            options = ConvertOptions(data.options),
            distance = data.distance or 2.5,
        })
    end
end

--- Add target to an entity (accepts ox_target params, works with all targets).
---@param netId number Network ID of the entity.
---@param options table Options for the target.
---@return boolean Success
Target.addEntity = function(netId, options)
    if target == 'ox_target' then
        return exports.ox_target:addEntity(netId, options)
    else
        local entity = NetworkGetEntityFromNetworkId(netId)
        exports[target]:AddTargetEntity(entity, {
            options = ConvertOptions(options),
            distance = options.distance or 2.5,
        })
        return true
    end
end

--- Add target to a local entity (accepts ox_target params, works with all targets).
---@param entity number Entity handle.
---@param options table Options for the target.
---@return boolean Success
Target.addLocalEntity = function(entity, options)
    if target == 'ox_target' then
        return exports.ox_target:addLocalEntity(entity, options)
    else
        exports[target]:AddTargetEntity(entity, {
            options = ConvertOptions(options),
            distance = options.distance or 2.5,
        })
        return true
    end
end

--- Add target to a model (accepts ox_target params, works with all targets).
---@param models table|string Model or array of models.
---@param options table Options for the target.
---@return boolean Success
Target.addModel = function(models, options)
    if target == 'ox_target' then
        return exports.ox_target:addModel(models, options)
    else
        local modelList = type(models) == 'table' and models or {models}
        exports[target]:AddTargetModel(modelList, {
            options = ConvertOptions(options),
            distance = options.distance or 2.5,
        })
        return true
    end
end

--- Remove a zone by ID (accepts ox_target params, works with all targets).
---@param id number|string Zone ID to remove.
---@return boolean Success
Target.removeZone = function(id)
    if target == 'ox_target' then
        return exports.ox_target:removeZone(id)
    else
        exports[target]:RemoveZone(id)
        return true
    end
end

--- Remove target from an entity (accepts ox_target params, works with all targets).
---@param netId number Network ID of the entity.
---@param label string|nil Optional label to remove specific option.
---@return boolean Success
Target.removeEntity = function(netId, label)
    if target == 'ox_target' then
        return exports.ox_target:removeEntity(netId, label)
    else
        local entity = NetworkGetEntityFromNetworkId(netId)
        exports[target]:RemoveTargetEntity(entity, label)
        return true
    end
end

--- Remove target from a local entity (accepts ox_target params, works with all targets).
---@param entity number Entity handle.
---@param label string|nil Optional label to remove specific option.
---@return boolean Success
Target.removeLocalEntity = function(entity, label)
    if target == 'ox_target' then
        return exports.ox_target:removeLocalEntity(entity, label)
    else
        exports[target]:RemoveTargetEntity(entity, label)
        return true
    end
end

--- Remove target from a model (accepts ox_target params, works with all targets).
---@param models table|string Model or array of models.
---@param label string|nil Optional label to remove specific option.
---@return boolean Success
Target.removeModel = function(models, label)
    if target == 'ox_target' then
        return exports.ox_target:removeModel(models, label)
    else
        local modelList = type(models) == 'table' and models or {models}
        exports[target]:RemoveTargetModel(modelList, label)
        return true
    end
end

--- Get player inventory items (client-side)
--- @return table Array of inventory items
GetPlayerInventory = function()
    local items = {}

    if GetResourceState('ox_inventory') == 'started' then
        local playerItems = exports.ox_inventory:GetPlayerItems()
        if playerItems then
            for _, item in pairs(playerItems) do
                if item.name then
                    local imagePath = GetItemImage(item.name)
                    local itemData = {
                        item = item.name,
                        label = item.label or item.name,
                        count = item.count or 1,
                        image = imagePath,
                        slot = item.slot
                    }
                    -- Include durability if present in metadata
                    if item.metadata and item.metadata.durability then
                        itemData.durability = item.metadata.durability
                    end
                    items[#items + 1] = itemData
                end
            end
        end
    elseif GetResourceState('tgiann-inventory') == 'started' then
        local success, playerItems = pcall(function()
            return exports['tgiann-inventory']:GetPlayerItems()
        end)
        if success and playerItems then
            for _, item in pairs(playerItems) do
                if item.name then
                    local imagePath = GetItemImage(item.name)
                    local itemData = {
                        item = item.name,
                        label = item.label or GetItemLabel(item.name) or item.name,
                        count = item.count or 1,
                        image = imagePath,
                        slot = item.slot
                    }
                    -- Include durability if present in metadata
                    if item.metadata and item.metadata.durability then
                        itemData.durability = item.metadata.durability
                    end
                    items[#items + 1] = itemData
                end
            end
        end
    elseif GetResourceState('jaksam_inventory') == 'started' then
        local success, inventory = pcall(function()
            return exports.jaksam_inventory:getInventory()
        end)
        if success and inventory and inventory.items then
            for slot, item in pairs(inventory.items) do
                if item and item.name then
                    local imagePath = GetItemImage(item.name)
                    local itemData = {
                        item = item.name,
                        label = item.label or exports.jaksam_inventory:getItemLabel(item.name) or item.name,
                        count = item.amount or item.count or 1,
                        image = imagePath,
                        slot = slot
                    }
                    -- Include durability if present in metadata
                    if item.metadata and item.metadata.durability then
                        itemData.durability = item.metadata.durability
                    end
                    items[#items + 1] = itemData
                end
            end
        end
    elseif GetResourceState('qb-inventory') == 'started' then
        local playerItems = exports['qb-inventory']:GetInventory()
        if playerItems then
            for _, item in pairs(playerItems) do
                if item.name then
                    items[#items + 1] = {
                        item = item.name,
                        label = item.label or item.name,
                        count = item.amount or item.count or 1,
                        image = GetItemImage(item.name)
                    }
                end
            end
        end
    elseif GetResourceState('qs-inventory') == 'started' then
        local playerItems = exports['qs-inventory']:GetInventory()
        if playerItems then
            for _, item in pairs(playerItems) do
                if item.name then
                    items[#items + 1] = {
                        item = item.name,
                        label = item.label or item.name,
                        count = item.amount or item.count or 1,
                        image = GetItemImage(item.name)
                    }
                end
            end
        end
    elseif Framework == 'qb' then
        -- Fallback to QBCore player data
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.items then
            for _, item in pairs(PlayerData.items) do
                if item and item.name then
                    items[#items + 1] = {
                        item = item.name,
                        label = item.label or item.name,
                        count = item.amount or item.count or 1,
                        image = GetItemImage(item.name)
                    }
                end
            end
        end
    end

    return items
end

--- Get the player's identifier (citizenid for QB, identifier for ESX)
---@return string|nil identifier The player's identifier or nil if not found
GetPlayerIdentifier = function()
    if Framework == 'qb' then
        local PlayerData = QBCore.Functions.GetPlayerData()
        return PlayerData and PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local PlayerData = ESX.GetPlayerData()
        return PlayerData and PlayerData.identifier or nil
    end
    return nil
end

print(string.format("^2[SD-CRAFTING]^0 Client bridge initialized - Target: ^3%s^0", target or "none"))
