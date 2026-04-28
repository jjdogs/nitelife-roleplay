local stateTimerConstants = {4.0, 2.0}
local soundId = nil
local managedFlatbeds = {}

-- Pre-load the bed model so it's ready the instant a flatbed spawns
CreateThread(function()
    local model = GetHashKey(Config.BedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    -- intentionally not calling SetModelAsNoLongerNeeded — keep it cached
end)

local function lerp(a, b, t)
    return (1 - t) * a + t * b
end

local function createAndAttachBed(flatbedVehicle)
    local model = GetHashKey(Config.BedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local coords = GetEntityCoords(flatbedVehicle)
    local bedEntity = CreateObjectNoOffset(model, coords.x, coords.y, coords.z - 3.0, true, false, false)
    while not DoesEntityExist(bedEntity) do Wait(10) end
    SetEntityAsMissionEntity(bedEntity, true, true)

    local sc = Config.FlatBedModels[GetEntityModel(flatbedVehicle)]
    AttachEntityToEntity(bedEntity, flatbedVehicle, GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
        sc[0].pos[1], sc[0].pos[2], sc[0].pos[3],
        sc[0].rot[1], sc[0].rot[2], sc[0].rot[3],
        false, false, true, false, 0, true)

    if not IsEntityAttachedToEntity(bedEntity, flatbedVehicle) then
        DeleteEntity(bedEntity)
        return nil
    end

    SetModelAsNoLongerNeeded(model)
    return NetworkGetNetworkIdFromEntity(bedEntity)
end

local function reattachBed(flatbedVehicle, bedNetId)
    local deadline = GetGameTimer() + 5000
    local bedEntity = NetworkGetEntityFromNetworkId(bedNetId)
    while not DoesEntityExist(bedEntity) and GetGameTimer() < deadline do
        Wait(50)
        bedEntity = NetworkGetEntityFromNetworkId(bedNetId)
    end
    if not DoesEntityExist(bedEntity) then return end
    if IsEntityAttachedToEntity(bedEntity, flatbedVehicle) then return end

    SetEntityAsMissionEntity(bedEntity, true, true)
    local sc = Config.FlatBedModels[GetEntityModel(flatbedVehicle)]
    local state = Entity(flatbedVehicle).state.bedLowered and 2 or 0
    AttachEntityToEntity(bedEntity, flatbedVehicle, GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
        sc[state].pos[1], sc[state].pos[2], sc[state].pos[3],
        sc[state].rot[1], sc[state].rot[2], sc[state].rot[3],
        false, false, true, false, 0, true)
end

-- Reattach when we become owner of a flatbed that already has a bed prop
AddStateBagChangeHandler('bedProp', '', function(bagName, _, value)
    if not value then return end
    local vehicle = GetEntityFromStateBagName(bagName)
    if not DoesEntityExist(vehicle) then return end
    if GetEntityModel(vehicle) ~= GetHashKey('flatbed') then return end
    if NetworkGetEntityOwner(vehicle) ~= PlayerId() then return end
    if managedFlatbeds[vehicle] then return end
    managedFlatbeds[vehicle] = true
    CreateThread(function() reattachBed(vehicle, value) end)
end)

-- Detect when local player drives a flatbed for the first time.
-- Polls fast (100ms) until a bed is set up, then relaxes to 2000ms.
CreateThread(function()
    while true do
        local interval = next(managedFlatbeds) and 2000 or 100
        Wait(interval)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0
            and GetEntityModel(vehicle) == GetHashKey('flatbed')
            and GetPedInVehicleSeat(vehicle, -1) == ped
            and not managedFlatbeds[vehicle]
        then
            managedFlatbeds[vehicle] = true
            local bedProp = Entity(vehicle).state.bedProp
            if bedProp then
                CreateThread(function() reattachBed(vehicle, bedProp) end)
            else
                CreateThread(function()
                    local bedNetId = createAndAttachBed(vehicle)
                    if not bedNetId then
                        managedFlatbeds[vehicle] = nil
                        return
                    end
                    Entity(vehicle).state:set('bedProp', bedNetId, true)
                    Entity(vehicle).state:set('bedLowered', false, true)
                    Entity(vehicle).state:set('bedMoving', false, true)
                    Entity(vehicle).state:set('attachedVehicle', -1, true)
                    TriggerServerEvent('nt_tow:bedCreated', NetworkGetNetworkIdFromEntity(vehicle), bedNetId)
                end)
            end
        end

        for v in pairs(managedFlatbeds) do
            if not DoesEntityExist(v) then managedFlatbeds[v] = nil end
        end
    end
end)

-- Tow controls — triggered from ox_target or command
RegisterNetEvent('nt_tow:lowerBed', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then LowerFlatbed(vehicle) end
end)

RegisterNetEvent('nt_tow:raiseBed', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then RaiseFlatbed(vehicle) end
end)

RegisterNetEvent('nt_tow:attachCar', function(targetNetId)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    local toAttach = NetworkGetEntityFromNetworkId(targetNetId)
    AttachVehicle(vehicle, toAttach)
    Entity(vehicle).state:set('attachedVehicle', targetNetId, true)
end)

RegisterNetEvent('nt_tow:detachCar', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    local attachedNetId = Entity(vehicle).state.attachedVehicle
    if not attachedNetId or attachedNetId == -1 then return end
    DetachVehicle(NetworkGetEntityFromNetworkId(attachedNetId))
    Entity(vehicle).state:set('attachedVehicle', -1, true)
end)

function LowerFlatbed(flatbedVehicle)
    if not DoesFlatbedHaveBedAndNotMoving(flatbedVehicle) then return end
    local sc = Config.FlatBedModels[GetEntityModel(flatbedVehicle)]
    Entity(flatbedVehicle).state:set('bedMoving', true, true)
    local bedEntity = NetworkGetEntityFromNetworkId(Entity(flatbedVehicle).state.bedProp)
    PlaySoundEffect(flatbedVehicle)
    local lerpVal = 0.0
    local state = 0
    CreateThread(function()
        while true do
            if state == 2 then
                Entity(flatbedVehicle).state:set('bedLowered', true, true)
                Entity(flatbedVehicle).state:set('bedMoving', false, true)
                ReleaseSoundEffect()
                return
            end
            local offsetPos, offsetRot = {}, {}
            for i = 1, 3 do
                offsetPos[i] = lerp(sc[state].pos[i], sc[state + 1].pos[i], lerpVal)
                offsetRot[i] = lerp(sc[state].rot[i], sc[state + 1].rot[i], lerpVal)
            end
            AttachEntityToEntity(bedEntity, flatbedVehicle, GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
                offsetPos[1], offsetPos[2], offsetPos[3], offsetRot[1], offsetRot[2], offsetRot[3],
                false, false, true, false, 0, true)
            lerpVal = lerpVal + GetFrameTime() / stateTimerConstants[state + 1]
            if lerpVal >= 1.0 then lerpVal = 0.0; state = state + 1 end
            Wait(0)
        end
    end)
end

function RaiseFlatbed(flatbedVehicle)
    if not DoesFlatbedHaveBedAndNotMoving(flatbedVehicle) then return end
    local sc = Config.FlatBedModels[GetEntityModel(flatbedVehicle)]
    Entity(flatbedVehicle).state:set('bedMoving', true, true)
    local bedEntity = NetworkGetEntityFromNetworkId(Entity(flatbedVehicle).state.bedProp)
    PlaySoundEffect(flatbedVehicle)
    local lerpVal = 0.0
    local state = 2
    CreateThread(function()
        while true do
            if state == 0 then
                Entity(flatbedVehicle).state:set('bedLowered', false, true)
                Entity(flatbedVehicle).state:set('bedMoving', false, true)
                ReleaseSoundEffect()
                return
            end
            local offsetPos, offsetRot = {}, {}
            for i = 1, 3 do
                offsetPos[i] = lerp(sc[state].pos[i], sc[state - 1].pos[i], lerpVal)
                offsetRot[i] = lerp(sc[state].rot[i], sc[state - 1].rot[i], lerpVal)
            end
            AttachEntityToEntity(bedEntity, flatbedVehicle, GetEntityBoneIndexByName(flatbedVehicle, 'chassis'),
                offsetPos[1], offsetPos[2], offsetPos[3], offsetRot[1], offsetRot[2], offsetRot[3],
                false, false, true, false, 0, true)
            lerpVal = lerpVal + GetFrameTime() / stateTimerConstants[state]
            if lerpVal >= 1.0 then lerpVal = 0.0; state = state - 1 end
            Wait(0)
        end
    end)
end

function AttachVehicle(flatbedVehicle, vehicleToAttach)
    if not DoesEntityExist(vehicleToAttach) then return end
    if not DoesFlatbedHaveBedAndNotMoving(flatbedVehicle) then return end
    local bedToAttachTo = NetworkGetEntityFromNetworkId(Entity(flatbedVehicle).state.bedProp)
    AttachEntityToEntity(vehicleToAttach, bedToAttachTo, 0,
        0.0, 1.8, 0.5,
        0.0, 0.0, 0.0,
        false, false, false, false, 2, true)
end

function DetachVehicle(vehicleToDetach)
    if not DoesEntityExist(vehicleToDetach) then return end
    DetachEntity(vehicleToDetach, false, true)
    SetVehicleOnGroundProperly(vehicleToDetach)
end

RegisterCommand('objbones', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closest, closestDist = nil, math.huge
    for _, obj in ipairs(GetGamePool('CObject')) do
        local dist = #(GetEntityCoords(obj) - playerCoords)
        if dist < closestDist then
            closest = obj
            closestDist = dist
        end
    end
    if not closest then print('No nearby object found') return end
    print(('Closest object: model=%s dist=%.2f'):format(GetEntityModel(closest), closestDist))
    local names = {'misc_a','misc_b','misc_c','chassis','root','attach','hook','winch','chain_attach','bone_0','bone_1','bone_2'}
    for _, name in ipairs(names) do
        local idx = GetEntityBoneIndexByName(closest, name)
        if idx ~= -1 then
            print(name .. ': ' .. idx)
        end
    end
end, false)

function DoesFlatbedHaveBedAndNotMoving(vehicle)
    return Entity(vehicle).state.bedProp ~= nil and not Entity(vehicle).state.bedMoving
end

function PlaySoundEffect(entity)
    if soundId then StopSound(soundId); ReleaseSoundId(soundId) end
    soundId = GetSoundId()
    PlaySoundFromEntity(soundId, 'OPENING', entity, 'DOOR_GARAGE', false, false)
end

function ReleaseSoundEffect()
    if not soundId then return end
    StopSound(soundId)
    ReleaseSoundId(soundId)
    soundId = nil
end
