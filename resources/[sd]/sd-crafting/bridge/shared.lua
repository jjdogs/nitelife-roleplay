local Config = require('configs/config')
Locale = {}

-- Dictionary to store flattened locale strings
local dict = {}

--- Flattens nested tables into dot-notation keys
---@param prefix string? The prefix for the current level
---@param source table The source table to flatten
---@param target table The target table to store flattened values
local function FlattenDict(prefix, source, target)
    for key, value in pairs(source) do
        local newKey = prefix and (prefix .. '.' .. key) or key

        if type(value) == 'table' then
            FlattenDict(newKey, value, target)
        else
            target[newKey] = value
        end
    end
end

--- Retrieves localized strings with optional dynamic content replacement
---@param key string The key for the localized string
---@param replacements table? Replacement values for dynamic content
---@return string The localized string with replacements applied
Locale.T = function(key, replacements)
    local lstr = dict[key]
    if lstr and replacements then
        for k, v in pairs(replacements) do
            lstr = lstr:gsub('{' .. tostring(k) .. '}', tostring(v))
        end
    end
    return lstr or key
end

--- Loads and applies locales from JSON file
---@param locale string The locale setting determining which file to load
Locale.LoadLocale = function(locale)
    local lang = locale or 'en'
    local path = ('locales/%s.json'):format(lang)
    local file = LoadResourceFile(GetCurrentResourceName(), path)

    if not file then
        print(string.format("^1[SD-CRAFTING] Could not load locale file: %s^0", path))
        -- Try fallback to English
        if lang ~= 'en' then
            print(string.format("^3[SD-CRAFTING] Falling back to English locale^0"))
            path = 'locales/en.json'
            file = LoadResourceFile(GetCurrentResourceName(), path)
        end

        if not file then
            error(string.format("Could not load fallback locale file: %s", path))
            return
        end
    end

    local locales = json.decode(file)
    if not locales then
        error("Failed to parse the locale JSON.")
        return
    end

    -- Clear existing dict
    for k in pairs(dict) do
        dict[k] = nil
    end

    -- Flatten the nested locale structure
    FlattenDict(nil, locales, dict)

    print(string.format("^2[SD-CRAFTING] Loaded locale: %s^0", lang))
end

-- Initialize locale on resource start
CreateThread(function()
    Wait(100) -- Wait for config to load
    if Config and Config.Locale then
        Locale.LoadLocale(Config.Locale)
    else
        Locale.LoadLocale('en')
    end
end)
