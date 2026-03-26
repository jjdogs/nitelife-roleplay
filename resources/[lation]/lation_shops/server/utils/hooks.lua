--- ===========================================================================
--- CUSTOM HOOKS
--- ===========================================================================
--- These are empty functions that you can fill with custom logic for your server.
--- They are called at specific points during shop operations.

--- Called BEFORE a player purchases an item from a shop
--- Return false to deny the purchase, or true to allow it
--- @param source number Player ID
--- @param shopId string Shop ID (e.g., '24_7', 'weapon_shop')
--- @param item string Item name being purchased
--- @param quantity number Quantity being purchased
--- @param price number Price per item
--- @param metadata table|nil Item metadata
--- @return boolean allowed Whether the purchase should be allowed
function OnBeforeItemPurchase(source, shopId, item, quantity, price, metadata)
    -- Example: Limit purchases based on player level
    -- local playerLevel = exports.xp_system:GetLevel(source)
    -- if item == 'advanced_rifle' and playerLevel < 10 then
    --     return false
    -- end

    return true -- Allow the purchase
end

--- Called to modify item metadata BEFORE the item is added to inventory
--- Return a table to use custom metadata, or nil to use the shop's default metadata
--- This is useful for items that need player-specific data (e.g., ID cards)
--- @param source number Player ID
--- @param shopId string Shop ID (e.g., '24_7', 'weapon_shop')
--- @param item string Item name being purchased
--- @param quantity number Quantity being purchased
--- @param price number Price per item
--- @param metadata table|nil Original item metadata from shop
--- @return table|nil customMetadata Custom metadata to use, or nil to use original
function OnPurchaseItemMetadata(source, shopId, item, quantity, price, metadata)
    -- Example: Add player data to ID card
    -- if item == 'id_card' then
    --     return exports.qbx_idcard:GetMetaLicense(source, 'id_card')
    -- end

    return nil -- Return nil to use shop's original metadata and/or no metadata
end

--- Called when a player purchases an item from a shop
--- @param source number Player ID
--- @param shopId string Shop ID (e.g., '24_7', 'weapon_shop')
--- @param item string Item name that was purchased
--- @param quantity number Quantity purchased
--- @param price number Price per item
--- @param metadata table|nil Item metadata
function OnItemPurchased(source, shopId, item, quantity, price, metadata)
    -- Example: Register weapon purchase
    -- if shopId == 'weapon_shop' then
    --     exports['your_mdt']:RegisterWeapon(source, item)
    -- end

    -- Example: Alert police for illegal purchases
    -- if shopId == 'illegal_shop' then
    --     TriggerEvent('police:alert', 'Illegal purchase detected')
    -- end
end

--- Called when a shop is created by an admin
--- @param source number Admin player ID
--- @param shopId string Shop ID
--- @param shopData table Complete shop data
function OnShopCreated(source, shopId, shopData)

end

--- Called when a shop is edited by an admin
--- @param source number Admin player ID
--- @param shopId string Shop ID
--- @param shopData table Updated shop data
function OnShopEdited(source, shopId, shopData)

end

--- Called when a shop is deleted by an admin
--- @param source number Admin player ID
--- @param shopId string Shop ID
function OnShopDeleted(source, shopId)

end

--- Called when revenue is shared to a society account
--- @param shopId string Shop ID
--- @param society string Society/job name
--- @param amount number Amount shared
--- @param percentage number Percentage of revenue shared
function OnRevenueShared(shopId, society, amount, percentage)

end

--- Called BEFORE a player sells an item to a shop
--- Return false to deny the sale, or true to allow it
--- @param source number Player ID
--- @param shopId string Shop ID
--- @param item string Item name being sold
--- @param quantity number Quantity being sold
--- @param sellPrice number Sell price per item
--- @return boolean allowed Whether the sale should be allowed
function OnBeforeItemSell(source, shopId, item, quantity, sellPrice)
    -- Example: Block selling stolen items
    -- if exports['your_resource']:IsItemStolen(source, item) then
    --     return false
    -- end

    return true -- Allow the sale
end

--- Called when a player successfully sells an item to a shop
--- @param source number Player ID
--- @param shopId string Shop ID
--- @param item string Item name that was sold
--- @param quantity number Quantity sold
--- @param sellPrice number Sell price per item
function OnItemSold(source, shopId, item, quantity, sellPrice)
    -- Example: Track economy stats
    -- exports['your_economy']:RecordSale(source, shopId, item, quantity, sellPrice)
end

return {
    OnBeforeItemPurchase = OnBeforeItemPurchase,
    OnPurchaseItemMetadata = OnPurchaseItemMetadata,
    OnItemPurchased = OnItemPurchased,
    OnShopCreated = OnShopCreated,
    OnShopEdited = OnShopEdited,
    OnShopDeleted = OnShopDeleted,
    OnRevenueShared = OnRevenueShared,
    OnBeforeItemSell = OnBeforeItemSell,
    OnItemSold = OnItemSold
}
