Framework, Inventory = nil, nil
PlayerLoaded = false

-- Handle player login
function OnPlayerLoaded()
    PlayerLoaded = true
    TriggerEvent('lation_shops:playerLoaded')
end

-- Handle player logout
function OnPlayerLogout()
    PlayerLoaded = false
    TriggerEvent('lation_shops:playerDropped')
end

-- Initialize framework
local function InitFramework()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'

        RegisterNetEvent('esx:playerLoaded', function() OnPlayerLoaded() end)
        RegisterNetEvent('esx:onPlayerLogout', function() OnPlayerLogout() end)
    elseif GetResourceState('qbx_core') == 'started' then
        Framework = 'qbx'

        AddEventHandler('QBCore:Client:OnPlayerLoaded', function() OnPlayerLoaded() end)
        RegisterNetEvent('qbx_core:client:playerLoggedOut', function() OnPlayerLogout() end)
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() OnPlayerLoaded() end)
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() OnPlayerLogout() end)
    elseif GetResourceState('ox_core') == 'started' then
        Ox = require '@ox_core.lib.init'
        Framework = 'ox'

        AddEventHandler('ox:playerLoaded', function() OnPlayerLoaded() end)
        AddEventHandler('ox:playerLogout', function() OnPlayerLogout() end)
    else
        -- Add custom framework here
    end

    AddEventHandler('onResourceStart', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            OnPlayerLoaded()
        end
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            OnPlayerLogout()
        end
    end)
end

-- Initialize inventory
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

-- Returns player data
function GetPlayerData()
    if Framework == 'esx' then
        return ESX.GetPlayerData()
    elseif Framework == 'qb' then
        return QBCore.Functions.GetPlayerData()
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetPlayerData()
    elseif Framework == 'ox' then
        return Ox.GetPlayer()
    else
        -- Add custom framework here
    end
end

-- Returns player licenses
--- @param license string|nil Specific licence to get
function GetPlayerLicense(license)
    local player = GetPlayerData()
    if not player then return end
    if Framework == 'esx' then
        return lib.callback.await('lation_shops:getPlayerLicense', false, license)
    elseif Framework == 'qb' then
        return player.metadata.licences[license] or false
    elseif Framework == 'qbx' then
        return player.metadata.licences[license] or false
    elseif Framework == 'ox' then
        -- TODO
    else
        -- Add custom framework here
    end
end

-- Returns player job
function GetPlayerJob()
    local player = GetPlayerData()
    if not player then return {} end

    if Framework == 'esx' then
        return {
            name = player.job.name,
            label = player.job.label,
            grade = player.job.grade
        }
    elseif Framework == 'qb' then
        return {
            name = player.job.name,
            label = player.job.label,
            grade = player.job.grade.level
        }
    elseif Framework == 'qbx' then
        return {
            name = player.job.name,
            label = player.job.label,
            grade = player.job.grade.level
        }
    else
        -- Add custom framework here
    end

    return {}
end

-- Return all jobs
function GetAllJobs()
    if Framework == 'esx' then
        return lib.callback.await('lation_shops:getAllJobs', false)
    elseif Framework == 'qb' then
        return QBCore.Shared.Jobs
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetJobs()
    elseif Framework == 'ox' then
        return Ox.GetGroupsByType('job')
    else
        -- Add custom framework here
    end
    return {}
end

-- Sanitize item data for certain inventories
local function sanitize(items)
    local sanitized = {}
    for itemName, itemData in pairs(items or {}) do
        if type(itemData) == 'table' then
            sanitized[itemName] = {}
            for key, value in pairs(itemData) do
                if key == 'client' or key == 'server' or key == 'weapon' then
                    goto continue
                end
                if type(key) == 'string' and not tonumber(key) and type(value) ~= 'function' then
                    if (key == 'label' or key == 'description') and type(value) == 'table' then
                        sanitized[itemName][key] = select(2, next(value)) or "INVALID"
                    elseif type(value) == 'table' then
                        local clean = {}
                        for k, v in pairs(value) do
                            if type(v) ~= 'function' then clean[k] = v end
                        end
                        if next(clean) then sanitized[itemName][key] = clean end
                    else
                        sanitized[itemName][key] = value
                    end
                end
                ::continue::
            end
        end
    end
    return sanitized
end

-- Return data for item and image path
function GetAllItems()
    local items
    if Inventory then
        if Inventory == 'ox_inventory' then
            items = exports[Inventory]:Items()
        elseif Inventory == 'qb-inventory' then
            items = QBCore.Shared.Items
        elseif Inventory == 'ps-inventory' then
            items = QBCore.Shared.Items
        elseif Inventory == 'qs-inventory' then
            items = exports[Inventory]:GetItemList()
        elseif Inventory == 'origen_inventory' then
            items = exports[Inventory]:GetItems()
        elseif Inventory == 'codem-inventory' then
            items = exports[Inventory]:GetItemList()
        elseif Inventory == 'core_inventory' then
            -- No available client-side export to get item list
            if Framework == 'qb' then
                items = QBCore.Shared.Items
            else
                print('^1[ERROR]: An issue has occured, please contact support at https://discord.gg/9EbY4nM5uu^0')
                return nil
            end
        elseif Inventory == 'tgiann-inventory' then
            items = exports[Inventory]:GetItemList()
        elseif Inventory == 'jaksam_inventory' then
            items = exports[Inventory]:getStaticItemsList()
        else
            -- Add custom inventory here
            return nil
        end
    else
        if Framework == 'esx' then
            -- Unlikely to need anything here but.. just in case..
            print('^1[ERROR]: An error has occured with lation_shops - please contact support^0')
            return nil
        elseif Framework == 'qb' then
            items = QBCore.Shared.Items
        elseif Framework == 'qbx' then
            -- Unlikely to need anything here but.. just in case..
            print('^1[ERROR]: Are you really not using ox_inventory? Contact support please lul.^0')
            return nil
        end
    end
    return sanitize(items)
end

-- Return image path for inventory items
function GetImagePath()
    if Inventory then
        if Inventory == 'ox_inventory' then
            return 'nui://ox_inventory/web/images/'
        elseif Inventory == 'qb-inventory' then
            return 'nui://qb-inventory/html/images/'
        elseif Inventory == 'ps-inventory' then
            return 'nui://ps-inventory/html/images/'
        elseif Inventory == 'qs-inventory' then
            return 'nui://qs-inventory/html/images/'
        elseif Inventory == 'origen_inventory' then
            return 'nui://origen_inventory/html/images/'
        elseif Inventory == 'codem-inventory' then
            return 'nui://codem-inventory/html/itemimages/'
        elseif Inventory == 'core_inventory' then
            return 'nui://core_inventory/html/images/'
        elseif Inventory == 'tgiann-inventory' then
            return 'nui://inventory_images/images/'
        elseif Inventory == 'jaksam_inventory' then
            return 'nui://jaksam_inventory/_images/'
        else
            -- Add custom inventory here
        end
    end
end

-- Check if player has item
--- @param item string
--- @param amount number
--- @return boolean
function HasItem(item, amount)
    if not item or not amount then return false end
    if Inventory then
        if Inventory == 'ox_inventory' then
            return exports[Inventory]:Search('count', item) >= amount
        elseif Inventory == 'core_inventory' then
            return exports[Inventory]:hasItem(item, amount)
        elseif Inventory == 'jaksam_inventory' then
            return exports[Inventory]:getTotalItemAmount(item) >= amount
        else
            return exports[Inventory]:HasItem(item, amount)
        end
    else
        local playerData = GetPlayerData()
        if not playerData then return false end
        local inventory = Framework == 'esx' and playerData.inventory or playerData.items
        if not inventory then return false end
        for _, itemData in pairs(inventory) do
            if itemData and itemData.name == item then
                local count = itemData.amount or itemData.count or 0
                if count >= amount then
                    return true
                end
            end
        end
        return false
    end
end

-- Disables access to open/view inventory
function DisableInventory()
    if Inventory == 'ox_inventory' then
        LocalPlayer.state.invBusy = true
    elseif Inventory == 'qb-inventory' then
        LocalPlayer.state.inv_busy = true
    elseif Inventory == 'qs-inventory' then
        exports[Inventory]:setInventoryDisabled(true)
    elseif Inventory == 'core_inventory' then
        exports[Inventory]:lockInventory()
    elseif Inventory == 'tgiann-inventory' then
        exports[Inventory]:SetInventoryActive(false)
    else
        -- Add custom inventory here
    end
end

-- Enables access to open/view inventory
function EnableInventory()
    if Inventory == 'ox_inventory' then
        LocalPlayer.state.invBusy = false
    elseif Inventory == 'qb-inventory' then
        LocalPlayer.state.inv_busy = false
    elseif Inventory == 'qs-inventory' then
        exports[Inventory]:setInventoryDisabled(false)
    elseif Inventory == 'core_inventory' then
        exports[Inventory]:unlockInventory()
    elseif Inventory == 'tgiann-inventory' then
        exports[Inventory]:SetInventoryActive(true)
    else
        -- Add custom inventory here
    end
end

InitFramework()
InitInventory()