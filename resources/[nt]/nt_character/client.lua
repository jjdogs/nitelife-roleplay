local MAX_SLOTS <const> = 4

local nuiOpen          = false
local nuiLoaded        = false   -- true once React sends the nuiReady callback
local nuiPendingOpen   = false   -- open was requested before NUI was ready
local nuiPendingScreen = 'menu'
local selectedChar     = nil     -- citizenid of character being spawned
local spawnCamera      = nil
local pendingSpawnCoords = nil   -- spawn coords stored by confirmSpawn, consumed by playerReady

-- Allow inbound reply events from the server
RegisterNetEvent('nt_character:getCharacters:reply')
RegisterNetEvent('nt_character:createCharacter:reply')
RegisterNetEvent('nt_character:deleteCharacter:reply')
RegisterNetEvent('nt_character:receiveSpawnLocations')
RegisterNetEvent('nt_character:playerReady')

-- ── Server call helper ────────────────────────────────────────────────────────
-- Triggers a net event, waits for the matching :reply event, returns its args.
local function serverCall(event, ...)
    local p       = promise.new()
    local handler = AddEventHandler(event .. ':reply', function(...)
        p:resolve({ ... })
    end)
    TriggerServerEvent(event, ...)
    local res = Citizen.Await(p)
    RemoveEventHandler(handler)
    return table.unpack(res)
end

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function loadAndSendCharacters()
    local characters = serverCall('nt_character:getCharacters')
    SendNUIMessage({
        action     = 'setCharacters',
        characters = characters or {},
        maxSlots   = MAX_SLOTS
    })
end

local function openNUI(screen)
    print('[nt_character] openNUI function executing, nuiLoaded=' .. tostring(nuiLoaded))
    SetNuiFocus(true, true)
    nuiOpen = true
    if nuiLoaded then
        -- NUI is already loaded and listener is ready — send immediately
        SendNUIMessage({ action = 'open', screen = screen or 'menu' })
        loadAndSendCharacters()
    else
        -- NUI page not ready yet — defer until nuiReady fires
        nuiPendingOpen   = true
        nuiPendingScreen = screen or 'menu'
        print('[nt_character] NUI not loaded yet — deferring open until nuiReady')
    end
end

local function closeNUI()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ── Commands ──────────────────────────────────────────────────────────────────

RegisterCommand('ntchar', function()
    CreateThread(function() openNUI('menu') end)
end, false)

RegisterCommand('ntchar_close', function()
    closeNUI()
end, false)

RegisterCommand('ntchar_create', function()
    CreateThread(function() openNUI('create') end)
end, false)

RegisterCommand('ntchar_delete', function()
    CreateThread(function() openNUI('delete') end)
end, false)

-- ── NUI callbacks ─────────────────────────────────────────────────────────────

-- nuiReady: React sends this on mount so Lua knows the message listener is active
RegisterNUICallback('nuiReady', function(_, cb)
    print('[nt_character] nuiReady received — NUI page is loaded')
    nuiLoaded = true
    cb('ok')
    -- NUI is now rendering; fade the game world in behind it
    DoScreenFadeIn(800)
    if nuiPendingOpen then
        nuiPendingOpen = false
        print('[nt_character] Sending deferred open: ' .. nuiPendingScreen)
        SendNUIMessage({ action = 'open', screen = nuiPendingScreen })
        CreateThread(loadAndSendCharacters)
    end
end)

RegisterNUICallback('playCharacter', function(data, cb)
    selectedChar = data.citizenid
    -- End the implicit FiveM tutorial session so the game world renders in the spawn preview.
    -- qbx_core's character.lua normally does NetworkStartSoloTutorialSession() then
    -- NetworkEndTutorialSession() after spawn, but since it returns early for external
    -- characters we are still in the default tutorial session from connect.
    NetworkEndTutorialSession()
    TriggerServerEvent('nt_character:getSpawnLocations', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    local success, result = serverCall('nt_character:createCharacter', data)
    if success then
        cb({ success = true, citizenid = result })
        -- Hand off to appearance editor
        CreateThread(function()
            Wait(100)  -- let NUI process the success response first
            print('[nt_character] Character created, citizenid: ' .. tostring(result))
            print('[nt_character] Closing NUI and handing off to nt_appearance...')
            local gender = tonumber(data.gender) or 0
            -- Fade to black so there is no visible flash between NUI close and the
            -- appearance editor opening (model swap + server call + camera init take time).
            DoScreenFadeOut(300)
            Wait(350)
            closeNUI()
            print('[nt_character] NUI closed, firing nt_appearance:open event...')
            TriggerEvent('nt_appearance:open', result, gender)
            print('[nt_character] Event fired')
        end)
    else
        print('[nt_character] createCharacter failed: ' .. tostring(result))
        cb({ success = false, error = result or 'Unknown error' })
    end
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local success = serverCall('nt_character:deleteCharacter', data.citizenid)
    if success then
        loadAndSendCharacters()
    else
        print('[nt_character] deleteCharacter failed for ' .. tostring(data.citizenid))
    end
    cb({ success = success })
end)

RegisterNUICallback('previewSpawn', function(data, cb)
    print('[nt_character] previewSpawn triggered')
    print('[nt_character] coords: ' .. json.encode(data.coords))

    -- Capture into locals before cb() — data table may be invalidated after cb returns
    local coords = data.coords
    cb('ok')

    CreateThread(function()
        print('[nt_character] previewSpawn thread: started')

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

        print('[nt_character] previewSpawn thread: ped repositioned and hidden')

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

        print('[nt_character] previewSpawn thread: creating camera at ' .. tostring(camX) .. ', ' .. tostring(camY) .. ', ' .. tostring(camZ))

        spawnCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(spawnCamera, camX, camY, camZ)
        PointCamAtCoord(spawnCamera, coords.x, coords.y, coords.z)
        SetCamFov(spawnCamera, 60.0)
        SetCamActive(spawnCamera, true)

        Wait(0)

        RenderScriptCams(true, true, 500, true, true)
        print('[nt_character] RenderScriptCams called')

        Wait(600)
        print('[nt_character] IsCamRendering: ' .. tostring(IsCamRendering()))
    end)
end)

RegisterNUICallback('confirmSpawn', function(data, cb)
    -- Capture into locals before cb() — data table may be invalidated after cb returns
    local citizenid = data.citizenid
    local coords    = data.coords
    cb('ok')

    -- Store so playerReady handler can use them for spawnmanager and to position the ped
    pendingSpawnCoords = coords

    CreateThread(function()
        if spawnCamera then
            RenderScriptCams(false, true, 500, true, true)
            Wait(500)
            DestroyCam(spawnCamera, false)
            spawnCamera = nil
        end
        -- Release streaming focus set by SetFocusArea during previewSpawn
        ClearFocus()
        TriggerServerEvent('nt_character:spawnPlayer', citizenid, coords)
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
        selectedChar = nil
    end)
end)

RegisterNUICallback('closeUI', function(_, cb)
    closeNUI()
    cb('ok')
end)

-- ── Inbound server events ─────────────────────────────────────────────────────

RegisterNetEvent('nt_character:openNUI')
AddEventHandler('nt_character:openNUI', function()
    print('[nt_character] openNUI event received — reopening character select')
    -- qbx_core:Logout may briefly trigger the loading screen; shut it down again
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    CreateThread(function()
        Wait(500)  -- let qbx_core finish unloading player data
        openNUI()
    end)
end)

AddEventHandler('nt_character:receiveSpawnLocations', function(locations)
    SendNUIMessage({ action = 'setSpawnLocations', locations = locations })
end)

AddEventHandler('nt_character:playerReady', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    CreateThread(function()
        local ped = PlayerPedId()

        -- Teleport to the confirmed spawn location (spawnmanager was already called
        -- during previewSpawn; here we just place the ped at the chosen coords).
        if pendingSpawnCoords then
            local sx, sy, sz = pendingSpawnCoords.x, pendingSpawnCoords.y, pendingSpawnCoords.z
            SetEntityCoords(ped, sx, sy, sz, false, false, false, false)
            SetEntityHeading(ped, pendingSpawnCoords.w or 0)

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

        -- nt_appearance:applyAppearance will reveal the ped once the skin is loaded.
        -- Fire both the QBCore bridge event and the native qbx_core event so the
        -- nt_appearance handler (which listens on qbx_core:client:onPlayerLoaded) fires.
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerEvent('qbx_core:client:onPlayerLoaded')

        -- Fallback: if nt_appearance hasn't revealed the ped within 3 s, do it now.
        Wait(3000)
        ped = PlayerPedId()
        if not IsEntityVisible(ped) then
            SetEntityVisible(ped, true, false)
            FreezeEntityPosition(ped, false)
            print('[nt_character] Fallback: revealed ped after appearance timeout')
        end

        print('[nt_character] Player spawned and ready')
    end)
end)

-- ── nt_appearance handoff (new character flow) ───────────────────────────────
--
-- After a new character completes the appearance editor, nt_appearance fires
-- this local event so we can show the spawn location picker.

AddEventHandler('nt_appearance:complete', function(citizenid)
    print('[nt_character] nt_appearance:complete received for citizenid: ' .. tostring(citizenid))
    if not citizenid then
        print('[nt_character] ERROR: nt_appearance:complete fired with nil citizenid — skipping spawn')
        return
    end
    selectedChar = citizenid
    CreateThread(function()
        -- Fade to black during transition back to spawn screen
        DoScreenFadeOut(300)
        Wait(350)

        -- Fetch updated character list so we can find the new char's display data
        local characters = serverCall('nt_character:getCharacters')
        local spawnChar = nil
        for _, char in ipairs(characters or {}) do
            if char.citizenid == citizenid then spawnChar = char; break end
        end
        if not spawnChar then
            print('[nt_character] ERROR: character ' .. tostring(citizenid) .. ' not found after appearance save')
            DoScreenFadeIn(500)
            return
        end

        -- End tutorial session so the preview camera can render the game world
        NetworkEndTutorialSession()

        -- Re-open NUI directly (nuiLoaded is still true from initial open)
        SetNuiFocus(true, true)
        nuiOpen = true
        SendNUIMessage({ action = 'setCharacters',    characters = characters, maxSlots = MAX_SLOTS })
        SendNUIMessage({ action = 'setSpawnCharacter', character  = spawnChar })
        SendNUIMessage({ action = 'open',              screen     = 'spawn' })
        DoScreenFadeIn(400)

        print('[nt_character] Requesting spawn locations for new character: ' .. citizenid)
        TriggerServerEvent('nt_character:getSpawnLocations', citizenid)
    end)
end)

-- ── Session-based character selection trigger ────────────────────────────────
--
-- qbx_core/client/character.lua returns early when useExternalCharacters = true,
-- which means it never calls:
--   - exports.spawnmanager:setAutoSpawn(false)  → spawnmanager holds the loading screen
--   - ShutdownLoadingScreen() / ShutdownLoadingScreenNui()
--   - chooseCharacter()
--
-- We replicate that exact pattern here so the timing is identical.

CreateThread(function()
    print('[nt_character] Waiting for network session to start...')
    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    -- Disable spawnmanager auto-spawn — without this, spawnmanager holds the
    -- loading screen and spawns the player before character selection completes.
    print('[nt_character] Session started — disabling spawnmanager auto-spawn')
    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)

    -- Spawn the player at a safe default location while still behind the loading screen.
    -- This transitions the ped from pre-spawn state to spawned state, which is required
    -- for RenderScriptCams to work in the preview camera later. The ped is invisible at
    -- this point because nothing has made it visible yet.
    pcall(function()
        exports.spawnmanager:spawnPlayer({
            x = -1037.0, y = -2738.0, z = 20.0, heading = 0,
        })
    end)
    Wait(800)  -- let spawnmanager finish before loading screen drops
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)  -- ensure ped stays hidden during char select

    Wait(200)

    -- Hold the game screen black before dismissing the loading screen NUI so there
    -- is no visible flash of the unrendered world in the gap before the character
    -- select NUI appears.
    DoScreenFadeOut(0)
    Wait(50)

    print('[nt_character] About to shutdown loading screen')
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    print('[nt_character] Loading screen shut down')

    Wait(200)

    print('[nt_character] About to open NUI')
    openNUI()
    print('[nt_character] openNUI called')
end)
