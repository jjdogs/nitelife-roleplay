local nuiOpen        = false
local appearanceOpen = false
local appearanceCam  = nil
local camAngle       = 0.0
local camDistance    = 0.0  -- initialised from config on open
local camHeight      = 0.6
local currentCitizenId = nil
local currentGender    = 0

local currentAppearance = {
    headBlend     = { shapeFirst = 0, shapeSecond = 0, skinFirst = 0, skinSecond = 0, shapeMix = 0.5, skinMix = 0.5 },
    faceFeatures  = {},
    hair          = 0,
    hairColor     = 0,
    hairHighlight = 0,
    headOverlays  = {},
    eyeColor      = -1,
    clothing      = {},
    props         = {},
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

    -- 3. Swap to freemode model based on character gender
    local model = currentGender == 1 and "mp_f_freemode_01" or "mp_m_freemode_01"
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
        headOverlays  = {},
        eyeColor      = -1,
        clothing      = {},
        props         = {},
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
    SendNUIMessage({ type = 'setConfig', panelPosition = Config.PanelPosition, appearanceReady = true, gender = currentGender })

    -- Fetch saved outfits for this character (if opened from character creation)
    if currentCitizenId then
        TriggerServerEvent('nt_appearance:getOutfits', currentCitizenId)
    end

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
    nuiOpen        = false
    appearanceOpen = false
    currentCitizenId = nil
    currentGender    = 0
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

-- ── Open event (called by nt_character after character creation) ───────────────

RegisterNetEvent('nt_appearance:open')
AddEventHandler('nt_appearance:open', function(citizenid, gender)
    currentCitizenId = citizenid
    currentGender    = gender or 0
    CreateThread(function()
        openAppearanceNUI()
    end)
end)

RegisterNetEvent('nt_appearance:appearanceSaved')
AddEventHandler('nt_appearance:appearanceSaved', function()
    print('[nt_appearance] Appearance saved successfully')
    closeAppearanceNUI()
    TriggerEvent('nt_appearance:complete', currentCitizenId)
end)

-- ── Commands ──────────────────────────────────────────────────────────────────

RegisterCommand('ntappearance', function(_, args)
    currentCitizenId = args[1] or nil
    if not currentCitizenId then
        local playerData = exports['qbx_core']:GetPlayerData()
        currentCitizenId = playerData and playerData.citizenid or nil
    end
    currentGender = tonumber(args[2]) or 0
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
    -- Reset all head overlays
    for i = 0, 11 do
        SetPedHeadOverlay(ped, i, 255, 0.0)
    end
    -- Reset eye color
    SetPedEyeColor(ped, -1)
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

RegisterNUICallback('setHeadOverlay', function(data, cb)
    local ped = PlayerPedId()
    if not currentAppearance.headOverlays then currentAppearance.headOverlays = {} end
    currentAppearance.headOverlays[data.overlay] = {
        style       = data.style,
        opacity     = data.opacity,
        color       = data.color,
        secondColor = data.secondColor,
    }
    if data.style == 255 then
        SetPedHeadOverlay(ped, data.overlay, 255, 0.0)
    else
        SetPedHeadOverlay(ped, data.overlay, data.style, data.opacity)
        SetPedHeadOverlayColor(ped, data.overlay, 1, data.color, data.secondColor)
    end
    cb('ok')
end)

RegisterNUICallback('setEyeColor', function(data, cb)
    local ped = PlayerPedId()
    currentAppearance.eyeColor = data.color
    SetPedEyeColor(ped, data.color)
    cb('ok')
end)

-- ── Outfit callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback('getOutfits', function(_, cb)
    if currentCitizenId then
        TriggerServerEvent('nt_appearance:getOutfits', currentCitizenId)
    end
    cb('ok')
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    if not currentCitizenId then cb('ok') return end
    local model     = currentGender == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    local compsJson = json.encode(data.components)
    local propsJson = json.encode(data.props)
    TriggerServerEvent('nt_appearance:saveOutfit', currentCitizenId, data.name, compsJson, propsJson, model)
    cb('ok')
end)

RegisterNUICallback('loadOutfit', function(data, cb)
    local ped = PlayerPedId()
    if data.components then
        for _, comp in ipairs(data.components) do
            SetPedComponentVariation(ped, comp.component_id, comp.drawable, comp.texture, 0)
            if not currentAppearance.clothing then currentAppearance.clothing = {} end
            currentAppearance.clothing[comp.component_id] = { drawable = comp.drawable, texture = comp.texture }
        end
    end
    if data.props then
        for _, prop in ipairs(data.props) do
            if prop.drawable == -1 then
                ClearPedProp(ped, prop.prop_id)
            else
                SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture, true)
            end
            if not currentAppearance.props then currentAppearance.props = {} end
            currentAppearance.props[prop.prop_id] = { drawable = prop.drawable, texture = prop.texture }
        end
    end
    cb('ok')
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    if not currentCitizenId then cb('ok') return end
    TriggerServerEvent('nt_appearance:deleteOutfit', data.id, currentCitizenId)
    cb('ok')
end)

RegisterNetEvent('nt_appearance:receiveOutfits')
AddEventHandler('nt_appearance:receiveOutfits', function(outfits)
    SendNUIMessage({ type = 'setOutfits', outfits = outfits })
end)

-- ── Save appearance ────────────────────────────────────────────────────────────

local faceFeatureNames = {
    [0]  = 'noseWidth',
    [1]  = 'nosePeakHigh',
    [2]  = 'nosePeakSize',
    [3]  = 'noseBoneHigh',
    [4]  = 'nosePeakLowering',
    [5]  = 'noseBoneTwist',
    [6]  = 'eyeBrownHigh',
    [7]  = 'eyeBrownForward',
    [8]  = 'cheeksBoneHigh',
    [9]  = 'cheeksBoneWidth',
    [10] = 'cheeksWidth',
    [11] = 'eyesOpening',
    [12] = 'lipsThickness',
    [13] = 'jawBoneWidth',
    [14] = 'jawBoneBackSize',
    [15] = 'chinBoneLenght',
    [16] = 'chinBoneLowering',
    [17] = 'chinBoneSize',
    [18] = 'chinHole',
    [19] = 'neckThickness',
}

local overlayNames = {
    [0]  = 'blemishes',
    [1]  = 'beard',
    [2]  = 'eyebrows',
    [3]  = 'ageing',
    [4]  = 'makeUp',
    [5]  = 'blush',
    [6]  = 'complexion',
    [7]  = 'sunDamage',
    [8]  = 'lipstick',
    [9]  = 'moleAndFreckles',
    [10] = 'chestHair',
    [11] = 'bodyBlemishes',
}

RegisterNUICallback('saveAppearance', function(_, cb)
    if not currentCitizenId then
        print('[nt_appearance] saveAppearance: no currentCitizenId — editor was opened via command, not nt_character')
        cb('ok')
        return
    end

    local model = currentGender == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    -- Map face features from index to named keys (illenium-appearance format)
    local faceFeatures = {}
    for i = 0, 19 do
        local name = faceFeatureNames[i]
        if name then
            faceFeatures[name] = currentAppearance.faceFeatures[i] or 0.0
        end
    end

    -- Build head overlays from stored state (illenium-appearance format)
    local headOverlays = {}
    for i = 0, 11 do
        local name = overlayNames[i]
        if name then
            local ov = currentAppearance.headOverlays and currentAppearance.headOverlays[i]
            headOverlays[name] = {
                style       = ov and ov.style       or 255,
                opacity     = ov and ov.opacity     or 0.0,
                color       = ov and ov.color       or 0,
                secondColor = ov and ov.secondColor or 0,
            }
        end
    end

    -- Build components array (all 12 slots, 0-11)
    local components = {}
    for i = 0, 11 do
        local comp = currentAppearance.clothing and currentAppearance.clothing[i]
        table.insert(components, {
            component_id = i,
            drawable     = comp and comp.drawable or 0,
            texture      = comp and comp.texture  or 0,
        })
    end

    -- Build props array (slots 0, 1, 2, 6, 7)
    local props = {}
    for _, propId in ipairs({ 0, 1, 2, 6, 7 }) do
        local prop = currentAppearance.props and currentAppearance.props[propId]
        table.insert(props, {
            prop_id  = propId,
            drawable = prop and prop.drawable or -1,
            texture  = prop and prop.texture  or -1,
        })
    end

    -- Full skin JSON matching illenium-appearance format
    local skin = {
        model      = model,
        eyeColor   = currentAppearance.eyeColor or -1,
        components = components,
        props      = props,
        headBlend  = {
            shapeFirst  = currentAppearance.headBlend.shapeFirst  or 0,
            shapeSecond = currentAppearance.headBlend.shapeSecond or 0,
            shapeThird  = 0,
            skinFirst   = currentAppearance.headBlend.skinFirst   or 0,
            skinSecond  = currentAppearance.headBlend.skinSecond  or 0,
            skinThird   = 0,
            shapeMix    = currentAppearance.headBlend.shapeMix    or 0.5,
            skinMix     = currentAppearance.headBlend.skinMix     or 0.5,
            thirdMix    = 0.0,
        },
        faceFeatures = faceFeatures,
        headOverlays = headOverlays,
        hair = {
            style     = currentAppearance.hair          or 0,
            texture   = 0,
            color     = currentAppearance.hairColor     or 0,
            highlight = currentAppearance.hairHighlight or 0,
        },
        tattoos = {},
    }

    TriggerServerEvent('nt_appearance:saveAppearance', currentCitizenId, model, json.encode(skin))
    cb('ok')
    -- NUI closes automatically when nt_appearance:appearanceSaved fires
end)
