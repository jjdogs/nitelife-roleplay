Cursor = {}

local cursorEnabled = false
local cursorCoords = vector2(0.5, 0.5)

--- Enable mouse cursor and NUI focus
---@param keepInput boolean|nil Keep game input while cursor is active (default true)
function Cursor.Enable(keepInput)
    if cursorEnabled then return end
    
    keepInput = keepInput ~= false
    
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(keepInput)
    
    cursorEnabled = true
    cursorCoords = vector2(0.5, 0.5)
end

--- Disable mouse cursor and NUI focus
function Cursor.Disable()
    if not cursorEnabled then return end
    
    SetNuiFocus(false, false)
    cursorEnabled = false
end

--- Check if cursor is enabled
---@return boolean
function Cursor.IsEnabled()
    return cursorEnabled
end

--- Get cursor position in screen space (0-1)
---@return vector2 x, y normalized screen coordinates
function Cursor.GetScreenPosition()
    if not cursorEnabled then
        return vector2(0.5, 0.5)
    end
    
    -- Get mouse position from controls
    local x = GetDisabledControlNormal(0, 239)  -- Cursor X
    local y = GetDisabledControlNormal(0, 240)  -- Cursor Y
    
    -- Fallback to center if no input
    if x == 0 and y == 0 then
        x, y = 0.5, 0.5
    end
    
    cursorCoords = vector2(x, y)
    return cursorCoords
end

--- Convert screen position to world coordinates
---@param screenX number|nil Screen X (0-1), defaults to cursor position
---@param screenY number|nil Screen Y (0-1), defaults to cursor position
---@param distance number|nil Max distance for raycast (default 100.0)
---@return vector3|nil World coordinates or nil if nothing hit
---@return number|nil Entity hit or nil
function Cursor.GetWorldPosition(screenX, screenY, distance)
    distance = distance or 100.0
    
    if not screenX or not screenY then
        local pos = Cursor.GetScreenPosition()
        screenX, screenY = pos.x, pos.y
    end
    
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    
    -- If using scripted camera, use that instead
    local activeCam = Camera.Get()
    if activeCam then
        camCoords = GetCamCoord(activeCam)
        camRot = GetCamRot(activeCam, 2)
    end
    
    -- Calculate direction from screen coords
    local direction = Cursor.ScreenToWorldDirection(screenX, screenY, camRot)
    local destination = camCoords + (direction * distance)
    
    -- Raycast
    local ray = StartShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        -1, PlayerPedId(), 0
    )
    
    local _, hit, coords, _, entity = GetShapeTestResult(ray)
    
    if hit then
        return coords, entity
    end
    
    return nil, nil
end

--- Convert screen coordinates to world direction vector
---@param screenX number Screen X (0-1)
---@param screenY number Screen Y (0-1)
---@param camRot vector3 Camera rotation
---@return vector3 Direction vector (normalized)
function Cursor.ScreenToWorldDirection(screenX, screenY, camRot)
    local camForward = Cursor.RotationToDirection(camRot)
    local camRight = Cursor.RotationToRight(camRot)
    local camUp = Cursor.RotationToUp(camRot)
    
    -- Convert screen coords to offset from center
    local offsetX = (screenX - 0.5) * 2.0
    local offsetY = (screenY - 0.5) * 2.0
    
    -- Get FOV for proper scaling
    local fov = 50.0
    local activeCam = Camera.Get()
    if activeCam then
        fov = GetCamFov(activeCam)
    else
        fov = GetGameplayCamFov()
    end
    
    local fovRad = math.rad(fov)
    local aspectRatio = GetAspectRatio(true)
    
    -- Calculate the direction
    local right = camRight * (offsetX * math.tan(fovRad / 2) * aspectRatio)
    local up = camUp * (-offsetY * math.tan(fovRad / 2))
    
    local direction = camForward + right + up
    return norm(direction)
end

--- Convert rotation to forward direction vector
---@param rot vector3 Rotation (pitch, roll, yaw)
---@return vector3 Forward direction (normalized)
function Cursor.RotationToDirection(rot)
    local rotX = math.rad(rot.x)
    local rotZ = math.rad(rot.z)
    
    local x = -math.sin(rotZ) * math.abs(math.cos(rotX))
    local y = math.cos(rotZ) * math.abs(math.cos(rotX))
    local z = math.sin(rotX)
    
    return vector3(x, y, z)
end

--- Convert rotation to right direction vector
---@param rot vector3 Rotation (pitch, roll, yaw)
---@return vector3 Right direction (normalized)
function Cursor.RotationToRight(rot)
    local rotZ = math.rad(rot.z + 90)
    
    local x = -math.sin(rotZ)
    local y = math.cos(rotZ)
    
    return vector3(x, y, 0.0)
end

--- Convert rotation to up direction vector
---@param rot vector3 Rotation (pitch, roll, yaw)
---@return vector3 Up direction (normalized)
function Cursor.RotationToUp(rot)
    local forward = Cursor.RotationToDirection(rot)
    local right = Cursor.RotationToRight(rot)
    
    -- Cross product
    return vector3(
        forward.y * right.z - forward.z * right.y,
        forward.z * right.x - forward.x * right.z,
        forward.x * right.y - forward.y * right.x
    )
end

--- Draw cursor sprite on screen (for visual feedback)
---@param sprite string|nil Sprite name (default 'mp_lobby_textures', 'cross_line')
---@param scale number|nil Scale multiplier (default 1.0)
---@param color table|nil {r, g, b, a} (default white)
function Cursor.Draw(sprite, scale, color)
    if not cursorEnabled then return end
    
    scale = scale or 1.0
    color = color or { r = 255, g = 255, b = 255, a = 255 }
    
    local pos = Cursor.GetScreenPosition()
    
    -- Draw simple crosshair
    DrawSprite(
        'mp_lobby_textures',
        sprite or 'cross_line',
        pos.x, pos.y,
        0.02 * scale, 0.035 * scale,
        0.0,
        color.r, color.g, color.b, color.a
    )
end

--- Disable player controls while cursor is active
function Cursor.DisableControls()
    -- Disable movement
    DisableControlAction(0, 30, true)  -- Move LR
    DisableControlAction(0, 31, true)  -- Move UD
    DisableControlAction(0, 32, true)  -- Move Up
    DisableControlAction(0, 33, true)  -- Move Down
    DisableControlAction(0, 34, true)  -- Move Left
    DisableControlAction(0, 35, true)  -- Move Right
    
    -- Disable combat
    DisableControlAction(0, 24, true)  -- Attack
    DisableControlAction(0, 25, true)  -- Aim
    DisableControlAction(0, 47, true)  -- Weapon
    DisableControlAction(0, 58, true)  -- Weapon
    
    -- Disable vehicle
    DisableControlAction(0, 71, true)  -- Accelerate
    DisableControlAction(0, 72, true)  -- Brake
    DisableControlAction(0, 59, true)  -- Vehicle Attack
    
    -- Disable misc
    DisableControlAction(0, 44, true)  -- Cover
    DisableControlAction(0, 37, true)  -- Select Weapon
end

--- Normalize a vector
---@param v vector3
---@return vector3
local function norm(v)
    local len = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    if len == 0 then return vector3(0, 0, 0) end
    return vector3(v.x / len, v.y / len, v.z / len)
end

-- Make norm available locally
Cursor._norm = norm

return Cursor
