Props = {}

local spawnedProps = {}
local attachedProp = nil
local attachedPropData = nil

--- Load a prop model
---@param model string|number Model name or hash
---@return boolean success
function Props.LoadModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end
    
    if HasModelLoaded(model) then
        return true
    end
    
    RequestModel(model)
    
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    return HasModelLoaded(model)
end

--- Spawn a prop at coordinates
---@param model string|number Model name or hash
---@param coords vector3 Spawn position
---@param rot vector3|nil Rotation (default 0,0,0)
---@param networked boolean|nil Create as networked entity (default false)
---@return number|nil Prop handle or nil if failed
function Props.Spawn(model, coords, rot, networked)
    if type(model) == 'string' then
        model = joaat(model)
    end
    
    if not Props.LoadModel(model) then
        return nil
    end
    
    rot = rot or vector3(0, 0, 0)
    networked = networked or false
    
    local prop = CreateObject(model, coords.x, coords.y, coords.z, networked, true, false)
    
    if prop and prop ~= 0 then
        SetEntityRotation(prop, rot.x, rot.y, rot.z, 2, true)
        SetEntityCollision(prop, false, false)
        FreezeEntityPosition(prop, true)
        
        spawnedProps[prop] = {
            model = model,
            coords = coords,
            rot = rot
        }
        
        return prop
    end
    
    return nil
end

--- Delete a spawned prop
---@param prop number Prop handle
function Props.Delete(prop)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
        spawnedProps[prop] = nil
    end
end

--- Delete all spawned props
function Props.DeleteAll()
    for prop, _ in pairs(spawnedProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    spawnedProps = {}
    
    if attachedProp then
        Props.DetachFromCursor()
    end
end

--- Attach a prop to follow the cursor in 3D space
---@param model string|number Model name or hash
---@param offset vector3|nil Offset from cursor hit point
---@param rot vector3|nil Initial rotation
---@return number|nil Prop handle
function Props.AttachToCursor(model, offset, rot)
    if attachedProp then
        Props.DetachFromCursor()
    end
    
    if type(model) == 'string' then
        model = joaat(model)
    end
    
    if not Props.LoadModel(model) then
        return nil
    end
    
    offset = offset or vector3(0, 0, 0)
    rot = rot or vector3(0, 0, 0)
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    attachedProp = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, false, true, false)
    
    if attachedProp and attachedProp ~= 0 then
        SetEntityRotation(attachedProp, rot.x, rot.y, rot.z, 2, true)
        SetEntityCollision(attachedProp, false, false)
        SetEntityAlpha(attachedProp, 200, false)
        
        attachedPropData = {
            model = model,
            offset = offset,
            rot = rot,
            baseHeight = 0.0
        }
        
        return attachedProp
    end
    
    return nil
end

--- Update attached prop position to follow cursor
---@param fixedHeight number|nil Fixed Z height (optional, for table-top minigames)
function Props.UpdateAttachedPosition(fixedHeight)
    if not attachedProp or not DoesEntityExist(attachedProp) then
        return
    end
    
    local hit, coords = Raycast.FromCursor(50.0)
    
    if hit and coords then
        local finalCoords = coords + attachedPropData.offset
        
        if fixedHeight then
            finalCoords = vector3(finalCoords.x, finalCoords.y, fixedHeight)
        end
        
        SetEntityCoords(attachedProp, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false, false)
    end
end

--- Rotate attached prop
---@param rot vector3 New rotation
function Props.SetAttachedRotation(rot)
    if not attachedProp or not DoesEntityExist(attachedProp) then
        return
    end
    
    attachedPropData.rot = rot
    SetEntityRotation(attachedProp, rot.x, rot.y, rot.z, 2, true)
end

--- Add rotation to attached prop
---@param addRot vector3 Rotation to add
function Props.AddAttachedRotation(addRot)
    if not attachedProp or not attachedPropData then
        return
    end
    
    local newRot = attachedPropData.rot + addRot
    Props.SetAttachedRotation(newRot)
end

--- Get attached prop handle
---@return number|nil
function Props.GetAttached()
    return attachedProp
end

--- Get attached prop coords
---@return vector3|nil
function Props.GetAttachedCoords()
    if not attachedProp or not DoesEntityExist(attachedProp) then
        return nil
    end
    
    return GetEntityCoords(attachedProp)
end

--- Detach and delete cursor-attached prop
function Props.DetachFromCursor()
    if attachedProp and DoesEntityExist(attachedProp) then
        DeleteEntity(attachedProp)
    end
    
    attachedProp = nil
    attachedPropData = nil
end

--- Place attached prop permanently (stop following cursor)
---@param collision boolean|nil Enable collision (default true)
---@param freeze boolean|nil Freeze position (default true)
---@return number|nil Prop handle
function Props.PlaceAttached(collision, freeze)
    if not attachedProp or not DoesEntityExist(attachedProp) then
        return nil
    end
    
    collision = collision ~= false
    freeze = freeze ~= false
    
    local prop = attachedProp
    local coords = GetEntityCoords(prop)
    
    SetEntityAlpha(prop, 255, false)
    SetEntityCollision(prop, collision, collision)
    FreezeEntityPosition(prop, freeze)
    
    spawnedProps[prop] = {
        model = attachedPropData.model,
        coords = coords,
        rot = attachedPropData.rot
    }
    
    attachedProp = nil
    attachedPropData = nil
    
    return prop
end

--- Attach prop to player ped bone
---@param model string|number Model name or hash
---@param bone string|number Bone name or index
---@param offset vector3|nil Position offset
---@param rot vector3|nil Rotation offset
---@return number|nil Prop handle
function Props.AttachToPed(model, bone, offset, rot)
    if type(model) == 'string' then
        model = joaat(model)
    end
    
    if not Props.LoadModel(model) then
        return nil
    end
    
    local ped = PlayerPedId()
    offset = offset or vector3(0, 0, 0)
    rot = rot or vector3(0, 0, 0)
    
    if type(bone) == 'string' then
        bone = GetPedBoneIndex(ped, joaat(bone))
    end
    
    local prop = CreateObject(model, 0, 0, 0, true, true, false)
    
    if prop and prop ~= 0 then
        AttachEntityToEntity(
            prop, ped, bone,
            offset.x, offset.y, offset.z,
            rot.x, rot.y, rot.z,
            true, true, false, true, 1, true
        )
        
        spawnedProps[prop] = {
            model = model,
            attachedTo = ped,
            bone = bone
        }
        
        return prop
    end
    
    return nil
end

--- Get all spawned props
---@return table
function Props.GetAll()
    return spawnedProps
end

--- Check if a prop exists
---@param prop number Prop handle
---@return boolean
function Props.Exists(prop)
    return prop and DoesEntityExist(prop)
end

return Props
