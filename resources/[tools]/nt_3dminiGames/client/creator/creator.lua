--[[
    nt_3dminigames - In-Game Creator
    Build and save minigames without coding
]]

local isCreatorActive = false
local creatorData = nil
local freecamActive = false
local selectedZone = nil

--- Start the minigame creator
local function StartCreator()
    if isCreatorActive then
        UI.Notify({ title = 'Creator', message = 'Creator already open', type = 'error' })
        return
    end
    
    isCreatorActive = true
    creatorData = {
        name = 'New Minigame',
        type = 'pour',
        zones = {},
        targets = {},
        camera = nil,
        holdProp = nil,
        particle = nil,
    }
    
    ShowCreatorMenu()
end

--- Show main creator menu
function ShowCreatorMenu()
    UI.Menu({
        id = 'minigame_creator',
        title = 'Minigame Creator',
        subtitle = creatorData.name,
        options = {
            {
                title = 'Minigame Name',
                description = 'Current: ' .. creatorData.name,
                icon = 'fas fa-tag',
                onSelect = function()
                    local result = UI.Input({
                        header = 'Minigame Name',
                        inputs = {
                            { type = 'input', label = 'Name', default = creatorData.name }
                        }
                    })
                    if result and result[1] then
                        creatorData.name = result[1]
                    end
                    ShowCreatorMenu()
                end
            },
            {
                title = 'Minigame Type',
                description = 'Current: ' .. creatorData.type,
                icon = 'fas fa-gamepad',
                onSelect = function()
                    ShowTypeMenu()
                end
            },
            {
                title = 'Set Camera Position',
                description = 'Define the minigame camera view',
                icon = 'fas fa-camera',
                onSelect = function()
                    StartCameraPlacement()
                end
            },
            {
                title = 'Add Zone',
                description = 'Add an interaction zone (' .. #creatorData.zones .. ' zones)',
                icon = 'fas fa-vector-square',
                onSelect = function()
                    StartZonePlacement()
                end
            },
            {
                title = 'Set Hold Prop',
                description = 'Prop player holds (cursor attached)',
                icon = 'fas fa-hand-holding',
                onSelect = function()
                    ShowPropMenu('holdProp')
                end
            },
            {
                title = 'Set Particle Effect',
                description = 'Pour/spray particle effect',
                icon = 'fas fa-spray-can',
                onSelect = function()
                    ShowParticleMenu()
                end
            },
            {
                title = 'Preview Minigame',
                description = 'Test the current configuration',
                icon = 'fas fa-play',
                onSelect = function()
                    PreviewMinigame()
                end
            },
            {
                title = 'Save Minigame',
                description = 'Save to file',
                icon = 'fas fa-save',
                onSelect = function()
                    SaveMinigame()
                end
            },
            {
                title = 'Exit Creator',
                description = 'Close without saving',
                icon = 'fas fa-times',
                iconColor = '#EF4444',
                onSelect = function()
                    local result = UI.Alert({
                        header = 'Exit Creator',
                        content = 'Are you sure? Unsaved changes will be lost.',
                        type = 'warning',
                    })
                    if result == 'confirm' then
                        ExitCreator()
                    else
                        ShowCreatorMenu()
                    end
                end
            },
        },
        onClose = function()
            -- Don't close creator, just menu
        end
    })
end

--- Show type selection menu
function ShowTypeMenu()
    local options = {}
    
    for typeName, typeData in pairs(Config.MinigameTypes) do
        table.insert(options, {
            title = typeName:sub(1,1):upper() .. typeName:sub(2),
            description = typeData.description,
            icon = 'fas fa-gamepad',
            onSelect = function()
                creatorData.type = typeName
                UI.Notify({ title = 'Type Set', message = 'Type: ' .. typeName, type = 'success' })
                ShowCreatorMenu()
            end
        })
    end
    
    UI.Menu({
        id = 'creator_type',
        title = 'Select Type',
        options = options,
        onClose = function()
            ShowCreatorMenu()
        end
    })
end

--- Start camera placement mode
function StartCameraPlacement()
    UI.HideMenu()
    freecamActive = true
    
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    
    -- Start at a default position looking at player
    local camCoords = playerCoords + vector3(0, 2, 2)
    local camRot = vector3(-30, 0, 180)
    
    Camera.Create(camCoords, camRot, 50)
    Cursor.Enable(true)
    
    UI.ShowText({
        title = 'Camera Placement',
        options = {
            { label = 'Move Camera', keybind = 'WASD' },
            { label = 'Rotate', keybind = 'Mouse' },
            { label = 'Up/Down', keybind = 'Q/E' },
            { label = 'Confirm', keybind = 'ENTER' },
            { label = 'Cancel', keybind = 'BACKSPACE' },
        }
    })
    
    CreateThread(function()
        while freecamActive do
            Wait(0)
            
            local cam = Camera.Get()
            if not cam then break end
            
            local currentCoords = GetCamCoord(cam)
            local currentRot = GetCamRot(cam, 2)
            local speed = Config.Creator.freecamSpeed
            
            -- Movement
            local forward = Camera.GetForwardVector()
            local right = Cursor.RotationToRight(currentRot)
            
            if IsDisabledControlPressed(0, 32) then -- W
                currentCoords = currentCoords + forward * speed
            end
            if IsDisabledControlPressed(0, 33) then -- S
                currentCoords = currentCoords - forward * speed
            end
            if IsDisabledControlPressed(0, 34) then -- A
                currentCoords = currentCoords - right * speed
            end
            if IsDisabledControlPressed(0, 35) then -- D
                currentCoords = currentCoords + right * speed
            end
            if IsDisabledControlPressed(0, 44) then -- Q (down)
                currentCoords = currentCoords - vector3(0, 0, speed)
            end
            if IsDisabledControlPressed(0, 38) then -- E (up)
                currentCoords = currentCoords + vector3(0, 0, speed)
            end
            
            Camera.SetCoords(currentCoords)
            
            -- Rotation (mouse)
            Camera.HandleLook(1.5)
            
            -- Confirm
            if IsDisabledControlJustPressed(0, 191) then -- ENTER
                creatorData.camera = {
                    coords = GetCamCoord(cam),
                    rot = GetCamRot(cam, 2),
                    fov = GetCamFov(cam),
                }
                UI.Notify({ title = 'Camera Saved', message = 'Camera position saved', type = 'success' })
                ExitCameraPlacement()
                return
            end
            
            -- Cancel
            if IsDisabledControlJustPressed(0, 177) then -- BACKSPACE
                ExitCameraPlacement()
                return
            end
            
            Cursor.DisableControls()
        end
    end)
end

--- Exit camera placement mode
function ExitCameraPlacement()
    freecamActive = false
    Camera.Destroy()
    Cursor.Disable()
    UI.HideText()
    ShowCreatorMenu()
end

--- Start zone placement mode
function StartZonePlacement()
    UI.HideMenu()
    
    local ped = PlayerPedId()
    local placing = true
    local zoneCoords = GetEntityCoords(ped) + vector3(0, 1, 0)
    local zoneSize = vector3(0.5, 0.5, 0.2)
    
    UI.ShowText({
        title = 'Zone Placement',
        options = {
            { label = 'Move Zone', keybind = 'WASD' },
            { label = 'Resize', keybind = 'Scroll' },
            { label = 'Height', keybind = 'Q/E' },
            { label = 'Place Zone', keybind = 'ENTER' },
            { label = 'Done', keybind = 'BACKSPACE' },
        }
    })
    
    CreateThread(function()
        while placing do
            Wait(0)
            
            local speed = 0.02
            
            -- Movement
            if IsDisabledControlPressed(0, 32) then zoneCoords = zoneCoords + vector3(0, speed, 0) end
            if IsDisabledControlPressed(0, 33) then zoneCoords = zoneCoords - vector3(0, speed, 0) end
            if IsDisabledControlPressed(0, 34) then zoneCoords = zoneCoords - vector3(speed, 0, 0) end
            if IsDisabledControlPressed(0, 35) then zoneCoords = zoneCoords + vector3(speed, 0, 0) end
            if IsDisabledControlPressed(0, 44) then zoneCoords = zoneCoords - vector3(0, 0, speed) end
            if IsDisabledControlPressed(0, 38) then zoneCoords = zoneCoords + vector3(0, 0, speed) end
            
            -- Resize with scroll
            local scroll = GetDisabledControlNormal(0, 14)
            if scroll ~= 0 then
                local change = scroll * 0.05
                zoneSize = vector3(
                    math.max(0.1, zoneSize.x + change),
                    math.max(0.1, zoneSize.y + change),
                    zoneSize.z
                )
            end
            
            -- Draw preview
            DrawMarker(
                1, zoneCoords.x, zoneCoords.y, zoneCoords.z - zoneSize.z/2,
                0, 0, 0, 0, 0, 0,
                zoneSize.x, zoneSize.y, zoneSize.z,
                0, 255, 0, 100,
                false, false, 2, false, nil, nil, false
            )
            
            -- Place zone
            if IsDisabledControlJustPressed(0, 191) then -- ENTER
                table.insert(creatorData.zones, {
                    coords = zoneCoords,
                    size = zoneSize,
                    maxProgress = 50,
                })
                UI.Notify({ title = 'Zone Added', message = 'Zone #' .. #creatorData.zones .. ' placed', type = 'success' })
            end
            
            -- Done
            if IsDisabledControlJustPressed(0, 177) then -- BACKSPACE
                placing = false
            end
            
            Cursor.DisableControls()
        end
        
        UI.HideText()
        ShowCreatorMenu()
    end)
end

--- Show prop selection menu
function ShowPropMenu(propType)
    local options = {}
    
    for name, model in pairs(Config.DefaultProps) do
        table.insert(options, {
            title = name:gsub('_', ' '):gsub('^%l', string.upper),
            description = model,
            icon = 'fas fa-cube',
            onSelect = function()
                creatorData[propType] = model
                UI.Notify({ title = 'Prop Set', message = 'Set to: ' .. model, type = 'success' })
                ShowCreatorMenu()
            end
        })
    end
    
    -- Custom prop option
    table.insert(options, {
        title = 'Custom Prop',
        description = 'Enter prop model name',
        icon = 'fas fa-keyboard',
        onSelect = function()
            local result = UI.Input({
                header = 'Custom Prop',
                inputs = {
                    { type = 'input', label = 'Model Name', placeholder = 'prop_example' }
                }
            })
            if result and result[1] then
                creatorData[propType] = result[1]
                UI.Notify({ title = 'Prop Set', message = 'Set to: ' .. result[1], type = 'success' })
            end
            ShowCreatorMenu()
        end
    })
    
    UI.Menu({
        id = 'creator_prop',
        title = 'Select Prop',
        options = options,
        onClose = function()
            ShowCreatorMenu()
        end
    })
end

--- Show particle selection menu
function ShowParticleMenu()
    local options = {
        {
            title = 'Water Pour',
            description = 'Water pouring effect',
            icon = 'fas fa-tint',
            onSelect = function()
                creatorData.particle = { dict = 'core', name = 'ent_sht_water', scale = 0.5 }
                ShowCreatorMenu()
            end
        },
        {
            title = 'Dust',
            description = 'Dust/powder effect',
            icon = 'fas fa-cloud',
            onSelect = function()
                creatorData.particle = { dict = 'core', name = 'ent_dst_rocks', scale = 0.5 }
                ShowCreatorMenu()
            end
        },
        {
            title = 'Sparks',
            description = 'Spark effect',
            icon = 'fas fa-bolt',
            onSelect = function()
                creatorData.particle = { dict = 'core', name = 'ent_ray_heli_spark', scale = 0.5 }
                ShowCreatorMenu()
            end
        },
        {
            title = 'None',
            description = 'No particle effect',
            icon = 'fas fa-ban',
            onSelect = function()
                creatorData.particle = nil
                ShowCreatorMenu()
            end
        },
    }
    
    UI.Menu({
        id = 'creator_particle',
        title = 'Select Particle',
        options = options,
        onClose = function()
            ShowCreatorMenu()
        end
    })
end

--- Preview the minigame
function PreviewMinigame()
    if not creatorData.camera then
        UI.Notify({ title = 'Error', message = 'Set camera position first', type = 'error' })
        return
    end
    
    if #creatorData.zones == 0 then
        UI.Notify({ title = 'Error', message = 'Add at least one zone', type = 'error' })
        return
    end
    
    UI.HideMenu()
    
    local config = {
        type = creatorData.type,
        name = creatorData.name,
        camera = creatorData.camera,
        zones = creatorData.zones,
        holdProp = creatorData.holdProp,
        particle = creatorData.particle,
        pourRate = 2.0,
        winCondition = { coverage = 100 },
    }
    
    exports['nt_3dminigames']:StartMinigame(config, function(success, data)
        UI.Notify({ 
            title = 'Preview Complete', 
            message = success and 'Completed!' or 'Cancelled', 
            type = success and 'success' or 'info' 
        })
        ShowCreatorMenu()
    end)
end

--- Save minigame to file
function SaveMinigame()
    local result = UI.Alert({
        header = 'Save Minigame',
        content = 'Save "' .. creatorData.name .. '" to registered minigames?',
        type = 'info',
    })
    
    if result == 'confirm' then
        local config = {
            type = creatorData.type,
            name = creatorData.name,
            camera = creatorData.camera,
            zones = creatorData.zones,
            targets = creatorData.targets,
            holdProp = creatorData.holdProp,
            particle = creatorData.particle,
            pourRate = 2.0,
            winCondition = { coverage = 100 },
        }
        
        exports['nt_3dminigames']:RegisterMinigame(creatorData.name, config)
        
        -- Print config for manual saving
        print('--- MINIGAME CONFIG ---')
        print('RegisterMinigame("' .. creatorData.name .. '", ' .. json.encode(config, { indent = true }) .. ')')
        print('--- END CONFIG ---')
        
        UI.Notify({ 
            title = 'Saved', 
            message = 'Minigame registered! Check console for config.', 
            type = 'success' 
        })
    end
    
    ShowCreatorMenu()
end

--- Exit the creator
function ExitCreator()
    isCreatorActive = false
    creatorData = nil
    Camera.Destroy()
    Cursor.Disable()
    UI.HideText()
    UI.HideMenu()
end

--- Check if creator is active
function IsCreatorActive()
    return isCreatorActive
end

-- Register command
if Config.Creator.enabled then
    RegisterCommand(Config.Creator.command, function()
        StartCreator()
    end, false)
    
    TriggerEvent('chat:addSuggestion', '/' .. Config.Creator.command, 'Open the minigame creator')
end

-- Exports
exports('StartCreator', StartCreator)
exports('IsCreatorActive', IsCreatorActive)
