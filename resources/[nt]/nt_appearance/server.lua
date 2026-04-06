-- ── Schema bootstrap ──────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS player_outfits (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            citizenid   VARCHAR(50)  NOT NULL,
            outfitname  VARCHAR(100) NOT NULL,
            model       VARCHAR(50)  NOT NULL DEFAULT 'mp_m_freemode_01',
            components  LONGTEXT     NOT NULL,
            props       LONGTEXT     NOT NULL,
            created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)

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

-- ── Outfits ────────────────────────────────────────────────────────────────────

local function getOutfitList(citizenid)
    return MySQL.query.await(
        'SELECT id, outfitname, components, props FROM player_outfits WHERE citizenid = ? ORDER BY id ASC',
        { citizenid }
    ) or {}
end

RegisterNetEvent('nt_appearance:getOutfits')
AddEventHandler('nt_appearance:getOutfits', function(citizenid)
    local src     = source
    local license = GetPlayerLicense(src)
    if not license then return end

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )
    if not char then
        print('[nt_appearance] WARNING: unauthorized getOutfits for ' .. tostring(citizenid) .. ' by ' .. license)
        return
    end

    TriggerClientEvent('nt_appearance:receiveOutfits', src, getOutfitList(citizenid))
end)

RegisterNetEvent('nt_appearance:saveOutfit')
AddEventHandler('nt_appearance:saveOutfit', function(citizenid, outfitname, componentsJson, propsJson, model)
    local src     = source
    local license = GetPlayerLicense(src)
    if not license then return end

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )
    if not char then
        print('[nt_appearance] WARNING: unauthorized saveOutfit for ' .. tostring(citizenid) .. ' by ' .. license)
        return
    end

    MySQL.insert.await(
        'INSERT INTO player_outfits (citizenid, outfitname, model, components, props) VALUES (?, ?, ?, ?, ?)',
        { citizenid, outfitname, model or 'mp_m_freemode_01', componentsJson, propsJson }
    )
    print('[nt_appearance] Saved outfit "' .. outfitname .. '" for ' .. citizenid)

    TriggerClientEvent('nt_appearance:receiveOutfits', src, getOutfitList(citizenid))
end)

RegisterNetEvent('nt_appearance:deleteOutfit')
AddEventHandler('nt_appearance:deleteOutfit', function(outfitId, citizenid)
    local src     = source
    local license = GetPlayerLicense(src)
    if not license then return end

    print('[nt_appearance] Deleting outfit id: ' .. tostring(outfitId) .. ' for citizenid: ' .. tostring(citizenid))

    MySQL.query.await(
        'DELETE FROM player_outfits WHERE id = ? AND citizenid = ?',
        { outfitId, citizenid }
    )
    print('[nt_appearance] Deleted outfit id=' .. tostring(outfitId) .. ' for ' .. tostring(citizenid))

    TriggerClientEvent('nt_appearance:receiveOutfits', src, getOutfitList(citizenid))
end)

-- ── Appearance for editor ─────────────────────────────────────────────────────
-- Returns the saved skin JSON so the editor can pre-populate its sliders.

RegisterNetEvent('nt_appearance:getAppearanceForEdit')
AddEventHandler('nt_appearance:getAppearanceForEdit', function(citizenid)
    local src     = source
    local license = GetPlayerLicense(src)
    if not license then
        TriggerClientEvent('nt_appearance:receiveAppearanceForEdit', src, nil)
        return
    end

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )
    if not char then
        TriggerClientEvent('nt_appearance:receiveAppearanceForEdit', src, nil)
        return
    end

    local skin = MySQL.single.await(
        'SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1',
        { citizenid }
    )

    TriggerClientEvent('nt_appearance:receiveAppearanceForEdit', src, skin and skin.skin or nil)
end)

-- ── Load appearance ────────────────────────────────────────────────────────────

RegisterNetEvent('nt_appearance:loadAppearance')
AddEventHandler('nt_appearance:loadAppearance', function(citizenid)
    local src     = source
    local license = GetPlayerLicense(src)
    if not license then return end

    local char = MySQL.single.await(
        'SELECT citizenid FROM players WHERE citizenid = ? AND license = ? AND disabled = 0',
        { citizenid, license }
    )
    if not char then return end

    local skin = MySQL.single.await(
        'SELECT model, skin FROM playerskins WHERE citizenid = ? AND active = 1',
        { citizenid }
    )

    if not skin then
        print('[nt_appearance] No saved appearance for ' .. citizenid)
        TriggerClientEvent('nt_appearance:applyAppearance', src, nil, nil)
        return
    end

    TriggerClientEvent('nt_appearance:applyAppearance', src, skin.model, skin.skin)
end)
