local db = require 'modules.db.station'

local Stations = {}

local canBuy = GetConvar('fuel_buystations', 'false') == 'true'

local notify = require 'modules.utils.server'.notify

function Stations.registerStation(id, data)
    Stations[id] = data
end

local addTank = require 'modules.db.fuelstorage'.addTank
local capacity = require 'shared.fuelstorage'.upgrades[1].maxFuel

function Stations.createStation(name, tablet, fuelPump, pedCoords)
    local id = db.createStation(name, json.encode(tablet), json.encode(fuelPump))

    if id then
        Stations.registerStation(id, {
            id = id,
            name = name,
            money = 0,
            employees = {},

            tablet = tablet,
            fuelpump = fuelPump,
            created = os.date('%Y/%m/%d'),
            price = 0,

            Pumps = {},
            fuelTanks = {
                {
                    fuelType = 86,
                    amount = 0,
                    capacity = capacity,
                    upgrade = 1
                }
            }
        })

        addTank(id)

        if canBuy and pedCoords then
            Stations[id].canBuy = true
            Stations[id].pedcoords = pedCoords
            db.updatePed(id, json.encode(pedCoords))
        end

        TriggerClientEvent('Renewed-Fuel:client:createStation', -1, id, Stations[id])
    end


    return id
end

function Stations.changePedCoords(id, coords, heading)
    local station = Stations[id]

    if station then
        station.pedcoords = { x = coords.x, y = coords.y, z = coords.z - 1, w = heading}
        db.updatePed(id, json.encode(station.pedcoords))

        if station.canBuy then
            TriggerClientEvent('Renewed-Fuel:client:changePedCoords', -1, id, station.pedcoords)
        end
    end
end

function Stations.changeStationPrice(id, price)
    local station = Stations[id]

    if station then
        station.price = price
        db.updatePrice(id, price)

        TriggerClientEvent('Renewed-Fuel:client:changeStationPrice', -1, id, price)
    end
end

function Stations.addTank(id)
    local station = Stations[id]

    if not station then return end

    station.fuelTanks[#station.fuelTanks+1] = {
        fuelType = 86,
        amount = 0,
        capacity = capacity,
        upgrade = 1
    }

    addTank(id)

    return true
end

function Stations.deleteStation(id)
    local Station = Stations[id]

    if Station then
        db.deleteStation(id)

        if Station.Pumps and next(Station.Pumps) then
            TriggerClientEvent('Renewed-Fuel:client:removePumps', -1, id, Station.Pumps)
        end

        Stations[id] = nil

        TriggerClientEvent('Renewed-Fuel:client:deleteStation', -1, id)
    end
end

function Stations.addPump(id, coords, heading)
    local pumps = id and Stations?[id]?.Pumps

    if pumps then
        for i = 1, #pumps do
            local pumpCoords = pumps[i].coords

            if #(coords - vec3(pumpCoords.x, pumpCoords.y,pumpCoords.z)) < 1.5 then
                return false, locale('already_added')
            end
        end

        local addedPump = db.addPump(id, coords, heading)

        if addedPump then
            local newPump = #pumps+1
            pumps[newPump] = {
                coords = vec4(coords.x, coords.y, coords.z, heading),
                isBusy = false,
                upgrade = 1,
                id = addedPump,
                price = {
                    ['86'] = 30,
                    ['89'] = 60,
                    ['92'] = 90,
                    ['95'] = 120,
                },
            }

            TriggerClientEvent('Renewed-Fuel:client:pumpAdded', -1, id, newPump, pumps[newPump])
        end

        return addedPump
    end

    return false, locale('unknown_station')
end


function Stations.addMoney(id, amount)
    local station = Stations[id]

    if station then
        station.money += amount
        db.setGasMoney(id, station.money)
    end

    return station
end

function Stations.removeMoney(source, id, amount)
    if Stations.isManager(source, id) then
        local station = Stations[id]

        if station.money < amount then
            return notify(source, 'error', locale('no_money'))
        end

        station.money -= amount
        db.setGasMoney(id, station.money)

        return true
    end

    return false
end


function Stations.addEmployee(source, id, employee, grade)
    local station = Stations[id]
    local charId = Renewed.getCharId(employee)

    if not charId or station.employees[charId] then
        return notify(source, 'error', locale('already_employee'))
    end

    local name = Renewed.getCharName(employee)

    station.employees[charId] = {
        name = name,
        isManager = grade,
    }

    TriggerClientEvent('Renewed-Fuel:client:addJob', employee, id, grade)


    return db.addGasEmployee(id, charId, name, grade), charId, name
end

function Stations.removeEmployee(id, employee)
    local station = Stations[id]

    if station and station.employees[employee] then
        local pSource = Renewed.getPlayerFromCharId(employee)

        if pSource then
            TriggerClientEvent('Renewed-Fuel:client:removeJob', pSource, id)
        end

        station.employees[employee] = nil

        return db.removeGasEmployee(id, employee)
    end
end

function Stations.changeEmployeeGrade(id, employee, grade)
    local station = Stations[id]

    if station and station.employees[employee] then
        local pSource = Renewed.getPlayerFromCharId(employee)

        if pSource then
            TriggerClientEvent('Renewed-Fuel:client:addJob', pSource, id, grade)
        end

        station.employees[employee].isManager = grade == 1 and true or false
        return db.changeGasEmployeeGrade(id, employee, grade)
    end
end

function Stations.isManager(source, station)
    local left = Stations[station]
    local charId = Renewed.getCharId(source)

    local employee = left and left.employees?[charId]

    return employee and employee.isManager
end

function Stations.changeTablet(id, coords, heading)
    local station = Stations[id]

    coords = { x = coords.x, y = coords.y, z = coords.z, w = heading}

    if station then
        local success = db.changeTablet(id, json.encode(coords))

        if success then
            station.tabletCoord = coords
            TriggerClientEvent('Renewed-Fuel:client:changeTablet', -1, id, coords)
        end
    end
end

function Stations.changeGasName(source, id, name)
    local station = Stations[id]

    if station then
        for k, v in pairs(Stations) do
            if type(k) == 'number' and v.name == name then
                return notify(source, 'error', locale('station_exsists'))
            end
        end


        station.name = name
        TriggerClientEvent('Renewed-Fuel:client:changeGasName', -1, id, station)

        db.changeStationName(id, name)

        return true
    end
end

function Stations.changePump(id, coords, heading)
    local station = Stations[id]

    coords = { x = coords.x, y = coords.y, z = coords.z, w = heading}

    if station then
        local success = db.changePump(id, json.encode(coords))

        if success then
            station.pumpCoord = coords
            TriggerClientEvent('Renewed-Fuel:client:changePump', -1, id, coords)
        end
    end
end

function Stations.addLog(id, source, text, log_type)
    db.addGasLog(id, Renewed.getCharName(source), text, log_type)
end

function Stations.getLogs(id)
    return db.getGasLog(id)
end

return Stations