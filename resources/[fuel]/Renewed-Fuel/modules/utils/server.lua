local Utils = {}

local fuelCanConfig = require 'shared.petrolcan'.customFuelCanWeight

function Utils.isAdmin(source)
    return IsPlayerAceAllowed(source, 'command.gasstation')
end


function Utils.getFuelCanWeight(fuelPercent)
    local newWeight = math.ceil(fuelCanConfig.maxWeight * (fuelPercent / 100))

    return newWeight > fuelCanConfig.minWeight and newWeight or fuelCanConfig.minWeight
end exports('GetFuelCanWeight', Utils.getFuelCanWeight)

function Utils.roundUp(number)
    local decimalPart = number % 1

    return decimalPart < 0.5 and math.floor(number) or math.ceil(number)
end

function Utils.notify(source, notiType, description)
    TriggerClientEvent('ox_lib:notify', source, { type = notiType, description = description })
end

local baseWeight = 1000
local maxWeight = 4000

function Utils.barrelWeight(oilAmount)
    if oilAmount >= 0 and oilAmount <= 5000 then
        return math.ceil(baseWeight + (maxWeight - baseWeight) * (oilAmount / 5000))
    end

    return 0
end


local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed

-- We utilize both vector 3s and 4s in our code, so we use this function to convert them to a vector 3 and return coords
function Utils.getDistance(source, coords)
    return #(GetEntityCoords(GetPlayerPed(source)) - vec3(coords.x, coords.y, coords.z))
end

return Utils