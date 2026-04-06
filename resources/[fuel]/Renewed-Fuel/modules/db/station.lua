local db = {}
local MySQL = MySQL

local GET_GAS_STATIONS = 'SELECT `id`, `name`, `tablet`, `fuelpump`, `money`, `price`, `pedcoords`, DATE_FORMAT(`created`, "%d/%m/%Y") AS `created` FROM `gas_stations`'
function db.getStations()
    return MySQL.query.await(GET_GAS_STATIONS)
end

local GET_OIL_TANKS = 'SELECT `tankId`, `fuelType`, `amount`, `upgrade` FROM `gas_stations_tanks` WHERE `station` = ?'
function db.getTanks(station)
    return MySQL.query.await(GET_OIL_TANKS, { station })
end


local SELECT_GAS_PUMPS = 'SELECT `x`, `y`, `z`, `w`, `price`, `pumpId`, `upgrade` FROM `gas_stations_pumps` WHERE `station` = ?'
function db.selectPumps(id)
    return MySQL.query.await(SELECT_GAS_PUMPS, { id })
end

local CHANGE_GAS_NAME = 'UPDATE `gas_stations` SET `name` = ? WHERE `id` = ?'
function db.changeStationName(id, name)
   MySQL.update(CHANGE_GAS_NAME, { name, id })
end

local GET_GAS_EMPLOYEES = 'SELECT `grade`, `station` FROM `gas_stations_employees` WHERE `charId` = ?'
function db.getGasJobs(charId)
    return MySQL.query.await(GET_GAS_EMPLOYEES, { charId })
end

local SELECT_GAS_EMPLOYEES = 'SELECT `charid`, `name`, `grade` FROM `gas_stations_employees` WHERE `station` = ?'
function db.selectGasEmployees(station)
    return MySQL.query.await(SELECT_GAS_EMPLOYEES, { station })
end

local ADD_GAS_EMPLOYEE = 'INSERT INTO `gas_stations_employees` (`station`, `charId`, `name`, `grade`) VALUES (?, ?, ?, ?)'
function db.addGasEmployee(station, charId, name, grade)
    return MySQL.query.await(ADD_GAS_EMPLOYEE, { station, charId, name, grade })
end

local REMOVE_GAS_EMPLOYEE = 'DELETE FROM `gas_stations_employees` WHERE `station` = ? AND `charId` = ?'
function db.removeGasEmployee(station, charId)
    return MySQL.query.await(REMOVE_GAS_EMPLOYEE, { station, charId })
end

local CHANGE_GASGRADE = 'UPDATE `gas_stations_employees` SET `grade` = ? WHERE `station` = ? AND `charId` = ?'
function db.changeGasEmployeeGrade(station, charId, grade)
    return MySQL.query.await(CHANGE_GASGRADE, { grade, station, charId })
end

local SET_GAS_MONEY = 'UPDATE `gas_stations` SET `money` = ? WHERE `id` = ?'
function db.setGasMoney(station, amount)
    MySQL.query(SET_GAS_MONEY, { amount, station })
end

local ADD_GAS_LOG = 'INSERT INTO `gas_stations_logs` (`station`, `employee`, `text`, `log_type`) VALUES (?, ?, ?, ?)'
function db.addGasLog(station, employee, text, log_type)
    MySQL.query(ADD_GAS_LOG, { station, employee, text, log_type })
end

local GET_GAS_LOG = 'SELECT `text`, `employee`, `log_type`, DATE_FORMAT(`date`, "%d/%m/%Y") AS `date` FROM `gas_stations_logs` WHERE `station` = ?'
function db.getGasLog(station)
    return MySQL.query.await(GET_GAS_LOG, { station })
end

--- ADMIN SQL QUERIES --
local INSERT_GAS_STATION = 'INSERT INTO `gas_stations` (`name`, `tablet`, `fuelpump`) VALUES (?, ?, ?)'
function db.createStation(name, tablet, fuelpump)
    return MySQL.insert.await(INSERT_GAS_STATION, { name, tablet, fuelpump })
end

local CHANGE_TABLET = 'UPDATE `gas_stations` SET `tablet` = ? WHERE `id` = ?'
function db.changeTablet(id, tablet)
    return MySQL.query.await(CHANGE_TABLET, { tablet, id })
end

local CHANGE_PUMP = 'UPDATE `gas_stations` SET `fuelpump` = ? WHERE `id` = ?'
function db.changePump(id, pump)
    return MySQL.query.await(CHANGE_PUMP, { pump, id })
end

local UPDATE_PED = 'UPDATE `gas_stations` SET `pedcoords` = ? WHERE `id` = ?'
function db.updatePed(id, ped)
    MySQL.query(UPDATE_PED, { ped, id })
end

local UPDATE_PRICE = 'UPDATE `gas_stations` SET `price` = ? WHERE `id` = ?'
function db.updatePrice(id, price)
    MySQL.query(UPDATE_PRICE, { price, id })
end

local DELETE_GAS_STATION = 'DELETE FROM `gas_stations` WHERE `id` = ?'
function db.deleteStation(id)
    MySQL.query(DELETE_GAS_STATION, { id })
end

local defaultPrice = json.encode({['95'] = 100, ['92'] = 75, ['89'] = 50, ['86'] = 25})

local ADD_GAS_PUMP = 'INSERT INTO `gas_stations_pumps` (`station`, `x`, `y`, `z`, `w`, `price`) VALUES (?, ?, ?, ?, ?, ?)'
function db.addPump(id, coords, heading)
    return MySQL.insert.await(ADD_GAS_PUMP, { id, coords.x, coords.y, coords.z, heading, defaultPrice })
end


return db