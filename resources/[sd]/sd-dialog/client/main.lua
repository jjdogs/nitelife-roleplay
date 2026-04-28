if not LoadResourceFile(GetCurrentResourceName(), 'web/build/index.html') then
    print('^1[SD-DIALOG] ERROR: web/build folder not found!^0')
    print('^1[SD-DIALOG] You likely downloaded the source code instead of the release.^0')
    print('^1[SD-DIALOG] Please download the latest release from: https://github.com/Samuels-Development/sd-dialog/releases/latest^0')
    return
end

local Config = require 'config'

local isDialogOpen = false --- Whether dialog is currently open
local currentDialog = nil --- Current dialog data
local originalOptions = nil --- Original options with functions intact
local dialogCamera = nil --- Camera handle
local originalCamCoords = nil --- Original camera position for restoration
local originalCamRot = nil --- Original camera position for restoration
local currentCallback = nil --- Current callback for option selection
local focusedEntity = nil --- Entity being focused on
local entityDialogs = {} --- Store dialog data for entities and models
local modelDialogs = {} --- Store dialog data for entities and models

--- Creates and activates the dialog camera focused on the NPC
--- @param entity number Entity to focus on
--- @param transitionTime number? Transition time in ms
local function CreateDialogCamera(entity, transitionTime)
    transitionTime = transitionTime or 1000

    originalCamCoords = GetGameplayCamCoord()
    originalCamRot = GetGameplayCamRot(2)

    local px, py, pz = table.unpack(GetEntityCoords(entity, true))
    local x = px + GetEntityForwardX(entity) * 1.2
    local y = py + GetEntityForwardY(entity) * 1.2
    local z = pz + 0.52

    local rx = GetEntityRotation(entity, 2)
    local camRotation = rx + vector3(0.0, 0.0, 181.0)

    dialogCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, camRotation.x, camRotation.y, camRotation.z, 65.0)
    SetCamActive(dialogCamera, true)
    RenderScriptCams(true, true, transitionTime, true, true)

    TaskLookAtEntity(entity, PlayerPedId(), -1, 2048, 3)

    focusedEntity = entity
end

--- Destroys the dialog camera and restores gameplay camera
--- @param transitionTime number? Transition time in ms
local function DestroyDialogCamera(transitionTime)
    transitionTime = transitionTime or 800

    if focusedEntity and DoesEntityExist(focusedEntity) then
        TaskClearLookAt(focusedEntity)
    end

    RenderScriptCams(false, true, transitionTime, true, false)

    SetTimeout(transitionTime, function()
        if dialogCamera then
            DestroyCam(dialogCamera, false)
            dialogCamera = nil
        end
    end)

    focusedEntity = nil
end

--- Opens a dialog with the specified configuration
--- @param data table Dialog configuration
--- @param callback function? Callback when option is selected
--- @param rawOptions table? Original options with functions intact
local function OpenDialog(data, callback, rawOptions)
    if isDialogOpen then
        CloseDialog()
        Wait(100)
    end

    currentDialog = data
    originalOptions = rawOptions or data.options
    currentCallback = callback
    isDialogOpen = true

    if data.entity and DoesEntityExist(data.entity) then
        CreateDialogCamera(data.entity, data.transitionTime)
    end

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openDialog',
        data = {
            name = data.name or 'Unknown',
            role = data.role,
            roleColor = data.roleColor or '#ec4899',
            description = data.description or '',
            options = data.options or {},
            showGoBack = data.showGoBack ~= false,
            itemsPerPage = data.itemsPerPage or Config.itemsPerPage,
        }
    })

    if data.entity and DoesEntityExist(data.entity) then
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local entityCoords = GetEntityCoords(data.entity)

        local angle = math.deg(math.atan((entityCoords.y - pedCoords.y) / (entityCoords.x - pedCoords.x)))
        if entityCoords.x < pedCoords.x then
            angle = angle + 180
        end

        TaskTurnPedToFaceCoord(ped, entityCoords.x, entityCoords.y, entityCoords.z, 1000)
    end
end

--- Closes the current dialog
local function CloseDialog()
    if not isDialogOpen then return end

    isDialogOpen = false
    currentDialog = nil
    originalOptions = nil
    currentCallback = nil

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'closeDialog'
    })

    DestroyDialogCamera()
end

--- Finds an option by ID, including nested menu options
---@param options table The options array to search
---@param targetId string The option ID to find
---@return table|nil The found option or nil
local function FindOptionById(options, targetId)
    for _, option in ipairs(options) do
        if option.id == targetId then
            return option
        end
        if option.menu and option.menu.options then
            local found = FindOptionById(option.menu.options, targetId)
            if found then return found end
        end
    end
    return nil
end

--- Handles option selection from NUI
RegisterNUICallback('selectOption', function(data, cb)
    local optionId = data.id

    if currentCallback then
        currentCallback(optionId, currentDialog)
    end

    if originalOptions then
        local option = FindOptionById(originalOptions, optionId)

        if option then
            if option.action and type(option.action) == 'function' then
                option.action(option.params, option, currentDialog)

            elseif option.clientEvent then
                if type(option.clientEvent) == 'table' then
                    local eventName = option.clientEvent[1]
                    local args = {table.unpack(option.clientEvent, 2)}
                    TriggerEvent(eventName, table.unpack(args))
                else
                    TriggerEvent(option.clientEvent)
                end

            elseif option.serverEvent then
                if type(option.serverEvent) == 'table' then
                    local eventName = option.serverEvent[1]
                    local args = {table.unpack(option.serverEvent, 2)}
                    TriggerServerEvent(eventName, table.unpack(args))
                else
                    TriggerServerEvent(option.serverEvent)
                end

            elseif option.onSelect then
                option.onSelect(option, currentDialog)
            end
        end
    end

    cb('ok')
end)

RegisterNUICallback('closeDialog', function(data, cb)
    CloseDialog()
    cb('ok')
end)

local function IsCallable(value)
    local valueType = type(value)
    if valueType == 'function' then
        return true
    end
    if valueType == 'table' then
        return value.__cfx_functionReference ~= nil or (getmetatable(value) and getmetatable(value).__call ~= nil)
    end
    return false
end

local function ProcessDialogOptions(options, entity)
    local processed = {}
    for _, opt in ipairs(options) do
        local newOpt = {}

        for k, v in pairs(opt) do
            if not IsCallable(v) then
                newOpt[k] = v
            end
        end

        newOpt.disabled = false

        if opt.canInteract and IsCallable(opt.canInteract) then
            local success, result = pcall(opt.canInteract, entity)
            if success then
                newOpt.disabled = not result
            else
                print('^1[SD-DIALOG]^0 Error in canInteract:', result)
                newOpt.disabled = true
            end
        end

        if opt.menu and opt.menu.options then
            newOpt.menu = {
                description = opt.menu.description,
                options = ProcessDialogOptions(opt.menu.options, entity)
            }
        end

        processed[#processed + 1] = newOpt
    end
    return processed
end

exports('Open', function(data, callback)
    local rawOptions = data.options or {}
    local processedData = {
        entity = data.entity,
        name = data.name,
        role = data.role,
        roleColor = data.roleColor,
        description = data.description,
        options = ProcessDialogOptions(rawOptions, data.entity),
        showGoBack = data.showGoBack,
        transitionTime = data.transitionTime,
        itemsPerPage = data.itemsPerPage,
    }
    OpenDialog(processedData, callback, rawOptions)
end)

exports('Close', function()
    CloseDialog()
end)

exports('IsOpen', function()
    return isDialogOpen
end)

--- Add a dialog to a local entity (creates target interaction that opens dialog)
---@param entity number Entity handle
---@param data table Dialog data configuration
---@return boolean Success
local function AddEntityDialog(entity, data)
    if not DoesEntityExist(entity) then return false end

    local targetName = 'sd_dialog_' .. tostring(entity)

    entityDialogs[entity] = data

    local targetOptions = {
        {
            name = targetName,
            icon = data.targetIcon or 'fas fa-comments',
            label = data.targetLabel or 'Talk',
            distance = data.targetDistance or 2.5,
            canInteract = data.targetCanInteract,
            onSelect = function()
                local dialogData = entityDialogs[entity]
                if dialogData then
                    local rawOptions = dialogData.options or {}
                    local processedOptions = ProcessDialogOptions(rawOptions, entity)

                    OpenDialog({
                        entity = entity,
                        name = dialogData.name,
                        role = dialogData.role,
                        roleColor = dialogData.roleColor,
                        description = dialogData.description,
                        options = processedOptions,
                        itemsPerPage = dialogData.itemsPerPage,
                    }, dialogData.onSelect, rawOptions)
                end
            end
        }
    }

    Target.addLocalEntity(entity, targetOptions)
    return true
end

--- Remove dialog from a local entity
---@param entity number Entity handle
---@return boolean Success
local function RemoveEntityDialog(entity)
    local targetName = 'sd_dialog_' .. tostring(entity)
    entityDialogs[entity] = nil

    Target.removeLocalEntity(entity, targetName)
    return true
end

--- Add a dialog to a model (creates target interaction that opens dialog)
---@param models table|string Model or array of models
---@param data table Dialog data configuration
---@return boolean Success
local function AddModelDialog(models, data)
    local modelList = type(models) == 'table' and models or {models}
    local targetName = 'sd_dialog_model_' .. tostring(modelList[1])

    for _, model in ipairs(modelList) do
        modelDialogs[model] = data
    end

    local targetOptions = {
        {
            name = targetName,
            icon = data.targetIcon or 'fas fa-comments',
            label = data.targetLabel or 'Talk',
            distance = data.targetDistance or 2.5,
            canInteract = data.targetCanInteract,
            onSelect = function(data2)
                local entity = data2.entity
                local model = GetEntityModel(entity)
                local dialogData = modelDialogs[model]

                if dialogData then
                    local rawOptions = dialogData.options or {}
                    local processedOptions = ProcessDialogOptions(rawOptions, entity)

                    OpenDialog({
                        entity = entity,
                        name = dialogData.name,
                        role = dialogData.role,
                        roleColor = dialogData.roleColor,
                        description = dialogData.description,
                        options = processedOptions,
                        itemsPerPage = dialogData.itemsPerPage,
                    }, dialogData.onSelect, rawOptions)
                end
            end
        }
    }

    Target.addModel(modelList, targetOptions)
    return true
end

--- Remove dialog from a model
---@param models table|string Model or array of models
---@return boolean Success
local function RemoveModelDialog(models)
    local modelList = type(models) == 'table' and models or {models}
    local targetName = 'sd_dialog_model_' .. tostring(modelList[1])

    for _, model in ipairs(modelList) do
        modelDialogs[model] = nil
    end

    Target.removeModel(modelList, targetName)
    return true
end

exports('addLocalEntity', AddEntityDialog)
exports('removeLocalEntity', RemoveEntityDialog)
exports('addModel', AddModelDialog)
exports('removeModel', RemoveModelDialog)

local spawnedEntities = {}
local entityPoints = {}

local function SpawnConfigEntity(entityConfig, index)
    if spawnedEntities[index] and DoesEntityExist(spawnedEntities[index]) then return end

    lib.requestModel(entityConfig.model)

    local ped = CreatePed(4, entityConfig.model,
        entityConfig.coords.x, entityConfig.coords.y,
        entityConfig.coords.z, entityConfig.coords.w, false, true)

    if not lib.waitFor(function()
        if DoesEntityExist(ped) then return true end
    end, 'Failed to create config ped', 5000) then
        SetModelAsNoLongerNeeded(entityConfig.model)
        return
    end

    if entityConfig.freeze ~= false then
        FreezeEntityPosition(ped, true)
    end

    if entityConfig.invincible ~= false then
        SetEntityInvincible(ped, true)
    end

    SetBlockingOfNonTemporaryEvents(ped, true)

    if entityConfig.scenario then
        TaskStartScenarioInPlace(ped, entityConfig.scenario, 0, true)
    elseif entityConfig.anim then
        if entityConfig.anim.dict then
            lib.requestAnimDict(entityConfig.anim.dict)
            TaskPlayAnim(ped, entityConfig.anim.dict, entityConfig.anim.name,
                entityConfig.anim.blendIn or 8.0, entityConfig.anim.blendOut or -8.0,
                entityConfig.anim.duration or -1, entityConfig.anim.flag or 1,
                entityConfig.anim.playbackRate or 0.0, false, false, false)
        end
    end

    SetModelAsNoLongerNeeded(entityConfig.model)
    spawnedEntities[index] = ped

    if entityConfig.dialog then
        AddEntityDialog(ped, entityConfig.dialog)
    end
end

local function DespawnConfigEntity(index)
    local ped = spawnedEntities[index]
    if ped and DoesEntityExist(ped) then
        RemoveEntityDialog(ped)
        DeleteEntity(ped)
        spawnedEntities[index] = nil
    end
end

local function InitConfigEntities()
    if not Config.entities or #Config.entities == 0 then return end

    for index, entityConfig in ipairs(Config.entities) do
        local spawnDist = entityConfig.spawnDistance or 50.0
        local despawnDist = entityConfig.despawnDistance or (spawnDist + 10.0)

        entityPoints[index] = lib.points.new({
            coords = vec3(entityConfig.coords.x, entityConfig.coords.y, entityConfig.coords.z),
            distance = despawnDist,
        })

        local point = entityPoints[index]
        point.entityIndex = index
        point.spawnDistance = spawnDist
        point.entityConfig = entityConfig

        function point:onEnter()
            SpawnConfigEntity(self.entityConfig, self.entityIndex)
        end

        function point:onExit()
            DespawnConfigEntity(self.entityIndex)
        end

        function point:nearby()
            if self.currentDistance <= self.spawnDistance then
                if not spawnedEntities[self.entityIndex] or not DoesEntityExist(spawnedEntities[self.entityIndex]) then
                    SpawnConfigEntity(self.entityConfig, self.entityIndex)
                end
            end
        end
    end
end

local function InitConfigModels()
    if not Config.models or #Config.models == 0 then return end

    for _, modelConfig in ipairs(Config.models) do
        if modelConfig.dialog then
            AddModelDialog(modelConfig.model, modelConfig.dialog)
        end
    end
end

CreateThread(function()
    while not lib do Wait(100) end
    Wait(500)
    InitConfigEntities()
    InitConfigModels()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if isDialogOpen then
        SetNuiFocus(false, false)
    end

    if dialogCamera then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(dialogCamera, false)
    end

    for index in pairs(spawnedEntities) do
        DespawnConfigEntity(index)
    end

    for index, point in pairs(entityPoints) do
        if point then
            point:remove()
            entityPoints[index] = nil
        end
    end
end)
