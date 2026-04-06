---@diagnostic disable: duplicate-set-field
-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

local found = GetResourceState('jaksam_inventory')
if found ~= 'started' and found ~= 'starting' then return end

WSB.inventory = {}
WSB.inventorySystem = 'jaksam_inventory'

local jaksam = exports['jaksam_inventory']
local registeredShops = {}
local registeredStashes = {}

---Convert bridge shop data to stash/inventory for jaksam (no native shop type)
local function ensureShopStash(data)
    if registeredShops[data.identifier] then return end
    local items = {}
    for _, row in ipairs(data.inventory or {}) do
        items[#items + 1] = { row.name, row.amount or 1, row.metadata or {} }
    end
    jaksam:createInventory(data.identifier, data.name or data.identifier, {
        maxSlots = math.max(50, #items),
        maxWeight = 1000,
    }, items, 'stash', nil)
    registeredShops[data.identifier] = true
end

AddEventHandler('wasabi_bridge:registerStash', function(data)
    local invokingResource = GetInvokingResource()
    if not invokingResource then return end
    if invokingResource:sub(1, 7) ~= 'wasabi_' then return end
    if registeredStashes[data.name] then return end
    jaksam:registerStash({
        id = data.name,
        label = data.name,
        maxWeight = data.maxWeight or 100,
        maxSlots = data.slots or 50,
        runtimeOnly = true,
    })
    registeredStashes[data.name] = true
end)

AddEventHandler('wasabi_bridge:registerShop', function(data)
    local invokingResource = GetInvokingResource()
    if not invokingResource then return end
    if invokingResource:sub(1, 7) ~= 'wasabi_' then return end
    ensureShopStash(data)
end)

RegisterNetEvent('wasabi_bridge:openShop', function(data)
    if not data or not data.identifier or not registeredShops[data.identifier] then return end
    if data.groups and not WSB.hasGroup(source, data.groups) then return end
    jaksam:forceOpenInventory(source, data.identifier)
end)

RegisterNetEvent('wasabi_bridge:openStash', function(data)
    local src = source
    -- Client already sets data.name to unique (name_identifier) when data.unique
    local stashId = data.name
    jaksam:registerStash({
        id = stashId,
        label = data.label or stashId,
        maxWeight = data.maxWeight or 100,
        maxSlots = data.slots or 50,
        runtimeOnly = true,
    })
    jaksam:forceOpenInventory(src, stashId)
end)

RegisterNetEvent('wasabi_bridge:openPlayerInventory', function(targetId)
    jaksam:forceOpenInventory(source, targetId)
end)

function WSB.inventory.getItemSlot(source, itemName)
    local item, slotId = jaksam:getItemByName(source, itemName)
    return slotId or false
end

function WSB.inventory.getItemSlots(source, itemName)
    local inv = jaksam:getInventory(source)
    if not inv or not inv.items then return {} end
    local slots = {}
    for slotKey, item in pairs(inv.items) do
        if item and item.name == itemName then
            local n = tonumber(slotKey:match('%d+')) or slotKey
            slots[#slots + 1] = n
        end
    end
    return slots
end

function WSB.inventory.getItemMetadata(source, slot)
    local item = jaksam:getItemFromSlot(source, slot)
    return item and item.metadata or nil
end

function WSB.inventory.setItemMetadata(source, slot, metadata)
    if not slot or not metadata then return false end
    local item = jaksam:getItemFromSlot(source, slot)
    if not item then return false end
    return jaksam:setItemMetadataInSlot(source, slot, metadata)
end

---Clears specified inventory
---@param source number
---@param identifier string|number|nil
---@param keepItems string|table|nil
function WSB.inventory.clearInventory(source, identifier, keepItems)
    local exclude = keepItems
    if type(keepItems) == 'string' then
        exclude = { keepItems }
    elseif type(keepItems) ~= 'table' or not next(keepItems) then
        exclude = nil
    end
    return jaksam:clearInventory(identifier or source, exclude)
end
