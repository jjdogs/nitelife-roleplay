Config = {}

-- Debug flags — set to true to enable console output for that category.
-- Set All = true to enable everything at once (useful during development).
Config.Debug = {
    Character = false, -- Character load, create, delete, DB queries
    All       = true,  -- Master override — if true, enables all of the above
}

function DebugPrint(category, message)
    if Config.Debug.All or Config.Debug[category] then
        print('[nt_character:' .. category .. '] ' .. tostring(message))
    end
end
