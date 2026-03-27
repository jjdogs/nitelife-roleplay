Zones = {}

local activeZones = {}
local zoneIdCounter = 0

--- Create an interaction zone
---@param data table Zone configuration
---@return string Zone ID
function Zones.Create(data)
    zoneIdCounter = zoneIdCounter + 1
    local id = data.id or ('zone_' .. zoneIdCounter)
    
    activeZones[id] = {
        id = id,
        coords = data.coords,
        size = data.size or vector3(1.0, 1.0, 1.0),
        radius = data.radius,  -- For sphere zones
        type = data.type or 'box',  -- 'box' or 'sphere'
        rotation = data.rotation or 0.0,
        color = data.color or { r = 0, g = 255, b = 0, a = 100 },
        filled = data.filled ~= false,
        progress = 0.0,
        maxProgress = data.maxProgress or 100.0,
        active = true,
        onEnter = data.onEnter,
        onProgress = data.onProgress,
        onComplete = data.onComplete,
        data = data.data or {},
    }
    
    return id
end

--- Create multiple zones at once
---@param zones table Array of zone configurations
---@return table Array of zone IDs
function Zones.CreateMultiple(zones)
    local ids = {}
    for _, zoneData in ipairs(zones) do
        table.insert(ids, Zones.Create(zoneData))
    end
    return ids
end

--- Delete a zone
---@param id string Zone ID
function Zones.Delete(id)
    activeZones[id] = nil
end

--- Delete all zones
function Zones.DeleteAll()
    activeZones = {}
end

--- Check if a point is inside a zone
---@param id string Zone ID
---@param point vector3 Point to check
---@return boolean
function Zones.IsPointInside(id, point)
    local zone = activeZones[id]
    if not zone or not zone.active then return false end
    
    if zone.type == 'sphere' then
        local dist = #(point - zone.coords)
        return dist <= (zone.radius or zone.size.x)
    else
        -- Rotate point into zone local space to handle zone.rotation
        local halfSize = zone.size / 2
        local dx = point.x - zone.coords.x
        local dy = point.y - zone.coords.y
        local angle = math.rad(-zone.rotation)
        local cos_a = math.cos(angle)
        local sin_a = math.sin(angle)
        local lx = cos_a * dx - sin_a * dy
        local ly = sin_a * dx + cos_a * dy
        return math.abs(lx) <= halfSize.x
           and math.abs(ly) <= halfSize.y
           and math.abs(point.z - zone.coords.z) <= halfSize.z
    end
end

--- Check if cursor is pointing at a zone
---@param id string Zone ID
---@return boolean isPointing, vector3|nil hitCoords
function Zones.IsCursorPointing(id)
    local zone = activeZones[id]
    if not zone or not zone.active then return false, nil end
    
    local hit, coords = Raycast.FromCursor(50.0)
    
    if hit and coords then
        if Zones.IsPointInside(id, coords) then
            return true, coords
        end
    end
    
    return false, nil
end

--- Get the zone the cursor is currently pointing at
---@return string|nil zoneId, vector3|nil hitCoords
function Zones.GetCursorTarget()
    local hit, coords = Raycast.FromCursor(50.0)
    
    if hit and coords then
        for id, zone in pairs(activeZones) do
            if zone.active and Zones.IsPointInside(id, coords) then
                return id, coords
            end
        end
    end
    
    return nil, nil
end

--- Add progress to a zone
---@param id string Zone ID
---@param amount number Amount to add
---@return boolean completed
function Zones.AddProgress(id, amount)
    local zone = activeZones[id]
    if not zone then return false end
    
    zone.progress = math.min(zone.maxProgress, zone.progress + amount)
    
    if zone.onProgress then
        zone.onProgress(id, zone.progress, zone.maxProgress)
    end
    
    if zone.progress >= zone.maxProgress then
        if zone.onComplete then
            zone.onComplete(id, zone.data)
        end
        return true
    end
    
    return false
end

--- Set zone progress
---@param id string Zone ID
---@param progress number Progress value
function Zones.SetProgress(id, progress)
    local zone = activeZones[id]
    if not zone then return end
    
    zone.progress = math.max(0, math.min(zone.maxProgress, progress))
end

--- Get zone progress
---@param id string Zone ID
---@return number progress, number maxProgress
function Zones.GetProgress(id)
    local zone = activeZones[id]
    if not zone then return 0, 0 end
    
    return zone.progress, zone.maxProgress
end

--- Get zone progress as percentage
---@param id string Zone ID
---@return number percentage (0-100)
function Zones.GetProgressPercent(id)
    local zone = activeZones[id]
    if not zone or zone.maxProgress == 0 then return 0 end
    
    return (zone.progress / zone.maxProgress) * 100
end

--- Set zone active state
---@param id string Zone ID
---@param active boolean
function Zones.SetActive(id, active)
    local zone = activeZones[id]
    if zone then
        zone.active = active
    end
end

--- Set zone color
---@param id string Zone ID
---@param color table {r, g, b, a}
function Zones.SetColor(id, color)
    local zone = activeZones[id]
    if zone then
        zone.color = color
    end
end

--- Get zone data
---@param id string Zone ID
---@return table|nil
function Zones.Get(id)
    return activeZones[id]
end

--- Get all zones
---@return table
function Zones.GetAll()
    return activeZones
end

--- Get all completed zones
---@return table Array of zone IDs
function Zones.GetCompleted()
    local completed = {}
    for id, zone in pairs(activeZones) do
        if zone.progress >= zone.maxProgress then
            table.insert(completed, id)
        end
    end
    return completed
end

--- Get total progress across all zones
---@return number totalProgress, number totalMax, number percentage
function Zones.GetTotalProgress()
    local total = 0
    local max = 0
    
    for _, zone in pairs(activeZones) do
        total = total + zone.progress
        max = max + zone.maxProgress
    end
    
    local percent = max > 0 and (total / max) * 100 or 0
    return total, max, percent
end

--- Check if all zones are complete
---@return boolean
function Zones.AllComplete()
    for _, zone in pairs(activeZones) do
        if zone.active and zone.progress < zone.maxProgress then
            return false
        end
    end
    return true
end

--- Draw zone markers (call in tick)
---@param drawProgress boolean|nil Draw progress indicators
function Zones.Draw(drawProgress)
    for id, zone in pairs(activeZones) do
        if zone.active then
            local color = zone.color
            
            -- Adjust color based on progress
            if drawProgress and zone.maxProgress > 0 then
                local progressRatio = zone.progress / zone.maxProgress
                -- Fade from red to green as progress increases
                color = {
                    r = math.floor(255 * (1 - progressRatio)),
                    g = math.floor(255 * progressRatio),
                    b = 0,
                    a = color.a or 100
                }
            end
            
            if zone.type == 'sphere' then
                local radius = zone.radius or zone.size.x
                DrawMarker(
                    28,  -- Sphere
                    zone.coords.x, zone.coords.y, zone.coords.z,
                    0, 0, 0,
                    0, 0, 0,
                    radius * 2, radius * 2, radius * 2,
                    color.r, color.g, color.b, color.a,
                    false, false, 2, false, nil, nil, false
                )
            else
                DrawMarker(
                    1,  -- Cylinder/box
                    zone.coords.x, zone.coords.y, zone.coords.z - zone.size.z / 2,
                    0, 0, 0,
                    0, 0, zone.rotation,
                    zone.size.x, zone.size.y, zone.size.z,
                    color.r, color.g, color.b, color.a,
                    false, false, 2, false, nil, nil, false
                )
            end
        end
    end
end

--- Reset all zone progress
function Zones.ResetProgress()
    for _, zone in pairs(activeZones) do
        zone.progress = 0
    end
end

return Zones
