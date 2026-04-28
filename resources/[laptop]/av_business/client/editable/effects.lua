function useEffects(ingredients, type, itemName, effects) -- No need to modify this
    dbug("useEffects(itemName, type, ingredientes, effects)", itemName, type, json.encode(ingredients), json.encode(effects))
    local triggered = false
    if itemName and Config.DefaultEffects[itemName] then
        dbug('itemName exists in Config.DefaultEffects', itemName)
        Config.DefaultEffects[itemName]()
        triggered = true
    end
    if not triggered and ingredients then
        for _, v in pairs(ingredients) do
            if Config.Effects and Config.Effects[v] then
                triggered = true
                dbug("TriggerEffect(ingredient)", v)
                CreateThread(function()
                    Config.Effects[v]['effect']()
                end)
            end
        end
    end
    if not triggered and effects and next(effects) then
        for _, name in pairs(effects) do
            if Config.Effects and Config.Effects[name] then
                triggered = true
                dbug("TriggerEffect(effect)", name)
                CreateThread(function()
                    Config.Effects[name]['effect']()
                end)
            end
        end
    end
    if not triggered and Config.DefaultEffects[type] then
        dbug("TriggerDefaultEffect()", type)
        Config.DefaultEffects[type]()
    end
    dbug("useEffects() finished...")
end

function alcohol(seconds)
    CreateThread(function()
        local time = seconds or 30
        DoScreenFadeOut(1000)
        Wait(1000)
        SetTimecycleModifier("spectator5")
        SetPedMotionBlur(cache.ped, true)
        lib.requestAnimSet("MOVE_M@DRUNK@VERYDRUNK", 10000)
        SetPedMovementClipset(cache.ped, "MOVE_M@DRUNK@VERYDRUNK", 1)
        SetPedIsDrunk(cache.ped, true)
        SetPedAccuracy(cache.ped, 0)
        DoScreenFadeIn(1000)
        Wait(time * 1000)
        DoScreenFadeOut(1000)
        Wait(1000)
        DoScreenFadeIn(1000)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        ResetPedMovementClipset(cache.ped, 0)
        SetPedIsDrunk(cache.ped, false)
        SetPedMotionBlur(cache.ped, false)
    end)
end

function drugs(seconds)
    CreateThread(function()
        local time = seconds or 30
        DoScreenFadeOut(1000)
        Wait(1000)
        SetTimecycleModifier("spectator5")
        SetPedMotionBlur(cache.ped, true)
        lib.requestAnimSet("MOVE_M@DRUNK@VERYDRUNK", 10000)
        SetPedMoveRateOverride(cache.ped, 10.0)
        SetRunSprintMultiplierForPlayer(cache.ped, 1.49)
        SetPedIsDrunk(cache.ped, true)
        SetPedAccuracy(cache.ped, 0)
        DoScreenFadeIn(1000)
        Wait(time * 1000)
        DoScreenFadeOut(1000)
        Wait(1000)
        DoScreenFadeIn(1000)
        SetPedMoveRateOverride(cache.ped, 0.0)
        SetRunSprintMultiplierForPlayer(cache.ped, 1.0)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        ResetPedMovementClipset(cache.ped, 0)
        SetPedIsDrunk(cache.ped, false)
        SetPedMotionBlur(cache.ped, false)
    end)
end