Config = {}
---------- [Framework] ----------
-- (DONT TOUCH THIS UNLESS YOU HAVE A CUSTOM FRAMEWORK)
if GetResourceState('es_extended') == 'started' then
    Framework = "ESX" -- (ESX) or (QBCore)
elseif GetResourceState('qb-core') == 'started' then
    Framework = "QBCore" -- (ESX) or (QBCore)
end
if Framework == "QBCore" then
    Config.CoreName = "qb-core" -- your core name
    FWork = exports[Config.CoreName]:GetCoreObject()
elseif Framework == "ESX" then
    Config.CoreName = "es_extended" -- your core name
    FWork = exports[Config.CoreName]:getSharedObject()
end
------------------------------
-- [THESE ARE NOT NOT MEANT TO BE TOUCHED UNLESS YOU KNOW WHAT YOU ARE DOING]
Config.CompatibleTargetScripts = { -- Put whatever target script you use in this table if it is not here.
    "ox_target",
    "qb-target",
    "qtarget",
}
Config.CompatibleInputScripts = { -- If you have multiple input scripts in your server, Put only the one you want to use in this table or else dont touch this.
    "lation_ui",
    -- "ox_lib",
    -- "qb-input",
    -- "ps-ui",
}
Config.CompatibleMenuScripts = { -- If you have multiple Menu scripts in your server, Put only the one you want to use in this table or else dont touch this.
   "lation_ui",
    -- "ox_lib",
    -- "qb-menu",
    -- "ps-ui",
}
Config.CompatibleInventoryScripts = { -- Having a compatible inventory script is not required
    "ak47_inventory",
    "qb-inventory",
    "qs-inventory",
    "ps-inventory",
    "lj-inventory",
    "ox_inventory",
}

Config.CompatibleSmallResourceScripts = {}
-- (DONT TOUCH ANY OF THIS SECTION)
for _, v in pairs(Config.CompatibleTargetScripts) do
    if GetResourceState(v) == 'started' then
        Config.Target = tostring(v)
        break
    end
end
-- (DONT TOUCH ANY OF THIS SECTION)
for _, v in pairs(Config.CompatibleInputScripts) do
    if GetResourceState(v) == 'started' then
        Config.Input = tostring(v)
        break
    end
end
-- (DONT TOUCH ANY OF THIS SECTION)
for _, v in pairs(Config.CompatibleMenuScripts) do
    if GetResourceState(v) == 'started' then
        Config.Menu = tostring(v)
        break
    end
end
-- (DONT TOUCH ANY OF THIS SECTION)
for _, v in pairs(Config.CompatibleInventoryScripts) do
    if GetResourceState(v) == 'started' then
        Config.InventoryType = tostring(v)
        break
    end
end
-- (DONT TOUCH ANY OF THIS SECTION)
for _, v in pairs(Config.CompatibleSmallResourceScripts) do
    if GetResourceState(v) == 'started' then
        Config.SmallResource = tostring(v)
        break
    end
end
if GetResourceState("pug-battleroyale") == 'started' then
    Config.HasBattleRoyaleScript = true
end
-- if GetResourceState("nh-context") == 'started' then
--     Config.MapMenuPreview = true
-- end
------------------------------
---------- [Core Framework Functions] ----------
-- (DONT TOUCH ANY OF THIS SECTION)
Config.FrameworkFunctions = {
    -- Client-side trigger callback
    TriggerCallback = function(...)
        if Framework == 'QBCore' then
            FWork.Functions.TriggerCallback(...)
        else
            FWork.TriggerServerCallback(...)
        end
    end,

    -- Server-side register callback
    CreateCallback = function(...)
        if Framework == 'QBCore' then
            FWork.Functions.CreateCallback(...)
        else
            FWork.RegisterServerCallback(...)
        end
    end,

    -- Server-side Get All Players
    GetPlayers = function()
        if Framework == 'QBCore' then
            return FWork.Functions.GetPlayers()
        else
            return FWork.GetPlayers()
        end
    end,

    HasPermission = function(source, perm)
        if Framework == 'QBCore' then 
            return FWork.Functions.HasPermission(source, perm)
        else
            return player.getInventoryItem(source, perm)
        end
    end,

    GetItemByName = function(source, item, amount) 
        if Framework == 'QBCore' then 
            local player = FWork.Functions.GetPlayer(source)
            return player.Functions.GetItemByName(item, amount)
        else
            local player = FWork.GetPlayerFromId(source)
            return player.getInventoryItem(item, amount)
        end
    end,

    -- Server-side get player data
    GetPlayer = function(source,cid,client)
        if Framework == 'QBCore' then
            local self = {}
            local player = nil
            if cid then
                player = FWork.Functions.GetPlayerByCitizenId(source)
            elseif client then
                player = FWork.Functions.GetPlayerData()
            else
                player = FWork.Functions.GetPlayer(source)
            end

            if(player ~= nil) then
                self.source = source
                if client then
                    self.PlayerData = { charinfo = { firstname = player.charinfo.firstname, lastname = player.charinfo.lastname}, citizenid = player.citizenid, money = player.money, metadata = player.metadata }
                else
                    self.PlayerData = { job = {name = player.PlayerData.job.name}, charinfo = { firstname = player.PlayerData.charinfo.firstname, lastname = player.PlayerData.charinfo.lastname, birthdate = player.PlayerData.charinfo.birthdate, phone = player.PlayerData.charinfo.phone}, citizenid = player.PlayerData.citizenid, 
                    money = player.PlayerData.money, metadata = player.PlayerData.metadata, items = player.PlayerData.items }
                end
                self.AddMoney = function(currency, amount) 
                    player.Functions.AddMoney(currency, amount)
                end
                self.RemoveMoney = function(currency, amount) 
                    player.Functions.RemoveMoney(currency, amount)
                end

                self.SetMetaData = function(type, data) 
                    player.Functions.SetMetaData(type,data) -- this is for setting inventory to nothing in qbcore
                end

                self.RemoveItem = function(item, amount) 
                    player.Functions.RemoveItem(item, amount, false)
                end

                self.AddItem = function(item, amount, info) 
                    player.Functions.AddItem(item, amount, false, info)
                end
                
                self.ClearInventory = function() 
                    player.Functions.ClearInventory()
                end
                self.SetJob = function(job, grade) 
                    player.Functions.SetJob(job, grade)
                end

                self.getItemCount = function(item) --this is not used for qbcore, esx only
                    local _, itemData = player.getItem(item)

                    if itemData then
                        return tonumber(itemData.quantity)
                    end

                    return 0
                end

                return self
            end
        else
            local self = {}
            local player = nil
            if client then
                player = FWork.GetPlayerData()
            else
                player = FWork.GetPlayerFromId(source)
            end

            if (player ~= nil) then
                self.source = source
                if client then
                    self.PlayerData = { charinfo = { firstname = player.charinfo.firstname, lastname = player.charinfo.lastname}, citizenid = player.identifier, money = {cash = player.getAccount('money').money, bank = player.getAccount('bank').money}, metadata = player.metadata }
                else
                    self.PlayerData = { charinfo = { firstname = player.get('firstName'), lastname = player.get('lastName')}, citizenid = FWork.GetIdentifier(source), 
                    money = {cash = player.getAccount('money').money, bank = player.getAccount('bank').money}}
                end
                self.AddMoney = function(currency, amount) 
                    player.addMoney(amount)
                end
                self.RemoveMoney = function(currency, amount) 
                    player.removeMoney(amount)
                end

                self.RemoveItem = function(item, amount) 
                    player.removeInventoryItem(item, amount)
                end

                self.AddItem = function(item, amount, info) 
                    player.addInventoryItem(item, amount, false, info)
                end
                
                self.ClearInventory = function(source) 
                    ClearInventoryESX(source)
                end

                self.SetJob = function()
                    player.setJob(job, grade)
                end

                return self
            end
        end

        return nil
    end,
}