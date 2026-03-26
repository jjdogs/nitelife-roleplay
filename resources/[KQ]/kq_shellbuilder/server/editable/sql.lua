
--- SQL Stuff
local SQL_DRIVER = Config.sql.driver
local function SqlQuery(query, data)
    if SQL_DRIVER == 'mysql' then
        return MySQL.Sync.fetchAll(query, data or {})
    end

    if SQL_DRIVER == 'oxmysql' then
        return exports[SQL_DRIVER]:query_async(query, data or {})
    else
        return exports[SQL_DRIVER]:executeSync(query, data or {})
    end
end

local function SqlMutate(query, data)
    if SQL_DRIVER == 'mysql' then
        return MySQL.Sync.insert(query, data)
    end

    if SQL_DRIVER == 'oxmysql' then
        return exports[SQL_DRIVER]:insert_async(query, data)
    else
        return exports[SQL_DRIVER]:executeSync(query, data)
    end
end


DB = {
    FetchShells = function()
        local query = 'SELECT * FROM kq_shellbuilder WHERE deleted_at IS NULL ORDER BY updated_at DESC'

        return SqlQuery(query)
    end,

    SaveNewShell = function(player, title, coords, settings, builderData, spawnData, thumbnail)
        local mutation = 'INSERT INTO kq_shellbuilder (`title`, `user`, `coords`, `settings`, `builder_data`, `spawn_data`, `thumbnail`) VALUES(@title, @user, @coords, @settings, @builderData, @spawnData, @thumbnail);'
        local data = {
            ['@title'] = title,
            ['@user'] = json.encode({
                id = GetPlayerIdentifierByType(player, 'license'),
                name = GetPlayerName(player)
            }),
            ['@coords'] = json.encode(coords),
            ['@settings'] = json.encode(settings),
            ['@builderData'] = json.encode(builderData),
            ['@spawnData'] = json.encode(spawnData),
            ['@thumbnail'] = thumbnail,
        }

        return SqlMutate(mutation, data)
    end,

    UpdateShell = function(id, title, settings, builderData, spawnData, thumbnail)
        local mutation = 'UPDATE kq_shellbuilder SET `title` = @title, `settings` = @settings, `builder_data` = @builderData, `spawn_data` = @spawnData, `thumbnail` = @thumbnail WHERE `id` = @id;'
        local data = {
            ['@id'] = id,
            ['@title'] = title,
            ['@settings'] = json.encode(settings),
            ['@builderData'] = json.encode(builderData),
            ['@spawnData'] = json.encode(spawnData),
            ['@thumbnail'] = thumbnail,
        }

        return SqlMutate(mutation, data)
    end,

    SetShellCoordinates = function(id, coords)
        local mutation = 'UPDATE kq_shellbuilder SET `coords` = @coords WHERE `id` = @id;'
        local data = {
            ['@id'] = id,
            ['@coords'] = json.encode(coords),
        }

        return SqlMutate(mutation, data)
    end,

    SetShellDeleted = function(id)
        local mutation = 'UPDATE kq_shellbuilder SET `deleted_at` = CURRENT_TIMESTAMP() WHERE `id` = @id;'
        local data = {
            ['@id'] = id,
        }

        return SqlMutate(mutation, data)
    end,
}

DB.SqlMutate = SqlMutate
DB.SqlQuery = SqlQuery
