-- ── State ─────────────────────────────────────────────────────────────────────

local activePlayers = {}  -- [source] = citizenid
local sessionStart  = {}  -- [source] = os.time() when character session began

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GenerateCitizenId()
    local template = 'XXXXXXX'
    local id = string.gsub(template, 'X', function()
        return string.format('%x', math.random(0, 15))
    end)
    local exists = MySQL.scalar.await('SELECT citizenid FROM players WHERE citizenid = ?', { id })
    if exists then return GenerateCitizenId() end
    return id
end

local function GeneratePhoneNumber()
    return tostring(math.random(1000000, 9999999))
end

local function GenerateBankAccount()
    return 'US0' .. math.random(1, 9) .. 'QBX' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
end

local function GetPlayerLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 9) == 'license2:' then
            return id
        end
    end
    -- fallback to license:
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

-- ── Event handlers ────────────────────────────────────────────────────────────

RegisterNetEvent('nt_character:getCharacters')
AddEventHandler('nt_character:getCharacters', function()
    local src     = source
    local license = GetPlayerLicense(src)

    if not license then
        TriggerClientEvent('nt_character:getCharacters:reply', src, {})
        return
    end

    local rows = MySQL.query.await(
        'SELECT * FROM players WHERE license = ? AND disabled = 0',
        { license }
    )

    local result = {}
    for _, char in ipairs(rows) do
        local charinfo = json.decode(char.charinfo) or {}
        local money    = json.decode(char.money)    or {}
        local job      = json.decode(char.job)      or {}

        table.insert(result, {
            citizenid  = char.citizenid,
            firstName  = charinfo.firstname,
            middleName = charinfo.middlename  or '',
            lastName   = charinfo.lastname,
            suffix     = charinfo.suffix      or '',
            dob        = charinfo.birthdate,
            nationality= charinfo.nationality,
            job        = job.label            or 'Unemployed',
            properties = 0,
            playtime   = char.playtime        or 0,
            created    = char.created_at,
            lastPlayed = char.last_logged_out,
            money      = money
        })
    end

    DebugPrint('Character', 'Loaded ' .. #result .. ' characters for ' .. license)
    TriggerClientEvent('nt_character:getCharacters:reply', src, result)
end)

RegisterNetEvent('nt_character:createCharacter')
AddEventHandler('nt_character:createCharacter', function(data)
    local src     = source
    local license = GetPlayerLicense(src)

    if not license then
        TriggerClientEvent('nt_character:createCharacter:reply', src, false, 'No license found')
        return
    end

    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM players WHERE license = ? AND disabled = 0',
        { license }
    )
    if count >= 4 then
        TriggerClientEvent('nt_character:createCharacter:reply', src, false, 'Character limit reached')
        return
    end

    local citizenid = GenerateCitizenId()
    local phone     = GeneratePhoneNumber()

    local maxCid = MySQL.scalar.await(
        'SELECT MAX(cid) FROM players WHERE license = ?',
        { license }
    )
    local newCid = (maxCid or 0) + 1

    local userId = MySQL.scalar.await(
        'SELECT userId FROM players WHERE license = ? LIMIT 1',
        { license }
    )
    userId = userId or 1

    local charinfo = json.encode({
        firstname   = data.firstName,
        middlename  = data.middleName  or '',
        lastname    = data.lastName,
        suffix      = data.suffix      or '',
        birthdate   = data.dob,
        gender      = tonumber(data.gender) or 0,
        nationality = data.nationality,
        phone       = phone,
        account     = GenerateBankAccount(),
        backstory   = 'placeholder backstory',
        cid         = newCid
    })

    local money    = json.encode({ cash = 500, bank = 2000, crypto = 0 })
    local job      = json.encode({ name = 'unemployed', label = 'Civilian',  grade = { name = 'Freelancer',   level = 0 }, payment = 10, isboss = false, bankAuth = false, onduty = true })
    local gang     = json.encode({ name = 'none',       label = 'No Gang',   grade = { name = 'Unaffiliated', level = 0 }, isboss = false, bankAuth = false })
    local metadata = json.encode({})
    local position = json.encode({ x = -1037.0, y = -2738.0, z = 20.0, w = 0.0 })

    local id = MySQL.insert.await(
        'INSERT INTO players (citizenid, license, name, charinfo, money, job, gang, metadata, position, cid, userId, phone_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { citizenid, license, data.firstName .. ' ' .. data.lastName, charinfo, money, job, gang, metadata, position, newCid, userId, phone }
    )

    if id then
        DebugPrint('Character', 'Created character ' .. citizenid .. ' for ' .. license)
        TriggerClientEvent('nt_character:createCharacter:reply', src, true, citizenid)
    else
        TriggerClientEvent('nt_character:createCharacter:reply', src, false, 'Failed to insert into database')
    end
end)

RegisterNetEvent('nt_character:deleteCharacter')
AddEventHandler('nt_character:deleteCharacter', function(citizenid)
    local src     = source
    local license = GetPlayerLicense(src)

    if not license then
        TriggerClientEvent('nt_character:deleteCharacter:reply', src, false)
        return
    end

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )

    if not char then
        DebugPrint('Character', 'WARNING: ' .. license .. ' tried to delete character they don\'t own: ' .. tostring(citizenid))
        TriggerClientEvent('nt_character:deleteCharacter:reply', src, false)
        return
    end

    MySQL.update.await(
        'UPDATE players SET disabled = 1 WHERE citizenid = ? AND license = ?',
        { citizenid, license }
    )

    DebugPrint('Character', 'Disabled character ' .. citizenid .. ' for ' .. license)
    TriggerClientEvent('nt_character:deleteCharacter:reply', src, true)
end)

-- ── Active character tracking ──────────────────────────────────────────────
--
-- Called by nt_spawn/server.lua before qbx_core:Login so that playtime
-- accounting and playerDropped saving remain in one place (this resource).

exports('SetActiveCharacter', function(src, citizenid)
    activePlayers[src] = citizenid
    sessionStart[src]  = os.time()
    DebugPrint('Character', 'Active character set for ' .. src .. ': ' .. citizenid)
end)

AddEventHandler('playerDropped', function()
    local src       = source
    local citizenid = activePlayers[src]
    if not citizenid then return end

    local ped     = GetPlayerPed(src)
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    DebugPrint('Character', 'playerDropped - citizenid: ' .. tostring(citizenid) .. ', sessionStart: ' .. tostring(sessionStart[src]) .. ', elapsed: ' .. tostring(os.time() - (sessionStart[src] or os.time())))
    local elapsed = os.time() - (sessionStart[src] or os.time())
    local elapsedMinutes = math.floor(elapsed / 60)

    MySQL.update.await(
        'UPDATE players SET position = ?, last_logged_out = NOW(), playtime = playtime + ? WHERE citizenid = ?',
        { json.encode({ x = coords.x, y = coords.y, z = coords.z, w = heading }), elapsedMinutes, citizenid }
    )

    DebugPrint('Character', 'Saved logout for ' .. citizenid .. ' (session: ' .. elapsedMinutes .. 'm)')
    activePlayers[src] = nil
    sessionStart[src]  = nil
end)

-- ── Logout command ─────────────────────────────────────────────────────────

RegisterCommand('logout', function(src)
    local citizenid = activePlayers[src]
    DebugPrint('Character', 'logout — src: ' .. src .. ', citizenid: ' .. tostring(citizenid))

    if citizenid then
        local elapsed        = os.time() - (sessionStart[src] or os.time())
        local elapsedMinutes = math.floor(elapsed / 60)

        MySQL.update.await(
            'UPDATE players SET last_logged_out = NOW(), playtime = playtime + ? WHERE citizenid = ?',
            { elapsedMinutes, citizenid }
        )

        DebugPrint('Character', 'Saved logout for ' .. citizenid .. ' (session: ' .. elapsedMinutes .. 'm)')
    end

    activePlayers[src] = nil
    sessionStart[src]  = nil
    exports.qbx_core:Logout(src)
    -- Clean up any in-progress spawn selection in nt_spawn
    TriggerClientEvent('nt_spawn:cancelAndReset', src)
    TriggerClientEvent('nt_character:openNUI', src)
end, false)
