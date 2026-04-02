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

-- ── Idle animation ────────────────────────────────────────────────────────────

local function PlayIdleAnim(ped)
    local animDict = currentGender == 1
        and 'amb@world_human_stand_impatient@female@base'
        or  'amb@world_human_stand_impatient@male@base'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(100) end
    TaskPlayAnim(ped, animDict, 'base', 3.0, 3.0, -1, 1, 0, false, false, false)
end

-- ── Core ──────────────────────────────────────────────────────────────────────

local function openAppearanceNUI()
    print('[nt_appearance] openAppearanceNUI called')

    -- Fade to black while setting up (model swap + server call + camera init)
    -- so there is no visible flash during the transition from either the character
    -- selector or the open world. If nt_character already faded out this is a no-op.
    DoScreenFadeOut(300)
    Wait(350)

    -- Reset camera orbit state
    camAngle    = 0.0
    camDistance = Config.Camera.distance
    camHeight   = 0.6

    -- 1. Capture current position — editor opens in-place, no teleport
    local ped = PlayerPedId()
    local currentCoords  = GetEntityCoords(ped)
    local currentHeading = GetEntityHeading(ped)

    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)

    -- 2. Swap to freemode model based on character gender
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

    -- Restore position after model swap (SetPlayerModel can reset coords)
    SetEntityCoords(ped, currentCoords.x, currentCoords.y, currentCoords.z, false, false, false, false)
    SetEntityHeading(ped, currentHeading)
    -- Snap to ground in case the stored position is slightly above terrain
    Wait(100)
    for _ = 1, 5 do
        local found, gz = GetGroundZFor_3dCoord(currentCoords.x, currentCoords.y, currentCoords.z + 2.0, false)
        if found then
            SetEntityCoords(ped, currentCoords.x, currentCoords.y, gz + 0.05, false, false, false, false)
            break
        end
        Wait(100)
    end
    FreezeEntityPosition(ped, true)

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

    -- ── Pre-populate editor with saved appearance ─────────────────────────────
    -- If this character already has a saved skin, load it so the editor opens
    -- showing their current look rather than a bare default ped.
    local nuiInitAppearance = nil
    if currentCitizenId then
        local p = promise.new()
        local editHandler = AddEventHandler('nt_appearance:receiveAppearanceForEdit', function(skinData)
            p:resolve(skinData)
        end)
        TriggerServerEvent('nt_appearance:getAppearanceForEdit', currentCitizenId)
        local skinJson = Citizen.Await(p)
        RemoveEventHandler(editHandler)

        if skinJson then
            local skin = json.decode(skinJson)
            if skin then
                ped = PlayerPedId()

                -- Head blend
                if skin.headBlend then
                    local h = skin.headBlend
                    SetPedHeadBlendData(ped,
                        h.shapeFirst or 0, h.shapeSecond or 0, h.shapeThird or 0,
                        h.skinFirst or 0, h.skinSecond or 0, h.skinThird or 0,
                        h.shapeMix or 0.5, h.skinMix or 0.5, h.thirdMix or 0.0, false)
                    currentAppearance.headBlend = {
                        shapeFirst = h.shapeFirst or 0, shapeSecond = h.shapeSecond or 0,
                        skinFirst  = h.skinFirst  or 0, skinSecond  = h.skinSecond  or 0,
                        shapeMix   = h.shapeMix   or 0.5, skinMix   = h.skinMix    or 0.5,
                    }
                end

                -- Face features
                local featureOrder = {
                    'noseWidth','nosePeakHigh','nosePeakSize','noseBoneHigh','nosePeakLowering',
                    'noseBoneTwist','eyeBrownHigh','eyeBrownForward','cheeksBoneHigh','cheeksBoneWidth',
                    'cheeksWidth','eyesOpening','lipsThickness','jawBoneWidth','jawBoneBackSize',
                    'chinBoneLenght','chinBoneLowering','chinBoneSize','chinHole','neckThickness',
                }
                local faceArr = {}
                if skin.faceFeatures then
                    for i, name in ipairs(featureOrder) do
                        local v = skin.faceFeatures[name] or 0.0
                        SetPedFaceFeature(ped, i - 1, v)
                        currentAppearance.faceFeatures[i - 1] = v
                        faceArr[i] = v  -- 1-indexed Lua table → 0-indexed JSON array
                    end
                end

                -- Hair
                if skin.hair then
                    SetPedComponentVariation(ped, 2, skin.hair.style or 0, 0, 0)
                    SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
                    currentAppearance.hair          = skin.hair.style     or 0
                    currentAppearance.hairColor     = skin.hair.color     or 0
                    currentAppearance.hairHighlight = skin.hair.highlight or 0
                end

                -- Head overlays
                local overlayNameMap = {
                    blemishes=0,beard=1,eyebrows=2,ageing=3,makeUp=4,blush=5,
                    complexion=6,sunDamage=7,lipstick=8,moleAndFreckles=9,chestHair=10,bodyBlemishes=11,
                }
                local overlaysNUI = {}
                for name, idx in pairs(overlayNameMap) do
                    local ov = skin.headOverlays and skin.headOverlays[name]
                    local entry = {
                        style       = ov and ov.style       or 255,
                        opacity     = ov and ov.opacity     or 0.0,
                        color       = ov and ov.color       or 0,
                        secondColor = ov and ov.secondColor or 0,
                    }
                    if ov and ov.style ~= 255 then
                        SetPedHeadOverlay(ped, idx, ov.style or 0, ov.opacity or 0.0)
                        if (ov.color or 0) >= 0 then
                            SetPedHeadOverlayColor(ped, idx, 1, ov.color or 0, ov.secondColor or 0)
                        end
                    end
                    currentAppearance.headOverlays[idx] = entry
                    overlaysNUI[tostring(idx)] = entry
                end

                -- Eye color
                currentAppearance.eyeColor = skin.eyeColor or -1
                if skin.eyeColor and skin.eyeColor >= 0 then
                    SetPedEyeColor(ped, skin.eyeColor)
                end

                -- Components / clothing
                local clothingNUI = {}
                if skin.components then
                    for _, comp in ipairs(skin.components) do
                        local cid = comp.component_id
                        SetPedComponentVariation(ped, cid, comp.drawable or 0, comp.texture or 0, 0)
                        currentAppearance.clothing[cid] = { drawable = comp.drawable or 0, texture = comp.texture or 0 }
                        clothingNUI[tostring(cid)]       = { drawable = comp.drawable or 0, texture = comp.texture or 0 }
                    end
                end

                -- Props
                local propsNUI = {}
                if skin.props then
                    for _, prop in ipairs(skin.props) do
                        local pid = prop.prop_id
                        if (prop.drawable or -1) == -1 then
                            ClearPedProp(ped, pid)
                        else
                            SetPedPropIndex(ped, pid, prop.drawable, prop.texture or 0, true)
                        end
                        currentAppearance.props[pid] = { drawable = prop.drawable or -1, texture = prop.texture or 0 }
                        propsNUI[tostring(pid)]       = { drawable = prop.drawable or -1, texture = prop.texture or 0 }
                    end
                end

                -- Build the NUI init payload to pre-populate sliders
                nuiInitAppearance = {
                    headBlend     = currentAppearance.headBlend,
                    faceFeatures  = faceArr,
                    hair          = currentAppearance.hair,
                    hairColor     = currentAppearance.hairColor,
                    hairHighlight = currentAppearance.hairHighlight,
                    clothing      = clothingNUI,
                    props         = propsNUI,
                    overlays      = overlaysNUI,
                    eyeColor      = currentAppearance.eyeColor,
                }
            end
        end
    end

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
    print('[nt_appearance] SetNuiFocus called')
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    print('[nt_appearance] SendNUIMessage open sent')
    SendNUIMessage({ action = 'open' })
    SendNUIMessage({
        type            = 'setConfig',
        panelPosition   = Config.PanelPosition,
        appearanceReady = true,
        gender          = currentGender,
    })
    -- Send saved appearance to pre-populate sliders if we loaded one
    if nuiInitAppearance then
        nuiInitAppearance.type = 'initAppearance'
        SendNUIMessage(nuiInitAppearance)
    end

    -- Camera and NUI are ready — fade the screen in to reveal the editor
    DoScreenFadeIn(500)

    -- Play idle anim in its own thread so tick setup isn't delayed
    CreateThread(function() PlayIdleAnim(PlayerPedId()) end)

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

            local ped        = PlayerPedId()
            local pedCoords  = GetEntityCoords(ped)
            local camX       = pedCoords.x + math.sin(math.rad(camAngle)) * camDistance
            local camY       = pedCoords.y + math.cos(math.rad(camAngle)) * camDistance
            local camZ       = pedCoords.z + camHeight
            local lookTarget = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, camHeight)

            SetCamCoord(appearanceCam, camX, camY, camZ)
            PointCamAtCoord(appearanceCam, lookTarget.x, lookTarget.y, lookTarget.z)
        end
    end)

    -- 6. Control disable tick
    CreateThread(function()
        while appearanceOpen do
            Wait(0)
            -- Movement
            DisableControlAction(0, 30,  true)  -- Move LR
            DisableControlAction(0, 31,  true)  -- Move UD
            DisableControlAction(0, 36,  true)  -- Duck
            -- Combat
            DisableControlAction(0, 24,  true)  -- Attack
            DisableControlAction(0, 25,  true)  -- Aim
            DisableControlAction(0, 47,  true)  -- Weapon
            DisableControlAction(0, 58,  true)  -- Weapon 2
            DisableControlAction(0, 44,  true)  -- Cover
            DisableControlAction(0, 37,  true)  -- Select Weapon
            DisableControlAction(0, 23,  true)  -- Melee Attack
            -- Vehicle
            DisableControlAction(0, 71,  true)  -- Accelerate
            DisableControlAction(0, 72,  true)  -- Brake
            -- Interaction / phone
            DisableControlAction(0, 51,  true)  -- Context
            DisableControlAction(0, 38,  true)  -- Enter
            DisableControlAction(0, 29,  true)  -- Phone (B key)
            -- Chat and frontend keys
            DisableControlAction(0, 245, true)  -- INPUT_TALK (T - chat)
            DisableControlAction(0, 199, true)  -- INPUT_FRONTEND_SOCIAL_CLUB
            DisableControlAction(0, 200, true)  -- INPUT_FRONTEND_SOCIAL_CLUB_SECONDARY
            DisableControlAction(0, 166, true)  -- INPUT_SCRIPT_PAD_LEFT
            DisableControlAction(0, 167, true)  -- INPUT_SCRIPT_PAD_RIGHT
            DisableControlAction(0, 168, true)  -- INPUT_SCRIPT_PAD_UP
            DisableControlAction(0, 169, true)  -- INPUT_SCRIPT_PAD_DOWN
            DisableControlAction(0, 182, true)  -- INPUT_FRONTEND_DOWN
            DisableControlAction(0, 183, true)  -- INPUT_FRONTEND_UP
            DisableControlAction(0, 184, true)  -- INPUT_FRONTEND_LEFT
            DisableControlAction(0, 185, true)  -- INPUT_FRONTEND_RIGHT
            DisableControlAction(0, 186, true)  -- INPUT_FRONTEND_RDOWN
            DisableControlAction(0, 187, true)  -- INPUT_FRONTEND_RUP
            DisableControlAction(0, 188, true)  -- INPUT_FRONTEND_RLEFT
            DisableControlAction(0, 189, true)  -- INPUT_FRONTEND_RRIGHT
            DisableControlAction(0, 194, true)  -- INPUT_FRONTEND_ACCEPT
            DisableControlAction(0, 195, true)  -- INPUT_FRONTEND_CANCEL
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

    -- Release streaming focus set by SetFocusArea during editor open
    ClearFocus()

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    print('[nt_appearance] Closed appearance editor')
end

-- ── Open event (called by nt_character after character creation) ───────────────

RegisterNetEvent('nt_appearance:open')
AddEventHandler('nt_appearance:open', function(citizenid, gender)
    print('[nt_appearance] Received open event for citizenid: ' .. tostring(citizenid) .. ', gender: ' .. tostring(gender))
    currentCitizenId = citizenid
    currentGender    = gender or 0
    CreateThread(function()
        openAppearanceNUI()
    end)
end)

RegisterNetEvent('nt_appearance:appearanceSaved')
AddEventHandler('nt_appearance:appearanceSaved', function()
    print('[nt_appearance] Appearance saved successfully')
    -- Capture before closeAppearanceNUI() nils currentCitizenId
    local savedCitizenId = currentCitizenId
    closeAppearanceNUI()
    print('[nt_appearance] Firing nt_appearance:complete for citizenid: ' .. tostring(savedCitizenId))
    TriggerEvent('nt_appearance:complete', savedCitizenId)
end)

-- ── Commands ──────────────────────────────────────────────────────────────────

RegisterCommand('ntappearance', function(_, args)
    currentCitizenId = args[1] or nil
    local playerData = exports['qbx_core']:GetPlayerData()
    if not currentCitizenId then
        currentCitizenId = playerData and playerData.citizenid or nil
    end
    -- If gender is not explicitly passed, read it from the character's charinfo
    if args[2] then
        currentGender = tonumber(args[2]) or 0
    else
        currentGender = (playerData and playerData.charinfo and playerData.charinfo.gender) or 0
    end
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
    -- Stop anim
    ClearPedTasks(ped)
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

-- ── Appearance callbacks ───────────────────────────────────────────────────────

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
    SetPedComponentVariation(ped, data.component, data.drawable, data.texture, 0)
    if not currentAppearance.clothing then currentAppearance.clothing = {} end
    currentAppearance.clothing[data.component] = { drawable = data.drawable, texture = data.texture }
    cb('ok')
end)

RegisterNUICallback('setProp', function(data, cb)
    local ped = PlayerPedId()
    if data.drawable == -1 then
        ClearPedProp(ped, data.prop)
    else
        SetPedPropIndex(ped, data.prop, data.drawable, data.texture, true)
    end
    if not currentAppearance.props then currentAppearance.props = {} end
    currentAppearance.props[data.prop] = { drawable = data.drawable, texture = data.texture }
    cb('ok')
end)

RegisterNUICallback('setHairColor', function(data, cb)
    local ped = PlayerPedId()
    currentAppearance.hairColor     = data.color
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

-- ── Apply appearance ───────────────────────────────────────────────────────────

-- Allow server to push the saved skin for the appearance editor pre-population
RegisterNetEvent('nt_appearance:receiveAppearanceForEdit')

local function ApplyAppearance(model, skinJson)
    local ped = PlayerPedId()

    if model then
        local modelHash = joaat(model)
        if IsModelInCdimage(modelHash) then
            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do Wait(0) end
            SetPlayerModel(PlayerId(), modelHash)
            Wait(150)
            SetModelAsNoLongerNeeded(modelHash)
            SetPedDefaultComponentVariation(PlayerPedId())
        end
    end

    if not skinJson then return end
    local skin = json.decode(skinJson)
    if not skin then return end
    ped = PlayerPedId()

    -- Head blend (must come first — resets face features, so apply features after)
    if skin.headBlend then
        local h = skin.headBlend
        SetPedHeadBlendData(ped,
            h.shapeFirst  or 0, h.shapeSecond  or 0, h.shapeThird  or 0,
            h.skinFirst   or 0, h.skinSecond   or 0, h.skinThird   or 0,
            h.shapeMix    or 0.5, h.skinMix    or 0.5, h.thirdMix  or 0.0,
            false
        )
    end

    -- Face features
    if skin.faceFeatures then
        local featureMap = {
            noseWidth=0,       nosePeakHigh=1,    nosePeakSize=2,    noseBoneHigh=3,
            nosePeakLowering=4,noseBoneTwist=5,   eyeBrownHigh=6,    eyeBrownForward=7,
            cheeksBoneHigh=8,  cheeksBoneWidth=9, cheeksWidth=10,    eyesOpening=11,
            lipsThickness=12,  jawBoneWidth=13,   jawBoneBackSize=14,chinBoneLenght=15,
            chinBoneLowering=16,chinBoneSize=17,  chinHole=18,       neckThickness=19,
        }
        for name, index in pairs(featureMap) do
            if skin.faceFeatures[name] then
                SetPedFaceFeature(ped, index, skin.faceFeatures[name])
            end
        end
    end

    -- Head overlays
    if skin.headOverlays then
        local overlayMap = {
            blemishes=0, beard=1,     eyebrows=2,      ageing=3,   makeUp=4,
            blush=5,     complexion=6,sunDamage=7,      lipstick=8,
            moleAndFreckles=9,        chestHair=10,    bodyBlemishes=11,
        }
        for name, index in pairs(overlayMap) do
            local overlay = skin.headOverlays[name]
            if overlay then
                SetPedHeadOverlay(ped, index, overlay.style or 0, overlay.opacity or 0.0)
                if (overlay.color or 0) >= 0 then
                    SetPedHeadOverlayColor(ped, index, 1, overlay.color or 0, overlay.secondColor or 0)
                end
            end
        end
    end

    -- Hair (must come after head blend — SetPedHairColor requires it)
    if skin.hair then
        SetPedComponentVariation(ped, 2, skin.hair.style or 0, skin.hair.texture or 0, 0)
        SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
    end

    -- Eye color
    if skin.eyeColor and skin.eyeColor >= 0 then
        SetPedEyeColor(ped, skin.eyeColor)
    end

    -- Components
    if skin.components then
        for _, comp in ipairs(skin.components) do
            SetPedComponentVariation(ped, comp.component_id, comp.drawable or 0, comp.texture or 0, 0)
        end
    end

    -- Props
    if skin.props then
        for _, prop in ipairs(skin.props) do
            if prop.drawable == -1 then
                ClearPedProp(ped, prop.prop_id)
            else
                SetPedPropIndex(ped, prop.prop_id, prop.drawable or 0, prop.texture or 0, true)
            end
        end
    end
end

RegisterNetEvent('nt_appearance:applyAppearance')
AddEventHandler('nt_appearance:applyAppearance', function(model, skinJson)
    CreateThread(function()
        local ped = PlayerPedId()
        -- Save position because ApplyAppearance calls SetPlayerModel which resets coords
        local savedCoords  = GetEntityCoords(ped)
        local savedHeading = GetEntityHeading(ped)

        ApplyAppearance(model, skinJson)

        -- Restore position after model swap
        ped = PlayerPedId()
        SetEntityCoords(ped, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
        SetEntityHeading(ped, savedHeading)

        -- Reveal ped now that skin is applied (editor manages its own visibility)
        if not appearanceOpen then
            SetEntityVisible(ped, true, false)
            FreezeEntityPosition(ped, false)
        end
    end)
end)

AddEventHandler('qbx_core:client:onPlayerLoaded', function()
    local playerData = exports.qbx_core:GetPlayerData()
    if not playerData or not playerData.citizenid then return end
    TriggerServerEvent('nt_appearance:loadAppearance', playerData.citizenid)
end)

exports('ApplyAppearance', ApplyAppearance)
exports('LoadAppearance', function(citizenid)
    TriggerServerEvent('nt_appearance:loadAppearance', citizenid)
end)
