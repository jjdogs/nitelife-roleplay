function ShowTextOption(text)
    SendNUIMessage({
        type = 'adminui:hint',
        text = tostring(text or '')
    })
end

function HideTextOption()
    SendNUIMessage({
        type = 'adminui:hint_hide'
    })
end


function PugSoundPlay(Name, Volume, Looped)
    local actionName = "PlaySound"
    if Looped then actionName = "playlooped" end
    SendNUIMessage({
        type = actionName,
        audio = tostring(Name)..".mp3",
        volume = tonumber(Volume),
        loop = Looped,
    })
end