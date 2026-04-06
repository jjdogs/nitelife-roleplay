
function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1) -- Wanted Stars
    HideHudComponentThisFrame(2) -- Weapon icon
    HideHudComponentThisFrame(3) -- Cash
    HideHudComponentThisFrame(4) -- MP CASH
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13) -- Cash Change
    HideHudComponentThisFrame(11) -- Floating Help Text
    HideHudComponentThisFrame(12) -- more floating help text
    HideHudComponentThisFrame(15) -- Subtitle Text
    HideHudComponentThisFrame(18) -- Game Stream
    HideHudComponentThisFrame(19) -- weapon wheel
end


function TakePhoto(url, api)
    exports[Config.ScreenshotResource]:requestScreenshotUpload(url,
        'file',
        {
            headers = {
                Authorization = api,
            },
            encoding = 'webp'
        },
        function(data)
        local resp = json.decode(data)
        if resp then
            lib.setClipboard(resp.url)
            TriggerServerEvent("snipe-evidence:server:sendImage", resp.url)
            ShowNotification(Locales["photo_taken"], "success")
        end
    end)
end