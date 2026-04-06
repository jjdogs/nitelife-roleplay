-- ── Helpers ───────────────────────────────────────────────────────────────────

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

-- ── Spawn selection ────────────────────────────────────────────────────────

-- Builds a dynamic list of spawn options for the given citizenid:
--   1. Legion Square (always present as fallback)
--   2. Job spawn if the character's job has an entry in Config.JobSpawns
--   3. All properties the character has access to (via nolag_properties)
-- Also queries charinfo so the NUI can display the character's name.
RegisterNetEvent('nt_spawn:getSpawnOptions')
AddEventHandler('nt_spawn:getSpawnOptions', function(citizenid)
    local src     = source
    local license = GetPlayerLicense(src)

    local char = MySQL.single.await(
        'SELECT job, charinfo FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )

    if not char then
        DebugPrint('Spawn', 'WARNING: getSpawnOptions — invalid character: ' .. tostring(citizenid))
        TriggerClientEvent('nt_spawn:receiveSpawnOptions', src, {
            { id = 'default', type = 'default', label = 'Legion Square', coords = Config.DefaultSpawn }
        }, nil)
        return
    end

    -- Character name data for NUI display
    local charinfo     = json.decode(char.charinfo) or {}
    local characterData = {
        citizenid  = citizenid,
        firstName  = charinfo.firstname  or '',
        middleName = charinfo.middlename or '',
        lastName   = charinfo.lastname   or '',
        suffix     = charinfo.suffix     or '',
    }

    local spawnOptions = {}

    -- 1. Legion Square — always the first option
    table.insert(spawnOptions, {
        id     = 'default',
        type   = 'default',
        label  = 'Legion Square',
        coords = Config.DefaultSpawn,
    })

    -- 2. Job spawn
    local job = json.decode(char.job)
    if job and job.name and job.name ~= 'unemployed' then
        local jobSpawn = Config.JobSpawns[job.name]
        if jobSpawn then
            table.insert(spawnOptions, {
                id      = 'job_' .. job.name,
                type    = 'job',
                label   = jobSpawn.label,
                jobName = job.name,
                coords  = jobSpawn.coords,
            })
        end
    end

    -- 3. Properties — includeRented = true so starter apartments (rented) are included
    local ok, properties = pcall(function()
        return exports.nolag_properties:GetAllProperties(citizenid, 'user', true)
    end)
    if ok and properties then
        for _, prop in ipairs(properties) do
            local c = prop.coords
            local propCoords = c
                and { x = c.x, y = c.y, z = c.z, w = c.w or 0.0 }
                or  Config.DefaultSpawn
            table.insert(spawnOptions, {
                id         = 'property_' .. tostring(prop.id),
                type       = 'property',
                label      = prop.label or prop.address or 'My Apartment',
                propertyId = prop.id,
                coords     = propCoords,
            })
        end
    end

    TriggerClientEvent('nt_spawn:receiveSpawnOptions', src, spawnOptions, characterData)
end)

-- Handles brand-new characters after appearance editor completion.
-- Order: DB validation → assign apartment → poll until property loads →
--        Login → playerReady (with propertyId so client calls WrapIntoProperty).
RegisterNetEvent('nt_spawn:spawnNewCharacter')
AddEventHandler('nt_spawn:spawnNewCharacter', function(citizenid)
    local src     = source
    local license = GetPlayerLicense(src)

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )
    if not char then
        DebugPrint('Spawn', 'WARNING: spawnNewCharacter — invalid character: ' .. tostring(citizenid))
        return
    end

    -- 1. Track active character in nt_character (records session start time for playtime)
    pcall(function() exports.nt_character:SetActiveCharacter(src, citizenid) end)

    -- 2. Log player in via qbx_core FIRST — nolag_properties requires the qbx_core player
    --    object to exist before AddStarterApartment can correctly associate the property.
    --    (This matches qbx_core's pattern: Login → giveStarterItems → AddStarterApartment)
    local success = exports.qbx_core:Login(src, citizenid)

    if not success then
        TriggerClientEvent('nt_spawn:hideCreationLoading', src)
        DebugPrint('Spawn', 'spawnNewCharacter: Login failed for ' .. citizenid)
        return
    end

    DebugPrint('Spawn', 'spawnNewCharacter: Login succeeded for ' .. citizenid)

    -- 3. Assign starter apartment (player is now logged in — nolag_properties can see qbx_core player)
    local assignedPropertyId = nil

    local ok, propertyId = pcall(function()
        return exports.nolag_properties:AddStarterApartment(citizenid)
    end)

    if ok and propertyId then
        DebugPrint('Properties', 'Starter apartment assigned: ' .. tostring(propertyId))
        assignedPropertyId = propertyId
    else
        DebugPrint('Properties', 'AddStarterApartment failed: ' .. tostring(propertyId) .. ' — player will spawn at default location')
    end

    -- assignedPropertyId: client calls WrapIntoProperty if set (handles routing bucket + teleport).
    -- If nil (AddStarterApartment failed), client falls back to raw teleport to DefaultSpawn.
    TriggerClientEvent('nt_spawn:playerReady', src, Config.DefaultSpawn, true, assignedPropertyId)
end)

RegisterNetEvent('nt_spawn:spawnPlayer')
AddEventHandler('nt_spawn:spawnPlayer', function(citizenid, coords)
    local src     = source
    local license = GetPlayerLicense(src)
    DebugPrint('Spawn', 'spawnPlayer called — citizenid: ' .. tostring(citizenid) .. ', coords: ' .. json.encode(coords))

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )

    if not char then
        DebugPrint('Spawn', 'WARNING: ' .. tostring(license) .. ' tried to spawn invalid character: ' .. tostring(citizenid))
        return
    end

    -- Track active character and record session start time for playtime accounting
    pcall(function() exports.nt_character:SetActiveCharacter(src, citizenid) end)

    -- Load character via qbx_core
    local success = exports.qbx_core:Login(src, citizenid)

    if success then
        DebugPrint('Spawn', 'qbx_core Login succeeded for ' .. citizenid)
        TriggerClientEvent('nt_spawn:playerReady', src)
    else
        DebugPrint('Spawn', 'qbx_core Login failed for ' .. citizenid .. ' — cannot spawn')
    end
end)
