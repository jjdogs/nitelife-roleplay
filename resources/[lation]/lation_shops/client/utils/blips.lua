shopBlips = {}

-- Create map blips for a shop at all eligible locations
--- @param shopId string
--- @param shop table
function CreateShopBlips(shopId, shop)
    if not shop.blip or not next(shop.blip) then return end
    if not shop.blip.sprite or not shop.blip.label then return end

    -- Initialize storage for this shop if needed
    if not shopBlips[shopId] then
        shopBlips[shopId] = {}
    end

    for _, location in ipairs(shop.locations) do
        -- Skip if blip is disabled for this location (default: true if not specified)
        if location.showBlip == false then goto continue end

        if location.type == 'coords' or location.type == 'ped' then
            local coords = location.coords
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipScale(blip, shop.blip.scale + 0.0)
            SetBlipColour(blip, shop.blip.color)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(shop.blip.label)
            EndTextCommandSetBlipName(blip)

            -- Store blip handle by shopId for cleanup
            shopBlips[shopId][#shopBlips[shopId] + 1] = blip
        end

        ::continue::
    end
end

-- Remove all blips for a specific shop
--- @param shopId string
function RemoveShopBlips(shopId)
    if not shopBlips[shopId] then return end

    for _, blip in ipairs(shopBlips[shopId]) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    shopBlips[shopId] = nil
end

-- Remove all shop blips across all shops
function RemoveAllBlips()
    for shopId, _ in pairs(shopBlips) do
        RemoveShopBlips(shopId)
    end
    shopBlips = {}
end
