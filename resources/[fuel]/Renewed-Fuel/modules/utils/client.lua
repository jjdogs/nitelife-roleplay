local Utils = {}

function Utils.progressbar(data)
    return lib.progressCircle(data)
end

function Utils.registerNetEvent(event, fn)
    RegisterNetEvent(event, function(...)
        if source ~= '' then fn(...) end
    end)
end

function Utils.caluclatePercent(currentFuel, maxFuel)
    return math.floor((currentFuel / maxFuel) * 100)
end

function Utils.roundUp(number)
    local decimalPart = number % 1

    return decimalPart < 0.5 and math.floor(number) or math.ceil(number)
end


local useInteract = GetConvar('renewed_useinteract', 'false') == 'true'
function Utils.getInteract(data)
    local changed = false
    if useInteract then
        local target = data.target
        for i = 1, #target do
            local option = target[i]
            if option.onSelect then
                option.action = option.onSelect

                option.onSelect = nil
                option.icon = nil
            end
        end

        data.target = nil
        data.interact = {
            id = data.id,
            distance = 10,
            interactDst = 3,
            options = target,
        }
        changed = true
    end

    return changed, data
end


function Utils.formatDollars(number)
    number = number or 0
    local formattedNumber = string.format("%.2f", number)

    local integerPart, fractionalPart = formattedNumber:match("([^%.]+)%.([^.]+)")

    integerPart = integerPart:reverse():gsub("(%d%d%d)", "%1,"):reverse()

    formattedNumber = '$'..integerPart .. (fractionalPart == "00" and "" or "." .. fractionalPart)

    return formattedNumber
end

function Utils.notify(msg, type)
    lib.notify({ description = msg, type = type })
end

function Utils.createBlip(settings)
    if not settings then return end

    local blip = AddBlipForCoord(settings.coords.x, settings.coords.y, settings.coords.z)
    SetBlipSprite(blip, settings.id)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, settings.scale)
    SetBlipColour(blip, settings.colour)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(settings.name)
    EndTextCommandSetBlipName(blip)

    return blip
end


local GetGameplayCamFov = GetGameplayCamFov
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextProportional = SetTextProportional
local SetTextColour = SetTextColour
local SetTextOutline = SetTextOutline
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local SetTextCentre = SetTextCentre
local AddTextComponentSubstringKeyboardDisplay = AddTextComponentSubstringKeyboardDisplay
local EndTextCommandDisplayText = EndTextCommandDisplayText

function Utils.Text3D(coords, text)
    coords = vec3(coords.x, coords.y, coords.z)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

    if onScreen then
        local fov = (1 / GetGameplayCamFov()) * 75
        local scale = (1 / #(coords - GetFinalRenderedCamCoord())) * 4 * fov * 0.5
        local r, g, b = 2, 241, 181

        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(r, g, b, 255)
        SetTextOutline()
        BeginTextCommandDisplayText("STRING")
        SetTextCentre(true)
        AddTextComponentSubstringKeyboardDisplay(text)
        EndTextCommandDisplayText(screenX, screenY)
    end
end

return Utils