function IsPlayerUnreachable()
    local playerPed = PlayerPedId()
    return IsPedRagdoll(playerPed) or IsEntityDead(playerPed)
end

function DisableInputs()
    -- https://docs.fivem.net/docs/game-references/controls/#controls
    local inputs = { 13, 14, 15, 16, 99, 17, 241, 242 }

    for k, input in pairs(inputs) do
        DisableControlAction(0, input, true)
    end
end

function DisableWeatherSync()
    if not Config.disableWeatherSyncWhenIndoors then
        return
    end

    TriggerEvent("vSync:toggle", true)
    TriggerEvent("cs:weather:client:DisableSync")
    TriggerEvent("weathersync:toggleSync")
    TriggerEvent("qb-weathersync:client:DisableSync")
    TriggerEvent('esx-weathersync:client:DisableSync')
    TriggerServerEvent("cs:weather:client:DisableSync")
    TriggerEvent('cd_easytime:PauseSync', true)
end

function EnableWeatherSync()
    if not Config.disableWeatherSyncWhenIndoors then
        return
    end

    TriggerEvent("vSync:toggle", false)
    TriggerEvent('cs:weather:client:EnableSync')
    TriggerEvent("av_weather:freeze", false)
    TriggerEvent('esx-weathersync:client:EnableSync')
    TriggerEvent("qb-weathersync:client:EnableSync")
    TriggerEvent("weathersync:toggleSync")
    TriggerEvent('cd_easytime:PauseSync', false)
end

function DrawMissionText(text, time)
    SetTextEntry_2("STRING")
    AddTextComponentString(text)
    DrawSubtitleTimed(time or 1000, 1)
end

function DrawKeybinds(str)
    SetTextComponentFormat("STRING")
    AddTextComponentString(str)
    EndTextCommandDisplayHelp(0, 0, 0, 7000)
end

if Config.debug then
    RegisterCommand("objectstats", function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local handle, object = FindFirstObject()
        local success
        local radius = 500.0

        local total = 0
        local withinRadius = 0

        local networked = 0
        local unnetworked = 0

        local missionEntities = 0
        local nonMissionEntities = 0

        repeat
            if DoesEntityExist(object) then
                total = total + 1

                local isMission = IsEntityAMissionEntity(object)
                if isMission then
                    missionEntities = missionEntities + 1
                else
                    nonMissionEntities = nonMissionEntities + 1
                end

                local objCoords = GetEntityCoords(object)
                local dist = #(playerCoords - objCoords)
                if dist <= radius then
                    withinRadius = withinRadius + 1

                    if NetworkGetEntityIsNetworked(object) then
                        networked = networked + 1
                    else
                        unnetworked = unnetworked + 1
                    end
                end
            end
            success, object = FindNextObject(handle)
        until not success

        EndFindObject(handle)

        print('^3[KQ_SHELLBUILDER OBJECT DEBUG]^0')
        print("^7 Total: " .. total)
        print("^7 |- Mission Entities: " .. missionEntities)
        print("^7 |- Non-Mission Entities: " .. nonMissionEntities)
        print("^7 Within " .. radius .. "m: " .. withinRadius)
        print("^7 |- Networked: " .. networked)
        print("^7 |- Unnetworked: " .. unnetworked)
    end)
end

