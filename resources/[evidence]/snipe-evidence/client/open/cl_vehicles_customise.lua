local inVehicle = false

local throttledPlayers = {}

local prevSpeed, currSpeed, prevBodyHealth, currBodyHealth
local vehicleCrashCooldown = {}
local lastTriggeredHealth = {}
local CRASH_COOLDOWN_MS = 8000

local lastGlobalCrash = 0
local GLOBAL_COOLDOWN = 3000

local function GlobalCrashAllowed()
    local now = GetGameTimer()
    if (now - lastGlobalCrash) < GLOBAL_COOLDOWN then
        return false
    end
    lastGlobalCrash = now
    return true
end

local function SignificantCrash(vehicle, bodyDamage, speedDiff)
    local lastHealth = lastTriggeredHealth[vehicle] or 1000.0
    local currHealth = GetVehicleBodyHealth(vehicle)

    if currHealth >= lastHealth - Config.VehicleEvidence.Crash.damageDiff then
        return false
    end

    lastTriggeredHealth[vehicle] = currHealth
    return speedDiff > Config.VehicleEvidence.Crash.speedDiff
end

local function CanTriggerCrash(vehicle)
    local now = GetGameTimer()
    local last = vehicleCrashCooldown[vehicle]

    if last and (now - last) < CRASH_COOLDOWN_MS then
        return false
    end

    vehicleCrashCooldown[vehicle] = now
    return true
end

local function StartCrashThread(vehicle)
    if inVehicle then return end
    inVehicle = true
    CreateThread(function()
        while inVehicle do
            Wait(200)
            prevSpeed = currSpeed
            currSpeed = GetEntitySpeed(vehicle)
            prevBodyHealth = currBodyHealth
            currBodyHealth = GetVehicleBodyHealth(vehicle)

            if not HasEntityCollidedWithAnything(vehicle) then goto continue end
            if currSpeed < 8.0 then goto continue end


           
            local bodyDamage = (prevBodyHealth or currBodyHealth) - currBodyHealth
            local speedDiff  = (prevSpeed or currSpeed) - currSpeed

            if Config.VehicleEvidence.Crash.debug then
                print("Debug Info: PrevSpeed: "..(prevSpeed or 0).." CurrSpeed: "..(currSpeed or 0).." SpeedDiff: "..speedDiff)
                print("Debug Info: PrevBodyHealth: "..(prevBodyHealth or 0).." CurrBodyHealth: "..(currBodyHealth or 0).." BodyDamage: "..bodyDamage)
            end

            if bodyDamage <= 0 and speedDiff <= 0 then goto continue end
            if not SignificantCrash(vehicle, bodyDamage, speedDiff) then goto continue end
            if not CanTriggerCrash(vehicle) then goto continue end
            if not GlobalCrashAllowed() then goto continue end

            if Config.VehicleEvidence.fragment and math.random(100) <= Config.VehicleEvidence.Chance.fragment then
                local vehicleModel = GetEntityModel(vehicle)
                local r, g, b = GetVehicleColor(vehicle)
                local vehCoords = GetEntityCoords(vehicle)
                local vehHeading = GetEntityHeading(vehicle)
                local plate = GetVehicleNumberPlateText(vehicle)
                CreateVehicleFragment(vehicleModel, vehCoords + vec3((math.random(1,10)/100), math.random(1,10)/100, 0.0), vehCoords + vec3((math.random(1,10)/100), math.random(1,10)/100, 0.0), vehHeading, plate, r, g, b)
            end

            ::continue::
        end
    end)
end

lib.onCache('vehicle', function(value, oldValue)
    Wait(1000)

    local playerPed = PlayerPedId()

    local vehicle = value 
    if not vehicle then inVehicle = false return end
    if IsThisModelABicycle(GetEntityModel(vehicle)) then inVehicle = false return end

    if Config.VehicleEvidence.fingerprint and math.random(1, 100) <= Config.VehicleEvidence.Chance.fingerprint then
        CreateVehicleFingerprint(vehicle)
    end

    local seat = GetPedInVehicleSeat(vehicle, -1)
    if seat == playerPed then
        StartCrashThread(vehicle)
    end
end)

lib.onCache('seat', function()
    Wait(1000)

    local playerPed = PlayerPedId()

    local vehicle = GetVehiclePedIsIn(playerPed, false) 
    if not vehicle then inVehicle = false return end
    if IsThisModelABicycle(GetEntityModel(vehicle)) then inVehicle = false return end
    local seat = GetPedInVehicleSeat(vehicle, -1)
    if seat == playerPed then
        StartCrashThread(vehicle)
    else
        inVehicle = false
    end
end)