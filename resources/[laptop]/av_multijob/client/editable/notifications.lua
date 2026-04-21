RegisterNetEvent('av_multijob:notification', function(title, message, type)
    lib.notify({
        title = title,
        description = message,
        type = type
    })
end)