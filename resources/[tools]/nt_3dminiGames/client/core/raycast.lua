Raycast = {}

--- Perform a raycast from cursor position into world
---@param distance number|nil Max distance (default 100.0)
---@param flags number|nil Raycast flags (default -1 for everything)
---@param ignoreEntity number|nil Entity to ignore (default player ped)
---@return boolean hit, vector3|nil coords, vector3|nil surfaceNormal, number|nil entity
function Raycast.FromCursor(distance, flags, ignoreEntity)
    distance = distance or 100.0
    flags = flags or -1
    ignoreEntity = ignoreEntity or PlayerPedId()
    
    local screenPos = Cursor.GetScreenPosition()
    
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    
    -- Use scripted camera if active
    local activeCam = Camera.Get()
    if activeCam then
        camCoords = GetCamCoord(activeCam)
        camRot = GetCamRot(activeCam, 2)
    end
    
    local direction = Cursor.ScreenToWorldDirection(screenPos.x, screenPos.y, camRot)
    local destination = camCoords + (direction * distance)
    
    local ray = StartShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        flags, ignoreEntity, 0
    )
    
    local _, hit, coords, surfaceNormal, entity = GetShapeTestResult(ray)
    
    return hit == 1, coords, surfaceNormal, entity
end

--- Perform a raycast from one point to another
---@param start vector3 Start position
---@param finish vector3 End position
---@param flags number|nil Raycast flags (default -1)
---@param ignoreEntity number|nil Entity to ignore
---@return boolean hit, vector3|nil coords, vector3|nil surfaceNormal, number|nil entity
function Raycast.FromTo(start, finish, flags, ignoreEntity)
    flags = flags or -1
    ignoreEntity = ignoreEntity or PlayerPedId()
    
    local ray = StartShapeTestLosProbe(
        start.x, start.y, start.z,
        finish.x, finish.y, finish.z,
        flags, ignoreEntity, 0
    )
    
    local _, hit, coords, surfaceNormal, entity = GetShapeTestResult(ray)
    
    return hit == 1, coords, surfaceNormal, entity
end

--- Perform a raycast from camera forward
---@param distance number|nil Max distance (default 100.0)
---@param flags number|nil Raycast flags (default -1)
---@param ignoreEntity number|nil Entity to ignore
---@return boolean hit, vector3|nil coords, vector3|nil surfaceNormal, number|nil entity
function Raycast.FromCamera(distance, flags, ignoreEntity)
    distance = distance or 100.0
    flags = flags or -1
    ignoreEntity = ignoreEntity or PlayerPedId()
    
    local camCoords = GetGameplayCamCoord()
    local forward = Camera.GetForwardVector()
    
    -- Use scripted camera if active
    local activeCam = Camera.Get()
    if activeCam then
        camCoords = GetCamCoord(activeCam)
    end
    
    local destination = camCoords + (forward * distance)
    
    return Raycast.FromTo(camCoords, destination, flags, ignoreEntity)
end

--- Check if cursor is pointing at a specific entity
---@param targetEntity number Entity handle to check
---@param distance number|nil Max distance (default 100.0)
---@return boolean isPointing, vector3|nil hitCoords
function Raycast.IsPointingAtEntity(targetEntity, distance)
    local hit, coords, _, entity = Raycast.FromCursor(distance)
    
    if hit and entity == targetEntity then
        return true, coords
    end
    
    return false, nil
end

--- Check if cursor is pointing at any entity with a specific model
---@param modelHash number|string Model hash or name
---@param distance number|nil Max distance (default 100.0)
---@return boolean found, number|nil entity, vector3|nil coords
function Raycast.IsPointingAtModel(modelHash, distance)
    if type(modelHash) == 'string' then
        modelHash = joaat(modelHash)
    end
    
    local hit, coords, _, entity = Raycast.FromCursor(distance)
    
    if hit and entity and entity ~= 0 then
        local entityModel = GetEntityModel(entity)
        if entityModel == modelHash then
            return true, entity, coords
        end
    end
    
    return false, nil, nil
end

--- Get all entities within cursor raycast path
---@param distance number|nil Max distance (default 100.0)
---@param entityType number|nil Entity type filter (1=ped, 2=vehicle, 3=object)
---@return table Array of {entity, coords, distance}
function Raycast.GetEntitiesInPath(distance, entityType)
    distance = distance or 100.0
    
    local screenPos = Cursor.GetScreenPosition()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    
    local activeCam = Camera.Get()
    if activeCam then
        camCoords = GetCamCoord(activeCam)
        camRot = GetCamRot(activeCam, 2)
    end
    
    local direction = Cursor.ScreenToWorldDirection(screenPos.x, screenPos.y, camRot)
    local results = {}
    
    -- Get nearby entities and check if they're in the ray path
    local entities = {}
    
    if not entityType or entityType == 3 then
        local objects = GetGamePool('CObject')
        for _, obj in ipairs(objects) do
            table.insert(entities, { entity = obj, type = 3 })
        end
    end
    
    if not entityType or entityType == 1 then
        local peds = GetGamePool('CPed')
        for _, ped in ipairs(peds) do
            if ped ~= PlayerPedId() then
                table.insert(entities, { entity = ped, type = 1 })
            end
        end
    end
    
    if not entityType or entityType == 2 then
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            table.insert(entities, { entity = veh, type = 2 })
        end
    end
    
    for _, data in ipairs(entities) do
        local entityCoords = GetEntityCoords(data.entity)
        local dist = #(camCoords - entityCoords)
        
        if dist <= distance then
            -- Check if entity is roughly in the ray direction
            local toEntity = entityCoords - camCoords
            local toEntityNorm = toEntity / #toEntity
            local dot = direction.x * toEntityNorm.x + direction.y * toEntityNorm.y + direction.z * toEntityNorm.z
            
            if dot > 0.95 then  -- Within ~18 degrees of ray direction
                table.insert(results, {
                    entity = data.entity,
                    type = data.type,
                    coords = entityCoords,
                    distance = dist
                })
            end
        end
    end
    
    -- Sort by distance
    table.sort(results, function(a, b) return a.distance < b.distance end)
    
    return results
end

--- Raycast flags reference
Raycast.Flags = {
    WORLD = 1,
    VEHICLES = 2,
    PEDS_AND_RAGDOLLS = 4,
    OBJECTS = 16,
    WATER = 32,
    FOLIAGE = 256,
    EVERYTHING = -1,
}

return Raycast
