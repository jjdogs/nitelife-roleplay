Core = nil

CreateThread(function()
    while not Config.Framework do Wait(1) end
    Wait(500)
    print("^2Framework: ^7"..Config.Framework)
    Core = getCore()
    if Config.Framework == "qbox" then return end
end)

function refreshGroups()
    local insertData = {}
    if Config.Framework == "qb" then
        local Players = MySQL.query.await("SELECT `citizenid`, `job` FROM `players`")
        if Players and #Players > 0 then
            for _, Player in ipairs(Players) do
                local PlayerJob = Player['job'] and json.decode(Player['job']) or nil
                if PlayerJob and PlayerJob['name'] and PlayerJob['grade'] then
                    if not Config.IgnoredJobs[PlayerJob['name']] then
                        local level = PlayerJob['grade']['level'] or 0
                        insertData[#insertData+1] = {
                            Player['citizenid'],
                            PlayerJob['name'],
                            'job',
                            tonumber(level)
                        }
                    end
                end
            end
        end
    elseif Config.Framework == "esx" then
        local Players = MySQL.query.await("SELECT `identifier`, `job`, `job_grade` FROM `users`")
        for _, Player in ipairs(Players) do
            if not Config.IgnoredJobs[Player['job']] then
                insertData[#insertData+1] = {
                    Player['identifier'],
                    Player['job'],
                    'job',
                    tonumber(Player.job_grade)
                }
            end
        end
    end
    if #insertData > 0 then
        MySQL.insert.await('INSERT INTO `player_groups` (`citizenid`, `group`, `type`, `grade`) VALUES ?', { insertData })
    end
    dbug("Players added to player_groups:", #insertData)
end

-- Get Framework Core
function getCore()
    if not Core then
        if Config.Framework == "qb" then
            return exports['qb-core']:GetCoreObject()
        elseif Config.Framework == "esx" then
            return exports['es_extended']:getSharedObject()
        end
    end
    return Core
end

-- Get Player Object
function getPlayer(src)
    if Config.Framework == "qb" then
        return Core.Functions.GetPlayer(src)
    elseif Config.Framework == "qbox" then
        return exports.qbx_core:GetPlayer(src)
    elseif Config.Framework == "esx" then
        return Core.GetPlayerFromId(src)
    end
end

-- Get Player ID by identifier
function getSourceByIdentifier(identifier)
    if Config.Framework == "qb" then
        local Player = Core.Functions.GetPlayerByCitizenId(identifier)
        if Player then
            return Player.PlayerData.source
        end
    elseif Config.Framework == "qbox" then
        local Player = getPlayerByIdentifier(identifier)
        if Player then
            return Player.PlayerData.source
        end
    elseif Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            return xPlayer.source
        end
    end
    return false
end

function getPlayerByIdentifier(identifier)
    if Config.Framework == "qb" then
        local Player = Core.Functions.GetPlayerByCitizenId(identifier)
        if Player then
            return Player
        end
    elseif Config.Framework == "qbox" then
        return exports.qbx_core:GetPlayerByCitizenId(identifier)
    elseif Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            return xPlayer
        end
    end
    return false
end

-- Get Player Identifier
function getIdentifier(src)
    if Config.Framework == "qb" then
        local Player = Core.Functions.GetPlayer(src)
        if Player then
            return Player.PlayerData.citizenid
        end
    elseif Config.Framework == "qbox" then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            return Player.PlayerData.citizenid
        end
    elseif Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.identifier
        end
    end
    return false
end

-- Get Player Job
function getJob(src)
    if not src then return false end
    if Config.Framework == "qb" then
        local Player = Core.Functions.GetPlayer(src)
        if not Player then return false end
        return Player.PlayerData.job
    elseif Config.Framework == "qbox" then
        local Player = getPlayer(src)
        if not Player then return false end
        return Player.PlayerData.job
    elseif Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromId(src)
        if not xPlayer then return false end
        return xPlayer.getJob()
    end
end

-- get current job from an offline player
function getOfflineJob(identifier)
    dbug('getOfflineJob(identifier)', identifier)
    if not identifier then
        warn("getOfflineJob(identifier) received nil instead of identifier", identifier)
        return false
    end
    if Config.Framework == "qb" then

    elseif Config.Framework == "qbox" then
        local Player = exports.qbx_core:GetOfflinePlayer(identifier)
        if Player and Player.PlayerData then
            return Player.PlayerData.job and Player.PlayerData.job.name or false
        end
    elseif Config.Framework == "esx" then

    end
    return false
end

-- set job for offline player
function setOfflineJob(identifier, jobName, grade)
    dbug("setOfflineJob(identifier, jobName, grade)", identifier, jobName, grade)
    grade = grade or 0
    if Config.Framework == "qb" then
        local jobData = Core.Shared.Jobs[jobName] and Core.Shared.Jobs[jobName]['grades'][tostring(grade)] or false
        if not jobData then
            jobData = Core.Shared.Jobs[jobName] and (Core.Shared.Jobs[jobName]['grades'][grade] or Core.Shared.Jobs[jobName]['grades'][1])
        end
        local newJob = {
            name = jobData['name'] or "unemployed",
            onduty = true,
            isboss = false,
            payment = jobData['payment'] or 10,
            grade = { name = jobData['name'] or "Freelancer", level = grade }
        }
        MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(newJob), identifier })
    elseif Config.Framework == "qbox" then
        exports.qbx_core:SetJob(identifier, jobName, grade)
    elseif Config.Framework == "esx" then
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?',
            { jobName, grade, identifier })
    end
end

-- return job info
function getJobData(job)
    dbug("getJobdata(job)", job)
    if Config.Framework == "qb" then
        return Core.Shared.Jobs[job]
    elseif Config.Framework == "qbox" then
        return exports.qbx_core:GetJob(job)
    elseif Config.Framework == "esx" then
		if Core.Jobs and not Core.Jobs[job] then
            Core = exports['es_extended']:getSharedObject()
        end
        return Core.Jobs[job]
    end
    return false
end

function toggleDuty(playerId,state)
    if Config.Framework == "qbox" then
        local identifier = getIdentifier(playerId)
        if identifier then
            exports.qbx_core:SetJobDuty(identifier, state)
        end
    elseif Config.Framework == "qb" then
        local Player = getPlayer(playerId)
        if Player then
            Player.Functions.SetJobDuty(state)
        end
    elseif Config.Framework == "esx" then
        local Player = getPlayer(playerId)
        if Player then -- cmon esx just add a SetDuty function lol
            local job = Player.job
            if not job then return end -- idk just in case
            Player.setJob(job.name, job.grade, state)
        end
    end
    if Config.ToggleAVBusinessDuty and GetResourceState("av_business") == "started" then
        exports['av_business']:toggleDuty(playerId,state,true)
    end
end

function setJob(playerId, job, grade, duty)
    grade = grade or 0
    dbug('setJob(playerId, job, grade)', playerId, job, grade)
    local applied = false
    if not playerId or not job then
        warn("setJob(playerId, job, grade) received a nil param", playerId, job, grade)
        return
    end
    if Config.Framework == "qb" then
        local Player = Core.Functions.GetPlayer(playerId)
        if Player then
            if Core.Shared.Jobs[job] then
                Player.Functions.SetJob(job, grade)
                Player.Functions.SetJobDuty(duty)
                applied = true
            end
        end
    elseif Config.Framework == "qbox" then
        local identifier = getIdentifier(playerId)
        if identifier then
            local success, msg = exports.qbx_core:SetJob(identifier, job, grade)
            dbug("SetPlayerPrimaryJob(success, msg)", success, msg and json.encode(msg) or "ok")
            if success then
                exports.qbx_core:SetJobDuty(identifier, duty)
                applied = true
            end
        end
    elseif Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromId(playerId)
        if xPlayer then
            xPlayer.setJob(job, grade, duty)
            applied = true
        end
    end
    if duty and applied and (Config.ToggleAVBusinessDuty and GetResourceState("av_business") == "started") then
        exports['av_business']:toggleDuty(playerId,duty,true)
    end
end

-- Get all players from X job
function getJobPlayers(job)
    dbug("getJobPlayers(job)", job)
    if not job then
        warn("getJobPlayers(job) received nil intead of job", job)
        return {}
    end
    if Config.Framework == "qb" then
        local data = {}
        local added = {}
        local OnlinePlayers = Core.Functions.GetQBPlayers()
        local PlayersGroup = MySQL.query.await("SELECT `citizenid`, `grade` FROM `player_groups` WHERE `group` = ? AND `type` = ?", {job, "job"})
        local PlayersDb = MySQL.query.await("SELECT * FROM players WHERE job LIKE '%" .. job .. "%'", {})
        for _, v in ipairs(PlayersGroup) do
            local Player = Core.Functions.GetPlayerByCitizenId(v['citizenid'])
            if not Player then
                Player = Core.Functions.GetOfflinePlayerByCitizenId(v['citizenid'])
            end
            if Player then
                data[#data + 1] = {
                    identifier = Player['PlayerData']['citizenid'],
                    name = Player['PlayerData']['charinfo']['firstname'] .. ' ' .. Player['PlayerData']['charinfo']['lastname'],
                    grade = Player['PlayerData']['job']['grade'],
                }
                added[Player['PlayerData']['citizenid']] = true
            end
        end
        for _, v in pairs(OnlinePlayers) do
            local jobData = v['PlayerData'] and v['PlayerData']['job']
            if jobData and jobData['name'] == job then
                local citizenid = v['PlayerData']['citizenid']
                if not added[citizenid] then
                    data[#data + 1] = {
                        identifier = v['PlayerData']['citizenid'],
                        name = v['PlayerData']['charinfo']['firstname'] .. ' ' .. v['PlayerData']['charinfo']['lastname'],
                        grade = jobData['grade'],
                    }
                    added[citizenid] = true
                end
            end
        end
        for _, v in ipairs(PlayersDb) do
            if not added[v['citizenid']] then
                local Player = getPlayerByIdentifier(v['citizenid'])
                if Player then
                    local jobData = Player['PlayerData'] and Player['PlayerData']['job']
                    if jobData and jobData['name'] == job then
                        data[#data + 1] = {
                            identifier = v['citizenid'],
                            name = Player['PlayerData']['charinfo']['firstname'] .. ' ' .. Player['PlayerData']['charinfo']['lastname'],
                            grade = jobData['grade'],
                        }
                    end
                else
                    data[#data + 1] = {
                        identifier = v['citizenid'],
                        name = json.decode(v['charinfo']).firstname .. ' ' .. json.decode(v['charinfo']).lastname,
                        grade = json.decode(v['job']).grade,
                    }
                end
            end
        end
        return data
    elseif Config.Framework == "qbox" then
        local data = {}
        local Players = exports.qbx_core:GetGroupMembers(job, "job")
        if Players and next(Players) then
            for _, v in pairs(Players) do
                local res = exports.qbx_core:GetPlayerByCitizenId(v['citizenid'])
                PlayerData = res and res.PlayerData or false
                if not PlayerData then
                    local offline = exports.qbx_core:GetOfflinePlayer(v['citizenid'])
                    PlayerData = offline and offline.PlayerData or false
                end
                if PlayerData then
                    data[#data + 1] = {
                        identifier = PlayerData['citizenid'],
                        name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
                        grade = PlayerData.job.grade,
                    }
                end
            end
        end
        return data
    elseif Config.Framework == "esx" then
        if Core.Jobs and not Core.Jobs[job] then
            Core = exports['es_extended']:getSharedObject()
        end
        local jobData = Core.Jobs[job]
        local added = {}
        local data = {}
        local OnlinePlayers = Core.GetExtendedPlayers('job', job)
        local PlayersGroup = MySQL.query.await("SELECT `citizenid`, `grade` FROM `player_groups` WHERE `group` = ? AND `type` = ?", {job, "job"})
        local PlayersDb = MySQL.query.await("SELECT `identifier`, `job_grade`, `firstname`, `lastname` FROM `users` WHERE `job` = ?", {job})
        for _, v in pairs(OnlinePlayers) do
            local xPlayer = getPlayerByIdentifier(v['identifier'])
            if xPlayer then
                local onlineJob = xPlayer.getJob()
                data[#data + 1] = {
                    identifier = v['identifier'],
                    name = xPlayer.getName(),
                    grade = { name = onlineJob.grade_label, level = onlineJob.grade },
                }
                added[v['identifier']] = true
            end
        end
        for _, v in ipairs(PlayersDb) do
            if not added[v['identifier']] then
                local myGrade = jobData['grades'] and jobData['grades'][tostring(v['job_grade'])]
                if myGrade then
                    data[#data + 1] = {
                        identifier = v['identifier'],
                        name = v['firstname'] .. ' ' .. v['lastname'],
                        grade = { name = myGrade['label'], level = myGrade['grade'] },
                    }
                    added[v['identifier']] = true
                else
                    dbug("No data for job grade ", v['job_grade'], " in job ", v['job'])
                end
            end
        end
        for _, v in ipairs(PlayersGroup) do
            if not added[v['citizenid']] then
                local Player = MySQL.single.await("SELECT `job_grade`, `firstname`, `lastname` FROM `users` WHERE `job` = ? AND `identifier` = ?", {job, v['citizenid']})
                local myGrade = jobData['grades'] and jobData['grades'][tostring(v['grade'])]
                if myGrade then
                    data[#data + 1] = {
                        identifier = v['citizenid'],
                        name = Player['firstname'] .. ' ' .. Player['lastname'],
                        grade = { name = myGrade['label'], level = myGrade['grade'] },
                    }
                    added[v['citizenid']] = true
                else
                    dbug("No data for job grade ", v['grade'], " in job ", v['job'])
                end
            end
        end
        return data
    end
end

function getGradeData(job)
    local data = {}
    if Config.Framework == "esx" then
        data['label'] = job and job['label'] or ""
        data['grade'] = job and job['grade'] or 0
        data['grade_label'] = job and job['grade_label'] or ""
        data['onDuty'] = job and job['onDuty']
    else
        data['label'] = job and job['label'] or ""
        data['grade'] = job and job['grade'] and job['grade']['level'] or 0
        data['grade_label'] = job and job['grade'] and job['grade']['name'] or ""
        data['onDuty'] = job and job['onduty']
    end
    return data
end

function getExtraData(playerId, identifier, jobData)
    -- Use this function to return a table with all your extra values to use in UI with the extraData field
    -- examples: online job players, player salary, etc... that's on you to fetch and render in the job panel
    return {}
end

function updater(playerId, type, job, grade)
    dbug("updated(playerId,type,job,grade)", playerId, type, job, grade)
    
end

-- Event catchers
AddEventHandler("qbx_core:server:onGroupUpdate", function(playerId)
    if not playerId then return end
    TriggerClientEvent("av_multijob:listeners", playerId, "refresh")
end)

AddEventHandler("QBCore:Server:OnJobUpdate", function(playerId, jobData)
    if not playerId or not jobData then return end
    TriggerClientEvent("av_multijob:listeners", playerId, "refresh")
end)

AddEventHandler("esx:setJob", function(playerId)
    if not playerId then return end
    TriggerClientEvent("av_multijob:listeners", playerId, "refresh")
end)