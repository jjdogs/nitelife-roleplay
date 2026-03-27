--[[
    nt_3dminigames - Creator v0.1
    In-game tool for building minigame configurations.
    Open with: /ntcreator

    Gizmo powered by DemiAutomatic/object_gizmo
    https://github.com/DemiAutomatic/object_gizmo
]]

local isCreatorActive = false
local suppressClose   = false  -- prevents onClose → ExitCreator when hiding menu programmatically
local nameCounter     = 0      -- increments each session so default names stay unique

-- Per-session state; reset each time the creator opens
local session = nil

-- Table placement working state
local currentTableProp       = nil  -- entity handle of the prop currently being placed/edited
local currentTableModelIndex = 1    -- index into Config.Props.table_props
local isPlacingTable         = false
local lastScrollTime         = 0

-- ─── Session ──────────────────────────────────────────────────────────────────

local function NewSession()
    nameCounter = nameCounter + 1
    return {
        name  = 'Minigame' .. nameCounter,
        table = {
            prop    = nil,
            model   = nil,
            coords  = nil,
            rot     = nil,
            placed  = false,
        },
    }
end

-- ─── Cleanup ──────────────────────────────────────────────────────────────────

local function ExitCreator()
    isCreatorActive = false
    isPlacingTable  = false
    suppressClose   = false

    if currentTableProp then
        Props.Delete(currentTableProp)
        currentTableProp = nil
    end

    Cursor.Disable()
    UI.HideText()
end

-- ─── Model cycling ────────────────────────────────────────────────────────────

-- Spawns a new prop model at the position/rotation of the current one.
-- Only valid during the placement phase (before gizmo handoff).
local function CycleTableModel(direction)
    if not currentTableProp then return end

    local tableProps = Config.Props.table_props
    if not tableProps or #tableProps == 0 then return end

    local oldCoords = GetEntityCoords(currentTableProp)
    local oldRot    = GetEntityRotation(currentTableProp, 2)

    Props.Delete(currentTableProp)

    currentTableModelIndex = currentTableModelIndex + direction
    if currentTableModelIndex < 1 then
        currentTableModelIndex = #tableProps
    elseif currentTableModelIndex > #tableProps then
        currentTableModelIndex = 1
    end

    local newModel = tableProps[currentTableModelIndex]
    currentTableProp = Props.Spawn(newModel, oldCoords, oldRot)

    -- Unfreeze so raycast placement can still move it
    FreezeEntityPosition(currentTableProp, false)

    -- Keep session reference current
    session.table.prop  = currentTableProp
    session.table.model = newModel
end

-- ─── Menus ────────────────────────────────────────────────────────────────────

local ShowMainMenu
local ShowTableMenu

ShowMainMenu = function()
    local tableLabel = (session.table.placed and '✓ ' or '') .. 'Table'
    local tableDesc  = session.table.placed
        and ('Model: ' .. tostring(session.table.model))
        or  'Place the table prop'

    lib.registerContext({
        id      = 'nt_creator_main',
        title   = 'Minigame Creator',
        options = {
            {
                title       = 'Name: ' .. session.name,
                description = 'Click to rename',
                icon        = 'tag',
                onSelect    = function()
                    local result = lib.inputDialog('Minigame Name', {
                        { type = 'input', label = 'Name', default = session.name, required = true }
                    })
                    if result and result[1] and result[1] ~= '' then
                        session.name = result[1]
                    end
                    ShowMainMenu()
                end,
            },
            {
                title       = tableLabel,
                description = tableDesc,
                icon        = 'table',
                onSelect    = function()
                    if session.table.placed then
                        ShowTableMenu()
                    else
                        suppressClose = true
                        lib.hideContext()
                        StartTablePlacement()
                    end
                end,
            },
            {
                title       = 'Item',
                description = 'Coming soon',
                icon        = 'box-open',
                disabled    = true,
            },
            {
                title       = 'Camera',
                description = 'Coming soon',
                icon        = 'camera',
                disabled    = true,
            },
        },
        onClose = function()
            if suppressClose then
                suppressClose = false
                return
            end
            ExitCreator()
        end,
    })

    lib.showContext('nt_creator_main')
end

ShowTableMenu = function()
    lib.registerContext({
        id      = 'nt_creator_table',
        title   = '✓ Table',
        menu    = 'nt_creator_main',
        options = {
            {
                title       = 'Edit',
                description = 'Move the table prop with the gizmo',
                icon        = 'pencil',
                onSelect    = function()
                    suppressClose = true
                    lib.hideContext()
                    EditTable()
                end,
            },
            {
                title       = 'Remove',
                description = 'Delete the placed table',
                icon        = 'trash',
                onSelect    = function()
                    RemoveTable()
                    ShowMainMenu()
                end,
            },
        },
    })

    lib.showContext('nt_creator_table')
end

-- ─── Table placement ──────────────────────────────────────────────────────────

function StartTablePlacement()
    local tableProps = Config.Props.table_props
    if not tableProps or #tableProps == 0 then
        print('[nt_3dminigames] StartTablePlacement: Config.Props.table_props is empty')
        ShowMainMenu()
        return
    end

    currentTableModelIndex = 1
    local ped    = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local fwd    = GetEntityForwardVector(ped)
    local spawnPos = origin + fwd * 2.0

    currentTableProp  = Props.Spawn(tableProps[1], spawnPos, vector3(0, 0, 0))
    -- Unfreeze so SetEntityCoords can move it during cursor-follow
    FreezeEntityPosition(currentTableProp, false)

    session.table.prop  = currentTableProp
    session.table.model = tableProps[1]

    isPlacingTable = true
    Cursor.Enable(true)

    lib.showTextUI('[LMB] Confirm   [Scroll ↕] Cycle model   [BACKSPACE] Cancel', {
        position = 'left-center',
        icon     = 'arrows-up-down-left-right',
    })

    CreateThread(function()
        while isPlacingTable do
            Wait(0)

            Cursor.DisableControls()
            DisableControlAction(0, 14, true)   -- scroll up
            DisableControlAction(0, 15, true)   -- scroll down
            Cursor.Draw()

            -- Prop follows cursor
            if currentTableProp and DoesEntityExist(currentTableProp) then
                local hit, coords = Raycast.FromCursor(50.0)
                if hit and coords then
                    SetEntityCoords(currentTableProp, coords.x, coords.y, coords.z, false, false, false, false)
                end
            end

            -- Scroll to cycle model (150 ms debounce)
            local now = GetGameTimer()
            if now - lastScrollTime > 150 then
                if IsDisabledControlJustPressed(0, 14) then   -- scroll up
                    lastScrollTime = now
                    CycleTableModel(-1)
                elseif IsDisabledControlJustPressed(0, 15) then  -- scroll down
                    lastScrollTime = now
                    CycleTableModel(1)
                end
            end

            -- LMB → confirm position, hand off to gizmo
            if IsDisabledControlJustPressed(0, Config.Controls.interact) then
                isPlacingTable = false
                lib.hideTextUI()
                Cursor.Disable()
                StartGizmoForTable()
                return
            end

            -- BACKSPACE → cancel
            if IsDisabledControlJustPressed(0, Config.Controls.exit) then
                isPlacingTable = false
                lib.hideTextUI()
                if currentTableProp then
                    Props.Delete(currentTableProp)
                    currentTableProp = nil
                end
                session.table = { prop=nil, model=nil, coords=nil, rot=nil, placed=false }
                Cursor.Disable()
                Wait(0)  -- let BACKSPACE "just pressed" state clear before showing menu
                ShowMainMenu()
                return
            end
        end
    end)
end

-- Hand off to object_gizmo for fine positioning after initial cursor placement
function StartGizmoForTable()
    if not currentTableProp then
        ShowMainMenu()
        return
    end

    CreateThread(function()
        local result = exports.object_gizmo:useGizmo(currentTableProp)

        if result then
            session.table.coords = result.position
            session.table.rot    = result.rotation
            session.table.placed = true
            FreezeEntityPosition(currentTableProp, true)
            currentTableProp = nil
        else
            Props.Delete(currentTableProp)
            currentTableProp = nil
            session.table = { prop=nil, model=nil, coords=nil, rot=nil, placed=false }
        end

        ShowMainMenu()
    end)
end

-- Re-open the gizmo on the already-placed table prop
function EditTable()
    if not session.table.prop or not DoesEntityExist(session.table.prop) then
        session.table.placed = false
        ShowMainMenu()
        return
    end

    -- Unfreeze so gizmo can move it
    FreezeEntityPosition(session.table.prop, false)

    CreateThread(function()
        local result = exports.object_gizmo:useGizmo(session.table.prop)

        if result then
            session.table.coords = result.position
            session.table.rot    = result.rotation
            FreezeEntityPosition(session.table.prop, true)
        else
            -- Restore original position on failure
            if session.table.prop and DoesEntityExist(session.table.prop) then
                SetEntityCoords(session.table.prop, session.table.coords.x, session.table.coords.y, session.table.coords.z, false, false, false, false)
                SetEntityRotation(session.table.prop, session.table.rot.x, session.table.rot.y, session.table.rot.z, 2, true)
                FreezeEntityPosition(session.table.prop, true)
            end
        end

        ShowMainMenu()
    end)
end

function RemoveTable()
    if session.table.prop and DoesEntityExist(session.table.prop) then
        Props.Delete(session.table.prop)
    end
    currentTableProp = nil
    session.table = { prop=nil, model=nil, coords=nil, rot=nil, placed=false }
end

-- ─── Entry point ──────────────────────────────────────────────────────────────

if Config.Creator and Config.Creator.enabled == false then return end

RegisterCommand('ntcreator', function()
    if isCreatorActive then
        -- onClose may not have fired (e.g. ESC intercepted by pause menu);
        -- re-show the menu to recover rather than blocking the user.
        if not isPlacingTable then
            ShowMainMenu()
        end
        return
    end

    isCreatorActive = true
    session         = NewSession()

    ShowMainMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/ntcreator', 'Open the minigame creator')
