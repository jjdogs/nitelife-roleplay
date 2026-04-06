function ShowNotification(source, msg, type)
    if Config.Notify == "qb" then
        TriggerClientEvent('QBCore:Notify', source, msg, type)
    elseif Config.Notify == "ox" then
        TriggerClientEvent('ox_lib:notify', source, {type = type, description = msg})
    elseif Config.Notify == "esx" then
        TriggerClientEvent('esx:showNotification', source, msg)
    elseif Config.Notify == "okok" then
        TriggerClientEvent('okokNotify:Alert', source, "Bundles", msg, 5000, type)
    end
end

function ForceTakeFingerprint(source)
    if Config.FingerprintScannerData.forceTakeFingerprint then
        return true
    end

    return IsPlayerDead(source) -- edit this in server/open/modules/framework/[framework].lua to fit your framework's is dead logic
end

function GenerateFingerPrint(source)
    local template = "xxxx-yyy-xxxx-yyy-xxxx"
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function GenerateDNAId(source)
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local pouchAllowedItems = {
    ["collected_evidence_bag"] = true,
    -- add items you want to allow in the pouch here
}

local hook = exports.ox_inventory:registerHook("swapItems", function(payload)
    if payload.action == "swap" and (startsWith(tostring(payload.fromInventory), "pouchevidence_") or startsWith(tostring(payload.toInventory), "pouchevidence_")) then
        return false
    end

    if startsWith(payload.toInventory, "pouchevidence_") and not pouchAllowedItems[payload.fromSlot.name] then
        return false
    end

    return true
end)