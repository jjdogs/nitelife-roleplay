local db = {}


local ADD_OIL_TANK = 'INSERT INTO `gas_stations_tanks` (`station`) VALUES (?)'
function db.addTank(station)
    MySQL.insert(ADD_OIL_TANK, { station })
end

local UPGRADE_OIL_TANK = 'UPDATE `gas_stations_tanks` SET `upgrade` = ? WHERE `tankId` = ?'
function db.upgradeTank(tankId, upgrade)
    MySQL.query(UPGRADE_OIL_TANK, { upgrade, tankId })
end

local SET_OIL_STORAGE = 'UPDATE `gas_stations_tanks` SET `amount` = ? WHERE `tankId` = ?'
function db.setStorage(tankId, amount)
    MySQL.prepare(SET_OIL_STORAGE, { amount, tankId })
end

function db.saveStorage(queries)
    return MySQL.transaction.await(queries)
end

return db