-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GetPlayerLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 9) == 'license2:' then return id end
    end
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 8) == 'license:' then return id end
    end
    return nil
end

-- ── Save appearance ────────────────────────────────────────────────────────────

RegisterNetEvent('nt_appearance:saveAppearance')
AddEventHandler('nt_appearance:saveAppearance', function(citizenid, model, skinJson)
    local src     = source
    local license = GetPlayerLicense(src)

    if not license then
        print('[nt_appearance] saveAppearance: no license for source ' .. tostring(src))
        return
    end

    -- Verify the citizen belongs to this player and is active
    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )
    if not char then
        print('[nt_appearance] WARNING: unauthorized save attempt for ' .. tostring(citizenid) .. ' by ' .. license)
        return
    end

    local existing = MySQL.single.await(
        'SELECT id FROM playerskins WHERE citizenid = ?',
        { citizenid }
    )

    if existing then
        MySQL.update.await(
            'UPDATE playerskins SET model = ?, skin = ?, active = 1 WHERE citizenid = ?',
            { model, skinJson, citizenid }
        )
    else
        MySQL.insert.await(
            'INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)',
            { citizenid, model, skinJson }
        )
    end

    print('[nt_appearance] Saved appearance for ' .. citizenid)
    TriggerClientEvent('nt_appearance:appearanceSaved', src)
end)
