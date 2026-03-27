--[[
    nt_3dminigames - 3D Minigame Framework
    Core framework only — no minigame implementations.
    Minigame types are registered externally via RegisterMinigameType().
]]

local isMinigameActive = false
local currentMinigame = nil
local savedMinigames = {}
local registeredTypes = {}  -- populated by minigame type modules

--- Resolve offset-based config fields to absolute coordinates
---@param config table Minigame configuration (may use offset patterns)
---@param origin vector3 Activation point to resolve offsets from
---@return table Resolved config with absolute coords
local function ResolveConfigOffsets(config, origin)
    local resolved = {}
    for k, v in pairs(config) do
        resolved[k] = v
    end

    -- Resolve camera from offset
    if config.cameraOffset and not config.camera then
        resolved.camera = {
            coords = origin + config.cameraOffset,
            rot    = config.cameraRot or vector3(-30, 0, 180),
            fov    = config.cameraFov or 50,
        }
    end

    -- Resolve zones from pattern
    if config.zonePattern and not config.zones then
        resolved.zones = {}
        for _, pattern in ipairs(config.zonePattern) do
            local zone = {}
            for k, v in pairs(pattern) do zone[k] = v end
            zone.coords = origin + pattern.offset
            zone.offset = nil
            table.insert(resolved.zones, zone)
        end
    end

    -- Resolve targets from pattern
    if config.targetPattern and not config.targets then
        resolved.targets = {}
        for i, pattern in ipairs(config.targetPattern) do
            table.insert(resolved.targets, {
                id     = pattern.id or i,
                model  = pattern.model or config.targetModel,
                coords = origin + pattern.offset,
                rot    = pattern.rot,
                data   = pattern.data,
            })
        end
    end

    return resolved
end

--- Start a minigame
---@param nameOrConfig string|table Minigame name (from saved) or config table
---@param activationPoint vector3|function|nil World position to resolve offset-based configs, or callback (legacy)
---@param callback function|nil Callback function(success, data)
---@return boolean started
local function StartMinigame(nameOrConfig, activationPoint, callback)
    -- Backwards compatibility: if activationPoint is a function, treat it as callback
    if type(activationPoint) == 'function' then
        callback = activationPoint
        activationPoint = nil
    end

    if isMinigameActive then
        UI.Notify({ title = 'Minigame', message = 'Already in a minigame', type = 'error' })
        return false
    end

    local config

    if type(nameOrConfig) == 'string' then
        config = savedMinigames[nameOrConfig]
        if not config then
            print('[nt_3dminigames] Minigame not found: ' .. nameOrConfig)
            return false
        end
    else
        config = nameOrConfig
    end

    if activationPoint then
        config = ResolveConfigOffsets(config, activationPoint)
    end

    if not config.type then
        print('[nt_3dminigames] Minigame config missing type')
        return false
    end

    local startFunc = registeredTypes[config.type]
    if not startFunc then
        print('[nt_3dminigames] Unknown minigame type: ' .. config.type)
        return false
    end

    isMinigameActive = true
    currentMinigame = {
        config    = config,
        callback  = callback,
        startTime = GetGameTimer(),
        data      = {},
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
            title       = config.name or 'Minigame',
            description = config.description or 'Complete the objective',
            options     = { { label = 'Exit', keybind = 'BACKSPACE' } },
        })
    end

    CreateThread(function()
        startFunc(config)
    end)

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
        UI.Notify({ title = 'Complete',  message = 'Minigame completed!', type = 'success' })
    else
        UI.Notify({ title = 'Cancelled', message = 'Minigame cancelled',  type = 'info'    })
    end

    isMinigameActive = false
    currentMinigame  = nil
end

--- Get current minigame state
---@return boolean active, table|nil config
local function GetMinigameState()
    return isMinigameActive, currentMinigame and currentMinigame.config or nil
end

--- Register a saved minigame configuration
---@param name string Minigame name
---@param config table Minigame configuration
local function RegisterMinigame(name, config)
    config.name = name
    savedMinigames[name] = config
    print('[nt_3dminigames] Registered minigame: ' .. name)
end

--- Get all registered minigame configurations
---@return table
local function GetRegisteredMinigames()
    return savedMinigames
end

--- Register a minigame type implementation
---@param typeName string Type identifier (e.g. 'bag', 'place')
---@param startFunc function Function(config) called when a minigame of this type starts
local function RegisterMinigameType(typeName, startFunc)
    registeredTypes[typeName] = startFunc
    print('[nt_3dminigames] Registered type: ' .. typeName)
end

-- ============================================
-- EXPORTS
-- ============================================

exports('StartMinigame',        StartMinigame)
exports('EndMinigame',          EndMinigame)
exports('GetMinigameState',     GetMinigameState)
exports('RegisterMinigame',     RegisterMinigame)
exports('GetRegisteredMinigames', GetRegisteredMinigames)
exports('RegisterMinigameType', RegisterMinigameType)

-- Core module exports
exports('Camera',    function() return Camera    end)
exports('Cursor',    function() return Cursor    end)
exports('Raycast',   function() return Raycast   end)
exports('Props',     function() return Props     end)
exports('Particles', function() return Particles end)
exports('Zones',     function() return Zones     end)
exports('UI',        function() return UI        end)

print('[nt_3dminigames] Framework loaded')
