local MySQL = MySQL
local db = {}

local GET_USER_DATA = 'SELECT * FROM character_oil WHERE charId = ?'
function db.getPlayerData(charId)
    return MySQL.query.await(GET_USER_DATA, { charId })
end

local INSERT_USER = 'INSERT INTO character_oil (charId, controller, blending) VALUES (?, ?, ?)'
function db.insertPlayer(charId, controller, blending)
    return MySQL.query.await(INSERT_USER, { charId, controller, blending })
end

local SAVE_USER = 'UPDATE character_oil SET controller = ?, blending = ?, normal = ?, premium = ?, fuel86 = ?, fuel89 = ?, fuel92 = ?, fuel95 = ? WHERE charId = ?'
function db.savePlayer(charId, controller, blending, normal, premium, fuel86, fuel89, fuel92, fuel95)
    MySQL.query(SAVE_USER, { controller, blending, normal or 0, premium or 0, fuel86 or 0, fuel89 or 0, fuel92 or 0, fuel95 or 0, charId })
end


return db