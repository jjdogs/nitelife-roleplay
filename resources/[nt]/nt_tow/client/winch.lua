local hasHook = false
local hookedVehicle = nil
local hookProp = nil
local ropeHandle = nil
local isWinding = false
local attachedToBed = nil
local RegisterBedAttachTarget

local function RegisterBedDetachTarget(flatbed, vehicle)
    exports.ox_target:removeLocalEntity(flatbed, 'bed_detach')
    exports.ox_target:addLocalEntity(flatbed, {{
        name = 'bed_detach',
        label = 'Detach from Bed',
        bones = {'misc_a'},
        onSelect = function()
            if attachedToBed and DoesEntityExist(attachedToBed) then
                DetachVehicle(attachedToBed)
                attachedToBed = nil
            end
            exports.ox_target:removeLocalEntity(flatbed, 'bed_detach')
            if vehicle and DoesEntityExist(vehicle) then
                RegisterBedAttachTarget(flatbed, vehicle)
            end
        end,
        distance = 3.0,
    }})
end

RegisterBedAttachTarget = function(flatbed, vehicle)
    exports.ox_target:removeLocalEntity(vehicle, 'bed_attach')
    exports.ox_target:addLocalEntity(vehicle, {{
        name = 'bed_attach',
        label = 'Attach to Bed',
        onSelect = function()
            if ropeHandle ~= nil then
                lib.notify({ title = 'Tow Truck', description = 'Unhook the vehicle first', type = 'error' })
                return
            end
            AttachVehicle(flatbed, vehicle)
            attachedToBed = vehicle
            exports.ox_target:removeLocalEntity(vehicle, 'bed_attach')
            RegisterBedDetachTarget(flatbed, vehicle)
        end,
        distance = 3.0,
    }})
end

local function ShowFlatbedMenu(flatbed)
    lib.registerContext({
        id = 'flatbed_control',
        title = 'Tow Truck Flatbed Controller',
        position = 'top-right',
        options = {
            {
                title = Entity(flatbed).state.bedLowered and 'Raise Bed' or 'Lower Bed',
                description = 'Raise or lower the flatbed',
                icon = 'circle',
                onSelect = function()
                    if Entity(flatbed).state.bedLowered then
                        if hookProp ~= nil then
                            lib.notify({ title = 'Tow Truck', description = 'Return the hook to the truck before raising the bed', type = 'error' })
                            return
                        end
                        RaiseFlatbed(flatbed)
                    else
                        LowerFlatbed(flatbed)
                        exports.ox_target:removeLocalEntity(flatbed, 'grab_hook')
                        exports.ox_target:addLocalEntity(flatbed, {{
                            name = 'grab_hook',
                            label = 'Grab Hook',
                            bones = {'misc_a'},
                            onSelect = function() CreateThread(function() GrabHook(flatbed) end) end,
                            distance = 3.0,
                        }})
                    end
                end,
            },
            {
                title = isWinding and 'Stop Winch' or 'Start Winch',
                description = 'Pull vehicle onto bed',
                icon = 'circle',
                disabled = hookedVehicle == nil,
                onSelect = function()
                    if isWinding then
                        isWinding = false
                        FreezeEntityPosition(flatbed, false)
                    else
                        isWinding = true
                        FreezeEntityPosition(flatbed, true)
                        local bedEntity = NetworkGetEntityFromNetworkId(Entity(flatbed).state.bedProp)
                        CreateThread(function()
                            while isWinding and hookedVehicle and DoesEntityExist(hookedVehicle) do
                                local vehCoords = GetEntityCoords(hookedVehicle)
                                local targetCoords = GetOffsetFromEntityInWorldCoords(bedEntity, 0.0, 1.8, 0.5)
                                local dist = #(targetCoords - vehCoords)
                                if dist < 1.5 then
                                    isWinding = false
                                    break
                                end
                                local dir = (targetCoords - vehCoords) / dist
                                NetworkRequestControlOfEntity(hookedVehicle)
                                SetEntityVelocity(hookedVehicle, dir.x * 1.0, dir.y * 1.0, dir.z * 1.0)
                                Wait(0)
                            end
                            if hookedVehicle and DoesEntityExist(hookedVehicle) then
                                NetworkRequestControlOfEntity(hookedVehicle)
                                SetEntityVelocity(hookedVehicle, 0.0, 0.0, 0.0)
                                local targetCoords = GetOffsetFromEntityInWorldCoords(bedEntity, 0.0, 1.8, 0.5)
                                if #(targetCoords - GetEntityCoords(hookedVehicle)) < 2.0 then
                                    RegisterBedAttachTarget(flatbed, hookedVehicle)
                                    hookedVehicle = nil
                                end
                            end
                            FreezeEntityPosition(flatbed, false)
                        end)
                    end
                    ShowFlatbedMenu(flatbed)
                end,
            },
        }
    })
    lib.showContext('flatbed_control')
end

local function StartHookScan(flatbed)
    local hookedTargets = {}
    CreateThread(function()
        while hasHook do
            local nearby = lib.getNearbyVehicles(GetEntityCoords(PlayerPedId()), 15.0, false)
            for _, data in ipairs(nearby) do
                if data.vehicle ~= flatbed and not hookedTargets[data.vehicle] then
                    hookedTargets[data.vehicle] = true
                    exports.ox_target:addLocalEntity(data.vehicle, {{
                        name = 'attach_hook',
                        label = 'Attach Hook',
                        onSelect = function(targetData) AttachHook(flatbed, data.vehicle, targetData.coords) end,
                        distance = 3.0,
                    }})
                end
            end
            Wait(500)
        end
        for v in pairs(hookedTargets) do
            exports.ox_target:removeLocalEntity(v, 'attach_hook')
        end
        hookedTargets = {}
    end)
end

RegisterNetEvent('nt_tow:openControl')
AddEventHandler('nt_tow:openControl', function()
    local ped = PlayerPedId()
    local flatbed = GetVehiclePedIsIn(ped, false)
    if flatbed == 0 or GetEntityModel(flatbed) ~= GetHashKey('flatbed') then
        flatbed = lib.getClosestVehicle(GetEntityCoords(ped), 30.0)
        if not flatbed or GetEntityModel(flatbed) ~= GetHashKey('flatbed') then return end
    end
    ShowFlatbedMenu(flatbed)
end)

function GrabHook(flatbed)
    hasHook = true

    -- Spawn hook prop and attach to player's right hand
    local model = GetHashKey('prop_rope_hook_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local playerCoords = GetEntityCoords(PlayerPedId())
    hookProp = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    local handBone = GetPedBoneIndex(PlayerPedId(), 40269)
    AttachEntityToEntity(hookProp, PlayerPedId(), handBone,
        0.05, 0.02, -0.02, 84.0, -191.0, 29.0,
        false, false, false, false, 0, true)

    -- Rope from flatbed rear to player's hand bone
    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do Wait(10) end
    local bedCoords = GetOffsetFromEntityInWorldCoords(flatbed, 0.0, -3.0, 0.5)
    local handCoords = GetWorldPositionOfEntityBone(PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 40269))
    ropeHandle = AddRope(bedCoords.x, bedCoords.y, bedCoords.z,
        0.0, 0.0, 0.0, 0.5, 4, 0.5, 0.1, 1.0, false, false, true, 5.0, false)
    AttachEntitiesToRope(ropeHandle, PlayerPedId(), flatbed,
        handCoords.x, handCoords.y, handCoords.z,
        bedCoords.x, bedCoords.y, bedCoords.z,
        Config.MaxRopeLength, false, false, '', '')

    exports.ox_target:removeLocalEntity(flatbed, 'grab_hook')

    StartHookScan(flatbed)
end

function AttachHook(flatbed, vehicle, attachCoords)
    hookedVehicle = vehicle
    hasHook = false

    -- Remove hand prop
    if hookProp and DoesEntityExist(hookProp) then
        DetachEntity(hookProp, false, false)
        DeleteEntity(hookProp)
        hookProp = nil
    end

    -- Replace rope: flatbed rear -> targeted point on vehicle
    if ropeHandle then
        DeleteRope(ropeHandle)
        ropeHandle = nil
    end
    local flatbedCoords = GetOffsetFromEntityInWorldCoords(flatbed, 0.0, -3.0, 0.5)
    local vehicleAttachCoords = attachCoords or GetEntityCoords(vehicle)
    local dist = #(flatbedCoords - vehicleAttachCoords)
    ropeHandle = AddRope(flatbedCoords.x, flatbedCoords.y, flatbedCoords.z,
        0.0, 0.0, 0.0, 0.5, 4, 0.5, 0.1, 1.0, false, false, true, 5.0, false)
    AttachEntitiesToRope(ropeHandle, flatbed, vehicle,
        flatbedCoords.x, flatbedCoords.y, flatbedCoords.z,
        vehicleAttachCoords.x, vehicleAttachCoords.y, vehicleAttachCoords.z,
        dist + 0.5, false, false, '', '')


    exports.ox_target:addLocalEntity(vehicle, {{
        name = 'detach_hook',
        label = 'Detach Hook',
        onSelect = function() CreateThread(function()
            -- Delete vehicle rope
            if ropeHandle then
                DeleteRope(ropeHandle)
                ropeHandle = nil
            end
            exports.ox_target:removeLocalEntity(vehicle, 'detach_hook')

            -- Re-spawn hook prop in hand
            local model = GetHashKey('prop_rope_hook_01')
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(10) end
            local playerCoords = GetEntityCoords(PlayerPedId())
            hookProp = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
            SetModelAsNoLongerNeeded(model)
            AttachEntityToEntity(hookProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 40269),
                0.05, 0.02, -0.02, 84.0, -191.0, 29.0,
                false, false, false, false, 0, true)

            -- Re-create rope flatbed -> hand
            local bedCoords = GetOffsetFromEntityInWorldCoords(flatbed, 0.0, -3.0, 0.5)
            local handCoords = GetWorldPositionOfEntityBone(PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 40269))
            ropeHandle = AddRope(bedCoords.x, bedCoords.y, bedCoords.z,
                0.0, 0.0, 0.0, 0.5, 4, 0.5, 0.1, 1.0, false, false, true, 5.0, false)
            AttachEntitiesToRope(ropeHandle, PlayerPedId(), flatbed,
                handCoords.x, handCoords.y, handCoords.z,
                bedCoords.x, bedCoords.y, bedCoords.z,
                Config.MaxRopeLength, false, false, '', '')

            lib.notify({ title = 'Tow Truck', description = 'Return the hook to the truck before raising the bed', type = 'inform' })

            StartHookScan(flatbed)

            -- Add return hook target on flatbed
            exports.ox_target:addLocalEntity(flatbed, {{
                name = 'return_hook',
                label = 'Return Hook',
                bones = {'misc_a'},
                onSelect = function()
                    if ropeHandle then
                        DeleteRope(ropeHandle)
                        RopeUnloadTextures()
                        ropeHandle = nil
                    end
                    if hookProp and DoesEntityExist(hookProp) then
                        DetachEntity(hookProp, false, false)
                        DeleteEntity(hookProp)
                        hookProp = nil
                    end
                    hasHook = false
                    hookedVehicle = nil
                    exports.ox_target:removeLocalEntity(flatbed, 'return_hook')
                    exports.ox_target:addLocalEntity(flatbed, {{
                        name = 'grab_hook',
                        label = 'Grab Hook',
                        bones = {'misc_a'},
                        onSelect = function() CreateThread(function() GrabHook(flatbed) end) end,
                        distance = 3.0,
                    }})
                end,
                distance = 3.0,
            }})
        end) end,
        distance = 3.0,
    }})

    -- Remove vehicle targets
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearby = lib.getNearbyVehicles(playerCoords, 10.0, false)
    for _, data in ipairs(nearby) do
        if data.vehicle ~= flatbed then
            exports.ox_target:removeLocalEntity(data.vehicle, 'attach_hook')
        end
    end
end

function CleanupTow(flatbed)
    -- Delete rope
    if ropeHandle then
        DeleteRope(ropeHandle)
        RopeUnloadTextures()
        ropeHandle = nil
    end

    -- Delete hook prop
    if hookProp and DoesEntityExist(hookProp) then
        DetachEntity(hookProp, false, false)
        DeleteEntity(hookProp)
        hookProp = nil
    end

    -- Detach any vehicle on the bed
    if flatbed and DoesEntityExist(flatbed) then
        local attachedNetId = Entity(flatbed).state.attachedVehicle
        if attachedNetId and attachedNetId ~= -1 then
            local attached = NetworkGetEntityFromNetworkId(attachedNetId)
            if DoesEntityExist(attached) then
                DetachVehicle(attached)
                exports.ox_target:removeLocalEntity(attached, 'detach_hook')
                exports.ox_target:removeLocalEntity(attached, 'bed_attach')
                exports.ox_target:removeLocalEntity(flatbed, 'bed_detach')
            end
            Entity(flatbed).state:set('attachedVehicle', -1, true)
        end
        -- Delete the flatbed
        FreezeEntityPosition(flatbed, false)
        SetEntityAsMissionEntity(flatbed, false, true)
        DeleteEntity(flatbed)
    end

    -- Reset state
    hasHook = false
    hookedVehicle = nil
    attachedToBed = nil
    isWinding = false

end

if Config.Debug then
    RegisterCommand('bones', function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then return end
        local names = {'misc_a','misc_b','misc_c','chassis','bodyshell','boot','bumper_r','hook','winch','chain_attach'}
        for _, name in ipairs(names) do
            local idx = GetEntityBoneIndexByName(vehicle, name)
            print(name .. ': ' .. idx)
        end
    end, false)

    RegisterCommand('cleanup', function ()
        CleanupTow()
    end, false) 
end