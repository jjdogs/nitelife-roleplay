local jobs = {}
local myJobs = {}

function jobs.isManager(station)
    return myJobs[station] and myJobs[station].isManager
end exports('IsManager', jobs.isManager)

function jobs.isEmployee(station)
    return myJobs[station]
end exports('IsEmployee', jobs.isEmployee)

RegisterNetEvent('Renewed-Fuel:client:addJob', function(station, isManager)
    myJobs[station] = {
        isManager = isManager
    }
end)

RegisterNetEvent('Renewed-Fuel:client:removeJob', function(station)
    myJobs[station] = nil
end)

local function initJobs()
    local dbJobs = lib.callback.await('Renewed-Fuel:server:getJobs', false)

    if dbJobs then
        for i = 1, #dbJobs do
            local job = dbJobs[i]
            myJobs[job.station] = {
                isManager = job.grade
            }
        end
    end
end

AddEventHandler('Renewed-Lib:client:PlayerLoaded', initJobs)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        initJobs()
    end
end)





return jobs