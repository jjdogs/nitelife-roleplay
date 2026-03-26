Framework, Inventory = nil, nil

-- Get framework
local function InitFramework()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    elseif GetResourceState('qbx_core') == 'started' then
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
    elseif GetResourceState('ox_core') == 'started' then
        Ox = require '@ox_core.lib.init'
        Framework = 'ox'
    else
        -- Add custom framework here
    end
end

-- Get inventory
local function InitInventory()
    if GetResourceState('ox_inventory') == 'started' then
        Inventory = 'ox_inventory'
    elseif GetResourceState('qb-inventory') == 'started' then
        Inventory = 'qb-inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        Inventory = 'qs-inventory'
    elseif GetResourceState('ps-inventory') == 'started' then
        Inventory = 'ps-inventory'
    elseif GetResourceState('origen_inventory') == 'started' then
        Inventory = 'origen_inventory'
    elseif GetResourceState('codem-inventory') == 'started' then
        Inventory = 'codem-inventory'
    elseif GetResourceState('core_inventory') == 'started' then
        Inventory = 'core_inventory'
    elseif GetResourceState('tgiann-inventory') == 'started' then
        Inventory = 'tgiann-inventory'
    elseif GetResourceState('jaksam_inventory') == 'started' then
        Inventory = 'jaksam_inventory'
    else
        -- Add custom inventory here
    end
end

-- Get player from source
--- @param source number Player ID
function GetPlayer(source)
    if not source then return end
    if Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    else
        -- Add custom framework here
    end
end

-- Return player's name
--- @param source number Player ID
--- @return string
function GetPlayerFullName(source)
    local player = GetPlayer(source)
    if not player then return 'Unknown' end
    if Framework == 'esx' then
        return player.getName()
    elseif Framework == 'qb' then
        return player.PlayerData.charinfo.firstname.. ' ' ..player.PlayerData.charinfo.lastname
    elseif Framework == 'qbx' then
        return player.PlayerData.charinfo.firstname.. ' ' ..player.PlayerData.charinfo.lastname
    else
        -- Add custom framework here
    end
    return 'Unknown'
end

-- Returns player licences
--- @param source number Player ID
--- @param license string|nil Specific licence to get
function GetPlayerLicense(source, license)
    local player = GetPlayer(source)
    if not player then return end
    if Framework == 'esx' then
        local result = promise.new()
        TriggerEvent('esx_license:getLicenses', source, function(licenses)
            result:resolve(licenses)
        end)
        local licenses = Citizen.Await(result)
        for _, lic in ipairs(licenses) do
            if lic.type == license then return true end
        end
        return false
    elseif Framework == 'qb' then
        return player.PlayerData.metadata.licences[license] or false
    elseif Framework == 'qbx' then
        return player.PlayerData.metadata.licences[license] or false
    else
        -- Add custom framework here
    end
end

-- Callback to get player licenses
---@param source number Player ID
---@param license string|nil Specific licence to get
--- @return any|boolean
lib.callback.register('lation_shops:getPlayerLicense', function(source, license)
    return GetPlayerLicense(source, license)
end)

-- Returns player job
--- @param source number Player ID
--- @return table
function GetPlayerJob(source)
    local player = GetPlayer(source)
    if not player then return {} end

    if Framework == 'esx' then
        return {
            name = player.getJob().name,
            label = player.getJob().label,
            grade = player.getJob().grade
        }
    elseif Framework == 'qb' then
        return {
            name = player.PlayerData.job.name,
            label = player.PlayerData.job.label,
            grade = player.PlayerData.job.grade.level
        }
    elseif Framework == 'qbx' then
        return {
            name = player.PlayerData.job.name,
            label = player.PlayerData.job.label,
            grade = player.PlayerData.job.grade.level
        }
    else
        -- Add custom framework here
    end

    return {}
end

-- Returns all jobs
function GetAllJobs()
    if Framework == 'esx' then
        return ESX.GetJobs()
    elseif Framework == 'qb' then
        return QBCore.Shared.Jobs
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetJobs()
    else
        -- Add custom framework here
    end

    return {}
end

-- Callback to get all jobs
lib.callback.register('lation_shops:getAllJobs', function()
    return GetAllJobs()
end)

-- Function to get a player identifier by source
--- @param source number Player ID
function GetIdentifier(source)
    local player = GetPlayer(source)
    if not player then return end
    if Framework == 'esx' then
        return player.identifier
    elseif Framework == 'qb' then
        return player.PlayerData.citizenid
    elseif Framework == 'qbx' then
        return player.PlayerData.citizenid
    else
        -- Add custom framework here
    end
end

-- Returns number of specified item in players inventory
--- @param source number Player ID
--- @param item string Item to search
--- @return number
function GetItemCount(source, item)
    if not source or not item then return 0 end
    local player = GetPlayer(source)
    if not player then return 0 end
    if Inventory then
        if Inventory == 'ox_inventory' then
            return exports[Inventory]:Search(source, 'count', item) or 0
        elseif Inventory == 'core_inventory' then
            return exports[Inventory]:getItemCount(source, item)
        elseif Inventory == 'jaksam_inventory' then
            return exports[Inventory]:getTotalItemAmount(source, item) or 0
        else
            local itemData = exports[Inventory]:GetItemByName(source, item)
            if not itemData then return 0 end
            return itemData.amount or itemData.count or 0
        end
    else
        if Framework == 'esx' then
            local itemData = player.getInventoryItem(item)
            if not itemData then return 0 end
            return itemData.count or itemData.amount or 0
        elseif Framework == 'qb' then
            local itemData = player.Functions.GetItemByName(item)
            if not itemData then return 0 end
            return itemData.amount or itemData.count or 0
        else
            -- Add custom framework here
        end
    end
    return 0
end

-- Returns if player can carry item
--- @param source number Player ID
--- @param item string Item name
--- @param count number Item quantity
--- @return boolean
function CanCarry(source, item, count)
    if count <= 0 then return true end
    local player = GetPlayer(source)
    if not player then return false end
    if Inventory then
        if Inventory == 'ox_inventory' then
            return exports[Inventory]:CanCarryItem(source, item, count)
        elseif Inventory == 'qb-inventory' then
            return exports[Inventory]:CanAddItem(source, item, count)
        elseif Inventory == 'qs-inventory' then
            return exports[Inventory]:CanCarryItem(source, item, count)
        elseif Inventory == 'ps-inventory' then
            -- ps sucks, why do they not have a dedicated export for this..?
            local totalWeight = exports[Inventory]:GetTotalWeight(player.PlayerData.items)
            if not totalWeight then return false end
            local itemInfo = QBCore.Shared.Items[item:lower()]
            if not itemInfo then return false end
            if (totalWeight + (itemInfo['weight'] * count)) <= 120000 then
                return true
            end
            return false
        elseif Inventory == 'origen_inventory' then
            -- origen's CanCarry export not working as expected, just return true
            return true
        elseif Inventory == 'codem-inventory' then
            -- CodeM docs dont specify an export for this so..
            return true
        elseif Inventory == 'core_inventory' then
            -- core's canCarry export not working as expected, just return true
            return true
        elseif Inventory == 'tgiann-inventory' then
            return exports[Inventory]:CanCarryItem(source, item, count)
        elseif Inventory == 'jaksam_inventory' then
            return exports[Inventory]:canCarryItem(source, item, count)
        else
            -- Add custom inventory here
            return true
        end
    else
        if Framework == 'esx' then
            if player.canCarryItem(item, count) then
                return true
            end
            return false
        elseif Framework == 'qb' then
            local totalWeight = QBCore.Player.GetTotalWeight(player.PlayerData.items)
            if not totalWeight then return false end
            local itemInfo = QBCore.Shared.Items[item:lower()]
            if not itemInfo then return false end
            if (totalWeight + (itemInfo['weight'] * count)) <= 120000 then
                return true
            end
            return false
        else
            -- Add custom framework here
        end
    end
    return true
end

-- Adds an item to players inventory
--- @param source number Player ID
--- @param item string Item to add
--- @param count number Quantity to add
--- @param metadata any|table Optional metadata
function AddItem(source, item, count, metadata)
    if count <= 0 then return end
    local player = GetPlayer(source)
    if not player then return end
    if Inventory then
        if Inventory == 'ox_inventory' then
            exports[Inventory]:AddItem(source, item, count, metadata)
        elseif Inventory == 'core_inventory' or Inventory == 'jaksam_inventory' then
            exports[Inventory]:addItem(source, item, count, metadata)
        else
            exports[Inventory]:AddItem(source, item, count, nil, metadata)
        end
    else
        if Framework == 'esx' then
            player.addInventoryItem(item, count)
        elseif Framework == 'qb' then
            player.Functions.AddItem(item, count, nil, metadata)
        else
            -- Add custom framework here
        end
    end
end

-- Removes an item from players inventory
--- @param source number Player ID
--- @param item string Item to remove
--- @param count number Quantity to remove
function RemoveItem(source, item, count)
    local player = GetPlayer(source)
    if not player then return end
    if Inventory then
        if Inventory == 'core_inventory' or Inventory == 'jaksam_inventory' then
            exports[Inventory]:removeItem(source, item, count)
        else
            exports[Inventory]:RemoveItem(source, item, count)
        end
    else
        if Framework == 'esx' then
            player.removeInventoryItem(item, count)
        elseif Framework == 'qb' then
            player.Functions.RemoveItem(item, count)
        else
            -- Add custom framework here
        end
    end
end

-- Returns correct framework money type if needed
--- @param type string Money type
--- @return string
local function ConvertMoneyType(type)
    if type == 'money' and (Framework == 'qb' or Framework == 'qbx') then
        type = 'cash'
    elseif type == 'cash' and Framework == 'esx' then
        type = 'money'
    else
        -- Add custom framework here
    end
    return type
end

-- Returns balance of players account
--- @param source number Player ID
--- @param type string Account
--- @param shopId string|nil Shop ID for tracking
--- @return number
function GetPlayerBalance(source, type, shopId)
    local player = GetPlayer(source)
    if not player then return 0 end
    if Framework == 'esx' then
        return player.getAccount(ConvertMoneyType(type)).money or 0
    elseif Framework == 'qb' then
        return player.PlayerData.money[ConvertMoneyType(type)] or 0
    elseif Framework == 'qbx' then
        return player.Functions.GetMoney(ConvertMoneyType(type)) or 0
    else
        -- Add custom framework here
    end
    return 0
end

-- Add money to players account
--- @param source number Player ID
--- @param type string Account to add to
--- @param amount number Amount to add
--- @param shopId string|nil Shop ID for tracking
function AddPlayerMoney(source, type, amount, shopId)
    local player = GetPlayer(source)
    if not player then return end
    if Framework == 'esx' then
        player.addAccountMoney(ConvertMoneyType(type), amount)
    elseif Framework == 'qb' then
        player.Functions.AddMoney(ConvertMoneyType(type), amount)
    elseif Framework == 'qbx' then
        player.Functions.AddMoney(ConvertMoneyType(type), amount)
    else
        -- Add custom framework here
    end
end

-- Remove money from players account
--- @param source number Player ID
--- @param type string Account to remove from
--- @param amount number Amount to remove
--- @param shopId string|nil Shop ID for tracking
function RemovePlayerMoney(source, type, amount, shopId)
    local player = GetPlayer(source)
    if not player then return end
    if Framework == 'esx' then
        player.removeAccountMoney(ConvertMoneyType(type), amount)
    elseif Framework == 'qb' then
        player.Functions.RemoveMoney(ConvertMoneyType(type), amount)
    elseif Framework == 'qbx' then
        player.Functions.RemoveMoney(ConvertMoneyType(type), amount)
    else
        -- Add custom framework here
    end
end

InitFramework()
InitInventory()