--[[
    nt_3dminigames - 3D Minigame Framework
    Entry point and exports
]]

local isMinigameActive = false
local currentMinigame = nil
local savedMinigames = {}

--- Start a minigame
---@param nameOrConfig string|table Minigame name (from saved) or config table
---@param callback function|nil Callback function(success, data)
---@return boolean started
local function StartMinigame(nameOrConfig, callback)
    if isMinigameActive then
        UI.Notify({ title = 'Minigame', message = 'Already in a minigame', type = 'error' })
        return false
    end
    
    local config
    
    if type(nameOrConfig) == 'string' then
        -- Load from saved minigames
        config = savedMinigames[nameOrConfig]
        if not config then
            print('[nt_3dminigames] Minigame not found: ' .. nameOrConfig)
            return false
        end
    else
        config = nameOrConfig
    end
    
    if not config.type then
        print('[nt_3dminigames] Minigame config missing type')
        return false
    end
    
    isMinigameActive = true
    currentMinigame = {
        config = config,
        callback = callback,
        startTime = GetGameTimer(),
        data = {},
    }
    
    -- Lock player
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    
    -- Setup camera
    if config.camera then
        Camera.Create(config.camera.coords, config.camera.rot, config.camera.fov)
    end
    
    -- Enable cursor
    Cursor.Enable(true)
    
    -- Show instructions
    if config.instructions then
        UI.ShowInstructions(config.instructions)
    else
        UI.ShowText({
            title = config.name or 'Minigame',
            description = config.description or 'Complete the objective',
            keybind = Config.Keys.exit,
            options = {
                { label = 'Exit', keybind = 'BACKSPACE' },
            }
        })
    end
    
    -- Spawn props
    if config.holdProp then
        Props.AttachToCursor(config.holdProp, config.holdPropOffset)
    end
    
    -- Create zones
    if config.zones then
        for _, zoneData in ipairs(config.zones) do
            Zones.Create(zoneData)
        end
    end
    
    -- Preload particles
    if config.particle then
        Particles.LoadDict(config.particle.dict)
    end
    
    -- Start minigame loop based on type
    local minigameTypes = {
        pour = StartPourMinigame,
        click = StartClickMinigame,
        collect = StartCollectMinigame,
        place = StartPlaceMinigame,
    }
    
    local startFunc = minigameTypes[config.type]
    if startFunc then
        CreateThread(function()
            startFunc(config)
        end)
    else
        print('[nt_3dminigames] Unknown minigame type: ' .. config.type)
        EndMinigame(false, { error = 'Unknown type' })
        return false
    end
    
    return true
end

--- End the current minigame
---@param success boolean Whether minigame was completed successfully
---@param data table|nil Result data
local function EndMinigame(success, data)
    if not isMinigameActive then return end
    
    data = data or {}
    
    -- Cleanup
    Props.DeleteAll()
    Zones.DeleteAll()
    Particles.StopAll()
    Camera.Destroy()
    Cursor.Disable()
    UI.HideText()
    
    -- Unlock player
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    
    -- Callback
    if currentMinigame and currentMinigame.callback then
        currentMinigame.callback(success, data)
    end
    
    -- Notify
    if success then
        UI.Notify({ title = 'Complete', message = 'Minigame completed!', type = 'success' })
    else
        UI.Notify({ title = 'Cancelled', message = 'Minigame cancelled', type = 'info' })
    end
    
    isMinigameActive = false
    currentMinigame = nil
end

--- Get current minigame state
---@return boolean active, table|nil config
local function GetMinigameState()
    return isMinigameActive, currentMinigame and currentMinigame.config or nil
end

--- Register a saved minigame
---@param name string Minigame name
---@param config table Minigame configuration
local function RegisterMinigame(name, config)
    config.name = name
    savedMinigames[name] = config
    print('[nt_3dminigames] Registered minigame: ' .. name)
end

--- Get all registered minigames
---@return table
local function GetRegisteredMinigames()
    return savedMinigames
end

-- ============================================
-- MINIGAME TYPE IMPLEMENTATIONS
-- ============================================

--- Pour minigame (watering, cheese sprinkling)
function StartPourMinigame(config)
    local pourRate = config.pourRate or 1.0
    local particleHandle = nil
    local isPressing = false
    
    while isMinigameActive do
        Wait(0)
        
        Cursor.DisableControls()
        
        -- Update prop position
        Props.UpdateAttachedPosition(config.fixedHeight)
        
        -- Draw zones
        Zones.Draw(true)
        
        -- Handle pour action
        if IsDisabledControlPressed(0, Config.Controls.interact) then
            if not isPressing then
                isPressing = true
                -- Start particle effect
                if config.particle then
                    local propCoords = Props.GetAttachedCoords()
                    if propCoords then
                        particleHandle = Particles.StartLoopedAt(
                            config.particle.dict,
                            config.particle.name,
                            propCoords + (config.particle.offset or vector3(0, 0, -0.2)),
                            nil,
                            config.particle.scale or 1.0,
                            'pour_particle'
                        )
                    end
                end
            end
            
            -- Check what zone we're pouring into
            local zoneId, hitCoords = Zones.GetCursorTarget()
            if zoneId then
                local completed = Zones.AddProgress(zoneId, pourRate)
            end
            
            -- Update particle position
            if particleHandle then
                local propCoords = Props.GetAttachedCoords()
                if propCoords then
                    -- Note: Can't move particles, would need to recreate
                end
            end
        else
            if isPressing then
                isPressing = false
                -- Stop particle effect
                if particleHandle then
                    Particles.Stop('pour_particle')
                    particleHandle = nil
                end
            end
        end
        
        -- Handle look (right click)
        if Config.Camera.allowLook and IsDisabledControlPressed(0, Config.Controls.secondary) then
            Camera.HandleLook()
        end
        
        -- Check for exit
        if IsDisabledControlJustPressed(0, Config.Controls.exit) then
            EndMinigame(false, { cancelled = true })
            return
        end
        
        -- Check win condition
        if config.winCondition then
            local _, _, percent = Zones.GetTotalProgress()
            if percent >= (config.winCondition.coverage or 100) then
                EndMinigame(true, { coverage = percent })
                return
            end
        elseif Zones.AllComplete() then
            local _, _, percent = Zones.GetTotalProgress()
            EndMinigame(true, { coverage = percent })
            return
        end
    end
end

--- Click minigame (fertilizing, clicking targets)
function StartClickMinigame(config)
    local clickedTargets = {}
    local requiredClicks = config.requiredClicks or #(config.targets or {})
    
    -- Spawn target props if specified
    local targetProps = {}
    if config.targets then
        for i, target in ipairs(config.targets) do
            local prop = Props.Spawn(target.model, target.coords, target.rot)
            if prop then
                targetProps[prop] = {
                    id = target.id or i,
                    data = target.data,
                    clicked = false
                }
            end
        end
    end
    
    while isMinigameActive do
        Wait(0)
        
        Cursor.DisableControls()
        
        -- Draw zones
        Zones.Draw(false)
        
        -- Draw cursor
        Cursor.Draw()
        
        -- Handle click
        if IsDisabledControlJustPressed(0, Config.Controls.interact) then
            local hit, coords, _, entity = Raycast.FromCursor(50.0)
            
            if hit and entity then
                -- Check if it's a target prop
                if targetProps[entity] and not targetProps[entity].clicked then
                    targetProps[entity].clicked = true
                    table.insert(clickedTargets, targetProps[entity].id)
                    
                    -- Visual feedback
                    SetEntityAlpha(entity, 100, false)
                    
                    -- Play sound or particle
                    if config.clickEffect then
                        Particles.PlayAt(
                            config.clickEffect.dict or 'core',
                            config.clickEffect.name or 'ent_dst_gen_gobject',
                            coords
                        )
                    end
                    
                    -- Callback
                    if config.onTargetClick then
                        config.onTargetClick(targetProps[entity].id, entity, coords)
                    end
                end
            end
            
            -- Check zone clicks
            local zoneId = Zones.GetCursorTarget()
            if zoneId then
                Zones.AddProgress(zoneId, 1)
            end
        end
        
        -- Handle look (right click)
        if Config.Camera.allowLook and IsDisabledControlPressed(0, Config.Controls.secondary) then
            Camera.HandleLook()
        end
        
        -- Check for exit
        if IsDisabledControlJustPressed(0, Config.Controls.exit) then
            EndMinigame(false, { cancelled = true, clicked = clickedTargets })
            return
        end
        
        -- Check win condition
        if #clickedTargets >= requiredClicks then
            EndMinigame(true, { clicked = clickedTargets, count = #clickedTargets })
            return
        end
    end
end

--- Collect minigame (harvesting buds)
function StartCollectMinigame(config)
    local collected = {}
    local requiredCollections = config.requiredCollections or #(config.targets or {})
    local holdTime = config.holdTime or Config.MinigameTypes.collect.holdTime
    local currentHold = nil
    local holdProgress = 0
    
    -- Spawn collectible props
    local collectibleProps = {}
    if config.targets then
        for i, target in ipairs(config.targets) do
            local prop = Props.Spawn(target.model, target.coords, target.rot)
            if prop then
                collectibleProps[prop] = {
                    id = target.id or i,
                    data = target.data,
                    collected = false
                }
            end
        end
    end
    
    while isMinigameActive do
        Wait(0)
        
        Cursor.DisableControls()
        
        -- Draw cursor
        Cursor.Draw()
        
        -- Handle hold-to-collect
        if IsDisabledControlPressed(0, Config.Controls.interact) then
            local hit, coords, _, entity = Raycast.FromCursor(50.0)
            
            if hit and entity and collectibleProps[entity] and not collectibleProps[entity].collected then
                if currentHold ~= entity then
                    currentHold = entity
                    holdProgress = 0
                end
                
                holdProgress = holdProgress + GetFrameTime() * 1000
                
                -- Show progress
                local percent = math.min(100, (holdProgress / holdTime) * 100)
                UI.ShowText({
                    title = 'Collecting',
                    description = string.format('%d%%', percent),
                    icon = 'fas fa-hand-holding',
                })
                
                if holdProgress >= holdTime then
                    -- Collected!
                    collectibleProps[entity].collected = true
                    table.insert(collected, collectibleProps[entity].id)
                    
                    -- Delete or hide the prop
                    Props.Delete(entity)
                    
                    -- Reset
                    currentHold = nil
                    holdProgress = 0
                    
                    -- Play effect
                    if config.collectEffect then
                        Particles.PlayAt(
                            config.collectEffect.dict or 'core',
                            config.collectEffect.name or 'ent_dst_gen_gobject',
                            coords
                        )
                    end
                end
            else
                currentHold = nil
                holdProgress = 0
            end
        else
            currentHold = nil
            holdProgress = 0
        end
        
        -- Handle look (right click)
        if Config.Camera.allowLook and IsDisabledControlPressed(0, Config.Controls.secondary) then
            Camera.HandleLook()
        end
        
        -- Check for exit
        if IsDisabledControlJustPressed(0, Config.Controls.exit) then
            EndMinigame(false, { cancelled = true, collected = collected })
            return
        end
        
        -- Check win condition
        if #collected >= requiredCollections then
            EndMinigame(true, { collected = collected, count = #collected })
            return
        end
    end
end

--- Place minigame (pepperoni placement)
function StartPlaceMinigame(config)
    local placed = {}
    local requiredPlacements = config.requiredPlacements or 5
    local placementModel = config.placementModel or config.holdProp
    
    while isMinigameActive do
        Wait(0)
        
        Cursor.DisableControls()
        
        -- Update preview prop position
        Props.UpdateAttachedPosition(config.fixedHeight)
        
        -- Draw zones
        Zones.Draw(false)
        
        -- Draw cursor
        Cursor.Draw()
        
        -- Handle placement
        if IsDisabledControlJustPressed(0, Config.Controls.interact) then
            local hit, coords = Raycast.FromCursor(50.0)
            
            if hit and coords then
                -- Check if in valid placement zone
                local zoneId = Zones.GetCursorTarget()
                local canPlace = not config.requireZone or zoneId
                
                if canPlace then
                    -- Place a new prop at this location
                    local placedProp = Props.Spawn(
                        placementModel,
                        coords + (config.placementOffset or vector3(0, 0, 0.01)),
                        config.placementRot
                    )
                    
                    if placedProp then
                        table.insert(placed, {
                            prop = placedProp,
                            coords = coords,
                            zone = zoneId
                        })
                        
                        -- Play effect
                        if config.placeEffect then
                            Particles.PlayAt(
                                config.placeEffect.dict or 'core',
                                config.placeEffect.name or 'ent_dst_gen_gobject',
                                coords
                            )
                        end
                        
                        -- Update progress text
                        UI.ShowText({
                            title = 'Placing',
                            description = string.format('%d / %d', #placed, requiredPlacements),
                            icon = 'fas fa-hand-pointer',
                        })
                    end
                end
            end
        end
        
        -- Handle rotation of preview prop
        if IsDisabledControlPressed(0, Config.Controls.secondary) then
            local scroll = GetDisabledControlNormal(0, Config.Controls.scroll)
            if scroll ~= 0 then
                Props.AddAttachedRotation(vector3(0, 0, scroll * 10))
            else
                -- Allow camera look if not scrolling
                Camera.HandleLook()
            end
        end
        
        -- Check for exit
        if IsDisabledControlJustPressed(0, Config.Controls.exit) then
            EndMinigame(false, { cancelled = true, placed = placed })
            return
        end
        
        -- Check win condition
        if #placed >= requiredPlacements then
            EndMinigame(true, { placed = placed, count = #placed })
            return
        end
    end
end

-- ============================================
-- EXPORTS
-- ============================================

exports('StartMinigame', StartMinigame)
exports('EndMinigame', EndMinigame)
exports('GetMinigameState', GetMinigameState)
exports('RegisterMinigame', RegisterMinigame)
exports('GetRegisteredMinigames', GetRegisteredMinigames)

-- Core module exports
exports('Camera', function() return Camera end)
exports('Cursor', function() return Cursor end)
exports('Raycast', function() return Raycast end)
exports('Props', function() return Props end)
exports('Particles', function() return Particles end)
exports('Zones', function() return Zones end)
exports('UI', function() return UI end)

-- ============================================
-- COMMANDS (for testing)
-- ============================================

RegisterCommand('testpour', function()
    StartMinigame({
        type = 'pour',
        name = 'Test Pour',
        description = 'Pour water on all the targets',
        holdProp = 'prop_wateringcan',
        holdPropOffset = vector3(0, 0, 0.1),
        camera = {
            coords = GetEntityCoords(PlayerPedId()) + vector3(0, 2, 2),
            rot = vector3(-30, 0, 180),
            fov = 50,
        },
        zones = {
            { coords = GetEntityCoords(PlayerPedId()) + vector3(-0.5, 1, 0), size = vector3(0.3, 0.3, 0.1), maxProgress = 50 },
            { coords = GetEntityCoords(PlayerPedId()) + vector3(0, 1, 0), size = vector3(0.3, 0.3, 0.1), maxProgress = 50 },
            { coords = GetEntityCoords(PlayerPedId()) + vector3(0.5, 1, 0), size = vector3(0.3, 0.3, 0.1), maxProgress = 50 },
        },
        particle = { dict = 'core', name = 'ent_sht_water', scale = 0.5 },
        pourRate = 2.0,
        winCondition = { coverage = 100 },
    }, function(success, data)
        print('Pour minigame result:', success, json.encode(data))
    end)
end, false)

RegisterCommand('testclick', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    StartMinigame({
        type = 'click',
        name = 'Test Click',
        description = 'Click on all the targets',
        camera = {
            coords = coords + vector3(0, 2, 2),
            rot = vector3(-30, 0, 180),
            fov = 50,
        },
        targets = {
            { id = 1, model = 'prop_cs_fertilizer', coords = coords + vector3(-0.5, 1, 0) },
            { id = 2, model = 'prop_cs_fertilizer', coords = coords + vector3(0, 1, 0) },
            { id = 3, model = 'prop_cs_fertilizer', coords = coords + vector3(0.5, 1, 0) },
        },
        requiredClicks = 3,
    }, function(success, data)
        print('Click minigame result:', success, json.encode(data))
    end)
end, false)

RegisterCommand('testplace', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    StartMinigame({
        type = 'place',
        name = 'Test Place',
        description = 'Place 5 items',
        holdProp = 'prop_cs_burger_01',
        placementModel = 'prop_cs_burger_01',
        camera = {
            coords = coords + vector3(0, 1.5, 1.5),
            rot = vector3(-45, 0, 180),
            fov = 60,
        },
        zones = {
            { coords = coords + vector3(0, 1, 0), size = vector3(1, 1, 0.1), type = 'box' },
        },
        requiredPlacements = 5,
        requireZone = true,
    }, function(success, data)
        print('Place minigame result:', success, json.encode(data))
    end)
end, false)

print('[nt_3dminigames] Framework loaded')
