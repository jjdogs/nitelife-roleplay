local allExternal = {}
local allSuccess = {}

RegisterNUICallback("external", function(data, cb)
    local command = data and data.command
    local args = data and data.args
    dbug("external(command, args?)", command, args and json.encode(args) or "none")
    local result = false
    if command and allExternal[command] then
        dbug("Found external callback for command", command)
        result = allExternal[command]({args = args, extraData = data and data.extraData})
        dbug("External callback result for command", command, result)
    else
        dbug("No external callback found for command", command)
    end
    cb(result)
end)

RegisterNUICallback('success', function(data, cb)
    local command = data and data.command
    local args = data and data.args
    dbug("Command triggered successfully (command,args)", command, args and json.encode(args) or "none")
    local isAllowed = lib.callback.await('av_laptop:verifyPlayerCommand', false, command, args)
    dbug("Was player allowed to run this command?", isAllowed and "yes" or "no")
    if isAllowed then
        if command and allSuccess[command] then
            dbug("Found success callback for command", command)
            allSuccess[command]({args = args, extraData = data and data.extraData})
        end
        -- if command == "wifi-crack" then
        --     exports['av_laptop']:connect(args)
        -- end
    end
    cb("ok")
end)

RegisterNUICallback("failed", function(data, cb)
    local command = data and data.command
    local args = data and data.args
    dbug("Command failed to complete (command, args)", command, args and json.encode(args) or "none")
    -- SendNUIMessage({
    --     action = "terminal",
    --     data = {
    --         actions = {
    --             {
    --                 type = "text",
    --                 input = "FAIL: System lockdown triggered.",
    --                 style = "error",
    --                 delay = 0
    --             }
    --         }
    --     }
    -- })
    cb("ok")
end)

exports("terminal", function(actions)
    dbug("terminal(actions)", actions and json.encode(actions) or "none")
    if not actions then return end
    SendNUIMessage({
        action = "terminal",
        data = {
            actions = actions
        }
    })
end)

exports("addExternal", function(command, callback)
    dbug("addExternal(command, callback)", command, callback and "function" or "none")
    if not command or not callback then return end
    allExternal[command] = callback
    dbug("External command added", command)
end)

exports("addSuccess", function(command, callback)
    dbug("addSuccess(command, callback)", command, callback and "function" or "none")
    if not command or not callback then return end
    allSuccess[command] = callback
    dbug("Success callback added", command)
end)

RegisterNetEvent("av_laptop:terminal", function(actions)
    dbug("Received terminal event with actions", actions and json.encode(actions) or "none")
    if not actions then return end
    SendNUIMessage({
        action = "terminal",
        data = {
            actions = actions
        }
    })
end)