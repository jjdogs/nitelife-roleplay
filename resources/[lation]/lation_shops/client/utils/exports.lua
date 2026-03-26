-- exports.lation_shops:openShop('my_shop_id')
exports('openShop', function(shopId)
    local shop = GetShopRestrictions(shopId)
    if not shop then return end
    OpenShop(shopId, shop.jobRestriction, shop.operatingHours, shop.itemRequirement)
end)
