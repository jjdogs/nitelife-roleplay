local MAX_SLOTS <const> = 4

local nuiOpen      = false
local selectedChar = nil   -- citizenid of character being spawned
local spawnCamera  = nil

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
    print('[nt_character] openNUI function executing')
    SetNuiFocus(true, true)
    nuiOpen = true
    SendNUIMessage({ action = 'open', screen = screen or 'menu' })
    loadAndSendCharacters()
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

RegisterNUICallback('playCharacter', function(data, cb)
    selectedChar = data.citizenid
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
            closeNUI()
            local gender = tonumber(data.gender) or 0
            TriggerEvent('nt_appearance:open', result, gender)
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

        local ped     = PlayerPedId()
        local heading = coords.w or 0.0

        print('[nt_character] previewSpawn thread: moving ped ' .. tostring(ped))
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, heading)
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
        print('[nt_character] previewSpawn thread: ped teleported and frozen')

        if spawnCamera then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(spawnCamera, false)
            spawnCamera = nil
        end

        Wait(0)

        -- Force game to load the area
        SetFocusArea(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
        Wait(0)

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

    CreateThread(function()
        if spawnCamera then
            RenderScriptCams(false, true, 500, true, true)
            Wait(500)
            DestroyCam(spawnCamera, false)
            spawnCamera = nil
        end
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

AddEventHandler('nt_character:receiveSpawnLocations', function(locations)
    SendNUIMessage({ action = 'setSpawnLocations', locations = locations })
end)

AddEventHandler('nt_character:playerReady', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    print('[nt_character] Player spawned and ready')
end)

-- ── Resource start ────────────────────────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        print('[nt_character] onClientResourceStart fired, waiting for qbx_core...')
        -- Wait for qbx_core to be ready
        while GetResourceState('qbx_core') ~= 'started' do
            Wait(500)
        end
        print('[nt_character] qbx_core ready, shutting down loading screen...')
        Wait(1000)
        print('[nt_character] About to shutdown loading screen')
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        print('[nt_character] Loading screen shut down')
        Wait(500)
        print('[nt_character] About to open NUI')
        openNUI()
        print('[nt_character] openNUI called')
    end)
end)

-- ── External character selection (qbx_core) ──────────────────────────────────

AddEventHandler('qbx_core:client:startCharacterSelection', function()
    print('[nt_character] qbx_core:client:startCharacterSelection fired')
    print('[nt_character] About to shutdown loading screen')
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    print('[nt_character] Loading screen shut down')

    CreateThread(function()
        Wait(500)
        print('[nt_character] About to open NUI')
        openNUI()
        print('[nt_character] openNUI called')
    end)
end)
