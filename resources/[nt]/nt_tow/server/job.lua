local registered = exports['av_contacts']:newContact(Config.Contact)

exports.qbx_core:CreateUseableItem('flatbed_control', function(source)
    TriggerClientEvent('nt_tow:openControl', source)
end)