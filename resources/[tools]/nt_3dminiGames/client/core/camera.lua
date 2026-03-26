Camera = {}

local activeCam = nil
local originalCamCoords = nil
local originalCamRot = nil
local isTransitioning = false

--- Create and activate a minigame camera
---@param coords vector3 Camera position
---@param rot vector3 Camera rotation (pitch, roll, yaw)
---@param fov number|nil Field of view (default from config)
---@param transition boolean|nil Smooth transition (default true)
function Camera.Create(coords, rot, fov, transition)
    if activeCam then
        Camera.Destroy()
    end
    
    fov = fov or Config.Camera.defaultFov
    transition = transition ~= false
    
    -- Store original camera position for restoration
    originalCamCoords = GetGameplayCamCoord()
    originalCamRot = GetGameplayCamRot(2)
    
    -- Create scripted camera
    activeCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(activeCam, coords.x, coords.y, coords.z)
    SetCamRot(activeCam, rot.x, rot.y, rot.z, 2)
    SetCamFov(activeCam, fov)
    
    -- Activate with transition
    if transition then
        isTransitioning = true
        SetCamActive(activeCam, true)
        RenderScriptCams(true, true, Config.Camera.transitionTime, true, true)
        
        SetTimeout(Config.Camera.transitionTime, function()
            isTransitioning = false
        end)
    else
        SetCamActive(activeCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    
    return activeCam
end

--- Destroy active minigame camera and restore gameplay camera
---@param transition boolean|nil Smooth transition back (default true)
function Camera.Destroy(transition)
    if not activeCam then return end
    
    transition = transition ~= false
    
    if transition then
        RenderScriptCams(false, true, Config.Camera.transitionTime, true, true)
        SetTimeout(Config.Camera.transitionTime, function()
            DestroyCam(activeCam, false)
            activeCam = nil
        end)
    else
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(activeCam, false)
        activeCam = nil
    end
    
    originalCamCoords = nil
    originalCamRot = nil
end

--- Get current active camera handle
---@return number|nil Camera handle or nil
function Camera.Get()
    return activeCam
end

--- Check if camera is active
---@return boolean
function Camera.IsActive()
    return activeCam ~= nil and not isTransitioning
end

--- Check if camera is transitioning
---@return boolean
function Camera.IsTransitioning()
    return isTransitioning
end

--- Set camera position
---@param coords vector3
function Camera.SetCoords(coords)
    if not activeCam then return end
    SetCamCoord(activeCam, coords.x, coords.y, coords.z)
end

--- Set camera rotation
---@param rot vector3
function Camera.SetRotation(rot)
    if not activeCam then return end
    SetCamRot(activeCam, rot.x, rot.y, rot.z, 2)
end

--- Set camera FOV
---@param fov number
function Camera.SetFov(fov)
    if not activeCam then return end
    SetCamFov(activeCam, fov)
end

--- Get camera forward vector
---@return vector3
function Camera.GetForwardVector()
    if not activeCam then 
        return vector3(0, 0, 0) 
    end
    
    local rot = GetCamRot(activeCam, 2)
    local rotX = math.rad(rot.x)
    local rotZ = math.rad(rot.z)
    
    local x = -math.sin(rotZ) * math.abs(math.cos(rotX))
    local y = math.cos(rotZ) * math.abs(math.cos(rotX))
    local z = math.sin(rotX)
    
    return vector3(x, y, z)
end

--- Point camera at specific coords
---@param coords vector3 Target coordinates
function Camera.PointAt(coords)
    if not activeCam then return end
    PointCamAtCoord(activeCam, coords.x, coords.y, coords.z)
end

--- Rotate camera based on mouse input (for look-around)
---@param sensitivity number|nil Look sensitivity multiplier
function Camera.HandleLook(sensitivity)
    if not activeCam then return end
    
    sensitivity = sensitivity or Config.Camera.lookSensitivity
    
    local mouseX = GetDisabledControlNormal(0, 1) * sensitivity
    local mouseY = GetDisabledControlNormal(0, 2) * sensitivity
    
    local rot = GetCamRot(activeCam, 2)
    local newRotX = math.max(-89.0, math.min(89.0, rot.x - mouseY))
    local newRotZ = rot.z - mouseX
    
    SetCamRot(activeCam, newRotX, rot.y, newRotZ, 2)
end

--- Create camera looking at a work area from above/angle
---@param targetCoords vector3 Center of work area
---@param distance number Distance from target
---@param angle number Angle in degrees (0 = above, 90 = side)
---@param rotation number Rotation around target in degrees
---@return vector3 camCoords, vector3 camRot
function Camera.CalculateWorkAreaView(targetCoords, distance, angle, rotation)
    angle = math.rad(angle or 45)
    rotation = math.rad(rotation or 0)
    
    local height = distance * math.sin(angle)
    local horizontalDist = distance * math.cos(angle)
    
    local camX = targetCoords.x + horizontalDist * math.sin(rotation)
    local camY = targetCoords.y - horizontalDist * math.cos(rotation)
    local camZ = targetCoords.z + height
    
    local coords = vector3(camX, camY, camZ)
    
    -- Calculate rotation to look at target
    local dx = targetCoords.x - camX
    local dy = targetCoords.y - camY
    local dz = targetCoords.z - camZ
    
    local pitch = math.deg(math.atan2(dz, math.sqrt(dx*dx + dy*dy)))
    local yaw = math.deg(math.atan2(dx, dy))
    
    local rot = vector3(pitch, 0.0, yaw)
    
    return coords, rot
end

return Camera
