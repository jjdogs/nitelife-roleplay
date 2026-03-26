lib = lib or {}

lib.registerContext = function(context)
    return exports.lation_ui:registerMenu(context)
end

lib.showContext = function(id)
    return exports.lation_ui:showMenu(id)
end

lib.alertDialog = function(data)
    return exports.lation_ui:alert(data)
end

lib.closeAlertDialog = function()
    return exports.lation_ui:closeAlert()
end

lib.hideContext = function()
    return exports.lation_ui:hideMenu()
end

lib.getOpenContextMenu = function()
    return exports.lation_ui:getOpenMenu()
end

lib.progressBar = function(data)
    return exports.lation_ui:progressBar(data)
end

lib.progressCircle = function(data)
    return exports.lation_ui:progressBar(data)
end

lib.progressActive = function()
    return exports.lation_ui:progressActive()
end

lib.cancelProgress = function()
    return exports.lation_ui:cancelProgress()
end

lib.showTextUI = function(text, options)
    if type(text) == 'table' and options == nil then
        return exports.lation_ui:showText(text)
    end

    local data = options or {}

    data.description = text

    return exports.lation_ui:showText(data)
end

lib.hideTextUI = function()
    return exports.lation_ui:hideText()
end

lib.isTextUIOpen = function()
    return exports.lation_ui:isOpen()
end

lib.skillCheck = function(difficulty, inputs)
    return exports.lation_ui:skillCheck(nil, difficulty, inputs)
end

lib.cancelSkillCheck = function()
    return exports.lation_ui:cancelSkillCheck()
end

lib.skillCheckActive = function()
    return exports.lation_ui:skillCheckActive()
end

if IsDuplicityVersion() then
    lib.notify = function(playerId, data)
        if type(playerId) ~= 'number' or type(data) ~= 'table' then
            return
        end

        TriggerClientEvent('lation_ui:notify', playerId, data)
    end
else
    lib.notify = function(a, b)
        local data

        if type(a) == 'table' then
            data = a
        elseif type(a) == 'number' and type(b) == 'table' then
            data = b
        else
            return
        end

        local notifyData = {}

        for k, v in pairs(data) do
            notifyData[k] = v
        end

        if notifyData.description and not notifyData.message then
            notifyData.message = notifyData.description
        end

        if notifyData.type == 'inform' then
            notifyData.type = 'info'
        end

        return exports.lation_ui:notify(notifyData)
    end
end

lib.inputDialog = function(heading, rows, options)
    local data = {}

    data.title = heading

    if type(rows) == 'table' then
        data.options = rows
    else
        data.options = { rows }
    end

    for i, option in ipairs(data.options) do
        if type(option) == 'string' then
            data.options[i] = {
                type = 'input',
                label = option
            }
        elseif type(option) == 'table' and not option.type then
            option.type = 'input'
        end
    end

    if type(options) == 'table' then
        for k, v in pairs(options) do
            data[k] = v
        end
        if options.allowCancel ~= nil then
            data.cancel = options.allowCancel
        end
    end

    return exports.lation_ui:input(data)
end

lib.closeInputDialog = function()
    return exports.lation_ui:closeInput()
end

lib.registerRadial = function(radial)
    return exports.lation_ui:registerRadial(radial)
end

lib.addRadialItem = function(items)
    return exports.lation_ui:addRadialItem(items)
end

lib.removeRadialItem = function(id)
    return exports.lation_ui:removeRadialItem(id)
end

lib.clearRadialItems = function()
    return exports.lation_ui:clearRadialItems()
end

lib.hideRadial = function()
    return exports.lation_ui:hideRadial()
end

lib.disableRadial = function(state)
    return exports.lation_ui:disableRadial(state)
end

lib.getCurrentRadialId = function()
    return exports.lation_ui:getCurrentRadialId()
end

_G.lib = lib