-- ── Contact ped (Naveed at the yard) ─────────────────────────────────────────
SD.Ped.CreatePedAtPoint({
    model           = Config.ContactPed.model,
    coords          = Config.ContactPed.coords,
    distance        = Config.ContactPed.distance,
    freeze          = Config.ContactPed.freeze,
    scenario        = Config.ContactPed.scenario,
    interactionType = 'target',
    targetOptions   = Config.TargetOptions,
})

-- ── Job state ─────────────────────────────────────────────────────────────────
local activeJob           = nil  -- { id, vehicleNetId, pay, stage, flatbed }
local jobVehicle          = nil  -- entity handle
local jobPed              = nil  -- entity handle
local jobBlip             = nil
local dropoffBlip         = nil
local towedVehicle      = nil
local alignmentNotified = false
local unloadTargetAdded   = false

-- ── NPC models ────────────────────────────────────────────────────────────────
local pedModels = {
    'a_m_m_business_01', 'a_f_m_business_02',
    'a_m_y_hipster_01',  'a_f_y_tourist_01',
    'a_m_m_skater_01',   'a_f_y_jogger_01',
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function GetTruckType(vehicle)
    local model = GetEntityModel(vehicle)
    if model == GetHashKey('flatbed') then return 'flatbed' end
    return 'wrecker'
end

-- ── Spawn job vehicle + NPC ───────────────────────────────────────────────────
local function spawnJobEntities(job)
    local coords  = vector3(job.Location.X, job.Location.Y, job.Location.Z)
    local heading = job.LocationHeading or 0.0

    local vehModel = GetHashKey(job.VehicleModel)
    RequestModel(vehModel)
    while not HasModelLoaded(vehModel) do Wait(100) end
    local veh = CreateVehicle(vehModel, coords.x, coords.y, coords.z, heading, true, false)
    SetModelAsNoLongerNeeded(vehModel)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, false, true, false)
    SetEntityInvincible(veh, true)

    if job.Reason and job.Reason:lower():find('flat') then
        for i = 0, 5 do SetVehicleTyreBurst(veh, i, true, 1000.0) end
    end

    local pedModelName = pedModels[math.random(#pedModels)]
    local pedModel = GetHashKey(pedModelName)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(100) end
    local pedOffset = GetOffsetFromEntityInWorldCoords(veh, -1.8, 0.5, 0.0)
    local ped = CreatePed(4, pedModel, pedOffset.x, pedOffset.y, pedOffset.z, heading + 180.0, true, false)
    SetModelAsNoLongerNeeded(pedModel)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_MOBILE_FILM_SHOCKING', 0, true)

    exports.ox_target:addLocalEntity(ped, {{
        name     = 'tow_dialog_' .. job.JobId,
        label    = 'Talk to Owner',
        distance = 3.0,
        onSelect = function()
            exports['sd-dialog']:Open({
                entity      = ped,
                name        = job.OwnerName,
                role        = 'Stranded Driver',
                roleColor   = '#ef4444',
                description = job.DialogText or ('My %s broke down. I really need a tow.'):format(job.VehicleModel),
                options     = {{
                    id          = 'complete_tow',
                    label       = 'Tow Vehicle',
                    icon        = 'truck',
                    description = ('Complete job for $%d'):format(job.PayAmount),
                    clientEvent = 'nt_tow:confirmTow',
                }},
            })
        end,
    }})

    return veh, ped
end

-- ── Unload vehicle at drop-off ────────────────────────────────────────────────
local function doUnload()
    if not activeJob or not activeJob.flatbed then return end
    local flatbed  = activeJob.flatbed
    local truckType = GetTruckType(flatbed)

    if unloadTargetAdded and towedVehicle and DoesEntityExist(towedVehicle) then
        exports.ox_target:removeLocalEntity(towedVehicle, 'unload_vehicle')
    end
    unloadTargetAdded = false
    alignmentNotified = false
    activeJob.stage   = 'unloading'

    if truckType == 'flatbed' then
        LowerFlatbed(flatbed)
        Wait(4000)
    end

    if towedVehicle and DoesEntityExist(towedVehicle) then
        DetachVehicle(towedVehicle)
        SetVehicleOnGroundProperly(towedVehicle)
    end

    exports.lation_ui:updateTimelineTask('tow_job', {
        { id = 'deliver', status = 'completed' },
    })
    Wait(1000)
    exports.lation_ui:hideTimeline('tow_job')

    if dropoffBlip and DoesBlipExist(dropoffBlip) then RemoveBlip(dropoffBlip) end
    dropoffBlip = nil

    local pay   = activeJob.pay
    local jobId = activeJob.id

    TriggerServerEvent('citysim:completeJob', jobId)
    TriggerServerEvent('nt_tow:completeJob', jobId, pay)

    SendNUIMessage({ action = 'tow:jobComplete', data = {} })
    lib.notify({ title = 'Job Complete', description = ('$%d paid to bank'):format(pay), type = 'success', duration = 5000 })

    -- Despawn job vehicle when player drives far enough away
    local despawnVeh = towedVehicle
    towedVehicle = nil

    if jobPed and DoesEntityExist(jobPed) then
        exports.ox_target:removeLocalEntity(jobPed)
        DeleteEntity(jobPed)
        jobPed = nil
    end

    activeJob = nil

    CreateThread(function()
        while despawnVeh and DoesEntityExist(despawnVeh) do
            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(despawnVeh))
            if dist > 100.0 then
                SetEntityAsMissionEntity(despawnVeh, false, true)
                DeleteEntity(despawnVeh)
                TriggerServerEvent('nt_tow:requestNewJob')
                break
            end
            Wait(2000)
        end
    end)
end

-- ── Called once vehicle is confirmed attached to the flatbed bed ──────────────
local function onVehicleLoaded()
    if not activeJob or activeJob.stage ~= 'confirmed' then return end
    activeJob.stage = 'loaded'
    towedVehicle    = jobVehicle

    exports.lation_ui:updateTimelineTask('tow_job', {
        { id = 'load',    status = 'completed' },
        { id = 'deliver', status = 'active' },
    })

    if jobBlip and DoesBlipExist(jobBlip) then RemoveBlip(jobBlip) end
    jobBlip = nil

    local c = Config.DropoffCoords
    dropoffBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(dropoffBlip, 1)
    SetBlipColour(dropoffBlip, 2)
    SetBlipScale(dropoffBlip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("Naveed's Yard")
    EndTextCommandSetBlipName(dropoffBlip)
    SetNewWaypoint(c.x, c.y)

    lib.notify({ title = 'Vehicle Loaded', description = 'Return to yard', type = 'success', duration = 5000 })

    -- Ground marker + alignment thread
    CreateThread(function()
        while activeJob and activeJob.stage ~= 'unloading' do
            local flatbed = activeJob and activeJob.flatbed
            if not flatbed or not DoesEntityExist(flatbed) then Wait(500) end

            local dropCoords = vector3(Config.DropoffCoords.x, Config.DropoffCoords.y, Config.DropoffCoords.z)
            local truckCoords = flatbed and GetEntityCoords(flatbed) or GetEntityCoords(PlayerPedId())
            local dist = #(truckCoords - dropCoords)

            if dist < 30.0 then
                local targetHeading = Config.DropoffCoords.w
                local truckHeading  = flatbed and GetEntityHeading(flatbed) or 0.0
                local headingDiff   = math.abs((truckHeading - targetHeading + 180) % 360 - 180)
                local aligned       = dist < Config.DropoffAlignThreshold.distance and headingDiff < Config.DropoffAlignThreshold.heading

                local r, g, b = 255, 255, 255
                if aligned then
                    r, g, b = 100, 255, 100
                elseif dist < Config.DropoffAlignThreshold.distance then
                    r, g, b = 255, 200, 0
                end

                DrawMarker(1,
                    dropCoords.x, dropCoords.y, dropCoords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, targetHeading,
                    4.0, 4.0, 1.5,
                    r, g, b, 160,
                    false, true, 2, false, nil, nil, false)

                if aligned then
                    if not alignmentNotified then
                        alignmentNotified = true
                        exports.lation_ui:updateTimelineTask('tow_job', {
                            { id = 'deliver', status = 'active', label = 'Unload Vehicle' },
                        })
                        lib.notify({ title = 'Tow Job', description = 'Exit vehicle and unload', type = 'inform' })
                    end

                    if not IsPedInAnyVehicle(PlayerPedId(), false) and not unloadTargetAdded then
                        if towedVehicle and DoesEntityExist(towedVehicle) then
                            unloadTargetAdded = true
                            exports.ox_target:addLocalEntity(towedVehicle, {{
                                name     = 'unload_vehicle',
                                label    = 'Unload Vehicle',
                                icon     = 'fas fa-truck-ramp-box',
                                distance = 4.0,
                                onSelect = function()
                                    CreateThread(doUnload)
                                end,
                            }})
                        end
                    end
                else
                    -- Remove unload target if truck drifted out of alignment
                    if unloadTargetAdded and towedVehicle and DoesEntityExist(towedVehicle) then
                        exports.ox_target:removeLocalEntity(towedVehicle, 'unload_vehicle')
                        unloadTargetAdded = false
                    end
                    if alignmentNotified then
                        alignmentNotified = false
                    end
                end
            end

            Wait(0)
        end
    end)
end

-- ── Full cleanup (cancel / death) ─────────────────────────────────────────────
local function cleanupJob()
    exports.lation_ui:hideTimeline('tow_job')

    if jobBlip     and DoesBlipExist(jobBlip)     then RemoveBlip(jobBlip)     end
    if dropoffBlip and DoesBlipExist(dropoffBlip) then RemoveBlip(dropoffBlip) end
    jobBlip     = nil
    dropoffBlip = nil

    if jobPed and DoesEntityExist(jobPed) then
        exports.ox_target:removeLocalEntity(jobPed)
        DeleteEntity(jobPed)
        jobPed = nil
    end

    if towedVehicle and DoesEntityExist(towedVehicle) and unloadTargetAdded then
        exports.ox_target:removeLocalEntity(towedVehicle, 'unload_vehicle')
    end

    if jobVehicle and DoesEntityExist(jobVehicle) then
        SetEntityAsMissionEntity(jobVehicle, false, true)
        DeleteEntity(jobVehicle)
        jobVehicle = nil
    end

    towedVehicle      = nil
    alignmentNotified = false
    unloadTargetAdded = false
    activeJob = nil
    SendNUIMessage({ action = 'tow:jobComplete', data = {} })
    SetWaypointOff()
end

-- ── State bag: vehicle attached via nt_tow:attachCar ─────────────────────────
-- Winch.lua's bed-attach target calls AttachVehicle() directly without setting
-- this state bag, so we also poll via GetEntityAttachedTo as a fallback below.
AddStateBagChangeHandler('attachedVehicle', '', function(bagName, _, value)
    if not activeJob or activeJob.stage ~= 'confirmed' then return end
    if not value or value == -1 then return end
    if not activeJob.vehicleNetId or value ~= activeJob.vehicleNetId then return end
    local flatbed = GetEntityFromStateBagName(bagName)
    if not flatbed or not DoesEntityExist(flatbed) then return end
    activeJob.flatbed = flatbed
    onVehicleLoaded()
end)

-- ── citysim events ────────────────────────────────────────────────────────────
RegisterNetEvent('citysim:receiveJobs')
AddEventHandler('citysim:receiveJobs', function(jsonStr)
    local jobs = json.decode(jsonStr)
    if not jobs or #jobs == 0 then
        lib.notify({ title = 'Tow Dispatch', description = 'No jobs available right now.', type = 'error' })
        return
    end
    local uiJobs = {}
    for _, j in ipairs(jobs) do
        uiJobs[#uiJobs + 1] = {
            id           = tostring(j.JobId),
            vehicleModel = j.VehicleModel or '???',
            ownerName    = j.OwnerName    or 'Unknown',
            reason       = j.Reason       or 'Breakdown',
            jobType      = 'tow',
            payAmount    = j.PayAmount    or 0,
        }
    end
    SendNUIMessage({ action = 'tow:setJobs', data = uiJobs })
    lib.notify({ title = 'Tow Dispatch', description = #jobs .. ' job(s) available — check your laptop', type = 'inform' })
end)

RegisterNetEvent('citysim:jobAccepted')
AddEventHandler('citysim:jobAccepted', function(jsonStr)
    local job = json.decode(jsonStr)

    activeJob = {
        id           = job.JobId,
        vehicleNetId = nil,
        pay          = job.PayAmount,
        vehicleModel = job.VehicleModel,
        stage        = 'assigned',
        flatbed      = nil,
    }
    SendNUIMessage({ action = 'tow:jobActive', data = {
        vehicleModel = job.VehicleModel or '???',
        pay          = job.PayAmount    or 0,
    }})

    local jobCoords = vector3(job.Location.X, job.Location.Y, job.Location.Z)

    jobBlip = AddBlipForCoord(jobCoords.x, jobCoords.y, jobCoords.z)
    SetBlipSprite(jobBlip, 522)
    SetBlipColour(jobBlip, 5)
    SetBlipScale(jobBlip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Tow: ' .. job.VehicleModel)
    EndTextCommandSetBlipName(jobBlip)
    SetNewWaypoint(jobCoords.x, jobCoords.y)

    lib.notify({
        title       = 'Tow Job Assigned',
        description = ('Head to the job location — %s'):format(job.Reason),
        type        = 'inform',
        duration    = 5000,
    })

    CreateThread(function()
        local spawned = false
        while activeJob do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist    = #(pCoords - jobCoords)

            if dist < 150.0 and not spawned then
                spawned = true
                CreateThread(function()
                    jobVehicle, jobPed = spawnJobEntities(job)
                    if jobVehicle and DoesEntityExist(jobVehicle) then
                        activeJob.vehicleNetId = NetworkGetNetworkIdFromEntity(jobVehicle)
                    end
                end)
            end

            if dist < 40.0 then
                DrawMarker(2,
                    jobCoords.x, jobCoords.y, jobCoords.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    3.0, 3.0, 1.0,
                    255, 200, 0, 150,
                    false, true, 2, false, nil, nil, false)
            end

            Wait(0)
        end
    end)
end)

RegisterNetEvent('citysim:jobUnavailable')
AddEventHandler('citysim:jobUnavailable', function()
    lib.notify({ title = 'Tow Test', description = 'That job is no longer available.', type = 'error' })
end)

-- ── Player confirms tow via NPC dialog ────────────────────────────────────────
RegisterNetEvent('nt_tow:confirmTow')
AddEventHandler('nt_tow:confirmTow', function()
    if not activeJob then return end
    exports['sd-dialog']:Close()

    activeJob.stage = 'confirmed'

    exports.lation_ui:showTimeline({
        id        = 'tow_job',
        title     = 'Tow Job',
        icon      = 'fas fa-truck-moving',
        iconColor = '#22c55e',
        position  = 'right-center',
        tasks     = {
            { id = 'locate',  label = 'Locate vehicle',         status = 'completed' },
            { id = 'load',    label = 'Load vehicle on flatbed', status = 'active'    },
            { id = 'deliver', label = 'Return to yard',          status = 'pending'   },
        },
    })

    -- Polling fallback: winch.lua's bed-attach calls AttachVehicle() directly
    -- without updating the attachedVehicle state bag, so we detect physical
    -- attachment via GetEntityAttachedTo as well.
    CreateThread(function()
        while activeJob and activeJob.stage == 'confirmed' do
            Wait(500)
            if jobVehicle and DoesEntityExist(jobVehicle) then
                local bedProp = GetEntityAttachedTo(jobVehicle)
                if bedProp ~= 0 then
                    local flatbed = GetEntityAttachedTo(bedProp)
                    if flatbed ~= 0 and DoesEntityExist(flatbed) then
                        activeJob.flatbed = flatbed
                        onVehicleLoaded()
                    end
                end
            end
        end
    end)
end)

-- ── Cleanup on death ──────────────────────────────────────────────────────────
AddEventHandler('baseevents:onPlayerKilled', function()
    if activeJob then cleanupJob() end
end)

-- ── Naveed: join queue ────────────────────────────────────────────────────────
RegisterNetEvent('nt_tow:startJob')
AddEventHandler('nt_tow:startJob', function()
    if activeJob then
        lib.notify({ title = 'Tow Dispatch', description = 'You already have an active job.', type = 'error' })
        return
    end
    exports['sd-dialog']:Close()
    TriggerServerEvent('citysim:requestJobs')
end)

-- ── Commands ──────────────────────────────────────────────────────────────────
RegisterCommand('towtest', function()
    if activeJob then
        lib.notify({ title = 'Tow Test', description = 'Already have an active test job.', type = 'error' })
        return
    end
    TriggerServerEvent('citysim:requestJobs')
end, false)

RegisterCommand('givetowjob', function()
    if activeJob then
        lib.notify({ title = 'Tow Test', description = 'Already have an active test job.', type = 'error' })
        return
    end
    TriggerServerEvent('citysim:giveJob')
end, false)

RegisterCommand('addJob', function(_, args)
    local count = math.max(1, math.min(tonumber(args[1]) or 1, 10))
    TriggerServerEvent('citysim:addJob', count)
    lib.notify({ title = 'City Sim', description = ('Queuing %d breakdown job(s)...'):format(count), type = 'inform' })
end, false)

if Config.Debug then
    RegisterCommand('canceltow', function()
        if not activeJob then
            lib.notify({ title = 'Tow', description = 'No active job.', type = 'error' })
            return
        end
        cleanupJob()
        lib.notify({ title = 'Tow', description = 'Job cancelled.', type = 'inform' })
    end, false)
end

-- ── Laptop NUI callbacks ──────────────────────────────────────────────────────
RegisterNUICallback('tow:open', function(_, cb)
    if activeJob then
        SendNUIMessage({ action = 'tow:jobActive', data = {
            vehicleModel = activeJob.vehicleModel or '???',
            pay          = activeJob.pay          or 0,
        }})
    else
        TriggerServerEvent('citysim:requestJobs')
    end
    cb({ ok = true })
end)

RegisterNUICallback('tow:acceptJob', function(data, cb)
    if activeJob then
        cb({ ok = false, reason = 'Already have an active job' })
        return
    end
    if data and data.jobId then
        TriggerServerEvent('citysim:acceptJob', data.jobId)
    end
    cb({ ok = true })
end)
