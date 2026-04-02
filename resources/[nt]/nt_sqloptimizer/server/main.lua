-- nt_sqloptimizer | server/main.lua
-- Runs ANALYZE TABLE and OPTIMIZE TABLE on all tables in the database at startup.
-- Uses oxmysql rawExecute (https://coxdocs.dev/oxmysql/Functions/rawExecute)

local Config = {
    -- Tables to SKIP optimization on (e.g. large log tables that take too long)
    skipTables = {
        -- 'some_huge_log_table',
    },

    -- If true, prints a line per table as it processes
    verbose = true,
}

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function log(msg)
    print(('[^5nt_sqloptimizer^7] %s'):format(msg))
end

local function warn(msg)
    print(('[^5nt_sqloptimizer^7] ^3[WARN]^7 %s'):format(msg))
end

local function isSkipped(tableName)
    for _, skip in ipairs(Config.skipTables) do
        if skip == tableName then return true end
    end
    return false
end

-- ─────────────────────────────────────────────
-- Core logic
-- ─────────────────────────────────────────────

local function getTableNames()
    -- Pull the current database name from the connection, then list all tables in it.
    -- DATABASE() is a MySQL/MariaDB built-in that returns the active schema name.
    local rows = MySQL.query.await('SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = "BASE TABLE"')
    local tables = {}
    if rows then
        for _, row in ipairs(rows) do
            -- information_schema returns column names in their original case
            local name = row.table_name or row.TABLE_NAME
            if name and not isSkipped(name) then
                tables[#tables + 1] = name
            end
        end
    end
    return tables
end

local function analyzeTable(tbl)
    -- ANALYZE TABLE updates index statistics so the query planner makes better decisions.
    -- rawExecute is used because this is a DDL-style statement with no placeholder values.
    local ok, err = pcall(function()
        MySQL.rawExecute.await(('ANALYZE TABLE `%s`'):format(tbl))
    end)
    if not ok then
        warn(('ANALYZE failed for `%s`: %s'):format(tbl, tostring(err)))
        return false
    end
    return true
end

local function optimizeTable(tbl)
    -- OPTIMIZE TABLE reclaims unused space and defragments data/index files.
    -- For InnoDB (standard on MariaDB), this rebuilds the table which can take a moment
    -- on very large tables — that's why Config.skipTables exists.
    local ok, err = pcall(function()
        MySQL.rawExecute.await(('OPTIMIZE TABLE `%s`'):format(tbl))
    end)
    if not ok then
        warn(('OPTIMIZE failed for `%s`: %s'):format(tbl, tostring(err)))
        return false
    end
    return true
end

local function runOptimization()
    log('^2Starting SQL optimization...^7')

    local tables = getTableNames()

    if #tables == 0 then
        warn('No tables found — check your database connection or oxmysql config.')
        return
    end

    log(('Found ^6%d^7 tables to process.'):format(#tables))

    local analyzed  = 0
    local optimized = 0
    local skipped   = 0

    for _, tbl in ipairs(tables) do
        if Config.verbose then
            log(('Processing `^6%s^7`...'):format(tbl))
        end

        local a = analyzeTable(tbl)
        local o = optimizeTable(tbl)

        if a then analyzed  = analyzed  + 1 end
        if o then optimized = optimized + 1 end
        if not a or not o then skipped = skipped + 1 end
    end

    log(('^2Optimization complete.^7 Analyzed: ^6%d^7 | Optimized: ^6%d^7 | Errors: ^1%d^7'):format(analyzed, optimized, skipped))
end

-- ─────────────────────────────────────────────
-- Entry point — wait for oxmysql to be ready
-- ─────────────────────────────────────────────

CreateThread(function()
    -- Give oxmysql a moment to finish its own startup before we hammer the DB.
    Wait(3000)
    runOptimization()
end)
