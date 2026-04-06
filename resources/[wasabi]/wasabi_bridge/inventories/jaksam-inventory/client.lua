---@diagnostic disable: duplicate-set-field
-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

local found = GetResourceState('jaksam_inventory')
if found ~= 'started' and found ~= 'starting' then return end

WSB.inventorySystem = 'jaksam_inventory'
WSB.inventory = {}

function WSB.inventory.openPlayerInventory(targetId)
    exports['jaksam_inventory']:openInventory(targetId)
end

function WSB.inventory.openStash(data)
    -- data = { name = name, unique = true, maxWeight = maxWeight, slots = slots }
    if data.unique then
        data.name = ('%s_%s'):format(data.name, WSB.getIdentifier())
    end
    TriggerServerEvent('wasabi_bridge:openStash', data)
end

function WSB.inventory.openShop(data)
    --[[
        Shops must be registered on the server via 'wasabi_bridge:registerShop'.
        See server.lua of this inventory for details.
    ]]
    TriggerServerEvent('wasabi_bridge:openShop', data)
end
