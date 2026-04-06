local Players = {}
local db = require 'modules.db.oilfield'
local Notify = require 'modules.utils.server'.notify

local stashCoords = require 'shared.oilfield'.ped.coords

function Players.loadCharacter(charId)
    local data = db.getPlayerData(tostring(charId))

    if data and data[1] then
        local Player = data[1]
        Players[charId] = {
            controller = json.decode(Player.controller),
            blending = json.decode(Player.blending),
            storage = {
                Gasoline = {
                    ['86'] = Player['fuel86'],
                    ['89'] = Player['fuel89'],
                    ['92'] = Player['fuel92'],
                    ['95'] = Player['fuel95'],
                },
                Crudeoil = {
                    normal = Player.normal,
                    premium = Player.premium,
                }
            }
        }

        exports.ox_inventory:RegisterStash(('fuel_oil_%s'):format(charId), locale('rig_storage'), 5, 95000, charId, nil, stashCoords)
    end

    return data and Players[charId]
end

function Players.createCharacter(source, charId)
    local controller = {
        temp = 0,
        oil = {
            premium = 0,
            normal = 0,
        }
    }

    local blending = {
        LightNeptha = 0,
        HeavyNeptha = 0,
        other = 0
    }

    Players[charId] = {
        controller = controller,
        blending = blending,
        storage = {
            Gasoline = {
                ['86'] = 0,
                ['89'] = 0,
                ['92'] = 0,
                ['95'] = 0,
            },
            Crudeoil = {
                normal = 0,
                premium = 0,
            }
        }
    }

    exports.ox_inventory:RegisterStash(('fuel_oil_%s'):format(charId), locale('rig_storage'), 5, 95000, charId, nil, stashCoords)

    TriggerClientEvent('renewed-fuel:client:updateTable', source, Players[charId])
    Notify(source, 'success', locale('recieved_access'))

    db.insertPlayer(charId, json.encode(controller), json.encode(blending))
end

function Players.addOil(source, charId, normal, premium)
    local Player = Players[charId]

    if Player then
        Player.storage.Crudeoil.normal += normal
        Player.storage.Crudeoil.premium += premium
        Player.changed = true
        TriggerClientEvent('renewed-fuel:client:UpdateStorage', source, Player.storage.Crudeoil.normal, Player.storage.Crudeoil.premium)
    end

    return Player
end

function Players.unloadCharacter(charId)
    local Player = Players[charId]

    if Player then
        if Player.changed then
            local Storage = Player.storage
            db.savePlayer(charId, json.encode(Player.controller), json.encode(Player.blending), Storage.Crudeoil.normal or 0, Storage.Crudeoil.premium or 0, Storage.Gasoline['86'] or 0, Storage.Gasoline['89'] or 0, Storage.Gasoline['92'] or 0, Storage.Gasoline['95'] or 0)
        end

        Players[charId] = nil
        exports.ox_inventory:RemoveInventory(('fuel_oil_%s'):format(charId))
    end
end


return Players