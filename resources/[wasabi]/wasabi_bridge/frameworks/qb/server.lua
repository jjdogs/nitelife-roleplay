-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

local foundQB = GetResourceState('qb-core')
local foundQBX = GetResourceState('qbx_core')
if (foundQB ~= 'started' and foundQB ~= 'starting') and (foundQBX ~= 'started' and foundQBX ~= 'starting') then return end

QBCore = (foundQB == 'started' or foundQB == 'starting') and exports['qb-core']:GetCoreObject() or exports['qbx_core']:GetCoreObject()
WSB = {}
WSB.framework = 'qb'

---@diagnostic disable: duplicate-set-field

local qbx = GetResourceState('qbx_core')
local qboxFound = qbx == 'started' or qbx == 'starting' or false

local oxInventory = GetResourceState('ox_inventory')
local oxFound = oxInventory == 'started' or oxInventory == 'starting' or false

function WSB.getCore()
    return QBCore
end

function WSB.getPlayer(source)
    if qboxFound then
        return exports.qbx_core:GetPlayer(source)
    end

    return QBCore.Functions.GetPlayer(source)
end

function WSB.getPlayerFromIdentifier(identifier)
    local player = qboxFound and exports.qbx_core:GetPlayerByCitizenId(identifier) or
        QBCore.Functions.GetPlayerByCitizenId(identifier)
    if not player then return false end
    return player
end

function WSB.getPlayerIdFromIdentifier(identifier)
    local player = qboxFound and exports.qbx_core:GetPlayerByCitizenId(identifier) or
        QBCore.Functions.GetPlayerByCitizenId(identifier)
    if not player then return false end
    return player.PlayerData.source
end

function WSB.getPlayers()
    if qboxFound then
        return exports.qbx_core:GetQBPlayers()
    end

    return QBCore.Functions.GetPlayers()
end

function WSB.getAllJobs()
    local jobs = qboxFound and exports.qbx_core:GetJobs() or QBCore and QBCore.Shared and QBCore.Shared.Jobs or nil
    local returnTb = {}
    if not next(jobs) then return end
    for k, v in pairs(jobs) do
        returnTb[k] = { label = v.label }
        for a, b in pairs(v.grades) do
            if not returnTb[k].grades then returnTb[k].grades = {} end
            local payment = 0
            if b then
                if b.salary then
                    payment = b.salary
                elseif b.payment then
                    payment = b.payment
                end
            end
            returnTb[k].grades[a] = {
                payment = payment,
                name = b.name,
                label = (b and b.label) or b.name
            }
        end
    end
    return returnTb
end

function WSB.awaitClientCallback(name, source, ...)
    return lib.callback.await(name, source, ...)
end

function WSB.registerCallback(name, fn)
    lib.callback.register(name, function(source, ...)
        local results = nil
        local cb = function(...)
            results = {...}
        end
        local ok, ret = pcall(function(...)
            return table.pack(fn(source, cb, ...))
        end, ...)
        if not ok then
            error(ret)
        end
        if results then
            return table.unpack(results)
        end
        if ret and ret.n then
            return table.unpack(ret, 1, ret.n)
        end
    end)
end

-- function WSB.registerCallback(name, handler)
--     QBCore.Functions.CreateCallback(name, function(source, cb, ...)
--         local responded = false
--         local function cbWrapper(...)
--             responded = true
--             cb(...)
--         end
--         local ok, ret = pcall(function(...)
--             return table.pack(handler(source, cbWrapper, ...))
--         end, ...)

--         if ok then
--             if not responded and ret ~= nil then
--                 cb(table.unpack(ret, 1, ret.n))
--             end
--         end
--     end)
-- end

function WSB.kickPlayer(source, reason)
    if qboxFound then
        return exports.qbx_core:ExploitBan(source, reason)
    end
    QBCore.Functions.Kick(source, reason, true, true)
end

function WSB.hasPermission(source, group)
    if qboxFound then
        return exports.qbx_core:HasPermission(source, group) or false
    end

    return QBCore.Functions.HasPermission(source, group) 
end

function WSB.hasGroup(source, filter)
    local player = WSB.getPlayer(source)
    if not player or not player.PlayerData then return end
    local groups = { 'job', 'gang' }
    local type = type(filter)

    if type == 'string' then
        for i = 1, #groups do
            local data = player.PlayerData[groups[i]]
            if data and data.name == filter then
                return data.name, data.grade.level
            end
        end
    elseif type == 'table' then
        local tabletype = table.type(filter)
        if tabletype == 'hash' then
            for i = 1, #groups do
                local data = player.PlayerData[groups[i]]
                if data then
                    local grade = filter[data.name]
                    if grade and grade <= data.grade.level then
                        return data.name, data.grade.level
                    end
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local group = filter[i]
                for j = 1, #groups do
                    local data = player.PlayerData[groups[j]]
                    if data and data.name == group then
                        return data.name, data.grade.level
                    end
                end
            end
        end
    end
end

function WSB.setJob(source, job, grade)
    local player = WSB.getPlayer(source)
    if not player then return end
    player.Functions.SetJob(job, grade)
end

function WSB.getJobData(source)
    local player = WSB.getPlayer(source)
    if not player then return end
    local job = player.PlayerData.job
    return job
end

function WSB.getJobLabel(source)
    local player = WSB.getPlayer(source)
    if not player then return end
    return player.PlayerData.job.label
end

function WSB.toggleDuty(source, _job, _grade)
    local player = WSB.getPlayer(source)
    if not player then return end
    if player.PlayerData.job.onduty then
        player.Functions.SetJobDuty(false)
        return 'off'
    else
        player.Functions.SetJobDuty(true)
        return 'on'
    end
end

function WSB.isPlayerBoss(source)
    local player = WSB.getPlayer(source)
    if not player then return end
    if player?.PlayerData?.job?.isboss then return true else return false end
end

function WSB.getIdentifier(source)
    local player = WSB.getPlayer(source)
    if not player then return end
    return player.PlayerData.citizenid
end

function WSB.getName(source)
    local player = WSB.getPlayer(source)
    if not player then return end
    return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
end

function WSB.getNameFromPlayerObj(player)
    if not player then return end
    return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
end

function WSB.registerUsableItem(item, cb)
    if WSB.inventorySystem == 'jaksam_inventory' then
        exports['jaksam_inventory']:registerUsableItem(item, cb)
        return
    end
    if qboxFound then
        exports.qbx_core:CreateUseableItem(item, cb)
    else
        QBCore.Functions.CreateUseableItem(item, cb)
    end
end

function WSB.getPlayerInventory(source)
    if WSB.inventorySystem == 'jaksam_inventory' then
        local inv = exports['jaksam_inventory']:getInventory(source)
        if not inv or not inv.items then return {} end
        local cleanedItems, count = {}, 0
        for _, item in pairs(inv.items) do
            if item and item.name then
                count = count + 1
                cleanedItems[count] = {
                    name = item.name,
                    amount = item.amount or 0,
                    count = item.amount or 0,
                    metadata = item.metadata or {}
                }
            end
        end
        return cleanedItems
    end
    local player = WSB.getPlayer(source)
    if not player then return end
    local cleanedItems, count = {}, 0
    for _, item in pairs(player.PlayerData.items) do
        if item then
            count = count + 1
            cleanedItems[count] = item
            cleanedItems[count].amount = cleanedItems[count].count or cleanedItems[count].amount
            cleanedItems[count].count = cleanedItems[count].count or cleanedItems[count].amount
        end
    end
    return cleanedItems or {}
end

function WSB.hasItem(source, _item)
    if WSB.inventorySystem == 'jaksam_inventory' then
        return exports['jaksam_inventory']:getTotalItemAmount(source, _item) or 0
    end
    if qboxFound or oxFound then
        return exports.ox_inventory:GetItem(source, _item, nil, true) or 0
    end
    local player = WSB.getPlayer(source)
    if not player then return end
    local item = player.Functions.GetItemByName(_item)
    return item?.count or item?.amount or 0
end

local qsInventory = GetResourceState('qs-inventory')
local qsFound = qsInventory == 'started' or qsInventory == 'starting' or false


function WSB.addItem(source, item, count, slot, metadata)
    if WSB.inventorySystem == 'jaksam_inventory' then
        local ok = exports['jaksam_inventory']:addItem(source, item, count or 1, metadata, slot)
        return ok
    end
    if qboxFound or oxFound then
        return exports.ox_inventory:AddItem(source, item, count, metadata, slot)
    end

    local player = WSB.getPlayer(source)
    if not player then return end
    local giveItem = player.Functions.AddItem(item, count, slot, metadata)
    item = player.Functions.GetItemByName(item)
    if item and item.count then item.count = count elseif item and item.amount then item.amount = count end
    if not qsFound then
        TriggerClientEvent('inventory:client:ItemBox', source, item, 'add')
    end
    return giveItem
end

function WSB.addWeapon(source, weapon, ammo)
    if WSB.inventorySystem == 'jaksam_inventory' then
        return exports['jaksam_inventory']:addItem(source, weapon, 1, nil, nil)
    end
    if qboxFound or oxFound then
        return exports.ox_inventory:AddItem(source, weapon, 1)
    end

    local player = WSB.getPlayer(source)
    if not player then return end
    return player.Functions.AddItem(weapon, 1, nil, nil)
end

function WSB.removeItem(source, item, count, slot, metadata)
    if WSB.inventorySystem == 'jaksam_inventory' then
        local ok = exports['jaksam_inventory']:removeItem(source, item, count or 1, metadata, slot)
        return ok
    end
    if qboxFound or oxFound then
        return exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
    end

    local player = WSB.getPlayer(source)
    if not player then return end
    player.Functions.RemoveItem(item, count, slot, metadata)
end

function WSB.addMoney(source, type, amount)
    if type == 'black_money' then
        WSB.addItem(source, 'black_money', amount)
        return
    end
    if type == 'money' then type = 'cash' end
    local player = WSB.getPlayer(source)
    if not player then return end
    player.Functions.AddMoney(type, amount)
end

function WSB.removeMoney(source, type, amount)
    if type == 'black_money' then
        WSB.removeItem(source, 'black_money', amount)
        return
    end
    if type == 'money' then type = 'cash' end
    local player = WSB.getPlayer(source)
    if not player then return end
    player.Functions.RemoveMoney(type, amount)
end

function WSB.hasLicense(source, license)
    local player = WSB.getPlayer(source)
    if not player then return end
    local licenses = player.PlayerData.metadata['licences']
    if licenses and licenses[license] then return true end
    return false
end

function WSB.grantLicense(source, license)
    local player = WSB.getPlayer(source)
    if not player then return false end
    local licenses = player.PlayerData.metadata['licences']
    if licenses and licenses[license] then return false end
    if not licenses then licenses = {} end
    licenses[license] = true
    player.Functions.SetMetaData('licences', licenses)
    return true
end

function WSB.revokeLicense(source, license)
    local targetPlayer = WSB.getPlayer(source)
    if not targetPlayer then return end
    local Oldlicenses = targetPlayer.PlayerData.metadata['licences']
    if not Oldlicenses[license] then return end
    local licenses = {}
    for k, v in pairs(Oldlicenses) do
        if k ~= license then
            licenses[k] = v
        end
    end
    targetPlayer.Functions.SetMetaData('licences', licenses)
end

function WSB.getPlayerAccountFunds(source, type)
    if type == 'money' then type = 'cash' end
    local player = WSB.getPlayer(source)
    if not player then return end
    return player.PlayerData.money[type]
end

WSB.getPlayerIdentity = function(source)
    local player = WSB.getPlayer(source)
    if not player then return end
    local data = {
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        job = player.PlayerData.job.label,
        position = player.PlayerData.job.grade.name,
        dob = player.PlayerData.charinfo.birthdate,
        licenses = {}
    }
    if player.PlayerData.charinfo.gender == 1 then
        data.sex = 'female'
    else
        data.sex = 'male'
    end
    if player.PlayerData.metadata['licences'] then
        for k, v in pairs(player.PlayerData.metadata['licences']) do
            if v then
                data.licenses[#data.licenses + 1] = {
                    type = k
                }
            end
        end
    end
    return data
end

function WSB.getVehicleOwner(plate)
    local owner
    MySQL.Async.fetchAll('SELECT citizenid FROM player_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            local identifier = result[1].citizenid
            MySQL.Async.fetchAll('SELECT charinfo FROM players WHERE citizenid = @identifier', {
                ['@identifier'] = identifier
            }, function(result2)
                if result2[1] then
                    local charData = json.decode(result2[1].charinfo)
                    owner = charData.firstname .. ' ' .. charData.lastname
                else
                    owner = false
                end
            end)
        else
            owner = false
        end
    end)
    while owner == nil do Wait(0) end
    return owner
end
