local db = {}
local MySQL = MySQL


local DB_CHANGE_PRICE = 'UPDATE `gas_stations_pumps` SET `price` = ? WHERE `pumpId` = ?'
function db.changePumpPrice(pumpId, price)
    MySQL.update(DB_CHANGE_PRICE, { json.encode(price), pumpId })
end


local DB_CHANGE_ALL_PRICES = 'UPDATE `gas_stations_pumps` SET `price` = ? WHERE `station` = ?'
function db.changeAllPrices(station, price)
    MySQL.update(DB_CHANGE_ALL_PRICES, { json.encode(price), station })
end


local DB_UPGRADE_PUMP = 'UPDATE `gas_stations_pumps` SET `upgrade` = ? WHERE `pumpId` = ?'
function db.upgradePump(pumpId, upgrade)
    MySQL.update(DB_UPGRADE_PUMP, { upgrade, pumpId })
end






return db