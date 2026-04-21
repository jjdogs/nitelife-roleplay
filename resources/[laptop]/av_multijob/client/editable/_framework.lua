function getJob()
    local PlayerJob = nil
    while not Core do Wait(10) end
    if Config.Framework == "esx" then
        PlayerJob = Core.GetPlayerData().job
    end
    if Config.Framework == "qb" then
        Core.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
        end)
    end
    if Config.Framework == "qbox" then
        PlayerJob = QBX.PlayerData.job
    end
    return PlayerJob
end

-- job update listeners just for debug
RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
    dbug("QBCore:Client:OnJobUpdate (job name)", job and job.name or job)
end)

RegisterNetEvent("esx:setJob", function(job, lastJob)
    dbug("esx:setJob(job,lastJob)", job and job.name or "n/a", lastJob and lastJob.name or "n/a")
end)