local setup =  require 'config.setup'

-- Display a notification
--- @param message string
--- @param type any
function ShowNotification(message, type)
    if setup.notify == 'lation_ui' then
        exports.lation_ui:notify({ message = message, type = type or 'info', icon = 'fas fa-shop' })
    elseif setup.notify == 'ox_lib' then
        lib.notify({ description = message, type = type or 'inform', position = 'top', icon = 'fas fa-shop' })
    elseif setup.notify == 'esx' then
        ESX.ShowNotification(message)
    elseif setup.notify == 'qb' then
        QBCore.Functions.Notify(message, type or 'primary')
    elseif setup.notify == 'okok' then
        exports['okokNotify']:Alert('Shops', message, 5000, type or 'info', false)
    elseif setup.notify == 'sd-notify' then
        exports['sd-notify']:Notify('Shops', message, type or 'primary')
    elseif setup.notify == 'wasabi_notify' then
        exports.wasabi_notify:notify('Shops', message, 5000, type or 'info', false, 'fas fa-shop')
    elseif setup.notify == 'custom' then
        -- Add custom notifications here
    end
end

-- Display notifications from server
--- @param message string
--- @param type string
RegisterNetEvent('lation_shops:notify', function(message, type)
    ShowNotification(message, type)
end)