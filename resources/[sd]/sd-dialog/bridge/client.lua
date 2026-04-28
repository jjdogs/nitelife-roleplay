Target = {}
local target = nil

--- Initialize the target system by checking available resources
local function InitializeTarget()
    local resources = {"ox_target", "qb-target", "qtarget"}
    for _, resource in ipairs(resources) do
        if GetResourceState(resource) == 'started' then
            target = resource
            break
        end
    end

    if not target then
        print("^1[SD-DIALOG]^0 No target resource found (ox_target, qb-target, qtarget)")
        return false
    end

    print(string.format("^2[SD-DIALOG]^0 Target system initialized: ^3%s^0", target))
    return true
end

InitializeTarget()

--- Converts ox_target style options to qb-target/qtarget style
---@param options table ox_target style options array
---@return table qb-target style options array
local function ConvertOptions(options)
    if target == 'ox_target' then
        return options
    end

    local converted = {}
    for _, option in ipairs(options) do
        table.insert(converted, {
            type = option.type or "client",
            event = option.event,
            icon = option.icon,
            label = option.label,
            action = option.onSelect,
            canInteract = option.canInteract,
            distance = option.distance,
            groups = option.groups,
            items = option.items
        })
    end
    return converted
end

-- =============================================
--              STANDARD TARGET FUNCTIONS
-- =============================================

--- Add target to a local entity
---@param entity number Entity handle
---@param options table Options for the target
---@return boolean Success
Target.addLocalEntity = function(entity, options)
    if not target then return false end

    if target == 'ox_target' then
        return exports.ox_target:addLocalEntity(entity, options)
    else
        exports[target]:AddTargetEntity(entity, {
            options = ConvertOptions(options),
            distance = options[1] and options[1].distance or 2.5,
        })
        return true
    end
end

--- Add target to a model
---@param models table|string Model or array of models
---@param options table Options for the target
---@return boolean Success
Target.addModel = function(models, options)
    if not target then return false end

    if target == 'ox_target' then
        return exports.ox_target:addModel(models, options)
    else
        local modelList = type(models) == 'table' and models or {models}
        exports[target]:AddTargetModel(modelList, {
            options = ConvertOptions(options),
            distance = options[1] and options[1].distance or 2.5,
        })
        return true
    end
end

--- Remove target from a local entity
---@param entity number Entity handle
---@param optionNames table|string|nil Option name(s) to remove, or nil for all
---@return boolean Success
Target.removeLocalEntity = function(entity, optionNames)
    if not target then return false end

    if target == 'ox_target' then
        return exports.ox_target:removeLocalEntity(entity, optionNames)
    else
        exports[target]:RemoveTargetEntity(entity, optionNames)
        return true
    end
end

--- Remove target from a model
---@param models table|string Model or array of models
---@param optionNames table|string|nil Option name(s) to remove, or nil for all
---@return boolean Success
Target.removeModel = function(models, optionNames)
    if not target then return false end

    if target == 'ox_target' then
        return exports.ox_target:removeModel(models, optionNames)
    else
        local modelList = type(models) == 'table' and models or {models}
        for _, model in ipairs(modelList) do
            exports[target]:RemoveTargetModel(model, optionNames)
        end
        return true
    end
end