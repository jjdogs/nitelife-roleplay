Config.Language = "english" -- YOU CAN CHANGE THIS IN THE IN GAME MENU AS WELL

Config.AdminCommand = "admin" -- Command for opening the admin menu
Config.AdminBind = "F3"

Config.NoclipCommand = "noclip" -- Command for toggling noclip
Config.NoclipBind = "F2"

Config.FixVehicleCommand = "fix" -- Command for fixing your vehicle

Config.DeleteVehicleCommand = "dv" -- Command for quick deleting either the closest vehicle to you or the vehicle that you are in. 
Config.MaxLogsAmount = 150 -- Max logs at a time

-- =========================
-- External Logging (optional)
-- Supports Discord webhook embeds OR FiveManage structured logs.
-- =========================
Config.ExternalLogs = {
    enabled = true,
    provider = 'fivemanage',

    discord = { -- I would not use discord as it has a rate limit and can stop working at times. FiveManage does not have that issue and that is what i recommend FiveManage.
        webhook = '',
        username = 'Pug Admin Menu',
        avatar_url = '',
    },

    fivemanage = {
        dataset = 'Admin_Logs', -- THIS IS NOT USED YET
    },

    includeArgs = true, -- Args are passed through when when logged
}

Config.TrollCageLocarion = vector3(-74.30, -817.69, 326.18) -- Troll cage location
Config.KillLog = {
    Enable = true, -- Enable the players death kill log.
    ShowWhenDeathIsSource = false,  -- Log the kill even when the player dies from killing themselves.
}

-- =========================
-- Dashboard Heat Map
-- Live population overlay for the dashboard map.
-- Smaller + cheaper by default to avoid wasting client render time.
-- =========================
Config.DashboardHeatMap = {
    enabled = true,

    -- How often the UI asks the server for fresh player coordinates.
    pollIntervalMs = 120000,

    -- Server-side cap before points are downsampled.
    maxPoints = 180,

    -- Client-side render tuning.
    bucketSizePx = 18,
    minRadiusPx = 16,
    baseRadiusPx = 18,
    zoomRadiusStepPx = 4,
    maxRadiusPx = 38,
    maxRenderedGroups = 80,

    -- Extra visuals. Turn these off first if you want the cheapest possible mode.
    usePulse = false,
    showCountPills = true,
    showCountAt = 4,

    -- Clamp high DPR screens so the overlay canvas stays cheaper.
    canvasMaxDpr = 1.5,
}

-- =========================
-- Staff Chat
-- =========================
Config.StaffChat = {
    enabled = true,
    maxMessages = 100,

    -- Room access supports either:
    -- roles   = { 'admin', 'god' }   -- exact allowed roles
    -- minRole = 'admin'              -- this role and anything above it
    -- If neither is set, any staff role can view/send that room.
    rooms = {
        { key = 'staff', label = 'Staff' },
        { key = 'admin', label = 'Admin', minRole = 'admin' },
    }
}
-- =========================
-- Staff Chat Role Badges
-- Used to color/label the role pill in Staff Chat messages.
-- Keys should match your RBAC roles (Config.Roles / DB roles).
-- =========================
Config.StaffChatRoleBadges = {
    god       = { label = "God",       color = "#a855f7" }, -- purple
    admin     = { label = "Admin",     color = "#ef4444" }, -- red
    moderator = { label = "Moderator", color = "#3b82f6" }, -- blue
    trialmod  = { label = "Trial Mod", color = "#22c55e" }, -- green
}


-- =========================
-- Reports
-- =========================
Config.Reports = {
    autoDelete = true,
    retentionHours = 1,
    popupOnReply = true,
    maxImageBytes = 750000, -- ~750kb
}

-- =========================
-- Statistics sampling (persistent)
-- Captures player count (and a couple other light metrics) at configured times each day.
-- This is DB-backed so you can graph over days/weeks without polling every second.
-- =========================
Config.StatsSampling = {
    enabled = true,

    -- Local server time (HH:MM, 24h). Example captures 4 times/day.
    times = {
        "01:00",
        "02:00",
        "03:00",
        "04:00",
        "05:00",
        "06:00",
        "07:00",
        "08:00",
        "09:00",
        "10:00",
        "11:00",
        "12:00",
        "13:00",
        "14:00",
        "15:00",
        "16:00",
        "17:00",
        "18:00",
        "19:00",
        "20:00",
        "21:00",
        "22:00",
        "23:00",
        "00:00",
    },

    -- Delete samples older than this many days (keeps DB small)
    retentionDays = 30,
}


-- DO NOT TOUCH THIS!!!
local RESOURCE = GetCurrentResourceName()
local function loadLuaTable(path)
    local src = LoadResourceFile(RESOURCE, path)
    assert(src, ("Missing file: %s"):format(path))

    local chunk, err = load(src, ("@@%s/%s"):format(RESOURCE, path), "t")
    assert(chunk, err)

    local ok, tbl = pcall(chunk)
    assert(ok and type(tbl) == "table", ("File must return a table: %s"):format(path))

    return tbl
end
local Languages = {
    english  = loadLuaTable("config/translations/english.lua"),
    spanish  = loadLuaTable("config/translations/spanish.lua"),
    finnish  = loadLuaTable("config/translations/finnish.lua"),
    french   = loadLuaTable("config/translations/french.lua"),
    polish   = loadLuaTable("config/translations/polish.lua"),
    japanese = loadLuaTable("config/translations/japanese.lua"),
    chinese  = loadLuaTable("config/translations/chinese.lua"),
}
Config.AllTranslations = Languages
Config.Translations = Languages[Config.Language] or Languages.english