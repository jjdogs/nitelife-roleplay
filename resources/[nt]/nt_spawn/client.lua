local spawnCamera            = nil
local pendingSpawnCoords     = nil   -- spawn coords stored by confirmSpawn, consumed by playerReady
local pendingSpawnPropertyId = nil   -- propertyId when player picks a property spawn location
local spawnCitizenId         = nil   -- citizenid of the character currently being spawned
local spawnGender            = nil   -- gender (0/1) for new character appearance editor

local spawnNuiLoaded      = false
local spawnNuiPendingOpen = false

-- Allow inbound reply events from the server
RegisterNetEvent('nt_spawn:receiveSpawnOptions')
RegisterNetEvent('nt_spawn:playerReady')
RegisterNetEvent('nt_spawn:cancelAndReset')

-- ── NUI helpers ───────────────────────────────────────────────────────────────

local function openSpawnNUI()
    SetNuiFocus(true, true)
    if spawnNuiLoaded then
        SendNUIMessage({ action = 'open' })
    else
        spawnNuiPendingOpen = true
    end
end

local function closeSpawnNUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('nuiReady', function(_, cb)
    DebugPrint('Spawn', 'nt_spawn NUI ready')
    spawnNuiLoaded = true
    cb('ok')
    if spawnNuiPendingOpen then
        spawnNuiPendingOpen = false
        SendNUIMessage({ action = 'open' })
    end
end)

-- ── Entry point from nt_character ─────────────────────────────────────────────
--
-- Fired as a local event by nt_character/client.lua when a character is chosen to play,
-- or after nt_appearance:complete for brand-new characters.
-- isNewChar = true: skip spawn selection, go directly to spawnNewCharacter.
-- isNewChar = false: open spawn location NUI, let player choose.

AddEventHandler('nt_spawn:beginSpawnSelection', function(citizenid, isNewChar, gender)
    DebugPrint('Spawn', 'beginSpawnSelection — citizenid: ' .. tostring(citizenid) .. ', isNewChar: ' .. tostring(isNewChar))
    spawnCitizenId = citizenid
    spawnGender    = gender
    if isNewChar then
        -- Show creation loading overlay immediately (no server round-trip gap).
        -- Screen is already black from DoScreenFadeOut in nt_character's createCharacter callback.
        SendNUIMessage({ type = 'showCreationLoading', messages = Config.CreationLoadingMessages })
        TriggerServerEvent('nt_spawn:spawnNewCharacter', citizenid)
    else
        -- End implicit FiveM tutorial session so the game world renders in the spawn preview.
        -- qbx_core's character.lua returns early for external characters, so we are still in the
        -- default tutorial session from connect. This must happen before RenderScriptCams works.
        NetworkEndTutorialSession()
        openSpawnNUI()
        TriggerServerEvent('nt_spawn:getSpawnOptions', citizenid)
    end
end)

-- Cleanup triggered by nt_character's /logout command if player is mid-spawn-selection
AddEventHandler('nt_spawn:cancelAndReset', function()
    DebugPrint('Spawn', 'cancelAndReset — cleaning up spawn state')
    if spawnCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(spawnCamera, false)
        spawnCamera = nil
    end
    ClearFocus()
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    spawnCitizenId         = nil
    pendingSpawnCoords     = nil
    pendingSpawnPropertyId = nil
    spawnGender            = nil
    closeSpawnNUI()

    -- Force-remove all nolag_properties ox_target zones.
    -- nolag_properties' own playerLoggedOut cleanup is unreliable; without this,
    -- zones accumulate across character switches (each login adds a new set).
    if lib and lib.zones then
        for _, zone in pairs(lib.zones.getAllZones()) do
            if zone.resource == 'nolag_properties' then
                zone:remove()
            end
        end
        DebugPrint('Spawn', 'cancelAndReset — nolag_properties zones cleared')
    end
end)

-- ── NUI callbacks ─────────────────────────────────────────────────────────────

RegisterNUICallback('previewSpawn', function(data, cb)
    DebugPrint('Spawn', 'previewSpawn triggered')
    DebugPrint('Spawn', 'coords: ' .. json.encode(data.coords))

    -- Capture into locals before cb() — data table may be invalidated after cb returns
    local coords = data.coords
    cb('ok')

    CreateThread(function()
        DebugPrint('Spawn', 'previewSpawn thread: started')

        local heading = coords.w or 0.0

        -- The ped is already in spawned state (spawnmanager was called at startup).
        -- Just hide, reposition, and set up the preview camera.
        local ped = PlayerPedId()
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, heading)

        if spawnCamera then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(spawnCamera, false)
            spawnCamera = nil
        end

        DebugPrint('Spawn', 'previewSpawn thread: ped repositioned and hidden')

        -- Force game to stream the area before showing the camera
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        SetFocusArea(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
        local timeout = 0
        while not HasCollisionLoadedAroundEntity(PlayerPedId()) and timeout < 30 do
            Wait(100)
            timeout = timeout + 1
        end
        Wait(100)

        local camX = coords.x - math.sin(math.rad(heading)) * 4.0
        local camY = coords.y - math.cos(math.rad(heading)) * 4.0
        local camZ = coords.z + 2.0

        DebugPrint('Spawn', 'previewSpawn thread: creating camera at ' .. tostring(camX) .. ', ' .. tostring(camY) .. ', ' .. tostring(camZ))

        spawnCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(spawnCamera, camX, camY, camZ)
        PointCamAtCoord(spawnCamera, coords.x, coords.y, coords.z)
        SetCamFov(spawnCamera, 60.0)
        SetCamActive(spawnCamera, true)

        Wait(0)

        RenderScriptCams(true, true, 500, true, true)
        DebugPrint('Spawn', 'RenderScriptCams called')

        Wait(600)
        DebugPrint('Spawn', 'IsCamRendering: ' .. tostring(IsCamRendering(spawnCamera)))
    end)
end)

RegisterNUICallback('confirmSpawn', function(data, cb)
    -- Capture into locals before cb() — data table may be invalidated after cb returns
    local citizenid  = data.citizenid
    local coords     = data.coords
    local propertyId = data.propertyId   -- nil for non-property locations
    cb('ok')

    -- Store so playerReady handler can use them to position the ped
    pendingSpawnCoords     = coords
    pendingSpawnPropertyId = propertyId

    CreateThread(function()
        if spawnCamera then
            RenderScriptCams(false, true, 500, true, true)
            Wait(500)
            DestroyCam(spawnCamera, false)
            spawnCamera = nil
        end
        -- Release streaming focus set by SetFocusArea during previewSpawn
        ClearFocus()
        TriggerServerEvent('nt_spawn:spawnPlayer', citizenid, coords)
    end)
end)

RegisterNUICallback('cancelSpawn', function(_, cb)
    cb('ok')
    CreateThread(function()
        if spawnCamera then
            RenderScriptCams(false, true, 300, true, true)
            Wait(300)
            DestroyCam(spawnCamera, false)
            spawnCamera = nil
        end
        -- Release streaming focus set by SetFocusArea during previewSpawn
        ClearFocus()
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        spawnCitizenId = nil
    end)
end)

-- ── Inbound server events ─────────────────────────────────────────────────────

AddEventHandler('nt_spawn:receiveSpawnOptions', function(locations, characterData)
    SendNUIMessage({ action = 'setSpawnData', locations = locations, character = characterData })
end)

-- coords: non-nil for new characters (fallback if no propertyId), nil for returning players.
-- isNewChar: true skips spawn selection and opens appearance editor after apartment entry.
-- propertyId: non-nil when new character has a starter apartment to enter.
-- pendingSpawnPropertyId: set by confirmSpawn when returning player picks a property location.
AddEventHandler('nt_spawn:playerReady', function(coords, isNewChar, propertyId)
    -- For returning characters: close spawn NUI immediately (location picker no longer needed).
    -- For new characters: keep the creation loading overlay visible — it covers the black screen
    -- while WrapIntoProperty runs and will be dismissed just before nt_appearance:open fires.
    if not isNewChar then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end

    CreateThread(function()
        -- Fire onPlayerLoaded first — nolag_properties polls its internal property cache inside
        -- WrapIntoProperty (waiting up to 30s); that cache is only populated once this fires.
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerEvent('qbx_core:client:onPlayerLoaded')

        if isNewChar then
            if propertyId then
                -- Enter starter apartment shell. Loading overlay stays visible throughout.
                -- Screen is already black from DoScreenFadeOut in nt_character's createCharacter.
                DebugPrint('Spawn', 'New character — entering apartment: ' .. tostring(propertyId))
                Wait(1000)  -- let nolag_properties finish loading property data
                exports.nolag_properties:WrapIntoProperty(propertyId)
                Wait(500)
            else
                -- AddStarterApartment failed — teleport to default spawn
                DebugPrint('Spawn', 'New character — no apartment, using default spawn')
                local ped = PlayerPedId()
                SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
                SetEntityHeading(ped, coords.w or 0)
            end

            -- Dismiss loading overlay, then hand off to nt_appearance.
            -- nt_appearance's DoScreenFadeOut(300) is a no-op (screen already black);
            -- its DoScreenFadeIn(500) is the first thing the player sees — inside the apartment.
            SendNUIMessage({ action = 'close' })
            DebugPrint('Spawn', 'Opening appearance editor for new character')
            TriggerEvent('nt_appearance:open', spawnCitizenId, spawnGender)
            spawnGender = nil

        elseif pendingSpawnPropertyId then
            -- Returning character picked a property/apartment as spawn location.
            DebugPrint('Spawn', 'Returning character — entering property: ' .. tostring(pendingSpawnPropertyId))
            Wait(500)
            exports.nolag_properties:WrapIntoProperty(pendingSpawnPropertyId)
            pendingSpawnPropertyId = nil

            -- Fallback: if nt_appearance hasn't revealed the ped within 3 s, do it now.
            Wait(3000)
            local ped = PlayerPedId()
            if not IsEntityVisible(ped) then
                SetEntityVisible(ped, true, false)
                FreezeEntityPosition(ped, false)
                DebugPrint('Spawn', 'Fallback: revealed ped after appearance timeout')
            end

        else
            -- Default / job spawn: teleport first, then fire loaded events.
            local spawnCoords = coords or pendingSpawnCoords

            if spawnCoords then
                local ped = PlayerPedId()
                local sx, sy, sz = spawnCoords.x, spawnCoords.y, spawnCoords.z
                SetEntityCoords(ped, sx, sy, sz, false, false, false, false)
                SetEntityHeading(ped, spawnCoords.w or 0)

                -- Snap ped to ground so it doesn't float above terrain
                RequestCollisionAtCoord(sx, sy, sz)
                for _ = 1, 10 do
                    local found, gz = GetGroundZFor_3dCoord(sx, sy, sz + 2.0, false)
                    if found then
                        SetEntityCoords(ped, sx, sy, gz + 0.05, false, false, false, false)
                        break
                    end
                    Wait(100)
                end

                pendingSpawnCoords = nil
            end

            -- Fallback: if nt_appearance hasn't revealed the ped within 3 s, do it now.
            Wait(3000)
            local ped = PlayerPedId()
            if not IsEntityVisible(ped) then
                SetEntityVisible(ped, true, false)
                FreezeEntityPosition(ped, false)
                DebugPrint('Spawn', 'Fallback: revealed ped after appearance timeout')
            end
        end

        DebugPrint('Spawn', 'Player spawned and ready')
    end)
end)
