local nuiOpen       = false
local appearanceOpen = false
local appearanceCam  = nil
local camAngle       = 0.0
local camDistance    = 0.0  -- initialised from config on open
local camHeight      = 0.6

local currentAppearance = {
    headBlend     = { shapeFirst = 0, shapeSecond = 0, skinFirst = 0, skinSecond = 0, shapeMix = 0.5, skinMix = 0.5 },
    faceFeatures  = {},
    hair          = 0,
    hairColor     = 0,
    hairHighlight = 0,
}

-- ── Model helper ──────────────────────────────────────────────────────────────

local function loadModel(hash)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
end

-- ── Core ──────────────────────────────────────────────────────────────────────

local function openAppearanceNUI()
    local loc = Config.AppearanceLocation

    -- Reset camera orbit state
    camAngle    = 0.0
    camDistance = Config.Camera.distance
    camHeight   = 0.6

    -- 1. Wait for collision at destination before teleporting (prevents falling through ground)
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    RequestCollisionAtCoord(loc.x, loc.y, loc.z)
    local timeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    -- 2. Teleport slightly above ground, then snap to actual ground Z
    SetEntityCoords(ped, loc.x, loc.y, loc.z + 2.0, false, false, false, false)
    SetEntityHeading(ped, loc.w)
    Wait(100)
    local found, groundZ = GetGroundZFor_3dCoord(loc.x, loc.y, loc.z + 2.0, false)
    if found then
        SetEntityCoords(ped, loc.x, loc.y, groundZ, false, false, false, false)
    end
    FreezeEntityPosition(ped, true)

    -- 3. Swap to freemode model (gender set from character data in a later phase)
    local gender = 0
    local model  = gender == 1 and "mp_f_freemode_01" or "mp_m_freemode_01"
    if type(model) == "string" then model = joaat(model) end

    if IsModelInCdimage(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        SetPlayerModel(PlayerId(), model)
        Wait(150)
        SetModelAsNoLongerNeeded(model)
        SetPedDefaultComponentVariation(PlayerPedId())
    else
        print('[nt_appearance] ERROR: model not in cdimage')
        return
    end

    local ped = PlayerPedId()
    print('[nt_appearance] Model loaded, new ped handle: ' .. ped)

    -- Initialise head blend so hair colour natives work (must be called before SetPedHairColor)
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, false)

    -- Reset tracked appearance state for this session
    currentAppearance = {
        headBlend     = { shapeFirst = 0, shapeSecond = 0, skinFirst = 0, skinSecond = 0, shapeMix = 0.5, skinMix = 0.5 },
        faceFeatures  = {},
        hair          = 0,
        hairColor     = 0,
        hairHighlight = 0,
    }

    SetEntityCoords(ped, loc.x, loc.y, found and groundZ or loc.z, false, false, false, false)
    SetEntityHeading(ped, loc.w)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    -- Tear down any stale camera
    if appearanceCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(appearanceCam, false)
        appearanceCam = nil
    end

    Wait(0)

    -- 4. Position camera in FRONT of ped (positive Y = forward in entity space)
    local camCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, Config.Camera.distance, 0.6)
    local camPoint  = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.6)

    print('[nt_appearance] ped visible: ' .. tostring(IsEntityVisible(ped)))
    print('[nt_appearance] cam coords: ' .. camCoords.x .. ', ' .. camCoords.y .. ', ' .. camCoords.z)

    appearanceCam = CreateCameraWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        camCoords.x, camCoords.y, camCoords.z,
        0.0, 0.0, 0.0,
        Config.Camera.fov,
        false, 0
    )

    PointCamAtCoord(appearanceCam, camPoint.x, camPoint.y, camPoint.z)
    SetCamActive(appearanceCam, true)
    SetFocusArea(camPoint.x, camPoint.y, camPoint.z, 0.0, 0.0, 0.0)
    Wait(0)
    RenderScriptCams(true, true, 500, true, true)

    nuiOpen        = true
    appearanceOpen = true
    DisplayHud(false)
    DisplayRadar(false)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = 'open' })
    SendNUIMessage({ type = 'setConfig', panelPosition = Config.PanelPosition })
    print('[nt_appearance] Opened appearance editor')

    -- 5. Camera position tick (input handled via NUI callbacks)
    CreateThread(function()
        while appearanceOpen do
            Wait(0)
            if not appearanceCam then break end

            local ped       = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local camX      = pedCoords.x + math.sin(math.rad(camAngle)) * camDistance
            local camY      = pedCoords.y + math.cos(math.rad(camAngle)) * camDistance
            local camZ      = pedCoords.z + camHeight
            local lookTarget = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, camHeight)

            SetCamCoord(appearanceCam, camX, camY, camZ)
            PointCamAtCoord(appearanceCam, lookTarget.x, lookTarget.y, lookTarget.z)
        end
    end)

    -- 6. Control disable tick (selective — do NOT use DisableAllControlActions)
    CreateThread(function()
        while appearanceOpen do
            Wait(0)
            -- Movement
            DisableControlAction(0, 30, true)  -- Move LR
            DisableControlAction(0, 31, true)  -- Move UD
            DisableControlAction(0, 36, true)  -- Duck
            -- Combat
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon
            DisableControlAction(0, 58, true)  -- Weapon 2
            DisableControlAction(0, 44, true)  -- Cover
            DisableControlAction(0, 37, true)  -- Select Weapon
            DisableControlAction(0, 23, true)  -- Melee Attack
            -- Vehicle
            DisableControlAction(0, 71, true)  -- Accelerate
            DisableControlAction(0, 72, true)  -- Brake
            -- Interaction
            DisableControlAction(0, 51, true)  -- Context
            DisableControlAction(0, 38, true)  -- Enter
            DisableControlAction(0, 29, true)  -- Phone
        end
    end)
end

local function closeAppearanceNUI()
    nuiOpen      = false
    appearanceOpen = false
    DisplayHud(true)
    DisplayRadar(true)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    if appearanceCam then
        RenderScriptCams(false, true, 500, true, true)
        Wait(500)
        DestroyCam(appearanceCam, false)
        appearanceCam = nil
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    print('[nt_appearance] Closed appearance editor')
end

-- ── Commands ──────────────────────────────────────────────────────────────────

RegisterCommand('ntappearance', function()
    CreateThread(function()
        openAppearanceNUI()
    end)
end, false)

RegisterCommand('ntappearance_close', function()
    closeAppearanceNUI()
end, false)

-- ── NUI callbacks ─────────────────────────────────────────────────────────────

RegisterNUICallback('exitAppearance', function(_, cb)
    local ped = PlayerPedId()
    -- Reset head blend and face features
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, false)
    for i = 0, 19 do
        SetPedFaceFeature(ped, i, 0.0)
    end
    -- Reset hair
    SetPedComponentVariation(ped, 2, 0, 0, 0)
    SetPedHairColor(ped, 0, 0)
    -- Reset all clothing components to defaults
    SetPedDefaultComponentVariation(ped)
    -- Clear all props
    ClearAllPedProps(ped)
    cb('ok')
    closeAppearanceNUI()
end)

RegisterNUICallback('rotateCam', function(data, cb)
    camAngle = camAngle + (data.deltaX * 0.3)
    cb('ok')
end)

RegisterNUICallback('adjustHeight', function(data, cb)
    camHeight = math.max(0.0, math.min(1.8, camHeight - (data.deltaY * 0.005)))
    cb('ok')
end)

RegisterNUICallback('zoomCam', function(data, cb)
    if data.delta > 0 then
        camDistance = math.min(Config.Camera.zoomMax, camDistance + 0.15)
    else
        camDistance = math.max(Config.Camera.zoomMin, camDistance - 0.15)
    end
    cb('ok')
end)

-- ── Appearance callbacks ───────────────────────────────────────────────────

RegisterNUICallback('setHeadBlend', function(data, cb)
    local ped = PlayerPedId()
    currentAppearance.headBlend = data
    SetPedHeadBlendData(
        ped,
        data.shapeFirst, data.shapeSecond, 0,
        data.skinFirst,  data.skinSecond,  0,
        data.shapeMix,   data.skinMix,     0.0,
        false
    )
    -- Re-apply all stored face features — SetPedHeadBlendData resets them
    for i, v in pairs(currentAppearance.faceFeatures) do
        SetPedFaceFeature(ped, i, v)
    end
    cb('ok')
end)

RegisterNUICallback('setFaceFeature', function(data, cb)
    local ped = PlayerPedId()
    print('[nt_appearance] Face feature index: ' .. data.index .. ' value: ' .. data.value)
    currentAppearance.faceFeatures[data.index] = data.value
    SetPedFaceFeature(ped, data.index, data.value)
    cb('ok')
end)

RegisterNUICallback('setHair', function(data, cb)
    local ped = PlayerPedId()
    currentAppearance.hair = data.hair
    SetPedComponentVariation(ped, 2, data.hair, 0, 0)
    -- Re-apply current hair color — changing drawable resets it
    SetPedHairColor(ped, currentAppearance.hairColor, currentAppearance.hairHighlight)
    cb('ok')
end)

RegisterNUICallback('setClothing', function(data, cb)
    local ped = PlayerPedId()
    print('[nt_appearance] Component ' .. data.component .. ' drawable: ' .. data.drawable .. ' texture: ' .. data.texture)
    SetPedComponentVariation(ped, data.component, data.drawable, data.texture, 0)
    if not currentAppearance.clothing then currentAppearance.clothing = {} end
    currentAppearance.clothing[data.component] = { drawable = data.drawable, texture = data.texture }
    cb('ok')
end)

RegisterNUICallback('setProp', function(data, cb)
    local ped = PlayerPedId()
    if data.drawable == -1 then
        print('[nt_appearance] Clearing prop ' .. data.prop)
        ClearPedProp(ped, data.prop)
    else
        print('[nt_appearance] Prop ' .. data.prop .. ' drawable: ' .. data.drawable .. ' texture: ' .. data.texture)
        SetPedPropIndex(ped, data.prop, data.drawable, data.texture, true)
    end
    if not currentAppearance.props then currentAppearance.props = {} end
    currentAppearance.props[data.prop] = { drawable = data.drawable, texture = data.texture }
    cb('ok')
end)

RegisterNUICallback('setHairColor', function(data, cb)
    local ped = PlayerPedId()
    print('[nt_appearance] Setting hair color: ' .. data.color .. ' highlight: ' .. data.highlight)
    currentAppearance.hairColor    = data.color
    currentAppearance.hairHighlight = data.highlight
    SetPedHairColor(ped, data.color, data.highlight)
    cb('ok')
end)
