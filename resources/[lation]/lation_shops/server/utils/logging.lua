local logs = require 'config.logs'

-- Check to see if fm-logs or fmsdk is started
local fmlogs = GetResourceState('fm-logs') == 'started'
local fmsdk = GetResourceState('fmsdk') == 'started'

-- Log player events if applicable
--- @param source number Player ID
--- @param title string Log title
--- @param message string Message contents
function LogEvent(source, title, message)
    if logs.service == 'fivemanage' then
        if not fmsdk then return end
        if logs.screenshots then
            exports.fmsdk:takeServerImage(source, {
                name = title,
                description = message,
            })
        else
            exports.fmsdk:LogMessage('info', message)
        end
    elseif logs.service == 'fivemerr' then
        if not fmlogs then return end
        exports['fm-logs']:createLog({
            LogType = 'Player',
            Message = message,
            Resource = 'lation_shops',
            Source = source,
        }, { Screenshot = logs.screenshots })
    elseif logs.service == 'discord' then
        local embed = {
            {
                ["color"] = 16711680,
                ["title"] = "**".. title .."**",
                ["description"] = message,
                ["footer"] = {
                    ["text"] = os.date("%a %b %d, %I:%M%p"),
                    ["icon_url"] = logs.discord.footer
                }
            }
        }
        PerformHttpRequest(logs.discord.link, function()
        end, 'POST', json.encode({username = logs.discord.name, embeds = embed, avatar_url = logs.discord.image}),
        {['Content-Type'] = 'application/json'})
    end
end