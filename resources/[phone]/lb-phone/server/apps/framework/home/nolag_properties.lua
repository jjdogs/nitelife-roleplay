if Config.HouseScript ~= 'nolag_properties' then
    return
end

local function getNameFromIdentifier(identifier)
    if Config.Framework == 'esx' then
        local result = MySQL.query.await([[
            SELECT CONCAT(COALESCE(firstname, ''), ' ', COALESCE(lastname, '')) AS name
            FROM `users`
            WHERE identifier = ?
        ]], { identifier })

        if result[1]?.name then
            return result[1].name or 'Unknown'
        end
    elseif Config.Framework == 'qb' or Config.Framework == 'qbox' then
        local result = MySQL.query.await([[
            SELECT
                JSON_VALUE(charinfo, '$.firstname') AS firstname,
                JSON_VALUE(charinfo, '$.lastname') AS lastname
            FROM `players`
            WHERE citizenid = ?
        ]], { identifier })

        if result[1]?.firstname and result[1]?.lastname then
            return (result[1].firstname .. ' ' .. result[1].lastname) or 'Unknown'
        end
    elseif Config.Framework == 'ox' then
        local result = MySQL.single.await('SELECT fullName FROM characters WHERE stateId = ?', { identifier })
        return result?.fullName or 'Unknown'
    end

    return identifier
end

local function formatKeyholders(keyholders)
    local formatted = {}
    for identifier, _ in pairs(keyholders) do
        formatted[#formatted + 1] = {
            identifier = identifier,
            name = getNameFromIdentifier(identifier)
        }
    end
    return formatted
end

RegisterCallback('phone:home:getOwnedHouses', function(source)
    local houses = {}
    local identifier = GetIdentifier(source)
    local properties = exports.nolag_properties:GetAllProperties(identifier, 'user', true)

    for _, v in pairs(properties) do
        local keyholders = exports.nolag_properties:GetKeyHolders(v.id)
        houses[#houses + 1] = {
            label = v.label,
            id = v.id,
            locked = v.doorLocked,
            keyholders = formatKeyholders(keyholders)
        }
    end

    return houses
end)

RegisterCallback('phone:home:getKeyholders', function(source, house)
    local keyholders = exports.nolag_properties:GetKeyHolders(house)
    return formatKeyholders(keyholders)
end)

RegisterCallback('phone:home:toggleLocked', function(source, house, locked)
    local success = exports.nolag_properties:ToggleDoorlock(source, house, not locked)
    return success and not locked
end)
