local hasHistoryColumn = false

--- Run database migrations on resource start
---@return nil
CreateThread(function()
    Wait(100)

    local columns = MySQL.query.await([[
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'sd_crafting_workbenches'
        AND COLUMN_NAME = 'history'
    ]])

    if not columns or #columns == 0 then
        MySQL.query.await([[
            ALTER TABLE sd_crafting_workbenches
            ADD COLUMN history JSON DEFAULT NULL
        ]])
        print('[SD-CRAFTING] Migration: Added history column to sd_crafting_workbenches')
    end

    hasHistoryColumn = true
end)

--- Check if the history column migration has completed
---@return boolean
function IsHistoryMigrationComplete()
    return hasHistoryColumn
end
