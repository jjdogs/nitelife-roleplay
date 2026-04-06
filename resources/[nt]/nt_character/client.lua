local MAX_SLOTS <const> = 4

local nuiOpen          = false
local nuiLoaded        = false   -- true once React sends the nuiReady callback
local nuiPendingOpen   = false   -- open was requested before NUI was ready
local nuiPendingScreen = 'menu'

-- Allow inbound reply events from the server
RegisterNetEvent('nt_character:getCharacters:reply')
RegisterNetEvent('nt_character:createCharacter:reply')
RegisterNetEvent('nt_character:deleteCharacter:reply')

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
    DebugPrint('Character', 'openNUI function executing, nuiLoaded=' .. tostring(nuiLoaded))
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
        DebugPrint('Character', 'NUI not loaded yet — deferring open until nuiReady')
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
    DebugPrint('Character', 'nuiReady received — NUI page is loaded')
    nuiLoaded = true
    cb('ok')
    -- NUI is now rendering; fade the game world in behind it
    DoScreenFadeIn(800)
    if nuiPendingOpen then
        nuiPendingOpen = false
        DebugPrint('Character', 'Sending deferred open: ' .. nuiPendingScreen)
        SendNUIMessage({ action = 'open', screen = nuiPendingScreen })
        CreateThread(loadAndSendCharacters)
    end
end)

-- Player selects a character to play — close character NUI and hand off to nt_spawn
RegisterNUICallback('playCharacter', function(data, cb)
    cb('ok')
    closeNUI()
    TriggerEvent('nt_spawn:beginSpawnSelection', data.citizenid, false)
end)

RegisterNUICallback('createCharacter', function(data, cb)
    local success, result = serverCall('nt_character:createCharacter', data)
    if success then
        cb({ success = true, citizenid = result })
        -- Hand off to appearance editor
        CreateThread(function()
            Wait(100)  -- let NUI process the success response first
            DebugPrint('Character', 'Character created, citizenid: ' .. tostring(result))
            local gender = tonumber(data.gender) or 0
            -- Fade to black, then hand off to nt_spawn to enter the starter apartment.
            -- The appearance editor will open INSIDE the apartment once WrapIntoProperty
            -- completes — the screen stays black throughout so there is no visible flash.
            DoScreenFadeOut(300)
            Wait(350)
            closeNUI()
            DebugPrint('Character', 'NUI closed, handing off to nt_spawn for apartment entry...')
            TriggerEvent('nt_spawn:beginSpawnSelection', result, true, gender)
        end)
    else
        DebugPrint('Character', 'createCharacter failed: ' .. tostring(result))
        cb({ success = false, error = result or 'Unknown error' })
    end
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local success = serverCall('nt_character:deleteCharacter', data.citizenid)
    if success then
        loadAndSendCharacters()
    else
        DebugPrint('Character', 'deleteCharacter failed for ' .. tostring(data.citizenid))
    end
    cb({ success = success })
end)

RegisterNUICallback('closeUI', function(_, cb)
    closeNUI()
    cb('ok')
end)

-- ── Inbound server events ─────────────────────────────────────────────────────

RegisterNetEvent('nt_character:openNUI')
AddEventHandler('nt_character:openNUI', function()
    DebugPrint('Character', 'openNUI event received — reopening character select')
    -- qbx_core:Logout may briefly trigger the loading screen; shut it down again
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    CreateThread(function()
        Wait(500)  -- let qbx_core finish unloading player data
        openNUI()
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
-- Pattern mirrors qbx_core's recommended external character flow (docs.qbox.re):
--   Wait(1500) → ShutdownLoadingScreen() → ShutdownLoadingScreenNui() → openNUI()

CreateThread(function()
    DebugPrint('Character', 'Waiting for network session to start...')
    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    -- Disable spawnmanager auto-spawn — without this, spawnmanager holds the
    -- loading screen and spawns the player before character selection completes.
    DebugPrint('Character', 'Session started — disabling spawnmanager auto-spawn')
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

    -- Hold the screen black, then lock into the tutorial session so the engine is in
    -- the correct state before we dismiss the loading screen. This matches the qbx_core
    -- pattern from character_cl.lua (NetworkStartSoloTutorialSession → wait → 1500ms →
    -- ShutdownLoadingScreen).
    DoScreenFadeOut(0)
    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do
        Wait(0)
    end
    Wait(1500)

    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)  -- ensure ped stays hidden during char select

    DebugPrint('Character', 'Shutting down loading screen')
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    openNUI()
    DebugPrint('Character', 'openNUI called')
end)
