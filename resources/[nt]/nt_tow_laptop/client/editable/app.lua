CreateThread(function()
    while GetResourceState('av_apps') ~= "started" do
        Wait(100)
    end
    registerApp()
end)

function registerApp()
    if Config.App then
        exports['av_apps']:registerApp(Config.App)
    end
end

exports("getState", function(serial)
    return Config.App.isEnabled(serial)
end)