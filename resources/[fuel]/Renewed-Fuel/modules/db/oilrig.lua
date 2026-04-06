local MySQL = MySQL
local db = {}



local RIG_LOOP_SAVE = 'UPDATE `player_oilrigs` SET `lastchecked` = ?, `temp` = ?, `speed` = ?, `oil` = ? WHERE `id` = ?'
function db.loopSave(RIGDATA)
    MySQL.prepare(RIG_LOOP_SAVE, RIGDATA)
end


local GET_OILRIGS = 'SELECT * FROM player_oilrigs'
function db.getOilRigs()
    return MySQL.query.await(GET_OILRIGS, {})
end

local INSERT_RIG = 'INSERT INTO `oil_rig` (`charId`, `x`, `y`, `z`, `w`) VALUES (?, ?, ?, ?, ?)'
function db.insertRig(charId, coords, heading)
    return MySQL.insert.await(INSERT_RIG, { charId, coords.x, coords.y, coords.z, heading })
end

local GET_RIGS = 'SELECT `id`, `charId`, `x`, `y`, `z`, `w`, `normal`, `premium`, `speed`, `temp`, UNIX_TIMESTAMP(`lastused`) AS `lastused` FROM `oil_rig`'
function db.getRigs()
    return MySQL.query.await(GET_RIGS)
end

local UPDATE_OWNER = 'UPDATE `oil_rig` SET `charid` = ? WHERE `id` = ?'
function db.saveOwner(id, newowner)
    MySQL.update(UPDATE_OWNER, { newowner, id })
end

function db.massSave(queries)
    return MySQL.transaction.await(queries)
end


return db