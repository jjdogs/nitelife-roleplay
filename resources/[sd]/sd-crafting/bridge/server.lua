--- Server-side bridge functions for sd-crafting
--- Handles inventory, player, and money management

-- Detect inventory system
local inventorySystem
local codemInv, oxInv, qbInv, qsProInv, qsInv, origenInv, jaksamInv, tgiannInv = 'codem-inventory', 'ox_inventory', 'qb-inventory', 'qs-inventory-pro', 'qs-inventory', 'origen_inventory', 'jaksam_inventory', 'tgiann-inventory'

if GetResourceState(codemInv) == 'started' then
    inventorySystem = 'codem'
elseif GetResourceState(oxInv) == 'started' then
    inventorySystem = 'ox'
elseif GetResourceState(tgiannInv) == 'started' then
    inventorySystem = 'tgiann'
elseif GetResourceState(jaksamInv) == 'started' then
    inventorySystem = 'jaksam'
elseif GetResourceState(origenInv) == 'started' then
    inventorySystem = 'origen'
elseif GetResourceState(qbInv) == 'started' then
    inventorySystem = 'qb'
elseif GetResourceState(qsProInv) == 'started' then
    inventorySystem = 'qs-pro'
elseif GetResourceState(qsInv) == 'started' then
    inventorySystem = 'qs'
end

--- Player Management
local CreateGetPlayerFunction = function()
    if Framework == 'esx' then
        return function(source)
            return ESX.GetPlayerFromId(source)
        end
    elseif Framework == 'qb' then
        return function(source)
            return QBCore.Functions.GetPlayer(source)
        end
    else
        return function(source)
            error(string.format("Unsupported framework. Unable to retrieve player object for source: %s", source))
            return nil
        end
    end
end

GetPlayer = CreateGetPlayerFunction()

--- Get player identifier
local CreateGetIdentifierFunction = function()
    if Framework == 'esx' then
        return function(player)
            return player.identifier
        end
    elseif Framework == 'qb' then
        return function(player)
            return player.PlayerData.citizenid
        end
    else
        return function()
            error("Unsupported framework for GetIdentifier.")
        end
    end
end

local GetIdentifierFromPlayer = CreateGetIdentifierFunction()

GetIdentifier = function(source)
    local player = GetPlayer(source)
    return player and GetIdentifierFromPlayer(player) or nil
end

--- Money Management
Money = {}

local ConvertMoneyType = function(moneyType)
    if moneyType == 'money' and Framework == 'qb' then
        return 'cash'
    elseif moneyType == 'cash' and Framework == 'esx' then
        return 'money'
    else
        return moneyType
    end
end

local CreateAddMoneyFunction = function()
    if Framework == 'esx' then
        return function(player, moneyType, amount)
            player.addAccountMoney(ConvertMoneyType(moneyType), amount)
        end
    elseif Framework == 'qb' then
        return function(player, moneyType, amount)
            player.Functions.AddMoney(ConvertMoneyType(moneyType), amount)
        end
    else
        return function()
            error("Unsupported framework for AddMoney.")
        end
    end
end

local CreateRemoveMoneyFunction = function()
    if Framework == 'esx' then
        return function(player, moneyType, amount)
            player.removeAccountMoney(ConvertMoneyType(moneyType), amount)
        end
    elseif Framework == 'qb' then
        return function(player, moneyType, amount)
            player.Functions.RemoveMoney(ConvertMoneyType(moneyType), amount)
        end
    else
        return function()
            error("Unsupported framework for RemoveMoney.")
        end
    end
end

local CreateGetPlayerAccountFundsFunction = function()
    if Framework == 'esx' then
        return function(player, moneyType)
            local account = player.getAccount(ConvertMoneyType(moneyType))
            return account and account.money or 0
        end
    elseif Framework == 'qb' then
        return function(player, moneyType)
            return player.PlayerData.money[ConvertMoneyType(moneyType)] or 0
        end
    else
        return function()
            error("Unsupported framework for GetPlayerAccountFunds.")
            return 0
        end
    end
end

local AddMoneyToPlayer = CreateAddMoneyFunction()
local RemoveMoneyFromPlayer = CreateRemoveMoneyFunction()
local GetPlayerAccountFunds = CreateGetPlayerAccountFundsFunction()

Money.AddMoney = function(source, moneyType, amount)
    local player = GetPlayer(source)
    if player then
        AddMoneyToPlayer(player, moneyType, amount)
    end
end

Money.RemoveMoney = function(source, moneyType, amount)
    local player = GetPlayer(source)
    if player then
        RemoveMoneyFromPlayer(player, moneyType, amount)
    end
end

Money.GetPlayerAccountFunds = function(source, moneyType)
    local player = GetPlayer(source)
    return player and GetPlayerAccountFunds(player, moneyType) or 0
end

--- Get player name
GetPlayerFullName = function(source)
    local player = GetPlayer(source)
    if not player then return "Unknown" end

    if Framework == 'esx' then
        return player.getName()
    elseif Framework == 'qb' then
        return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    end

    return "Unknown"
end

--- Get player job
GetPlayerJob = function(source)
    local player = GetPlayer(source)
    if not player then return nil end

    if Framework == 'esx' then
        return player.job and player.job.name or nil
    elseif Framework == 'qb' then
        return player.PlayerData.job and player.PlayerData.job.name or nil
    end

    return nil
end

--- Get player gang
GetPlayerGang = function(source)
    local player = GetPlayer(source)
    if not player then return nil end

    if Framework == 'esx' then
        return nil
    elseif Framework == 'qb' then
        return player.PlayerData.gang and player.PlayerData.gang.name or nil
    end

    return nil
end

--- Get player gang grade
---@param source number Player server ID
---@return number grade The player's gang grade level (0 if unavailable)
GetPlayerGangGrade = function(source)
    local player = GetPlayer(source)
    if not player then return 0 end

    if Framework == 'qb' then
        return player.PlayerData.gang and player.PlayerData.gang.grade and player.PlayerData.gang.grade.level or 0
    end

    return 0
end

--- Inventory Management
Inventory = {}

local CreateAddItemFunction = function()
    if inventorySystem == 'ox' then
        return function(source, item, count)
            return exports[oxInv]:AddItem(source, item, count)
        end
    elseif inventorySystem == 'tgiann' then
        return function(source, item, count)
            return exports[tgiannInv]:AddItem(source, item, count)
        end
    elseif inventorySystem == 'jaksam' then
        return function(source, item, count)
            local success, _ = exports[jaksamInv]:addItem(source, item, count)
            return success
        end
    elseif inventorySystem == 'codem' then
        return function(source, item, count)
            return exports[codemInv]:AddItem(source, item, count)
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source, item, count)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            return exports[inv]:AddItem(source, item, count)
        end
    elseif inventorySystem == 'origen' then
        return function(source, item, count)
            return exports[origenInv]:addItem(source, item, count)
        end
    elseif inventorySystem == 'qb' then
        return function(source, item, count)
            return exports[qbInv]:AddItem(source, item, count)
        end
    else
        -- Framework fallback
        if Framework == 'esx' then
            return function(source, item, count)
                local player = GetPlayer(source)
                if player then
                    player.addInventoryItem(item, count)
                    return true
                end
                return false
            end
        elseif Framework == 'qb' then
            return function(source, item, count)
                local player = GetPlayer(source)
                if player then
                    return player.Functions.AddItem(item, count)
                end
                return false
            end
        end
    end
end

local AddItemToPlayer = CreateAddItemFunction()

Inventory.AddItem = function(source, item, count)
    return AddItemToPlayer(source, item, count)
end

-- HasItem / GetItemCount function
local CreateHasItemFunction = function()
    if inventorySystem == 'ox' then
        return function(source, item)
            local items = exports[oxInv]:Search(source, 'slots', item)
            if type(items) == 'table' then
                local totalCount = 0
                for _, itemData in pairs(items) do
                    totalCount = totalCount + (itemData.count or 0)
                end
                return totalCount
            end
            return 0
        end
    elseif inventorySystem == 'tgiann' then
        return function(source, item)
            return exports[tgiannInv]:GetItemCount(source, item) or 0
        end
    elseif inventorySystem == 'jaksam' then
        return function(source, item)
            return exports[jaksamInv]:getTotalItemAmount(source, item) or 0
        end
    elseif inventorySystem == 'codem' then
        return function(source, item)
            return exports[codemInv]:GetItemsTotalAmount(source, item) or 0
        end
    elseif inventorySystem == 'origen' then
        return function(source, item)
            return exports[origenInv]:getItemCount(source, item, false, false) or 0
        end
    elseif inventorySystem == 'qb' then
        return function(source, item)
            return exports[qbInv]:GetItemCount(source, item) or 0
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source, item)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            return exports[inv]:GetItemTotalAmount(source, item) or 0
        end
    else
        -- Framework fallback
        if Framework == 'esx' then
            return function(source, item)
                local player = GetPlayer(source)
                if player then
                    local itemData = player.getInventoryItem(item)
                    return itemData and (itemData.count or itemData.amount) or 0
                end
                return 0
            end
        elseif Framework == 'qb' then
            return function(source, item)
                local player = GetPlayer(source)
                if player then
                    local itemData = player.Functions.GetItemByName(item)
                    return itemData and (itemData.amount or itemData.count) or 0
                end
                return 0
            end
        end
    end
end

local GetPlayerItemCount = CreateHasItemFunction()

Inventory.HasItem = function(source, item)
    return GetPlayerItemCount(source, item)
end

Inventory.GetItemCount = function(source, item)
    return GetPlayerItemCount(source, item)
end

-- RemoveItem function
local CreateRemoveItemFunction = function()
    if inventorySystem == 'ox' then
        return function(source, item, count)
            return exports[oxInv]:RemoveItem(source, item, count)
        end
    elseif inventorySystem == 'tgiann' then
        return function(source, item, count)
            return exports[tgiannInv]:RemoveItem(source, item, count)
        end
    elseif inventorySystem == 'jaksam' then
        return function(source, item, count)
            local success, _ = exports[jaksamInv]:removeItem(source, item, count)
            return success
        end
    elseif inventorySystem == 'codem' then
        return function(source, item, count)
            return exports[codemInv]:RemoveItem(source, item, count)
        end
    elseif inventorySystem == 'origen' then
        return function(source, item, count)
            return exports[origenInv]:removeItem(source, item, count)
        end
    elseif inventorySystem == 'qb' then
        return function(source, item, count)
            return exports[qbInv]:RemoveItem(source, item, count)
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source, item, count)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            return exports[inv]:RemoveItem(source, item, count)
        end
    else
        -- Framework fallback
        if Framework == 'esx' then
            return function(source, item, count)
                local player = GetPlayer(source)
                if player then
                    player.removeInventoryItem(item, count)
                    return true
                end
                return false
            end
        elseif Framework == 'qb' then
            return function(source, item, count)
                local player = GetPlayer(source)
                if player then
                    return player.Functions.RemoveItem(item, count)
                end
                return false
            end
        end
    end
end

local RemoveItemFromPlayer = CreateRemoveItemFunction()

Inventory.RemoveItem = function(source, item, count)
    return RemoveItemFromPlayer(source, item, count)
end

-- CanCarryItem function
local CreateCanCarryItemFunction = function()
    if inventorySystem == 'codem' then
        return function(player, item, count, metadata, source)
            return true
        end
    elseif inventorySystem == 'ox' then
        return function(player, item, count, metadata, source)
            return exports[oxInv]:CanCarryItem(source, item, count, metadata)
        end
    elseif inventorySystem == 'tgiann' then
        return function(player, item, count, metadata, source)
            return exports[tgiannInv]:CanCarryItem(source, item, count, metadata)
        end
    elseif inventorySystem == 'jaksam' then
        return function(player, item, count, metadata, source)
            return exports[jaksamInv]:canCarryItem(source, item, count)
        end
    elseif inventorySystem == 'origen' then
        return function(player, item, count, metadata, source)
            return exports[origenInv]:canCarryItem(source, item, count)
        end
    elseif inventorySystem == 'qb' then
        return function(player, item, count, slot, source)
            return exports[qbInv]:CanAddItem(source, item, count)
        end
    elseif inventorySystem == 'qs-pro' then
        return function(player, item, count, metadata, source)
            return exports[qsProInv]:CanCarryItem(source, item, count)
        end
    elseif inventorySystem == 'qs' then
        return function(player, item, count, slot, source)
            return exports[qsInv]:CanCarryItem(source, item, count)
        end
    else
        if Framework == 'esx' then
            return function(player, item, count)
                local currentItem = player.getInventoryItem(item)
                if currentItem then
                    local maxWeight = player.getMaxWeight()
                    local currentWeight = player.getWeight()
                    local itemWeight = currentItem.weight or 0
                    local totalWeight = currentWeight + (itemWeight * count)
                    return totalWeight <= maxWeight
                end
                return false
            end
        elseif Framework == 'qb' then
            return function(player, item, count, slot)
                return player.Functions.CanAddItem(item, count, slot)
            end
        else
            return function()
                error("Unsupported framework for CanCarryItem.")
            end
        end
    end
end

local CanCarryItemCheck = CreateCanCarryItemFunction()

Inventory.CanCarryItem = function(source, item, count, slot)
    local player = GetPlayer(source)
    if player then
        return CanCarryItemCheck(player, item, count, slot, source)
    end
    return false
end

-- GetPlayerItems function - retrieves all items from a player's inventory
local CreateGetPlayerItemsFunction = function()
    if inventorySystem == 'ox' then
        return function(source)
            local items = exports[oxInv]:GetInventoryItems(source, false)
            if not items then return {} end

            local result = {}
            for _, item in pairs(items) do
                if item.name and item.count and item.count > 0 then
                    table.insert(result, {
                        name = item.name,
                        count = item.count,
                        label = item.label or item.name,
                        slot = item.slot,
                        metadata = item.metadata
                    })
                end
            end
            return result
        end
    elseif inventorySystem == 'tgiann' then
        return function(source)
            local items = exports[tgiannInv]:GetPlayerItems(source)
            if not items or type(items) ~= 'table' then return {} end

            local result = {}
            for _, item in pairs(items) do
                if type(item) == 'table' and item.name then
                    local itemCount = item.count or item.amount or 0
                    if itemCount > 0 then
                        table.insert(result, {
                            name = item.name,
                            count = itemCount,
                            label = item.label or Inventory.GetItemLabel(item.name) or item.name,
                            slot = item.slot,
                            metadata = item.metadata or item.info
                        })
                    end
                end
            end
            return result
        end
    elseif inventorySystem == 'jaksam' then
        return function(source)
            local inventory = exports[jaksamInv]:getInventory(source)
            if not inventory or not inventory.items then return {} end

            local result = {}
            for slot, item in pairs(inventory.items) do
                if item and item.name and item.amount and item.amount > 0 then
                    table.insert(result, {
                        name = item.name,
                        count = item.amount,
                        label = item.label or exports[jaksamInv]:getItemLabel(item.name) or item.name,
                        slot = slot,
                        metadata = item.metadata
                    })
                end
            end
            return result
        end
    elseif inventorySystem == 'codem' then
        return function(source)
            local items = exports[codemInv]:GetInventory(source)
            if not items then return {} end

            local result = {}
            for _, item in pairs(items) do
                if item.name and item.amount and item.amount > 0 then
                    table.insert(result, {
                        name = item.name,
                        count = item.amount,
                        label = item.label or item.name,
                        slot = item.slot,
                        metadata = item.metadata or item.info
                    })
                end
            end
            return result
        end
    elseif inventorySystem == 'origen' then
        return function(source)
            local items = exports[origenInv]:getItems(source)
            if not items then return {} end

            local result = {}
            for _, item in pairs(items) do
                if item.name and item.count and item.count > 0 then
                    table.insert(result, {
                        name = item.name,
                        count = item.count,
                        label = item.label or item.name,
                        slot = item.slot,
                        metadata = item.metadata or item.info
                    })
                end
            end
            return result
        end
    elseif inventorySystem == 'qb' then
        return function(source)
            local player = QBCore.Functions.GetPlayer(source)
            if not player then return {} end

            local items = player.PlayerData.items
            if not items then return {} end

            local result = {}
            for slot, item in pairs(items) do
                if item and item.name and item.amount and item.amount > 0 then
                    table.insert(result, {
                        name = item.name,
                        count = item.amount,
                        label = item.label or item.name,
                        slot = item.slot or slot,
                        metadata = item.info
                    })
                end
            end
            return result
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            local items = exports[inv]:GetInventory(source)
            if not items then return {} end

            local result = {}
            for _, item in pairs(items) do
                if item.name and item.amount and item.amount > 0 then
                    table.insert(result, {
                        name = item.name,
                        count = item.amount,
                        label = item.label or item.name,
                        slot = item.slot,
                        metadata = item.metadata or item.info
                    })
                end
            end
            return result
        end
    else
        -- Framework fallback
        if Framework == 'esx' then
            return function(source)
                local player = GetPlayer(source)
                if not player then return {} end

                local items = player.getInventory()
                if not items then return {} end

                local result = {}
                for _, item in pairs(items) do
                    if item.name and item.count and item.count > 0 then
                        table.insert(result, {
                            name = item.name,
                            count = item.count,
                            label = item.label or item.name,
                            metadata = item.metadata or item.info
                        })
                    end
                end
                return result
            end
        elseif Framework == 'qb' then
            return function(source)
                local player = GetPlayer(source)
                if not player then return {} end

                local items = player.PlayerData.items
                if not items then return {} end

                local result = {}
                for slot, item in pairs(items) do
                    if item and item.name and item.amount and item.amount > 0 then
                        table.insert(result, {
                            name = item.name,
                            count = item.amount,
                            label = item.label or item.name,
                            slot = slot,
                            metadata = item.metadata or item.info
                        })
                    end
                end
                return result
            end
        else
            return function()
                return {}
            end
        end
    end
end

local GetPlayerItemsFunc = CreateGetPlayerItemsFunction()

Inventory.GetPlayerItems = function(source)
    return GetPlayerItemsFunc(source)
end

-- GetPlayerMaxWeight function - returns the maximum inventory weight capacity for a player
-- Returns nil if unable to retrieve from inventory system (caller should use Config.MaxInventoryWeight as fallback)
local CreateGetPlayerMaxWeightFunction = function()
    if inventorySystem == 'ox' then
        return function(source)
            -- ox_inventory GetInventory returns weight and maxWeight properties
            local success, inventory = pcall(function()
                return exports[oxInv]:GetInventory(source)
            end)
            if success and inventory and inventory.maxWeight then return inventory.maxWeight end
            return nil
        end
    elseif inventorySystem == 'tgiann' then
        return function(source)
            local success, inventory = pcall(function()
                return exports[tgiannInv]:GetInventory(source)
            end)
            if success and inventory then
                if inventory.maxWeight then return inventory.maxWeight end
                if inventory.maxweight then return inventory.maxweight end
            end
            return nil
        end
    elseif inventorySystem == 'jaksam' then
        return function(source)
            local success, inventory = pcall(function()
                return exports[jaksamInv]:getInventory(source)
            end)
            if success and inventory and inventory.limits then
                return inventory.limits.maxWeight or inventory.limits.maxweight
            end
            return nil
        end
    elseif inventorySystem == 'codem' then
        return function(source)
            -- codem-inventory: try GetMaxWeight first, then GetInventory
            local success, maxWeight = pcall(function()
                return exports[codemInv]:GetMaxWeight(source)
            end)
            if success and maxWeight then return maxWeight end
            local invSuccess, inventory = pcall(function()
                return exports[codemInv]:GetInventory(source)
            end)
            if invSuccess and inventory and inventory.maxWeight then return inventory.maxWeight end
            return nil
        end
    elseif inventorySystem == 'origen' then
        return function(source)
            local success, inventory = pcall(function()
                return exports[origenInv]:getInventory(source)
            end)
            if success and inventory then
                if inventory.maxWeight then return inventory.maxWeight end
                if inventory.maxweight then return inventory.maxweight end
            end
            return nil
        end
    elseif inventorySystem == 'qb' then
        return function(source)
            -- qb-inventory: calculate maxWeight from GetFreeWeight + GetTotalWeight
            local Player = QBCore and QBCore.Functions.GetPlayer(source)
            if Player then
                local freeSuccess, freeWeight = pcall(function()
                    return exports[qbInv]:GetFreeWeight(source)
                end)
                local totalSuccess, totalWeight = pcall(function()
                    return exports[qbInv]:GetTotalWeight(Player.PlayerData.items)
                end)
                if freeSuccess and totalSuccess and freeWeight and totalWeight then
                    return freeWeight + totalWeight
                end
            end
            return nil
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            -- qs-inventory: try GetInventory which may contain maxWeight
            local success, inventory = pcall(function()
                return exports[inv]:GetInventory(source)
            end)
            if success and inventory then
                if inventory.maxWeight then return inventory.maxWeight end
                if inventory.maxweight then return inventory.maxweight end
            end
            return nil
        end
    else
        -- Framework fallback
        if Framework == 'esx' then
            return function(source)
                local player = GetPlayer(source)
                if player and player.getMaxWeight then
                    return player.getMaxWeight()
                end
                return nil
            end
        else
            return function()
                return nil
            end
        end
    end
end

local GetPlayerMaxWeightFunc = CreateGetPlayerMaxWeightFunction()

--- Get the maximum inventory weight capacity for a player
--- Returns nil if unable to retrieve - caller should fallback to Config.MaxInventoryWeight
---@param source number Player server ID
---@return number|nil maxWeight The maximum weight in grams, or nil if unable to retrieve
Inventory.GetPlayerMaxWeight = function(source)
    return GetPlayerMaxWeightFunc(source)
end

-- GetItemLabel function
local CreateGetItemLabelFunction = function()
    if inventorySystem == 'ox' then
        return function(itemName)
            local item = exports[oxInv]:Items(itemName)
            return item and item.label or itemName
        end
    elseif inventorySystem == 'tgiann' then
        return function(itemName)
            local success, item = pcall(function()
                return exports[tgiannInv]:Items(itemName)
            end)
            if success and item then
                return item.label or itemName
            end
            -- Fallback to framework items
            if Framework == 'qb' and QBCore and QBCore.Shared and QBCore.Shared.Items then
                local qbItem = QBCore.Shared.Items[itemName]
                return qbItem and qbItem.label or itemName
            end
            return itemName
        end
    elseif inventorySystem == 'jaksam' then
        return function(itemName)
            local label = exports[jaksamInv]:getItemLabel(itemName)
            return label or itemName
        end
    elseif inventorySystem == 'codem' then
        return function(itemName)
            if Framework == 'qb' then
                local item = QBCore.Shared.Items[itemName]
                return item and item.label or itemName
            elseif Framework == 'esx' then
                local item = ESX.GetItemLabel(itemName)
                return item or itemName
            end
            return itemName
        end
    elseif inventorySystem == 'origen' then
        return function(itemName)
            local label = exports[origenInv]:GetItemLabel(itemName)
            return label or itemName
        end
    elseif inventorySystem == 'qb' then
        return function(itemName)
            local item = QBCore.Shared.Items[itemName]
            return item and item.label or itemName
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(itemName)
            if Framework == 'qb' then
                local item = QBCore.Shared.Items[itemName]
                return item and item.label or itemName
            elseif Framework == 'esx' then
                local item = ESX.GetItemLabel(itemName)
                return item or itemName
            end
            return itemName
        end
    else
        -- Framework fallback
        if Framework == 'esx' then
            return function(itemName)
                local item = ESX.GetItemLabel(itemName)
                return item or itemName
            end
        elseif Framework == 'qb' then
            return function(itemName)
                local item = QBCore.Shared.Items[itemName]
                return item and item.label or itemName
            end
        else
            return function(itemName)
                return itemName
            end
        end
    end
end

local GetItemLabelFunc = CreateGetItemLabelFunction()

-- Cache for item labels to avoid repeated lookups
local ItemLabelCache = {}

Inventory.GetItemLabel = function(itemName)
    if not itemName then return nil end

    -- Check cache first
    local cached = ItemLabelCache[itemName]
    if cached ~= nil then
        return cached == false and itemName or cached
    end

    -- Get label and cache it
    local label = GetItemLabelFunc(itemName)
    ItemLabelCache[itemName] = label or false
    return label or itemName
end

-- GetItemWeight function - returns the weight of a single item
-- Cache for qs-inventory item list (loaded once on first use)
local qsItemListCache = nil

local CreateGetItemWeightFunction = function()
    if inventorySystem == 'ox' then
        -- ox_inventory has Items export that returns item data with weight
        return function(itemName)
            local item = exports[oxInv]:Items(itemName)
            return item and item.weight or 0
        end
    elseif inventorySystem == 'tgiann' then
        return function(itemName)
            local success, item = pcall(function()
                return exports[tgiannInv]:Items(itemName)
            end)
            if success and item then
                return item.weight or 0
            end
            -- Fallback to framework items
            if Framework == 'qb' and QBCore and QBCore.Shared and QBCore.Shared.Items then
                local qbItem = QBCore.Shared.Items[itemName]
                return qbItem and qbItem.weight or 0
            end
            return 0
        end
    elseif inventorySystem == 'jaksam' then
        return function(itemName)
            local item = exports[jaksamInv]:getStaticItem(itemName)
            return item and item.weight or 0
        end
    elseif inventorySystem == 'codem' then
        -- Codem-inventory uses framework items for item definitions
        return function(itemName)
            if Framework == 'qb' then
                local item = QBCore.Shared.Items[itemName]
                return item and item.weight or 0
            elseif Framework == 'esx' then
                -- ESX items are typically defined in database or shared config
                local items = ESX.GetItems()
                if items and items[itemName] then
                    return items[itemName].weight or 0
                end
                return 0
            end
            return 0
        end
    elseif inventorySystem == 'origen' then
        return function(itemName)
            local item = exports[origenInv]:Items(itemName)
            return item and item.weight or 0
        end
    elseif inventorySystem == 'qb' then
        -- qb-inventory uses QBCore.Shared.Items
        return function(itemName)
            local item = QBCore.Shared.Items[itemName]
            return item and item.weight or 0
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        -- qs-inventory has GetItemList export that returns all items with weight
        local inv = inventorySystem == 'qs' and qsInv or qsProInv
        return function(itemName)
            -- Try to get from qs-inventory's own item list first
            if not qsItemListCache then
                local success, itemList = pcall(function()
                    return exports[inv]:GetItemList()
                end)
                if success and itemList then
                    qsItemListCache = itemList
                end
            end

            if qsItemListCache and qsItemListCache[itemName] then
                return qsItemListCache[itemName].weight or 0
            end

            -- Fallback to framework items
            if Framework == 'qb' then
                local item = QBCore.Shared.Items[itemName]
                return item and item.weight or 0
            elseif Framework == 'esx' then
                local items = ESX.GetItems()
                if items and items[itemName] then
                    return items[itemName].weight or 0
                end
                return 0
            end
            return 0
        end
    else
        -- Framework fallback (no specific inventory system detected)
        if Framework == 'esx' then
            return function(itemName)
                local items = ESX.GetItems()
                if items and items[itemName] then
                    return items[itemName].weight or 0
                end
                return 0
            end
        elseif Framework == 'qb' then
            return function(itemName)
                local item = QBCore.Shared.Items[itemName]
                return item and item.weight or 0
            end
        else
            return function()
                return 0
            end
        end
    end
end

local GetItemWeightFunc = CreateGetItemWeightFunction()

-- Cache for item weights to avoid repeated lookups
local ItemWeightCache = {}

--- Get the weight of a single item type
--- @param itemName string The item name
--- @return number weight The weight of the item (0 if not found)
Inventory.GetItemWeight = function(itemName)
    if not itemName then return 0 end

    -- Check cache first
    local cached = ItemWeightCache[itemName]
    if cached ~= nil then
        return cached
    end

    -- Get weight and cache it
    local weight = GetItemWeightFunc(itemName) or 0
    ItemWeightCache[itemName] = weight
    return weight
end

--- Get the total weight for a quantity of items
--- @param itemName string The item name
--- @param count number The quantity of items
--- @return number totalWeight The total weight (item weight * count)
Inventory.GetItemsTotalWeight = function(itemName, count)
    local weight = Inventory.GetItemWeight(itemName)
    return weight * (count or 1)
end

--- Get the total weight of multiple different items
--- @param items table Array of {item = string, count = number} or {name = string, count = number}
--- @return number totalWeight The combined total weight of all items
Inventory.GetMultipleItemsWeight = function(items)
    if not items or type(items) ~= 'table' then return 0 end

    local totalWeight = 0
    for _, itemData in pairs(items) do
        local itemName = itemData.item or itemData.name
        local count = itemData.count or itemData.amount or 1
        if itemName then
            totalWeight = totalWeight + Inventory.GetItemsTotalWeight(itemName, count)
        end
    end
    return totalWeight
end

--- Check if an item is stackable
--- @param itemName string The item name
--- @return boolean isStackable Whether the item can be stacked
local CreateIsItemStackableFunction = function()
    if inventorySystem == 'ox' then
        return function(itemName)
            local item = exports[oxInv]:Items(itemName)
            if item then
                -- ox_inventory: stack can be false, nil, or a number
                -- If stack is false or nil, item is not stackable
                -- If stack is 1, item is not stackable (can only have 1 per slot)
                -- If stack > 1 or true, item is stackable
                if item.stack == false or item.stack == nil then
                    return false
                elseif type(item.stack) == 'number' and item.stack <= 1 then
                    return false
                end
                return true
            end
            return true -- Default to stackable if item not found
        end
    elseif inventorySystem == 'tgiann' then
        return function(itemName)
            local success, item = pcall(function()
                return exports[tgiannInv]:Items(itemName)
            end)
            if success and item then
                if item.stack == false or item.stack == nil then
                    return false
                elseif type(item.stack) == 'number' and item.stack <= 1 then
                    return false
                end
                return true
            end
            return true
        end
    elseif inventorySystem == 'jaksam' then
        return function(itemName)
            local item = exports[jaksamInv]:getStaticItem(itemName)
            if item then
                -- jaksam_inventory uses stackable and maxStack properties
                if item.stackable == false then
                    return false
                end
                if item.maxStack and item.maxStack <= 1 then
                    return false
                end
                return true
            end
            return true
        end
    elseif inventorySystem == 'qb' or inventorySystem == 'codem' then
        return function(itemName)
            if QBCore and QBCore.Shared and QBCore.Shared.Items then
                local item = QBCore.Shared.Items[itemName]
                if item then
                    -- QB-Core: unique items are not stackable
                    if item.unique then
                        return false
                    end
                    -- Check stackable property if it exists
                    if item.stackable == false then
                        return false
                    end
                end
            end
            return true -- Default to stackable
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(itemName)
            if QBCore and QBCore.Shared and QBCore.Shared.Items then
                local item = QBCore.Shared.Items[itemName]
                if item then
                    if item.unique then
                        return false
                    end
                    if item.stackable == false then
                        return false
                    end
                end
            end
            return true
        end
    else
        -- Default fallback - assume stackable
        return function(itemName)
            return true
        end
    end
end

local IsItemStackableFunc = CreateIsItemStackableFunction()

--- Cache for item stackability to avoid repeated lookups
local ItemStackableCache = {}

--- Check if an item is stackable (with caching)
--- @param itemName string The item name
--- @return boolean isStackable Whether the item can be stacked
Inventory.IsItemStackable = function(itemName)
    if not itemName then return true end

    -- Check cache first
    local cached = ItemStackableCache[itemName]
    if cached ~= nil then
        return cached
    end

    -- Get stackability and cache it
    local stackable = IsItemStackableFunc(itemName)
    ItemStackableCache[itemName] = stackable
    return stackable
end

--- Job Management
Job = {}

-- Get player's job name
local CreateGetPlayerJobNameFunction = function()
    if Framework == 'esx' then
        return function(player)
            return player.job and player.job.name or nil
        end
    elseif Framework == 'qb' then
        return function(player)
            return player.PlayerData.job and player.PlayerData.job.name or nil
        end
    else
        return function()
            return nil
        end
    end
end

local GetPlayerJobNameFunc = CreateGetPlayerJobNameFunction()

Job.GetJobName = function(source)
    local player = GetPlayer(source)
    return player and GetPlayerJobNameFunc(player) or nil
end

-- Get player's job grade
local CreateGetPlayerJobGradeFunction = function()
    if Framework == 'esx' then
        return function(player)
            return player.job and player.job.grade or 0
        end
    elseif Framework == 'qb' then
        return function(player)
            return player.PlayerData.job and player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
        end
    else
        return function()
            return 0
        end
    end
end

local GetPlayerJobGradeFunc = CreateGetPlayerJobGradeFunction()

Job.GetJobGrade = function(source)
    local player = GetPlayer(source)
    return player and GetPlayerJobGradeFunc(player) or 0
end

-- Check if player has a specific job with minimum grade
Job.HasJob = function(source, jobName, minGrade)
    minGrade = minGrade or 0
    local playerJob = Job.GetJobName(source)
    local playerGrade = Job.GetJobGrade(source)

    if playerJob == jobName then
        return playerGrade >= minGrade
    end

    return false
end

--- RegisterUsableItem - Registers a callback for when an item is used
local CreateRegisterUsableItemFunction = function()
    if inventorySystem == 'ox' then
        return function(item, cb)
            -- ox_inventory uses exports with naming convention: use + ItemName (first letter capitalized)
            local exportName = 'use' .. item:gsub("^%l", string.upper)
            exports(exportName, function(event, itemData, inventory, slot, data)
                if event == 'usingItem' then
                    cb(inventory.id, itemData, inventory, slot, data)
                end
            end)
        end
    elseif inventorySystem == 'tgiann' then
        return function(item, cb)
            -- tgiann-inventory supports framework-style usable item registration
            if Framework == 'qb' then
                QBCore.Functions.CreateUseableItem(item, cb)
            elseif Framework == 'esx' then
                ESX.RegisterUsableItem(item, cb)
            end
        end
    elseif inventorySystem == 'jaksam' then
        return function(item, cb)
            -- jaksam_inventory supports RegisterUsableItem export
            exports[jaksamInv]:RegisterUsableItem(item, cb)
        end
    elseif inventorySystem == 'qs-pro' then
        return function(item, cb)
            return exports[qsProInv]:CreateUsableItem(item, cb)
        end
    elseif inventorySystem == 'origen' then
        return function(item, cb)
            return exports[origenInv]:CreateUseableItem(item, cb)
        end
    elseif inventorySystem == 'codem' then
        return function(item, cb)
            if Framework == 'qb' then
                QBCore.Functions.CreateUseableItem(item, cb)
            elseif Framework == 'esx' then
                ESX.RegisterUsableItem(item, cb)
            end
        end
    elseif inventorySystem == 'qb' then
        return function(item, cb)
            QBCore.Functions.CreateUseableItem(item, cb)
        end
    elseif inventorySystem == 'qs' then
        return function(item, cb)
            if Framework == 'qb' then
                QBCore.Functions.CreateUseableItem(item, cb)
            elseif Framework == 'esx' then
                ESX.RegisterUsableItem(item, cb)
            end
        end
    else
        if Framework == 'esx' then
            return function(item, cb)
                ESX.RegisterUsableItem(item, cb)
            end
        elseif Framework == 'qb' then
            return function(item, cb)
                QBCore.Functions.CreateUseableItem(item, cb)
            end
        else
            return function(item, cb)
                error("RegisterUsableItem is not supported in the current framework/inventory.")
            end
        end
    end
end

local RegisterUsableItemFunc = CreateRegisterUsableItemFunction()

Inventory.RegisterUsableItem = function(item, cb)
    RegisterUsableItemFunc(item, cb)
end

--- Check if using ox_inventory (required for durability system)
---@return boolean isOx Whether ox_inventory is being used
Inventory.IsOxInventory = function()
    return inventorySystem == 'ox'
end

--- Get all items with full data including metadata (ox_inventory only)
--- Returns items with slot, name, count, and metadata
---@param source number Player server ID
---@param itemName string|nil Optional filter by item name
---@return table|nil items Array of item data with metadata
Inventory.GetItemsWithMetadata = function(source, itemName)
    if inventorySystem ~= 'ox' then return nil end

    local items = exports[oxInv]:GetInventoryItems(source, false)
    if not items then return nil end

    local result = {}
    for slot, item in pairs(items) do
        if item and item.name and item.count and item.count > 0 then
            if not itemName or item.name == itemName then
                result[#result + 1] = {
                    slot = item.slot or slot,
                    name = item.name,
                    count = item.count,
                    metadata = item.metadata or {}
                }
            end
        end
    end

    return result
end

--- Set item metadata in a specific slot (ox_inventory only)
---@param source number Player server ID
---@param slot number The inventory slot
---@param metadata table The new metadata to set
---@return boolean success Whether the operation succeeded
Inventory.SetSlotMetadata = function(source, slot, metadata)
    if inventorySystem ~= 'ox' then return false end

    local success = exports[oxInv]:SetMetadata(source, slot, metadata)
    return success ~= false
end

--- Remove item from a specific slot (ox_inventory only)
---@param source number Player server ID
---@param itemName string The item name
---@param count number Amount to remove
---@param slot number The specific slot to remove from
---@return boolean success Whether the operation succeeded
Inventory.RemoveItemFromSlot = function(source, itemName, count, slot)
    if inventorySystem ~= 'ox' then return false end

    return exports[oxInv]:RemoveItem(source, itemName, count, nil, slot)
end

--- Add item with metadata (ox_inventory only)
---@param source number Player server ID
---@param itemName string The item name
---@param count number Amount to add
---@param metadata table|nil Optional metadata to set
---@return boolean success Whether the operation succeeded
Inventory.AddItemWithMetadata = function(source, itemName, count, metadata)
    if inventorySystem ~= 'ox' then
        return Inventory.AddItem(source, itemName, count)
    end

    return exports[oxInv]:AddItem(source, itemName, count, metadata)
end

--- Get total inventory slots for a player
--- Returns the maximum number of slots in the player's inventory
---@param source number Player server ID
---@return number slots Total inventory slots
local CreateGetInventorySlotsFunction = function()
    if inventorySystem == 'ox' then
        return function(source)
            local inventory = exports[oxInv]:GetInventory(source)
            if inventory and inventory.slots then
                return inventory.slots
            end
            return 50 -- Default for ox_inventory
        end
    elseif inventorySystem == 'tgiann' then
        return function(source)
            local success, inventory = pcall(function()
                return exports[tgiannInv]:GetInventory(source)
            end)
            if success and inventory then
                if inventory.slots then return inventory.slots end
                if inventory.maxSlots then return inventory.maxSlots end
            end
            return 50 -- Default fallback
        end
    elseif inventorySystem == 'jaksam' then
        return function(source)
            local success, inventory = pcall(function()
                return exports[jaksamInv]:getInventory(source)
            end)
            if success and inventory and inventory.limits then
                return inventory.limits.maxSlots or inventory.limits.slots or 50
            end
            return 50 -- Default fallback
        end
    elseif inventorySystem == 'codem' then
        return function(source)
            local success, slots = pcall(function()
                return exports[codemInv]:GetSlots(source)
            end)
            if success and slots then return slots end
            return 40 -- Default fallback
        end
    elseif inventorySystem == 'origen' then
        return function(source)
            local success, inventory = pcall(function()
                return exports[origenInv]:getInventory(source)
            end)
            if success and inventory then
                if inventory.slots then return inventory.slots end
                if inventory.maxSlots then return inventory.maxSlots end
            end
            return 50 -- Default fallback
        end
    elseif inventorySystem == 'qb' then
        return function(source)
            -- qb-inventory typically uses 41 slots (configurable in their config)
            local success, config = pcall(function()
                return exports[qbInv]:GetConfig()
            end)
            if success and config and config.MaxSlots then
                return config.MaxSlots
            end
            return 41 -- Default for qb-inventory
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            local success, inventory = pcall(function()
                return exports[inv]:GetInventory(source)
            end)
            if success and inventory then
                -- qs-inventory may have slots info
                if inventory.slots then return inventory.slots end
                if inventory.maxSlots then return inventory.maxSlots end
            end
            return 41 -- Default fallback
        end
    else
        return function()
            return 41 -- Generic fallback
        end
    end
end

local GetInventorySlotsFunc = CreateGetInventorySlotsFunction()

--- Get total inventory slots for a player
---@param source number Player server ID
---@return number slots Total inventory slots
Inventory.GetInventorySlots = function(source)
    return GetInventorySlotsFunc(source)
end

--- Add item to a specific slot in player inventory
---@param source number Player server ID
---@param itemName string The item name
---@param count number Amount to add
---@param slot number|nil The target slot (nil = first available)
---@param metadata table|nil Optional metadata
---@return boolean success Whether the operation succeeded
local CreateAddItemToSlotFunction = function()
    if inventorySystem == 'ox' then
        return function(source, itemName, count, slot, metadata)
            return exports[oxInv]:AddItem(source, itemName, count, metadata, slot)
        end
    elseif inventorySystem == 'tgiann' then
        return function(source, itemName, count, slot, metadata)
            if type(metadata) == 'string' then metadata = json.decode(metadata) or nil
            elseif type(metadata) ~= 'table' then metadata = nil end
            exports[tgiannInv]:AddItem(source, itemName, count, metadata)
            return true
        end
    elseif inventorySystem == 'jaksam' then
        return function(source, itemName, count, slot, metadata)
            local success, _ = exports[jaksamInv]:addItem(source, itemName, count, metadata, slot)
            return success
        end
    elseif inventorySystem == 'codem' then
        return function(source, itemName, count, slot, metadata)
            return exports[codemInv]:AddItem(source, itemName, count, slot, metadata)
        end
    elseif inventorySystem == 'origen' then
        return function(source, itemName, count, slot, metadata)
            return exports[origenInv]:addItem(source, itemName, count, metadata, slot)
        end
    elseif inventorySystem == 'qb' then
        return function(source, itemName, count, slot, metadata)
            return exports[qbInv]:AddItem(source, itemName, count, slot, metadata)
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source, itemName, count, slot, metadata)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            return exports[inv]:AddItem(source, itemName, count, slot, metadata)
        end
    else
        -- Framework fallback - no slot support, just add item
        return function(source, itemName, count, slot, metadata)
            return Inventory.AddItem(source, itemName, count)
        end
    end
end

local AddItemToSlotFunc = CreateAddItemToSlotFunction()

--- Add item to a specific slot in player inventory
---@param source number Player server ID
---@param itemName string The item name
---@param count number Amount to add
---@param slot number|nil The target slot (nil = first available)
---@param metadata table|nil Optional metadata
---@return boolean success Whether the operation succeeded
Inventory.AddItemToSlot = function(source, itemName, count, slot, metadata)
    return AddItemToSlotFunc(source, itemName, count, slot, metadata)
end

--- Remove item from a specific slot (supports all inventory systems)
---@param source number Player server ID
---@param itemName string The item name
---@param count number Amount to remove
---@param slot number|nil The specific slot to remove from (nil = any slot)
---@return boolean success Whether the operation succeeded
local CreateRemoveItemFromSlotFunction = function()
    if inventorySystem == 'ox' then
        return function(source, itemName, count, slot)
            return exports[oxInv]:RemoveItem(source, itemName, count, nil, slot)
        end
    elseif inventorySystem == 'tgiann' then
        return function(source, itemName, count, slot)
            if slot then
                local success = exports[tgiannInv]:RemoveItem(source, itemName, count, slot)
                if success then return success end
                -- Fallback to non-slot removal if slot-based removal fails
            end
            return exports[tgiannInv]:RemoveItem(source, itemName, count)
        end
    elseif inventorySystem == 'jaksam' then
        return function(source, itemName, count, slot)
            local success, _ = exports[jaksamInv]:removeItem(source, itemName, count, nil, slot)
            return success
        end
    elseif inventorySystem == 'codem' then
        return function(source, itemName, count, slot)
            if slot then
                return exports[codemInv]:RemoveItem(source, itemName, count, slot)
            end
            return exports[codemInv]:RemoveItem(source, itemName, count)
        end
    elseif inventorySystem == 'origen' then
        return function(source, itemName, count, slot)
            return exports[origenInv]:removeItem(source, itemName, count, nil, slot)
        end
    elseif inventorySystem == 'qb' then
        return function(source, itemName, count, slot)
            if slot then
                return exports[qbInv]:RemoveItem(source, itemName, count, slot)
            end
            return exports[qbInv]:RemoveItem(source, itemName, count)
        end
    elseif inventorySystem == 'qs' or inventorySystem == 'qs-pro' then
        return function(source, itemName, count, slot)
            local inv = inventorySystem == 'qs' and qsInv or qsProInv
            -- qs-inventory RemoveItem doesn't have slot parameter in all versions
            return exports[inv]:RemoveItem(source, itemName, count)
        end
    else
        return function(source, itemName, count, slot)
            return Inventory.RemoveItem(source, itemName, count)
        end
    end
end

local RemoveItemFromSlotAllFunc = CreateRemoveItemFromSlotFunction()

--- Remove item from a specific slot (supports all inventory systems)
---@param source number Player server ID
---@param itemName string The item name
---@param count number Amount to remove
---@param slot number|nil The specific slot to remove from
---@return boolean success Whether the operation succeeded
Inventory.RemoveItemFromSlotAll = function(source, itemName, count, slot)
    return RemoveItemFromSlotAllFunc(source, itemName, count, slot)
end

--- Get the current inventory system name
---@return string|nil inventorySystem The detected inventory system
Inventory.GetInventorySystem = function()
    return inventorySystem
end

--- Check if the inventory system supports slot-based operations
---@return boolean supportsSlots Whether slot operations are supported
Inventory.SupportsSlots = function()
    return inventorySystem == 'ox' or inventorySystem == 'codem' or inventorySystem == 'qb'
        or inventorySystem == 'qs' or inventorySystem == 'qs-pro' or inventorySystem == 'origen'
        or inventorySystem == 'tgiann' or inventorySystem == 'jaksam'
end


--- Checks for updates by comparing local version with GitHub releases
---@param repo string The GitHub repository in format 'owner/repository'
CheckVersion = function(repo)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resource, 'version', 0) or GetResourceMetadata(resource, 'Version', 0)

    if currentVersion then
        currentVersion = currentVersion:match('%d+%.%d+%.%d+')
    end

    if not currentVersion then
        return print("^1Unable to determine current resource version for '^2" .. resource .. "^1'^0")
    end

    print('^3Checking for updates for ^2' .. resource .. '^3...^0')

    SetTimeout(1000, function()
        local url = ('https://api.github.com/repos/%s/releases/latest'):format(repo)
        PerformHttpRequest(url, function(status, response)
            if status ~= 200 then
                print('^1Failed to fetch release information for ^2' .. resource .. '^1. HTTP status: ' .. status .. '^0')
                return
            end

            local data = json.decode(response)
            if not data then
                print('^1Failed to parse release information for ^2' .. resource .. '^1.^0')
                return
            end

            if data.prerelease then
                print('^3Skipping prerelease for ^2' .. resource .. '^3.^0')
                return
            end

            local latestVersion = data.tag_name and data.tag_name:match('%d+%.%d+%.%d+')
            if not latestVersion then
                print('^1Failed to get valid latest version for ^2' .. resource .. '^1.^0')
                return
            end

            if latestVersion == currentVersion then
                print('^2' .. resource .. ' ^3is up-to-date with version ^2' .. currentVersion .. '^3.^0')
                return
            end

            -- Compare versions
            local parseVersion = function(version)
                local parts = {}
                for part in version:gmatch('%d+') do
                    table.insert(parts, tonumber(part))
                end
                return parts
            end

            local cv = parseVersion(currentVersion)
            local lv = parseVersion(latestVersion)

            for i = 1, math.max(#cv, #lv) do
                local current = cv[i] or 0
                local latest = lv[i] or 0

                if current < latest then
                    local releaseNotes = data.body or "No release notes available."
                    local message = releaseNotes:find("\n") and
                        "Check release page or changelog channel on Discord for more information!" or
                        releaseNotes

                    print(string.format(
                        '^3An update is available for ^2%s^3 (current: ^2%s^3)\r\nLatest: ^2%s^3\r\nRelease Notes: ^7%s',
                        resource, currentVersion, latestVersion, message
                    ))
                    break
                elseif current > latest then
                    print(string.format(
                        '^2%s ^3has newer local version (^2%s^3) than latest public release (^2%s^3).^0',
                        resource, currentVersion, latestVersion
                    ))
                    break
                end
            end
        end, 'GET', '')
    end)
end

print(string.format("^2[SD-CRAFTING]^0 Server bridge initialized - Framework: ^3%s^0, Inventory: ^3%s^0", Framework, inventorySystem or "framework-default"))

--- Logger Module
--- Handles logging to various services (Discord, Fivemanage, Fivemerr, Loki, Grafana)
Logger = {}

local loggerCfg = {
    service = 'none',
    screenshots = false,
    events = {},
    discord = {},
    loki = {},
    grafana = {},
    fivemanage = {}
}

local logBuffers = {} -- Internal buffers for batched logging
local flushScheduled = false -- Whether a flush is scheduled
local discordLogBuffer = {} -- Buffer for Discord embeds
local discordFlushScheduled = false -- Whether a Discord flush is scheduled

local criticalEvents = { -- Critical events that can trigger @everyone tag
    error_occurred = true,
}

--- Base64-encodes a string for HTTP Basic Auth
---@param data string The string to encode
---@return string The base64-encoded result
local Base64Encode = function(data)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local bits, byte = '', x:byte()
        for i = 8, 1, -1 do
            bits = bits .. ((byte % 2^i >= 2^(i-1)) and '1' or '0')
        end
        return bits
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
        end
        return b64chars:sub(c+1, c+1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

--- Builds HTTP Basic Authorization header
---@param user string Username
---@param pass string Password
---@return string The 'Basic ...' header value
local GetAuthHeader = function(user, pass)
    return 'Basic ' .. Base64Encode(user .. ':' .. pass)
end

--- Replaces placeholders in a string with values from a data table
---@param str string The string containing {placeholder} markers
---@param data table Key-value pairs for replacement
---@return string The string with placeholders replaced
local ReplacePlaceholders = function(str, data)
    if not str or not data then return str or '' end
    return (str:gsub('{(%w+)}', function(key)
        local value = data[key]
        if value ~= nil then
            return tostring(value)
        end
        return '{' .. key .. '}'
    end))
end

--- Builds player info data for placeholder replacement
---@param source number|nil Player server ID
---@return table playerData Table with player-related placeholder values
local BuildPlayerData = function(source)
    if not source then
        return {
            player = 'Server',
            playerName = 'Server',
            playerId = 0,
            identifier = 'N/A',
            charName = 'N/A',
        }
    end

    local playerName = GetPlayerName(source) or 'Unknown'
    local identifier = GetIdentifier(source) or 'Unknown'
    local charName = GetPlayerFullName(source) or 'Unknown'

    return {
        player = string.format('%s (ID: %d)', playerName, source),
        playerName = playerName,
        playerId = source,
        identifier = identifier,
        charName = charName,
    }
end

--- Builds a Discord embed object from embed data
---@param embedData table The embed configuration
---@return table embed The formatted Discord embed
local BuildDiscordEmbed = function(embedData)
    local d = loggerCfg.discord
    return {
        title = embedData.title,
        description = embedData.description,
        color = embedData.color or 5793266,
        fields = embedData.fields or {},
        footer = {
            text = (d.footerText or 'SD-Crafting Logging') .. ' • ' .. os.date('%a %b %d, %I:%M %p'),
            icon_url = d.footerIcon ~= '' and d.footerIcon or nil
        },
        timestamp = embedData.timestamp or os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }
end

--- Sends multiple Discord embeds in a single webhook request (max 10 per request)
---@param embeds table Array of embed objects
---@param hasCritical boolean Whether any embed is a critical event
local SendDiscordEmbeds = function(embeds, hasCritical)
    local d = loggerCfg.discord
    if not d.webhook or d.webhook == '' then return end

    local payload = {
        username = d.botName or 'Crafting Logger',
        avatar_url = d.botAvatar ~= '' and d.botAvatar or nil,
        embeds = embeds
    }

    if hasCritical and d.tagEveryone then
        payload.content = '@everyone'
    end

    PerformHttpRequest(d.webhook, function(status)
        if status < 200 or status >= 300 then
            print(string.format('^1[SD-CRAFTING]^0 Discord webhook failed (status %d)', status))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

--- Schedules Discord log flush
local ScheduleDiscordFlush = function()
    if discordFlushScheduled then return end
    discordFlushScheduled = true

    local interval = (loggerCfg.discord.flushInterval or 5) * 1000

    SetTimeout(interval, function()
        if #discordLogBuffer == 0 then
            discordFlushScheduled = false
            return
        end

        -- Build all embeds and track if any are critical
        local allEmbeds = {}
        local hasCritical = false
        for _, entry in ipairs(discordLogBuffer) do
            local embed = BuildDiscordEmbed(entry.embedData)
            table.insert(allEmbeds, embed)
            if criticalEvents[entry.eventName] then
                hasCritical = true
            end
        end

        -- Discord allows max 10 embeds per message, send in batches
        local BATCH_SIZE = 10
        for i = 1, #allEmbeds, BATCH_SIZE do
            local batch = {}
            local batchHasCritical = false
            for j = i, math.min(i + BATCH_SIZE - 1, #allEmbeds) do
                table.insert(batch, allEmbeds[j])
                -- Check if this batch has critical (only tag once per batch)
                local entryIndex = j
                if criticalEvents[discordLogBuffer[entryIndex] and discordLogBuffer[entryIndex].eventName] then
                    batchHasCritical = true
                end
            end
            SendDiscordEmbeds(batch, batchHasCritical and hasCritical)
        end

        discordLogBuffer = {}
        discordFlushScheduled = false
    end)
end

--- Buffers a Discord embed for batched sending
---@param embedData table The embed configuration
---@param eventName string The event name
local BufferDiscordEmbed = function(embedData, eventName)
    -- Capture timestamp at buffer time for accurate chronological ordering
    embedData.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    discordLogBuffer[#discordLogBuffer + 1] = {
        embedData = embedData,
        eventName = eventName
    }
    ScheduleDiscordFlush()
end

--- Schedules a flush of buffered logs to Loki/Grafana
local ScheduleFlush = function()
    if flushScheduled then return end
    flushScheduled = true

    SetTimeout(500, function()
        local services = { loki = loggerCfg.loki, grafana = loggerCfg.grafana }

        for name, conf in pairs(services) do
            local buffer = logBuffers[name]
            if buffer and next(buffer) and conf.endpoint and conf.headers then
                local streams = {}
                for _, stream in pairs(buffer) do
                    if type(stream) == 'table' and stream.stream then
                        streams[#streams + 1] = stream
                    end
                end

                if #streams > 0 then
                    local body = json.encode({ streams = streams })
                    PerformHttpRequest(conf.endpoint, function(status)
                        local isSuccess = (name == 'loki' and status == 204) or
                                        (name == 'grafana' and status >= 200 and status < 300)
                        if not isSuccess then
                            print(string.format('^1[SD-CRAFTING]^0 %s push failed (status %d)', name, status))
                        end
                    end, 'POST', body, conf.headers)
                end
            end
        end

        logBuffers = {}
        flushScheduled = false
    end)
end

--- Buffers a log stream for Loki/Grafana
---@param serviceName string 'loki' or 'grafana'
---@param eventName string The event name
---@param message string The log message content
---@param data table Additional data to include
local BufferStream = function(serviceName, eventName, message, data)
    local conf = loggerCfg[serviceName]
    if not conf or not conf.endpoint or conf.endpoint == '' then return end

    if not logBuffers[serviceName] then
        logBuffers[serviceName] = {}
    end

    local ts = tostring(os.time() * 1000000000)

    if not logBuffers[serviceName][eventName] then
        logBuffers[serviceName][eventName] = {
            stream = {
                server = conf.server or GetConvar('sv_projectName', 'fxserver'),
                resource = GetCurrentResourceName(),
                event = eventName
            },
            values = {}
        }
    end

    local logEntry = {
        message = message,
        event = eventName,
        data = data
    }

    table.insert(logBuffers[serviceName][eventName].values, {
        ts,
        json.encode(logEntry)
    })

    ScheduleFlush()
end

--- Sends a log entry via Fivemanage
---@param eventName string The event name
---@param title string The log title
---@param message string The log message
---@param source number|nil The player source
local SendFivemanageLog = function(eventName, title, message, source)
    local sdk = exports.fmsdk
    if not sdk then return end

    local datasetId = loggerCfg.fivemanage.dataset or 'sd-crafting'
    local logMetadata = {
        event = eventName,
        title = title,
    }

    if source then
        logMetadata.playerSource = source
        logMetadata.playerName = GetPlayerName(source)
        logMetadata.identifier = GetIdentifier(source)
    end

    if loggerCfg.screenshots and source then
        pcall(function()
            sdk:takeServerImage(source, { name = title, description = message })
        end)
    else
        pcall(function()
            sdk:Log(datasetId, 'info', message, logMetadata)
        end)
    end
end

--- Sends a log entry via Fivemerr (fm-logs)
---@param eventName string The event name
---@param title string The log title
---@param message string The log message
---@param source number|nil The player source
local SendFivemerrLog = function(eventName, title, message, source)
    local fmlogs = exports['fm-logs']
    if not fmlogs then return end

    pcall(function()
        fmlogs:createLog({
            LogType = 'Generic',
            Message = string.format('[%s] %s\n%s', eventName, title, message),
            Resource = GetCurrentResourceName(),
            Source = source,
        }, { Screenshot = loggerCfg.screenshots and source ~= nil })
    end)
end

--- Initializes the logger with configuration from logs.lua
---@param logsConfig table The logs configuration table
Logger.Setup = function(logsConfig)
    if not logsConfig then return end

    loggerCfg.service = logsConfig.service or 'none'
    loggerCfg.screenshots = logsConfig.screenshots or false
    loggerCfg.events = logsConfig.events or {}

    if logsConfig.discord then
        local d = logsConfig.discord
        loggerCfg.discord = {
            webhook = d.webhook or '',
            botName = d.botName or 'Crafting Logger',
            botAvatar = d.botAvatar or '',
            footerText = d.footerText or 'SD-Crafting Logging',
            footerIcon = d.footerIcon or '',
            flushInterval = d.flushInterval or 5,
            tagEveryone = d.tagEveryone or false,
        }
    end

    if logsConfig.fivemanage then
        loggerCfg.fivemanage = {
            dataset = logsConfig.fivemanage.dataset or 'sd-crafting'
        }
    end

    if logsConfig.loki then
        local l = logsConfig.loki
        loggerCfg.loki = {
            endpoint = l.endpoint or '',
            server = l.server or '',
        }

        if loggerCfg.loki.endpoint ~= '' then
            if not loggerCfg.loki.endpoint:match('^https?://') then
                loggerCfg.loki.endpoint = 'https://' .. loggerCfg.loki.endpoint
            end
            loggerCfg.loki.endpoint = loggerCfg.loki.endpoint:gsub('/+$', '') .. '/loki/api/v1/push'
            loggerCfg.loki.headers = { ['Content-Type'] = 'application/json' }

            if l.user and l.user ~= '' and l.password and l.password ~= '' then
                loggerCfg.loki.headers['Authorization'] = GetAuthHeader(l.user, l.password)
            end
            if l.tenant and l.tenant ~= '' then
                loggerCfg.loki.headers['X-Scope-OrgID'] = l.tenant
            end
        end
    end

    if logsConfig.grafana then
        local g = logsConfig.grafana
        loggerCfg.grafana = {
            endpoint = g.endpoint or '',
            server = g.server or '',
        }

        if loggerCfg.grafana.endpoint ~= '' then
            if not loggerCfg.grafana.endpoint:match('^https?://') then
                loggerCfg.grafana.endpoint = 'https://' .. loggerCfg.grafana.endpoint
            end
            loggerCfg.grafana.endpoint = loggerCfg.grafana.endpoint:gsub('/+$', '') .. '/loki/api/v1/push'
            loggerCfg.grafana.headers = { ['Content-Type'] = 'application/json' }

            if g.apiKey and g.apiKey ~= '' then
                loggerCfg.grafana.headers['Authorization'] = 'Bearer ' .. g.apiKey
            end
            if g.tenant and g.tenant ~= '' then
                loggerCfg.grafana.headers['X-Scope-OrgID'] = g.tenant
            end
        end
    end

    local serviceDisplay = (not loggerCfg.service or loggerCfg.service == '') and 'none' or loggerCfg.service
    print(string.format("^2[SD-CRAFTING]^0 Logger initialized - Service: ^3%s^0", serviceDisplay))
end

--- Checks if a specific event is enabled for logging
---@param eventName string The event name to check
---@return boolean enabled Whether the event is enabled
---@return table|nil eventConfig The event configuration if enabled
Logger.IsEventEnabled = function(eventName)
    if not loggerCfg.service or loggerCfg.service == '' or loggerCfg.service == 'none' then return false, nil end

    local eventConfig = loggerCfg.events[eventName]
    if not eventConfig then return false, nil end

    if type(eventConfig) == 'boolean' then
        return eventConfig, nil
    elseif type(eventConfig) == 'table' then
        return eventConfig.enabled == true, eventConfig
    end

    return false, nil
end

--- Main logging function - logs an event using the configured service
---@param eventName string The event name (must match an event in logs.lua config)
---@param source number|nil The player's server ID (nil for server-wide events)
---@param data table Data to populate placeholders (merged with auto-generated player data)
Logger.Log = function(eventName, source, data)
    local isEnabled, eventConfig = Logger.IsEventEnabled(eventName)
    if not isEnabled then return end

    local placeholderData = BuildPlayerData(source)

    if data then
        for k, v in pairs(data) do
            placeholderData[k] = v
        end
    end

    if not eventConfig then
        eventConfig = {
            title = eventName,
            description = 'Event triggered',
            color = 5793266,
            fields = {},
        }
    end

    local description = ReplacePlaceholders(eventConfig.description, placeholderData)

    local fields = {}
    if eventConfig.fields then
        for _, field in ipairs(eventConfig.fields) do
            local fieldValue = ReplacePlaceholders(field.value, placeholderData)
            if fieldValue and fieldValue ~= '' and not fieldValue:match('^{%w+}$') then
                table.insert(fields, {
                    name = field.name,
                    value = fieldValue,
                    inline = field.inline
                })
            end
        end
    end

    local plainMessage = description
    if #fields > 0 then
        plainMessage = plainMessage .. '\n'
        for _, field in ipairs(fields) do
            plainMessage = plainMessage .. string.format('\n%s: %s', field.name, field.value)
        end
    end

    local service = loggerCfg.service

    if service == 'discord' then
        local embedData = {
            title = eventConfig.title,
            description = description,
            color = eventConfig.color or 5793266,
            fields = fields,
        }
        BufferDiscordEmbed(embedData, eventName)

    elseif service == 'fivemanage' then
        SendFivemanageLog(eventName, eventConfig.title, plainMessage, source)

    elseif service == 'fivemerr' then
        SendFivemerrLog(eventName, eventConfig.title, plainMessage, source)

    elseif service == 'loki' then
        BufferStream('loki', eventName, plainMessage, placeholderData)

    elseif service == 'grafana' then
        BufferStream('grafana', eventName, plainMessage, placeholderData)

    elseif service ~= 'none' then
        print(string.format("^1[SD-CRAFTING]^0 Logger: unsupported service '%s'", tostring(service)))
    end
end

--- Helper function to format a player list for logs
---@param players table Array of player source IDs
---@return string playerList Formatted player list string
Logger.FormatPlayerList = function(players)
    if not players or #players == 0 then return 'None' end

    local lines = {}
    for _, playerId in ipairs(players) do
        local name = GetPlayerName(playerId) or 'Unknown'
        table.insert(lines, string.format('%s (ID: %d)', name, playerId))
    end
    return table.concat(lines, '\n')
end

--- Helper function to format duration from seconds
---@param seconds number Duration in seconds
---@return string formatted Formatted duration string
Logger.FormatDuration = function(seconds)
    if not seconds or seconds <= 0 then return '0 minutes' end

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        return string.format('%dh %dm', hours, minutes)
    elseif minutes > 0 then
        return string.format('%d minutes', minutes)
    else
        return string.format('%d seconds', secs)
    end
end

--- Helper function to format item list for logs
---@param items table Array of items {name, count/amount, label, ...}
---@return string formatted Formatted items string
Logger.FormatItemList = function(items)
    if not items or #items == 0 then return 'None' end

    local lines = {}
    for _, item in ipairs(items) do
        local name = item.name or item.item or 'unknown'
        local label = item.label or name
        local count = item.count or item.amount or 1
        table.insert(lines, string.format('%s x%d', label, count))
    end
    return table.concat(lines, ', ')
end
