Particles = {}

local loadedDicts = {}
local activeParticles = {}

--- Load a particle dictionary
---@param dict string Particle dictionary name
---@return boolean success
function Particles.LoadDict(dict)
    if loadedDicts[dict] then
        return true
    end
    
    RequestNamedPtfxAsset(dict)
    
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(dict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if HasNamedPtfxAssetLoaded(dict) then
        loadedDicts[dict] = true
        return true
    end
    
    return false
end

--- Preload all particle dicts from config
function Particles.PreloadAll()
    for _, dict in ipairs(Config.ParticleDicts) do
        Particles.LoadDict(dict)
    end
end

--- Play a particle effect at coordinates (one-shot)
---@param dict string Particle dictionary
---@param name string Particle name
---@param coords vector3 Position
---@param rot vector3|nil Rotation (default 0,0,0)
---@param scale number|nil Scale (default 1.0)
---@return boolean success
function Particles.PlayAt(dict, name, coords, rot, scale)
    if not Particles.LoadDict(dict) then
        return false
    end
    
    rot = rot or vector3(0, 0, 0)
    scale = scale or 1.0
    
    UseParticleFxAsset(dict)
    StartParticleFxNonLoopedAtCoord(
        name,
        coords.x, coords.y, coords.z,
        rot.x, rot.y, rot.z,
        scale, false, false, false
    )
    
    return true
end

--- Start a looped particle effect at coordinates
---@param dict string Particle dictionary
---@param name string Particle name
---@param coords vector3 Position
---@param rot vector3|nil Rotation (default 0,0,0)
---@param scale number|nil Scale (default 1.0)
---@param id string|nil Optional ID for tracking
---@return number|nil Particle handle
function Particles.StartLoopedAt(dict, name, coords, rot, scale, id)
    if not Particles.LoadDict(dict) then
        return nil
    end
    
    rot = rot or vector3(0, 0, 0)
    scale = scale or 1.0
    
    UseParticleFxAsset(dict)
    local handle = StartParticleFxLoopedAtCoord(
        name,
        coords.x, coords.y, coords.z,
        rot.x, rot.y, rot.z,
        scale, false, false, false, false
    )
    
    if handle and handle ~= 0 then
        local trackingId = id or tostring(handle)
        activeParticles[trackingId] = {
            handle = handle,
            dict = dict,
            name = name,
            coords = coords,
            type = 'coord'
        }
        return handle
    end
    
    return nil
end

--- Start a looped particle effect on an entity
---@param dict string Particle dictionary
---@param name string Particle name
---@param entity number Entity handle
---@param offset vector3|nil Offset from entity origin
---@param rot vector3|nil Rotation offset
---@param scale number|nil Scale (default 1.0)
---@param bone string|number|nil Bone to attach to
---@param id string|nil Optional ID for tracking
---@return number|nil Particle handle
function Particles.StartLoopedOnEntity(dict, name, entity, offset, rot, scale, bone, id)
    if not Particles.LoadDict(dict) then
        return nil
    end
    
    offset = offset or vector3(0, 0, 0)
    rot = rot or vector3(0, 0, 0)
    scale = scale or 1.0
    
    local boneIndex = 0
    if bone then
        if type(bone) == 'string' then
            boneIndex = GetEntityBoneIndexByName(entity, bone)
        else
            boneIndex = bone
        end
    end
    
    UseParticleFxAsset(dict)
    local handle = StartParticleFxLoopedOnEntityBone(
        name, entity, 
        offset.x, offset.y, offset.z,
        rot.x, rot.y, rot.z,
        boneIndex, scale, false, false, false
    )
    
    if handle and handle ~= 0 then
        local trackingId = id or tostring(handle)
        activeParticles[trackingId] = {
            handle = handle,
            dict = dict,
            name = name,
            entity = entity,
            type = 'entity'
        }
        return handle
    end
    
    return nil
end

--- Stop a looped particle effect
---@param handleOrId number|string Particle handle or tracking ID
function Particles.Stop(handleOrId)
    local handle = handleOrId
    
    -- Check if it's a tracking ID
    if type(handleOrId) == 'string' then
        local data = activeParticles[handleOrId]
        if data then
            handle = data.handle
            activeParticles[handleOrId] = nil
        else
            return
        end
    else
        -- Remove from tracking by handle
        for id, data in pairs(activeParticles) do
            if data.handle == handleOrId then
                activeParticles[id] = nil
                break
            end
        end
    end
    
    if handle and DoesParticleFxLoopedExist(handle) then
        StopParticleFxLooped(handle, false)
    end
end

--- Stop all active looped particles
function Particles.StopAll()
    for id, data in pairs(activeParticles) do
        if data.handle and DoesParticleFxLoopedExist(data.handle) then
            StopParticleFxLooped(data.handle, false)
        end
    end
    activeParticles = {}
end

--- Update position of a looped particle
---@param handleOrId number|string Particle handle or tracking ID
---@param coords vector3 New position
function Particles.SetCoords(handleOrId, coords)
    local handle = handleOrId
    
    if type(handleOrId) == 'string' then
        local data = activeParticles[handleOrId]
        if data then
            handle = data.handle
            data.coords = coords
        else
            return
        end
    end
    
    -- Note: Can't directly move a particle, need to recreate it
    -- This is a limitation of GTA's particle system
end

--- Set particle effect color
---@param handle number Particle handle
---@param r number Red (0-1)
---@param g number Green (0-1)  
---@param b number Blue (0-1)
function Particles.SetColor(handle, r, g, b)
    if handle and DoesParticleFxLoopedExist(handle) then
        SetParticleFxLoopedColour(handle, r, g, b, false)
    end
end

--- Set particle effect alpha
---@param handle number Particle handle
---@param alpha number Alpha (0-1)
function Particles.SetAlpha(handle, alpha)
    if handle and DoesParticleFxLoopedExist(handle) then
        SetParticleFxLoopedAlpha(handle, alpha)
    end
end

--- Set particle effect scale
---@param handle number Particle handle
---@param scale number Scale multiplier
function Particles.SetScale(handle, scale)
    if handle and DoesParticleFxLoopedExist(handle) then
        SetParticleFxLoopedScale(handle, scale)
    end
end

--- Get active particles
---@return table
function Particles.GetActive()
    return activeParticles
end

--- Check if particle exists
---@param handleOrId number|string
---@return boolean
function Particles.Exists(handleOrId)
    if type(handleOrId) == 'string' then
        local data = activeParticles[handleOrId]
        return data ~= nil and DoesParticleFxLoopedExist(data.handle)
    end
    
    return DoesParticleFxLoopedExist(handleOrId)
end

-- Common particle presets
Particles.Presets = {
    water_pour = { dict = 'core', name = 'ent_sht_water' },
    water_splash = { dict = 'core', name = 'ent_sht_water' },
    dust = { dict = 'core', name = 'ent_dst_rocks' },
    smoke_light = { dict = 'core', name = 'exp_grd_bzgas_smoke' },
    sparks = { dict = 'core', name = 'ent_ray_heli_spark' },
    fire_small = { dict = 'core', name = 'ent_amb_fbi_fire' },
}

return Particles
