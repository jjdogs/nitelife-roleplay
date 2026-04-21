if Config.HouseScript ~= "nolag_properties" then
    return
end

RegisterNUICallback("Home", function(data, cb)
    local action, houseData = data.action, data.houseData

    if action == "getHomes" then
        local properties = AwaitCallback("phone:home:getOwnedHouses")
        cb(properties)
    elseif action == "removeKeyholder" then
        exports.nolag_properties:RemoveKey(houseData.id, data.identifier)
        local keyHolders = AwaitCallback("phone:home:getKeyholders", houseData.id)
        cb(keyHolders)
    elseif action == "addKeyholder" then
        exports.nolag_properties:AddKey(houseData.id, data.identifier)
        local keyHolders = AwaitCallback("phone:home:getKeyholders", houseData.id)
        cb(keyHolders)
    elseif action == "toggleLocked" then
        local isLocked = AwaitCallback("phone:home:toggleLocked", houseData.id, houseData.locked)
        cb(isLocked)
    elseif action == "setWaypoint" then
        exports.nolag_properties:SetWaypointToProperty(houseData.id)
        cb("ok")
    end
end)
