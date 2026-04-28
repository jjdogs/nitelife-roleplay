local weatherScript = ''

CreateThread(function()
    if GetResourceState('av_weather') == 'started' then
        weatherScript = 'av_weather'
        return
    end
end)

function getZoneWeather()
    if weatherScript == "av_weather" then
        local weather = exports['av_weather']:getZone()
--        dbug("getZoneWeather()", weather and json.encode(weather))
        return weather
    end
    return false
end

AddEventHandler('av_weather:timeUpdated', function(hour,minutes)
    if LocalPlayer.state.inLaptop and Config.UseGameClock then
        SendNUIMessage({
            action = "clock",
            data = {
                enabled = true,
                hour = hour,
                minutes = minutes
            }
        })
    end
end)

exports('getWeatherScript', function()
    return weatherScript
end)