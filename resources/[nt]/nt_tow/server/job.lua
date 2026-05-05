exports['av_contacts']:newContact(Config.Contact)

RegisterNetEvent('nt_tow:completeJob')
AddEventHandler('nt_tow:completeJob', function(jobId, pay)
    local src = source
    pay = math.min(math.max(math.floor(tonumber(pay) or 0), 0), 1000)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    ---@diagnostic disable-next-line: undefined-field
    Player.Functions.AddMoney('bank', pay, 'Tow job completed')
    if Config.Debug then
        print(('[nt_tow] %s completed job %s — $%d paid to bank'):format(GetPlayerName(src), tostring(jobId), pay))
    end
end)

RegisterNetEvent('nt_tow:requestNewJob')
AddEventHandler('nt_tow:requestNewJob', function()
    TriggerEvent('citysim:addJob', 1)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local spots = {}
    for _, v in ipairs(Config.BreakdownSpots) do
        spots[#spots + 1] = { X = v.x, Y = v.y, Z = v.z, Heading = v.w }
    end
    TriggerEvent('citysim:loadSpawnPoints', json.encode(spots))
end)
