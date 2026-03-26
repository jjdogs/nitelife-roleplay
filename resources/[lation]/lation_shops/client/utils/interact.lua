local setup = require 'config.setup'

-- Auto-detect interaction system
local function DetectInteractSystem()
    if GetResourceState('ox_target') == 'started' then
        return 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        return 'qb-target'
    elseif GetResourceState('interact') == 'started' then
        return 'interact'
    else
        print('^1[ERROR]: No interaction system was auto-detected.^0')
        return nil
    end
end

-- Get the interaction system to use
local interact = setup.interact == 'auto' and DetectInteractSystem() or setup.interact

-- Add interaction
--- @param data table
local function AddInteraction(data)
    if interact == 'ox_target' then
        exports.ox_target:addSphereZone(data)
    elseif interact == 'qb-target' then
        exports['qb-target']:AddCircleZone(data.name, data.coords, data.radius, {
            name = data.name,
            debugPoly = setup.debug}, {
            options = data.options,
            distance = 2,
        })
    elseif interact == 'interact' then
        exports.interact:AddInteraction({
            coords = data.coords,
            interactDst = 2.0,
            id = data.name,
            options = data.options
        })
    elseif interact == 'custom' then
        -- Add support for a custom target system here
    else
        print('^1[ERROR]: No interaction system defined in the config/setup.lua file^0')
    end
end

-- Add entity interaction
--- @param entity number Entity number
--- @param data table Options table
local function AddEntityInteraction(entity, data)
    if interact == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, data)
    elseif interact == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entity, {options = data, distance = 1.75})
    elseif interact == 'interact' then
        exports.interact:AddLocalEntityInteraction({
            entity = entity,
            interactDst = 1.75,
            options = data
        })
    elseif interact == 'custom' then
        -- Add support for a custom interaction system here
    else
        print('^1[ERROR]: No interaction system defined in the config/setup.lua file^0')
    end
end

-- Add model interaction
--- @param model string Model
--- @param data table Options table
local function AddModelInteraction(model, data)
    if interact == 'ox_target' then
        exports.ox_target:addModel(model, data)
    elseif interact == 'qb-target' then
        exports['qb-target']:AddTargetModel(model, {options = data, distance = 1.75})
    elseif interact == 'interact' then
        exports.interact:AddModelInteraction({
            model = model,
            id = model,
            interactDst = 1.75,
            options = data
        })
    elseif interact == 'custom' then
        -- Add support for a custom interaction system here
    else
        print('^1[ERROR]: No interaction system defined in the config/setup.lua file^0')
    end
end

-- Remove interaction
--- @param name string
local function RemoveInteraction(name)
    if interact == 'ox_target' then
        exports.ox_target:removeZone(name)
    elseif interact == 'qb-target' then
        exports['qb-target']:RemoveZone(name)
    elseif interact == 'interact' then
        exports.interact:RemoveInteraction(name)
    elseif interact == 'custom' then
        -- Add support for a custom target system here
    else
        print('^1[ERROR]: No interaction system defined in the config/setup.lua file^0')
    end
end

-- Remove entity interaction
--- @param entity any|number
--- @param data table|string
local function RemoveEntityInteraction(entity, data)
    if interact == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity, data)
    elseif interact == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity, data)
    elseif interact == 'interact' then
        exports.interact:RemoveLocalEntityInteraction(entity, data)
    elseif interact == 'custom' then
        -- Add support for a custom interaction system here
    else
        print('^1[ERROR]: No interaction system defined in the config/setup.lua file^0')
    end
end

-- Remove model interaction
--- @param model string Model
local function RemoveModelInteraction(model)
    if interact == 'ox_target' then
        exports.ox_target:removeModel(model, nil)
    elseif interact == 'qb-target' then
        exports['qb-target']:RemoveTargetModel(model, nil)
    elseif interact == 'interact' then
        exports.interact:RemoveModelInteraction(model, model)
    elseif interact == 'custom' then
        -- Add support for a custom interaction system here
    else
        print('^1[ERROR]: No interaction system defined in the config/setup.lua file^0')
    end
end

return {
    AddInteraction = AddInteraction,
    AddEntityInteraction = AddEntityInteraction,
    AddModelInteraction = AddModelInteraction,
    RemoveInteraction = RemoveInteraction,
    RemoveEntityInteraction = RemoveEntityInteraction,
    RemoveModelInteraction = RemoveModelInteraction
}