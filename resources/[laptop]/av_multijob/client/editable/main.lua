RegisterNetEvent("av_multijob:openMenu", openMenu)

function openMenu()
    SetNuiFocus(true,true)
    SendNUIMessage({
        message = "open",
        state = true
    })
end

exports("openMenu", openMenu)

if Config.Command then
    RegisterCommand(Config.Command, function()
        openMenu()
    end,false)
end

if Config.MenuKey then
    lib.addKeybind({
        name = 'multijob',
        description = Lang['multijob_key'] or "Open multijob menu",
        defaultKey = Config.MenuKey,
        onPressed = function()
            openMenu()
        end,
    })
end