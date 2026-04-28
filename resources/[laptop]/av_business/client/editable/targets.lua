if not Config.ZonesTarget then return end
local exists = {}

function addZone(data, isUpdate)
    dbug("addZone(target?)", Config.Target)
    while not Config.Target do
        Config.Target = exports['av_laptop']:getTarget()
        warn("We couldn't detect your Config.Target, if not using one, please set Config.ZonesTarget = false")
        Wait(50)
    end
    if not data then
        dbug("addZone() received null as argument")
        return
    end
    local name = data and data['name']
    dbug('zoneName?', name)
    if isUpdate then
        exists[name] = nil
        removeZone(name)
    end
    if exists[name] then return end
    exists[name] = true
    if data['type'] == "cashier" then
        dbug("Registering cashier zone(job)", data['job'])
        if Config.Target == "ox_target" then
            local radius = getZoneRadius(data)
            exports.ox_target:addSphereZone({
                name = data['name'],
                coords = vector3(data['coords']['x'], data['coords']['y'], data['coords']['z']),
                radius = radius or 1.0,
                debug = Config.ZonesDebug,
                drawSprite = true,
                options = {
                    {
                        type = "client",
                        event = "av_business:cashierEmployee",
                        icon = Config.Events['cashier']['icon']['employee'],
                        label = Config.Events['cashier']['label']['employee'],
                        groups = data['job'],
                        zoneName = data['name'],
                        zoneJob = data['job'],
                        distance = tonumber(data['distance'])
                    },
                    {
                        type = "client",
                        event = "av_business:cashierCustomer",
                        icon = Config.Events['cashier']['icon']['customer'],
                        label = Config.Events['cashier']['label']['customer'],
                        zoneName = data['name'],
                        zoneJob = data['job'],
                        distance = tonumber(data['distance'])
                    },
                }
            })
        else
            local boxData = getZoneBox(data)
            exports[Config.Target]:AddBoxZone(data['name'], vector3(data['coords']['x'], data['coords']['y'], data['coords']['z']), boxData['width'], boxData['height'], {
                name = data['name'],
                heading = boxData['heading'],
                debugPoly = Config.ZonesDebug,
                minZ = boxData['minZ'],
                maxZ = boxData['maxZ'],
            }, {
                options = {
                    {
                        type = "client",
                        event = "av_business:cashierEmployee",
                        icon = Config.Events['cashier']['icon']['employee'],
                        label = Config.Events['cashier']['label']['employee'],
                        job = data['job'],
                        zoneName = data['name'],
                        zoneJob = data['job']
                    },
                    {
                        type = "client",
                        event = "av_business:cashierCustomer",
                        icon = Config.Events['cashier']['icon']['customer'],
                        label = Config.Events['cashier']['label']['customer'],
                        zoneName = data['name'],
                        zoneJob = data['job']
                    },
                },
                distance = tonumber(data['distance'])
            })
        end
    else
        if Config.Events[data['type']] then
            dbug("Registering zone type:", data['type'])
            local job = false
            local jobConfig = Config.Events[data['type']]
            if jobConfig and jobConfig['job'] then
                job = data['job']
            end
            if Config.Target == "ox_target" then
                local radius = getZoneRadius(data)
                exports.ox_target:addSphereZone({
                    name = data['name'],
                    coords = vector3(data['coords']['x'], data['coords']['y'], data['coords']['z']),
                    radius = radius or 1.0,
                    debug = Config.ZonesDebug,
                    drawSprite = true,
                    options = {
                        {
                            name = data['name'],
                            type = "client",
                            event = Config.Events[data['type']]['event'],
                            icon = Config.Events[data['type']]['icon'],
                            label = Config.Events[data['type']]['label'],
                            groups = job,
                            zoneJob = data['job'],
                            zoneType = data['type'],
                            distance = tonumber(data['distance']),
                            animType = data['animType']
                        },
                    }
                })
            else
                local boxData = getZoneBox(data)
                exports[Config.Target]:AddBoxZone(data['name'], vector3(data['coords']['x'], data['coords']['y'], data['coords']['z']), boxData['width'], boxData['height'], {
                    name = data['name'],
                    heading = boxData['heading'],
                    debugPoly = Config.ZonesDebug,
                    minZ = boxData['minZ'],
                    maxZ = boxData['maxZ'],
                }, {
                    options = {
                        {
                            name = data['name'],
                            type = "client",
                            event = Config.Events[data['type']]['event'],
                            icon = Config.Events[data['type']]['icon'],
                            label = Config.Events[data['type']]['label'],
                            job = job,
                            zoneJob = data['job'],
                            zoneType = data['type'],
                            animType = data['animType']
                        },
                    },
                    distance = tonumber(data['distance'])
                })
            end
        else
            warn("Zone type", data['type'], "doesn't exist in Config.Events, check your config/events.lua !")
        end
    end
end

function removeZone(name)
    if Config.Target == "ox_target" then
        exports.ox_target:removeZone(name)
    else
        exports[Config.Target]:RemoveZone(name)
    end
end