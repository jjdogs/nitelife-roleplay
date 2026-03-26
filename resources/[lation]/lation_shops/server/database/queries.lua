local queries = {}

-- =====================================================
-- SHOP QUERIES
-- =====================================================

function queries.getAllShops()
    local result = MySQL.query.await('SELECT * FROM lation_shops')

    if not result then
        print('^1[ERROR]: Failed to load shops from database^0')
        return {}
    end

    local shops = {}

    for _, shopRow in ipairs(result) do
        local shop = {
            id = shopRow.shop_id,
            name = shopRow.name,
            title = shopRow.title,
            subtitle = shopRow.subtitle,
            currency = shopRow.currency,
            blip = json.decode(shopRow.blip),
            locations = json.decode(shopRow.locations) or {},
            categories = json.decode(shopRow.categories) or {},
            paymentMethods = json.decode(shopRow.payment_methods) or {},
            operatingHours = json.decode(shopRow.operating_hours),
            jobRestriction = json.decode(shopRow.job_restriction),
            itemRequirement = json.decode(shopRow.item_requirement),
            itemWhitelist = json.decode(shopRow.item_whitelist),
            revenueShares = json.decode(shopRow.revenue_shares) or {},
            hideAllCategory = shopRow.hide_all_category or false,
            randomPrices = shopRow.random_prices_enabled and {
                enabled = shopRow.random_prices_enabled,
                percentage = shopRow.random_prices_percentage
            } or nil,
            shopMode = shopRow.shop_mode or 'buy',
            sellPricePercentage = shopRow.sell_price_percentage,
            sellPaymentSource = shopRow.sell_payment_source and json.decode(shopRow.sell_payment_source) or nil,
            balance = shopRow.balance or 0,
            inventory = {}
        }

        if shop.blip and type(shop.blip) == 'table' and not next(shop.blip) then
            shop.blip = nil
        end

        local inventory = queries.getInventory(shopRow.shop_id)

        if inventory then
            for _, item in ipairs(inventory) do
                table.insert(shop.inventory, {
                    item = item.item_name,
                    label = item.label,
                    description = item.description,
                    category = item.category,
                    icon = item.icon,
                    price = item.base_price or item.price, -- Admin panel always shows base price
                    stock = item.stock,
                    metadata = item.metadata and json.decode(item.metadata) or nil,
                    license = item.license,
                    jobRestriction = json.decode(item.job_restriction),
                    sellPrice = item.sell_price,
                    sellEnabled = item.sell_enabled == 1 or item.sell_enabled == true,
                    sellHidden  = item.sell_hidden  == 1 or item.sell_hidden  == true
                })
            end
        end

        shops[shop.id] = shop
    end

    return shops
end

function queries.getShop(shopId)
    local shopRow = MySQL.single.await('SELECT * FROM lation_shops WHERE shop_id = ?', {shopId})

    if not shopRow then return nil end

    local shop = {
        id = shopRow.shop_id,
        name = shopRow.name,
        title = shopRow.title,
        subtitle = shopRow.subtitle,
        currency = shopRow.currency,
        blip = json.decode(shopRow.blip),
        locations = json.decode(shopRow.locations) or {},
        categories = json.decode(shopRow.categories) or {},
        paymentMethods = json.decode(shopRow.payment_methods) or {},
        operatingHours = json.decode(shopRow.operating_hours),
        jobRestriction = json.decode(shopRow.job_restriction),
        itemRequirement = json.decode(shopRow.item_requirement),
        itemWhitelist = json.decode(shopRow.item_whitelist),
        revenueShares = json.decode(shopRow.revenue_shares) or {},
        hideAllCategory = shopRow.hide_all_category or false,
        randomPrices = shopRow.random_prices_enabled and {
            enabled = shopRow.random_prices_enabled,
            percentage = shopRow.random_prices_percentage
        } or nil,
        shopMode = shopRow.shop_mode or 'buy',
        sellPricePercentage = shopRow.sell_price_percentage,
        sellPaymentSource = shopRow.sell_payment_source and json.decode(shopRow.sell_payment_source) or nil,
        balance = shopRow.balance or 0,
        inventory = {}
    }

    if shop.blip and type(shop.blip) == 'table' and not next(shop.blip) then
        shop.blip = nil
    end

    local inventory = queries.getInventory(shopRow.shop_id)

    if inventory then
        for _, item in ipairs(inventory) do
            table.insert(shop.inventory, {
                item = item.item_name,
                label = item.label,
                description = item.description,
                category = item.category,
                icon = item.icon,
                price = item.price, -- Customer shop uses randomized price
                basePrice = item.base_price, -- Needed for sell price % calculation
                maxStock = item.max_stock,
                stock = item.stock,
                metadata = item.metadata and json.decode(item.metadata) or nil,
                license = item.license,
                jobRestriction = json.decode(item.job_restriction),
                sellPrice = item.sell_price,
                sellEnabled = item.sell_enabled == 1 or item.sell_enabled == true,
                sellHidden  = item.sell_hidden  == 1 or item.sell_hidden  == true
            })
        end
    end

    return shop
end

function queries.createShop(data)
    return MySQL.insert.await([[
        INSERT INTO lation_shops (
            shop_id, name, title, subtitle, currency, blip, locations,
            categories, payment_methods, revenue_shares, random_prices_enabled, random_prices_percentage,
            operating_hours, job_restriction, item_requirement, item_whitelist, hide_all_category,
            shop_mode, sell_price_percentage, sell_payment_source
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.id,
        data.id,
        data.title,
        data.subtitle,
        data.currency or '$',
        json.encode(data.blip or {}),
        json.encode(data.locations or {}),
        json.encode(data.categories or {}),
        json.encode(data.paymentMethods or {}),
        json.encode(data.revenueShares or {}),
        data.randomPrices and data.randomPrices.enabled or false,
        data.randomPrices and data.randomPrices.percentage or nil,
        json.encode(data.operatingHours),
        json.encode(data.jobRestriction),
        data.itemRequirement and json.encode(data.itemRequirement) or nil,
        json.encode(data.itemWhitelist),
        data.hideAllCategory or false,
        data.shopMode or 'buy',
        data.sellPricePercentage or nil,
        data.sellPaymentSource and json.encode(data.sellPaymentSource) or nil
    })
end

function queries.updateShop(shopId, data)
    return MySQL.update.await([[
        UPDATE lation_shops SET
            name = ?, title = ?, subtitle = ?, currency = ?, blip = ?, locations = ?,
            categories = ?, payment_methods = ?, revenue_shares = ?, random_prices_enabled = ?, random_prices_percentage = ?,
            operating_hours = ?, job_restriction = ?, item_requirement = ?, item_whitelist = ?, hide_all_category = ?,
            shop_mode = ?, sell_price_percentage = ?, sell_payment_source = ?
        WHERE shop_id = ?
    ]], {
        data.id,
        data.title,
        data.subtitle,
        data.currency or '$',
        json.encode(data.blip or {}),
        json.encode(data.locations or {}),
        json.encode(data.categories or {}),
        json.encode(data.paymentMethods or {}),
        json.encode(data.revenueShares or {}),
        data.randomPrices and data.randomPrices.enabled or false,
        data.randomPrices and data.randomPrices.percentage or nil,
        json.encode(data.operatingHours),
        json.encode(data.jobRestriction),
        data.itemRequirement and json.encode(data.itemRequirement) or nil,
        json.encode(data.itemWhitelist),
        data.hideAllCategory or false,
        data.shopMode or 'buy',
        data.sellPricePercentage or nil,
        data.sellPaymentSource and json.encode(data.sellPaymentSource) or nil,
        shopId
    })
end

function queries.deleteShop(shopId)
    return MySQL.query.await('DELETE FROM lation_shops WHERE shop_id = ?', {shopId})
end

-- =====================================================
-- INVENTORY QUERIES
-- =====================================================

function queries.getInventory(shopId)
    return MySQL.query.await('SELECT * FROM lation_shops_inventory WHERE shop_id = ? ORDER BY display_order ASC', {shopId})
end

function queries.getInventoryItem(shopId, itemName)
    return MySQL.single.await([[
        SELECT * FROM lation_shops_inventory 
        WHERE shop_id = ? AND item_name = ?
    ]], {shopId, itemName})
end

function queries.createInventoryItem(shopId, item)
    return MySQL.insert.await([[
        INSERT INTO lation_shops_inventory (
            shop_id, item_name, label, description, category, icon, price, base_price, stock, max_stock, display_order, metadata, license, job_restriction, sell_price, sell_enabled, sell_hidden
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        shopId,
        item.item,
        item.label,
        item.description,
        item.category,
        item.icon,
        item.price, -- price starts as base price (will be randomized if enabled)
        item.price, -- base_price = the price set by admin
        item.stock or nil,
        item.stock or nil, -- max_stock = initial stock (nil = unlimited)
        item.displayOrder or 0,
        json.encode(item.metadata),
        item.license,
        json.encode(item.jobRestriction),
        item.sellPrice or nil,
        item.sellEnabled ~= false and 1 or 0,
        item.sellHidden and 1 or 0
    })
end

function queries.updateInventoryItem(shopId, itemName, data)
    return MySQL.update.await([[
        UPDATE lation_shops_inventory 
        SET label = ?, description = ?, category = ?, icon = ?, base_price = ?, price = ?, stock = ?, metadata = ?, license = ?, job_restriction = ?, sell_price = ?, sell_enabled = ?, sell_hidden = ?
        WHERE shop_id = ? AND item_name = ?
    ]], {
        data.label,
        data.description,
        data.category,
        data.icon,
        data.price, -- base_price = the price set by admin
        data.price, -- price also updated (will be randomized later if enabled)
        data.stock,
        json.encode(data.metadata),
        data.license,
        json.encode(data.jobRestriction),
        data.sellPrice or nil,
        data.sellEnabled ~= false and 1 or 0,
        data.sellHidden and 1 or 0,
        shopId,
        itemName
    })
end

function queries.deleteInventoryItem(shopId, itemName)
    return MySQL.query.await([[
        DELETE FROM lation_shops_inventory 
        WHERE shop_id = ? AND item_name = ?
    ]], {shopId, itemName})
end

function queries.deleteAllInventory(shopId)
    return MySQL.query.await('DELETE FROM lation_shops_inventory WHERE shop_id = ?', {shopId})
end

function queries.getItemStock(shopId, itemName)
    local result = MySQL.single.await([[
        SELECT stock FROM lation_shops_inventory 
        WHERE shop_id = ? AND item_name = ?
    ]], {shopId, itemName})

    if not result then return nil end
    return result.stock -- nil = unlimited, number = limited stock
end

function queries.reduceStock(shopId, itemName, quantity)
    return MySQL.update.await([[
        UPDATE lation_shops_inventory 
        SET stock = stock - ? 
        WHERE shop_id = ? AND item_name = ? AND stock >= ?
    ]], {quantity, shopId, itemName, quantity})
end

function queries.addStock(shopId, itemName, quantity)
    return MySQL.update.await([[
        UPDATE lation_shops_inventory 
        SET stock = CASE 
            WHEN stock IS NULL THEN NULL 
            ELSE stock + ? 
        END
        WHERE shop_id = ? AND item_name = ?
    ]], {quantity, shopId, itemName})
end

--- Restock an item after a player sells it back, capped at max_stock.
--- Unlimited-stock items (stock IS NULL) are unaffected.
function queries.addStockFromSell(shopId, itemName, quantity)
    return MySQL.update.await([[
        UPDATE lation_shops_inventory 
        SET stock = CASE 
            WHEN stock IS NULL THEN NULL 
            ELSE LEAST(stock + ?, max_stock)
        END
        WHERE shop_id = ? AND item_name = ?
    ]], {quantity, shopId, itemName})
end

-- =====================================================
-- TRANSACTION QUERIES
-- =====================================================

function queries.createTransaction(data)
    return MySQL.insert.await([[
        INSERT INTO lation_shops_transactions (
            shop_id, transaction_type, amount, item_name, 
            quantity, player_id, player_name, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.shop_id,
        data.transaction_type,
        data.amount,
        data.item_name,
        data.quantity,
        data.player_id,
        data.player_name,
        data.notes
    })
end

function queries.deleteTransaction(transactionId)
    return MySQL.query.await('DELETE FROM lation_shops_transactions WHERE id = ?', {transactionId})
end

function queries.updateShopBalance(shopId, amount)
    return MySQL.query.await('UPDATE lation_shops SET balance = balance + ? WHERE shop_id = ?', {amount, shopId})
end

function queries.getTransactionsFiltered(shopId, filters, limit, offset)
    limit = limit or 50
    offset = offset or 0

    local conditions = {'shop_id = ?'}
    local params = {shopId}

    if filters.type and filters.type ~= 'all' then
        table.insert(conditions, 'transaction_type = ?')
        table.insert(params, filters.type)
    end

    if filters.search and filters.search ~= '' then
        table.insert(conditions, '(player_name LIKE ? OR item_name LIKE ? OR notes LIKE ?)')
        local searchPattern = '%' .. filters.search .. '%'
        table.insert(params, searchPattern)
        table.insert(params, searchPattern)
        table.insert(params, searchPattern)
    end

    if filters.dateFrom then
        table.insert(conditions, 'DATE(created_at) >= ?')
        table.insert(params, filters.dateFrom)
    end

    if filters.dateTo then
        table.insert(conditions, 'DATE(created_at) <= ?')
        table.insert(params, filters.dateTo)
    end

    table.insert(params, limit)
    table.insert(params, offset)

    local whereClause = table.concat(conditions, ' AND ')
    local query = string.format([[
        SELECT * FROM lation_shops_transactions 
        WHERE %s 
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
    ]], whereClause)

    return MySQL.query.await(query, params)
end

function queries.getTransactionCount(shopId, filters)
    local conditions = {'shop_id = ?'}
    local params = {shopId}

    if filters.type and filters.type ~= 'all' then
        table.insert(conditions, 'transaction_type = ?')
        table.insert(params, filters.type)
    end

    if filters.search and filters.search ~= '' then
        table.insert(conditions, '(player_name LIKE ? OR item_name LIKE ? OR notes LIKE ?)')
        local searchPattern = '%' .. filters.search .. '%'
        table.insert(params, searchPattern)
        table.insert(params, searchPattern)
        table.insert(params, searchPattern)
    end

    if filters.dateFrom then
        table.insert(conditions, 'DATE(created_at) >= ?')
        table.insert(params, filters.dateFrom)
    end

    if filters.dateTo then
        table.insert(conditions, 'DATE(created_at) <= ?')
        table.insert(params, filters.dateTo)
    end

    local whereClause = table.concat(conditions, ' AND ')
    local query = string.format([[
        SELECT COUNT(*) as count FROM lation_shops_transactions 
        WHERE %s
    ]], whereClause)

    local result = MySQL.query.await(query, params)
    return result[1]?.count or 0
end

return queries