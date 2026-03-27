UI = {}

local hasLationUI = false
local textVisible = false

--- Initialize UI module and check for lation_ui
function UI.Init()
    if Config.UI.useLationUI then
        hasLationUI = GetResourceState('lation_ui') == 'started'
    end
    
    if hasLationUI then
        print('[nt_3dminigames] Using lation_ui for UI components')
    else
        print('[nt_3dminigames] Using ox_lib/native fallback for UI components')
    end
end

--- Check if lation_ui is available
---@return boolean
function UI.HasLationUI()
    return hasLationUI and Config.UI.useLationUI
end

--- Show text UI / instructions
---@param data table Text UI data
function UI.ShowText(data)
    textVisible = true
    
    if UI.HasLationUI() then
        exports.lation_ui:showText({
            title = data.title,
            description = data.description or data.text,
            icon = data.icon,
            iconColor = data.iconColor,
            keybind = data.keybind,
            position = data.position or Config.UI.textPosition,
            options = data.options,
        })
    else
        -- ox_lib fallback
        if lib and lib.showTextUI then
            local text = data.description or data.text or ''
            if data.title then
                text = '**' .. data.title .. '**\n' .. text
            end
            lib.showTextUI(text, {
                position = data.position or 'left-center',
                icon = data.icon,
            })
        else
            -- Native fallback
            UI._nativeTextData = data
        end
    end
end

--- Hide text UI
function UI.HideText()
    textVisible = false
    
    if UI.HasLationUI() then
        exports.lation_ui:hideText()
    else
        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end
        UI._nativeTextData = nil
    end
end

--- Check if text UI is visible
---@return boolean
function UI.IsTextVisible()
    return textVisible
end

--- Show notification
---@param data table Notification data
function UI.Notify(data)
    if UI.HasLationUI() then
        exports.lation_ui:notify({
            title = data.title,
            message = data.message or data.description,
            type = data.type or 'info',
            duration = data.duration or Config.UI.notifyDuration,
            position = data.position or Config.UI.notifyPosition,
            icon = data.icon,
            iconColor = data.iconColor,
        })
    else
        -- ox_lib fallback
        if lib and lib.notify then
            lib.notify({
                title = data.title,
                description = data.message or data.description,
                type = data.type or 'info',
                duration = data.duration or Config.UI.notifyDuration,
                position = data.position or 'top',
                icon = data.icon,
            })
        end
    end
end

--- Show progress bar
---@param data table Progress bar data
---@return boolean success
function UI.Progress(data)
    if UI.HasLationUI() then
        return exports.lation_ui:progressBar({
            label = data.label,
            description = data.description,
            duration = data.duration,
            icon = data.icon or 'fas fa-spinner',
            iconAnimation = data.iconAnimation or 'spin',
            canCancel = data.canCancel ~= false,
            position = data.position or Config.UI.progressPosition,
        })
    else
        -- ox_lib fallback
        if lib and lib.progressBar then
            return lib.progressBar({
                label = data.label,
                duration = data.duration,
                canCancel = data.canCancel ~= false,
                disable = data.disable or { move = true, car = true, combat = true },
                anim = data.anim,
                prop = data.prop,
            })
        end
    end
    
    return true
end

--- Check if progress bar is active
---@return boolean
function UI.IsProgressActive()
    if UI.HasLationUI() then
        return exports.lation_ui:isProgressActive()
    else
        if lib and lib.progressActive then
            return lib.progressActive()
        end
    end
    return false
end

--- Cancel active progress bar
function UI.CancelProgress()
    if UI.HasLationUI() then
        exports.lation_ui:cancelProgress()
    else
        if lib and lib.cancelProgress then
            lib.cancelProgress()
        end
    end
end

--- Show alert dialog
---@param data table Alert data
---@return string 'confirm' or 'cancel'
function UI.Alert(data)
    if UI.HasLationUI() then
        return exports.lation_ui:alert({
            header = data.header or data.title,
            content = data.content or data.message,
            icon = data.icon,
            iconColor = data.iconColor,
            type = data.type,
            size = data.size,
            cancel = data.cancel ~= false,
            labels = data.labels,
        })
    else
        -- ox_lib fallback
        if lib and lib.alertDialog then
            local result = lib.alertDialog({
                header = data.header or data.title,
                content = data.content or data.message,
                centered = true,
                cancel = data.cancel ~= false,
            })
            return result or 'cancel'
        end
    end
    
    return 'confirm'
end

--- Show input dialog
---@param data table Input dialog data
---@return table|nil Input values or nil if cancelled
function UI.Input(data)
    if UI.HasLationUI() then
        return exports.lation_ui:input({
            header = data.header or data.title,
            description = data.description,
            inputs = data.inputs or data.options,
        })
    else
        -- ox_lib fallback
        if lib and lib.inputDialog then
            return lib.inputDialog(data.header or data.title, data.inputs or data.options)
        end
    end
    
    return nil
end

--- Show menu
---@param data table Menu data
function UI.Menu(data)
    if UI.HasLationUI() then
        exports.lation_ui:registerMenu({
            id = data.id,
            title = data.title,
            subtitle = data.subtitle,
            options = data.options,
            onExit = data.onClose or data.onExit,
            position = data.position,
        })
        exports.lation_ui:showMenu(data.id)
    else
        -- ox_lib fallback
        if lib and lib.registerContext then
            lib.registerContext({
                id = data.id,
                title = data.title,
                options = data.options,
                onExit = data.onClose,
            })
            lib.showContext(data.id)
        end
    end
end

--- Hide menu
function UI.HideMenu()
    if UI.HasLationUI() then
        exports.lation_ui:hideMenu()
    else
        if lib and lib.hideContext then
            lib.hideContext()
        end
    end
end

--- Draw native text (fallback when no UI library)
--- Call this in a tick if using native fallback
function UI.DrawNative()
    if not UI._nativeTextData then return end
    
    local data = UI._nativeTextData
    local text = data.description or data.text or ''
    if data.title then
        text = data.title .. '\n' .. text
    end
    if data.keybind then
        text = '[' .. data.keybind .. '] ' .. text
    end
    
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.02, 0.5)
end

--- Show minigame instructions
---@param instructions table Array of {key, text} pairs
function UI.ShowInstructions(instructions)
    local options = {}
    for _, inst in ipairs(instructions) do
        table.insert(options, {
            label = inst.text,
            keybind = inst.key,
            icon = inst.icon,
        })
    end
    
    UI.ShowText({
        title = 'Controls',
        options = options,
        position = Config.UI.textPosition,
    })
end

--- Show minigame progress
---@param current number Current value
---@param max number Maximum value
---@param label string|nil Optional label
function UI.ShowProgress(current, max, label)
    local percent = math.floor((current / max) * 100)
    
    UI.ShowText({
        title = label or 'Progress',
        description = string.format('%d%%', percent),
        icon = 'fas fa-tasks',
    })
end

-- Initialize on resource start
CreateThread(function()
    Wait(100)
    UI.Init()
end)

return UI
