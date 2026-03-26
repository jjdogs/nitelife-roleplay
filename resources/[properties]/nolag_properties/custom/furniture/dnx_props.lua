if GetResourceState('dnxgenericaddonprops') ~= 'started' then
    return
end

CreateThread(function()
    InsertFurnitureCategory("dnx_buildings",            "DNX Buildings",        nil, "🏗️")
    InsertFurnitureCategory("dnx_effects",              "DNX Effects",          nil, "✨")
    InsertFurnitureCategory("dnx_electronics",          "DNX Electronics",      nil, "🔌")
    InsertFurnitureCategory("dnx_entertainment",        "DNX Entertainment",    nil, "📚")
    InsertFurnitureCategory("dnx_fire",                 "DNX Fire Safety",      nil, "🧯")
    InsertFurnitureCategory("dnx_furniture_bathroom",   "DNX Bathroom",         nil, "🚿")
    InsertFurnitureCategory("dnx_furniture_bedroom",    "DNX Bedroom",          nil, "🛏️")
    InsertFurnitureCategory("dnx_furniture_bookshelves","DNX Bookshelves",      nil, "📖")
    InsertFurnitureCategory("dnx_furniture_coatracks",  "DNX Coat Racks",       nil, "🧥")
    InsertFurnitureCategory("dnx_furniture_desks",      "DNX Desks",            nil, "🖊️")
    InsertFurnitureCategory("dnx_furniture_dining",     "DNX Dining",           nil, "🍽️")
    InsertFurnitureCategory("dnx_furniture_filing",     "DNX Filing",           nil, "🗂️")
    InsertFurnitureCategory("dnx_furniture_kitchen",    "DNX Kitchen",          nil, "🍳")
    InsertFurnitureCategory("dnx_furniture_shelves",    "DNX Shelves",          nil, "🗄️")
    InsertFurnitureCategory("dnx_home",                 "DNX Home Accessories", nil, "🏠")
    InsertFurnitureCategory("dnx_lighting",             "DNX Lighting",         nil, "💡")
    InsertFurnitureCategory("dnx_music",                "DNX Music",            nil, "🎵")
    InsertFurnitureCategory("dnx_tech",                 "DNX Tech / Gaming",    nil, "🎮")
    Wait(500)
end)

CreateThread(function()
    local Buildings = {
        { object = 'dnxprops_buildings_bulletinboard01_a',       price = 200,  label = 'Bulletin Board' },
        { object = 'dnxprops_buildings_bulletinboard01_empty',   price = 150,  label = 'Bulletin Board (Empty)' },
        { object = 'dnxprops_buildings_canopysmall01_a',         price = 300,  label = 'Canopy Small 01' },
        { object = 'dnxprops_buildings_canopysmall02_a',         price = 300,  label = 'Canopy Small 02' },
        { object = 'dnxprops_buildings_canopysmall03_a',         price = 300,  label = 'Canopy Small 03' },
        { object = 'dnxprops_buildings_canopysmall04_a',         price = 300,  label = 'Canopy Small 04' },
        { object = 'dnxprops_buildings_canopysmall05_a',         price = 300,  label = 'Canopy Small 05' },
        { object = 'dnxprops_buildings_canopysmall06_a',         price = 300,  label = 'Canopy Small 06' },
        { object = 'dnxprops_buildings_gasboiler01',             price = 500,  label = 'Gas Boiler 01' },
        { object = 'dnxprops_buildings_gasboiler02',             price = 500,  label = 'Gas Boiler 02' },
        { object = 'dnxprops_buildings_gasboiler03',             price = 500,  label = 'Gas Boiler 03' },
        { object = 'dnxprops_buildings_gasboiler04',             price = 500,  label = 'Gas Boiler 04' },
        { object = 'dnxprops_buildings_privacyscreen01_a',       price = 400,  label = 'Privacy Screen' },
        { object = 'dnxprops_buildings_privacyscreen01_a_hedge', price = 400,  label = 'Privacy Screen (Hedge)' },
        { object = 'dnxprops_buildings_watertank01',             price = 600,  label = 'Water Tank' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_buildings, Buildings)
end)

CreateThread(function()
    local Effects = {
        { object = 'dnxprops_effects_fire_campfire',          price = 100, label = 'Campfire' },
        { object = 'dnxprops_effects_fire_fireplace',         price = 100, label = 'Fireplace' },
        { object = 'dnxprops_effects_smoke_acvent',           price = 100, label = 'Smoke - AC Vent' },
        { object = 'dnxprops_effects_smoke_factory',          price = 100, label = 'Smoke - Factory' },
        { object = 'dnxprops_effects_smoke_roofvent',         price = 100, label = 'Smoke - Roof Vent' },
        { object = 'dnxprops_effects_water_drips_med',        price = 100, label = 'Water Drips (Med)' },
        { object = 'dnxprops_effects_water_drips_small',      price = 100, label = 'Water Drips (Small)' },
        { object = 'dnxprops_effects_water_drips_tap',        price = 100, label = 'Water Drips (Tap)' },
        { object = 'dnxprops_effects_water_fountain_single',  price = 100, label = 'Water Fountain' },
        { object = 'dnxprops_effects_water_pour_short_rain',  price = 100, label = 'Water Pour (Rain)' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_effects, Effects)
end)

CreateThread(function()
    local Electronics = {
        { object = 'dnxprops_electronics_arrowbutton01_a',              price = 50,  label = 'Arrow Button A' },
        { object = 'dnxprops_electronics_arrowbutton01_b',              price = 50,  label = 'Arrow Button B' },
        { object = 'dnxprops_electronics_doorbell01_a',                 price = 75,  label = 'Doorbell A' },
        { object = 'dnxprops_electronics_doorbell01_a_custom01',        price = 75,  label = 'Doorbell A Custom 01' },
        { object = 'dnxprops_electronics_doorbell01_a_custom02',        price = 75,  label = 'Doorbell A Custom 02' },
        { object = 'dnxprops_electronics_doorbell01_a_custom03',        price = 75,  label = 'Doorbell A Custom 03' },
        { object = 'dnxprops_electronics_doorbell01_a_custom04',        price = 75,  label = 'Doorbell A Custom 04' },
        { object = 'dnxprops_electronics_doorbell01_a_custom05',        price = 75,  label = 'Doorbell A Custom 05' },
        { object = 'dnxprops_electronics_doorbell01_b',                 price = 75,  label = 'Doorbell B' },
        { object = 'dnxprops_electronics_doorbell01_b_custom01',        price = 75,  label = 'Doorbell B Custom 01' },
        { object = 'dnxprops_electronics_doorbell01_b_custom02',        price = 75,  label = 'Doorbell B Custom 02' },
        { object = 'dnxprops_electronics_doorbell01_b_custom03',        price = 75,  label = 'Doorbell B Custom 03' },
        { object = 'dnxprops_electronics_doorbell01_b_custom04',        price = 75,  label = 'Doorbell B Custom 04' },
        { object = 'dnxprops_electronics_doorbell01_b_custom05',        price = 75,  label = 'Doorbell B Custom 05' },
        { object = 'dnxprops_electronics_intercom01_a',                 price = 100, label = 'Intercom' },
        { object = 'dnxprops_electronics_lightbutton01_a',              price = 50,  label = 'Light Button A' },
        { object = 'dnxprops_electronics_lightbutton01_b',              price = 50,  label = 'Light Button B' },
        { object = 'dnxprops_electronics_socketswitchus01_combo1_a',    price = 50,  label = 'Socket Switch Combo A' },
        { object = 'dnxprops_electronics_socketswitchus01_combo1_b',    price = 50,  label = 'Socket Switch Combo B' },
        { object = 'dnxprops_electronics_socketus01_double_a',          price = 50,  label = 'Double Socket A' },
        { object = 'dnxprops_electronics_socketus01_double_b',          price = 50,  label = 'Double Socket B' },
        { object = 'dnxprops_electronics_socketus01_single_a',          price = 50,  label = 'Single Socket A' },
        { object = 'dnxprops_electronics_socketus01_single_b',          price = 50,  label = 'Single Socket B' },
        { object = 'dnxprops_electronics_switch01_double_a',            price = 50,  label = 'Double Switch A' },
        { object = 'dnxprops_electronics_switch01_double_b',            price = 50,  label = 'Double Switch B' },
        { object = 'dnxprops_electronics_switch01_single_a',            price = 50,  label = 'Single Switch A' },
        { object = 'dnxprops_electronics_switch01_single_b',            price = 50,  label = 'Single Switch B' },
        { object = 'dnxprops_electronics_switch01_triple_a',            price = 50,  label = 'Triple Switch A' },
        { object = 'dnxprops_electronics_switch01_triple_b',            price = 50,  label = 'Triple Switch B' },
        { object = 'dnxprops_electronics_tvantenna01',                  price = 150, label = 'TV Antenna' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_electronics, Electronics)
end)

CreateThread(function()
    local Entertainment = {
        { object = 'dnxprops_entertainment_manga01_a', price = 50, label = 'Manga A' },
        { object = 'dnxprops_entertainment_manga01_b', price = 50, label = 'Manga B' },
        { object = 'dnxprops_entertainment_manga01_c', price = 50, label = 'Manga C' },
        { object = 'dnxprops_entertainment_manga01_d', price = 50, label = 'Manga D' },
        { object = 'dnxprops_entertainment_manga01_e', price = 50, label = 'Manga E' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_entertainment, Entertainment)
end)

CreateThread(function()
    local FireSafety = {
        { object = 'dnxprops_fire_extinguisher1',           price = 100, label = 'Fire Extinguisher 1' },
        { object = 'dnxprops_fire_extinguisher2',           price = 100, label = 'Fire Extinguisher 2' },
        { object = 'dnxprops_fire_extinguisherbracket01_a', price = 75,  label = 'Extinguisher Bracket A' },
        { object = 'dnxprops_fire_extinguisherbracket01_b', price = 75,  label = 'Extinguisher Bracket B' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_fire, FireSafety)
end)

CreateThread(function()
    local Bathroom = {
        { object = 'dnxprops_furniture_bathroomcabinet01_a', price = 500,  label = 'Bathroom Cabinet A' },
        { object = 'dnxprops_furniture_bathroomcabinet01_b', price = 500,  label = 'Bathroom Cabinet B' },
        { object = 'dnxprops_furniture_bathroomcabinet01_c', price = 500,  label = 'Bathroom Cabinet C' },
        { object = 'dnxprops_furniture_bathroomsink01_a',    price = 600,  label = 'Bathroom Sink' },
        { object = 'dnxprops_furniture_bathtub02_a',         price = 1200, label = 'Bathtub' },
        { object = 'dnxprops_furniture_bidet',               price = 400,  label = 'Bidet' },
        { object = 'dnxprops_furniture_shower01_a',          price = 1000, label = 'Shower 01' },
        { object = 'dnxprops_furniture_shower02_a',          price = 1000, label = 'Shower 02' },
        { object = 'dnxprops_furniture_shower03_a',          price = 1000, label = 'Shower 03' },
        { object = 'dnxprops_furniture_toilet01_a',          price = 500,  label = 'Toilet A' },
        { object = 'dnxprops_furniture_toilet01_b',          price = 500,  label = 'Toilet B' },
        { object = 'dnxprops_furniture_toilet01_c',          price = 500,  label = 'Toilet C' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_bathroom, Bathroom)
end)

CreateThread(function()
    local Bedroom = {
        { object = 'dnxprops_furniture_wardrobedrawer01_a', price = 800,  label = 'Wardrobe Drawer A' },
        { object = 'dnxprops_furniture_wardrobedrawer01_b', price = 800,  label = 'Wardrobe Drawer B' },
        { object = 'dnxprops_furniture_wardrobedrawer01_c', price = 800,  label = 'Wardrobe Drawer C' },
        { object = 'dnxprops_furniture_wardrobelarge01_a',  price = 1500, label = 'Wardrobe Large A' },
        { object = 'dnxprops_furniture_wardrobelarge01_b',  price = 1500, label = 'Wardrobe Large B' },
        { object = 'dnxprops_furniture_wardrobelarge01_c',  price = 1500, label = 'Wardrobe Large C' },
        { object = 'dnxprops_furniture_wardrobesmall01_a',  price = 700,  label = 'Wardrobe Small A' },
        { object = 'dnxprops_furniture_wardrobesmall01_b',  price = 700,  label = 'Wardrobe Small B' },
        { object = 'dnxprops_furniture_wardrobesmall01_c',  price = 700,  label = 'Wardrobe Small C' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_bedroom, Bedroom)
end)

CreateThread(function()
    local Bookshelves = {
        { object = 'dnxprops_furniture_bookshelf01_a',       price = 400, label = 'Bookshelf A' },
        { object = 'dnxprops_furniture_bookshelf01_b',       price = 400, label = 'Bookshelf B' },
        { object = 'dnxprops_furniture_bookshelf01_books',   price = 200, label = 'Bookshelf (Books)' },
        { object = 'dnxprops_furniture_bookshelf01_c',       price = 400, label = 'Bookshelf C' },
        { object = 'dnxprops_furniture_bookshelflarge01_a',  price = 700, label = 'Bookshelf Large A' },
        { object = 'dnxprops_furniture_bookshelflarge01_b',  price = 700, label = 'Bookshelf Large B' },
        { object = 'dnxprops_furniture_bookshelflarge01_c',  price = 700, label = 'Bookshelf Large C' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_bookshelves, Bookshelves)
end)

CreateThread(function()
    local CoatRacks = {
        { object = 'dnxprops_furniture_coatrack01_a', price = 250, label = 'Coat Rack A' },
        { object = 'dnxprops_furniture_coatrack01_b', price = 250, label = 'Coat Rack B' },
        { object = 'dnxprops_furniture_coatrack01_c', price = 250, label = 'Coat Rack C' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_coatracks, CoatRacks)
end)

CreateThread(function()
    local Desks = {
        { object = 'dnxprops_furniture_desk01_a',     price = 800,  label = 'Desk 01 A' },
        { object = 'dnxprops_furniture_desk01_b',     price = 800,  label = 'Desk 01 B' },
        { object = 'dnxprops_furniture_desk01_c',     price = 800,  label = 'Desk 01 C' },
        { object = 'dnxprops_furniture_desk02_a',     price = 800,  label = 'Desk 02 A' },
        { object = 'dnxprops_furniture_desk02_b',     price = 800,  label = 'Desk 02 B' },
        { object = 'dnxprops_furniture_desk02_c',     price = 800,  label = 'Desk 02 C' },
        { object = 'dnxprops_furniture_desk03_a',     price = 800,  label = 'Desk 03 A' },
        { object = 'dnxprops_furniture_desk03_b',     price = 800,  label = 'Desk 03 B' },
        { object = 'dnxprops_furniture_desk03_c',     price = 800,  label = 'Desk 03 C' },
        { object = 'dnxprops_furniture_desk04_a',     price = 800,  label = 'Desk 04 A' },
        { object = 'dnxprops_furniture_desk04_b',     price = 800,  label = 'Desk 04 B' },
        { object = 'dnxprops_furniture_desk04_c',     price = 800,  label = 'Desk 04 C' },
        { object = 'dnxprops_furniture_desk05_a',     price = 800,  label = 'Desk 05 A' },
        { object = 'dnxprops_furniture_desk05_b',     price = 800,  label = 'Desk 05 B' },
        { object = 'dnxprops_furniture_desk05_c',     price = 800,  label = 'Desk 05 C' },
        { object = 'dnxprops_furniture_desk06_a',     price = 800,  label = 'Desk 06 A' },
        { object = 'dnxprops_furniture_desk06_b',     price = 800,  label = 'Desk 06 B' },
        { object = 'dnxprops_furniture_desk06_c',     price = 800,  label = 'Desk 06 C' },
        { object = 'dnxprops_furniture_desk07_a',     price = 800,  label = 'Desk 07 A' },
        { object = 'dnxprops_furniture_desk07_b',     price = 800,  label = 'Desk 07 B' },
        { object = 'dnxprops_furniture_desk07_c',     price = 800,  label = 'Desk 07 C' },
        { object = 'dnxprops_furniture_desk08_a',     price = 800,  label = 'Desk 08 A' },
        { object = 'dnxprops_furniture_desk08_b',     price = 800,  label = 'Desk 08 B' },
        { object = 'dnxprops_furniture_desk08_c',     price = 800,  label = 'Desk 08 C' },
        { object = 'dnxprops_furniture_desk09_a',     price = 800,  label = 'Desk 09 A' },
        { object = 'dnxprops_furniture_desk09_b',     price = 800,  label = 'Desk 09 B' },
        { object = 'dnxprops_furniture_desk09_c',     price = 800,  label = 'Desk 09 C' },
        { object = 'dnxprops_furniture_desk10_a',     price = 800,  label = 'Desk 10 A' },
        { object = 'dnxprops_furniture_desk10_b',     price = 800,  label = 'Desk 10 B' },
        { object = 'dnxprops_furniture_desk10_c',     price = 800,  label = 'Desk 10 C' },
        { object = 'dnxprops_furniture_desk11_a',     price = 800,  label = 'Desk 11 A' },
        { object = 'dnxprops_furniture_desk11_b',     price = 800,  label = 'Desk 11 B' },
        { object = 'dnxprops_furniture_desk11_c',     price = 800,  label = 'Desk 11 C' },
        { object = 'dnxprops_furniture_desk12_a',     price = 800,  label = 'Desk 12 A' },
        { object = 'dnxprops_furniture_desk12_b',     price = 800,  label = 'Desk 12 B' },
        { object = 'dnxprops_furniture_desk12_c',     price = 800,  label = 'Desk 12 C' },
        { object = 'dnxprops_furniture_desk13_a',     price = 800,  label = 'Desk 13 A' },
        { object = 'dnxprops_furniture_desk13_b',     price = 800,  label = 'Desk 13 B' },
        { object = 'dnxprops_furniture_desk13_c',     price = 800,  label = 'Desk 13 C' },
        { object = 'dnxprops_furniture_deskwood01_a', price = 900,  label = 'Desk Wood A' },
        { object = 'dnxprops_furniture_deskwood01_b', price = 900,  label = 'Desk Wood B' },
        { object = 'dnxprops_furniture_deskwood01_c', price = 900,  label = 'Desk Wood C' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_desks, Desks)
end)

CreateThread(function()
    local Dining = {
        { object = 'dnxprops_furniture_dinningtable01_a', price = 900,  label = 'Dining Table 01 A' },
        { object = 'dnxprops_furniture_dinningtable01_b', price = 900,  label = 'Dining Table 01 B' },
        { object = 'dnxprops_furniture_dinningtable02_a', price = 1000, label = 'Dining Table 02 A' },
        { object = 'dnxprops_furniture_dinningtable02_b', price = 1000, label = 'Dining Table 02 B' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_dining, Dining)
end)

CreateThread(function()
    local Filing = {
        { object = 'dnxprops_furniture_filecabinetlarge01_a', price = 500, label = 'File Cabinet Large A' },
        { object = 'dnxprops_furniture_filecabinetlarge01_b', price = 500, label = 'File Cabinet Large B' },
        { object = 'dnxprops_furniture_filecabinetlarge01_c', price = 500, label = 'File Cabinet Large C' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_filing, Filing)
end)

CreateThread(function()
    local Kitchen = {
        { object = 'dnxprops_furniture_kitchencabinet01_a',     price = 600,  label = 'Kitchen Cabinet 01 A' },
        { object = 'dnxprops_furniture_kitchencabinet01_b',     price = 600,  label = 'Kitchen Cabinet 01 B' },
        { object = 'dnxprops_furniture_kitchencabinet02_a',     price = 600,  label = 'Kitchen Cabinet 02 A' },
        { object = 'dnxprops_furniture_kitchencabinet02_b',     price = 600,  label = 'Kitchen Cabinet 02 B' },
        { object = 'dnxprops_furniture_kitchencabinet03_a',     price = 600,  label = 'Kitchen Cabinet 03 A' },
        { object = 'dnxprops_furniture_kitchencabinet03_b',     price = 600,  label = 'Kitchen Cabinet 03 B' },
        { object = 'dnxprops_furniture_kitchencabinet04_a',     price = 600,  label = 'Kitchen Cabinet 04 A' },
        { object = 'dnxprops_furniture_kitchencabinet04_b',     price = 600,  label = 'Kitchen Cabinet 04 B' },
        { object = 'dnxprops_furniture_kitchencabinet05_a',     price = 600,  label = 'Kitchen Cabinet 05 A' },
        { object = 'dnxprops_furniture_kitchencabinet05_b',     price = 600,  label = 'Kitchen Cabinet 05 B' },
        { object = 'dnxprops_furniture_kitchencabinet06_a',     price = 600,  label = 'Kitchen Cabinet 06 A' },
        { object = 'dnxprops_furniture_kitchencabinet06_b',     price = 600,  label = 'Kitchen Cabinet 06 B' },
        { object = 'dnxprops_furniture_kitchencabinet07_a',     price = 600,  label = 'Kitchen Cabinet 07 A' },
        { object = 'dnxprops_furniture_kitchencabinet07_b',     price = 600,  label = 'Kitchen Cabinet 07 B' },
        { object = 'dnxprops_furniture_kitchencabinet08_a',     price = 600,  label = 'Kitchen Cabinet 08 A' },
        { object = 'dnxprops_furniture_kitchencabinet08_b',     price = 600,  label = 'Kitchen Cabinet 08 B' },
        { object = 'dnxprops_furniture_kitchencabinet09_a',     price = 600,  label = 'Kitchen Cabinet 09 A' },
        { object = 'dnxprops_furniture_kitchencabinet09_b',     price = 600,  label = 'Kitchen Cabinet 09 B' },
        { object = 'dnxprops_furniture_kitchencabinet10_a',     price = 600,  label = 'Kitchen Cabinet 10 A' },
        { object = 'dnxprops_furniture_kitchencabinet10_b',     price = 600,  label = 'Kitchen Cabinet 10 B' },
        { object = 'dnxprops_furniture_kitchencabinet11_a',     price = 600,  label = 'Kitchen Cabinet 11 A' },
        { object = 'dnxprops_furniture_kitchencabinet11_b',     price = 600,  label = 'Kitchen Cabinet 11 B' },
        { object = 'dnxprops_furniture_kitchencabinet12_a',     price = 600,  label = 'Kitchen Cabinet 12 A' },
        { object = 'dnxprops_furniture_kitchencabinet12_b',     price = 600,  label = 'Kitchen Cabinet 12 B' },
        { object = 'dnxprops_furniture_kitchencabinet13_a',     price = 600,  label = 'Kitchen Cabinet 13 A' },
        { object = 'dnxprops_furniture_kitchencabinet13_b',     price = 600,  label = 'Kitchen Cabinet 13 B' },
        { object = 'dnxprops_furniture_kitchendishwasher_a',    price = 800,  label = 'Dishwasher A' },
        { object = 'dnxprops_furniture_kitchendishwasher_b',    price = 800,  label = 'Dishwasher B' },
        { object = 'dnxprops_furniture_kitchenfridgelarge01_a', price = 1200, label = 'Fridge Large' },
        { object = 'dnxprops_furniture_kitchenoven01_a',        price = 900,  label = 'Oven 01 A' },
        { object = 'dnxprops_furniture_kitchenoven01_b',        price = 900,  label = 'Oven 01 B' },
        { object = 'dnxprops_furniture_kitchenoven02_a',        price = 900,  label = 'Oven 02 A' },
        { object = 'dnxprops_furniture_kitchenoven02_b',        price = 900,  label = 'Oven 02 B' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_kitchen, Kitchen)
end)

CreateThread(function()
    local Shelves = {
        { object = 'dnxprops_furniture_shelf01_a', price = 300, label = 'Shelf A' },
        { object = 'dnxprops_furniture_shelf01_b', price = 300, label = 'Shelf B' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_furniture_shelves, Shelves)
end)

CreateThread(function()
    local Home = {
        { object = 'dnxprops_home_aftershave01_a',              price = 50,  label = 'Aftershave' },
        { object = 'dnxprops_home_barberbrush01_a',             price = 50,  label = 'Barber Brush' },
        { object = 'dnxprops_home_bathroomorganizer01_a_empty', price = 100, label = 'Bathroom Organizer (Empty)' },
        { object = 'dnxprops_home_ceramicbowl01_a',             price = 75,  label = 'Ceramic Bowl A' },
        { object = 'dnxprops_home_ceramicbowl01_b',             price = 75,  label = 'Ceramic Bowl B' },
        { object = 'dnxprops_home_ceramicbowl01_c',             price = 75,  label = 'Ceramic Bowl C' },
        { object = 'dnxprops_home_contactlensescase',           price = 50,  label = 'Contact Lens Case' },
        { object = 'dnxprops_home_deskorganizer01_a',           price = 100, label = 'Desk Organizer 01 A' },
        { object = 'dnxprops_home_deskorganizer01_b',           price = 100, label = 'Desk Organizer 01 B' },
        { object = 'dnxprops_home_deskorganizer01_c',           price = 100, label = 'Desk Organizer 01 C' },
        { object = 'dnxprops_home_deskorganizer02_a',           price = 100, label = 'Desk Organizer 02 A' },
        { object = 'dnxprops_home_deskorganizer02_b',           price = 100, label = 'Desk Organizer 02 B' },
        { object = 'dnxprops_home_deskorganizer02_c',           price = 100, label = 'Desk Organizer 02 C' },
        { object = 'dnxprops_home_diecastrhino',                price = 150, label = 'Diecast Rhino' },
        { object = 'dnxprops_home_digitalbathroomscale01_a',    price = 75,  label = 'Bathroom Scale A' },
        { object = 'dnxprops_home_digitalbathroomscale01_b',    price = 75,  label = 'Bathroom Scale B' },
        { object = 'dnxprops_home_jarcoffee01_a',               price = 50,  label = 'Jar Coffee A' },
        { object = 'dnxprops_home_jarcoffee01_b',               price = 50,  label = 'Jar Coffee B' },
        { object = 'dnxprops_home_jarsalt01_a',                 price = 50,  label = 'Jar Salt A' },
        { object = 'dnxprops_home_jarsalt01_b',                 price = 50,  label = 'Jar Salt B' },
        { object = 'dnxprops_home_jarsugar01_a',                price = 50,  label = 'Jar Sugar A' },
        { object = 'dnxprops_home_jarsugar01_b',                price = 50,  label = 'Jar Sugar B' },
        { object = 'dnxprops_home_lantern01_a_empty',           price = 100, label = 'Lantern 01 (Empty)' },
        { object = 'dnxprops_home_lantern02_a_empty',           price = 100, label = 'Lantern 02 (Empty)' },
        { object = 'dnxprops_home_liquidsoap01_a',              price = 50,  label = 'Liquid Soap' },
        { object = 'dnxprops_home_mirror01_a',                  price = 200, label = 'Mirror 01 A' },
        { object = 'dnxprops_home_mirror01_b',                  price = 200, label = 'Mirror 01 B' },
        { object = 'dnxprops_home_mirror01_c',                  price = 200, label = 'Mirror 01 C' },
        { object = 'dnxprops_home_mirror02_a',                  price = 200, label = 'Mirror 02 A' },
        { object = 'dnxprops_home_mirror02_b',                  price = 200, label = 'Mirror 02 B' },
        { object = 'dnxprops_home_mirror02_c',                  price = 200, label = 'Mirror 02 C' },
        { object = 'dnxprops_home_mirror03_a',                  price = 200, label = 'Mirror 03 A' },
        { object = 'dnxprops_home_mirror03_b',                  price = 200, label = 'Mirror 03 B' },
        { object = 'dnxprops_home_mirror03_c',                  price = 200, label = 'Mirror 03 C' },
        { object = 'dnxprops_home_mirror04_a',                  price = 200, label = 'Mirror 04 A' },
        { object = 'dnxprops_home_mirror04_b',                  price = 200, label = 'Mirror 04 B' },
        { object = 'dnxprops_home_mirror04_c',                  price = 200, label = 'Mirror 04 C' },
        { object = 'dnxprops_home_mouthwash01_a',               price = 50,  label = 'Mouthwash' },
        { object = 'dnxprops_home_picture01',                   price = 150, label = 'Picture 01' },
        { object = 'dnxprops_home_picture02',                   price = 150, label = 'Picture 02' },
        { object = 'dnxprops_home_picture03',                   price = 150, label = 'Picture 03' },
        { object = 'dnxprops_home_picture04',                   price = 150, label = 'Picture 04' },
        { object = 'dnxprops_home_picture05',                   price = 150, label = 'Picture 05' },
        { object = 'dnxprops_home_picture06',                   price = 150, label = 'Picture 06' },
        { object = 'dnxprops_home_strawcup',                    price = 50,  label = 'Straw Cup' },
        { object = 'dnxprops_home_toiletbrush01_a',             price = 50,  label = 'Toilet Brush 01' },
        { object = 'dnxprops_home_toiletbrush02_a',             price = 50,  label = 'Toilet Brush 02' },
        { object = 'dnxprops_home_towelrail01_a',               price = 150, label = 'Towel Rail A' },
        { object = 'dnxprops_home_towelrail01_b',               price = 150, label = 'Towel Rail B' },
        { object = 'dnxprops_home_towelrail01_c',               price = 150, label = 'Towel Rail C' },
        { object = 'dnxprops_home_umbrellastand01',             price = 100, label = 'Umbrella Stand' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_home, Home)
end)

CreateThread(function()
    local Lighting = {
        { object = 'dnxprops_lighting_ceilinglight01_a',      price = 300, label = 'Ceiling Light 01' },
        { object = 'dnxprops_lighting_ceilinglight01_a_24h',  price = 300, label = 'Ceiling Light 01 (24h)' },
        { object = 'dnxprops_lighting_ceilinglight02_a',      price = 300, label = 'Ceiling Light 02' },
        { object = 'dnxprops_lighting_picketlight01_a',       price = 200, label = 'Picket Light 01' },
        { object = 'dnxprops_lighting_picketlight02_a',       price = 200, label = 'Picket Light 02' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_lighting, Lighting)
end)

CreateThread(function()
    local Music = {
        { object = 'dnxprops_music_guitarwallmount01_a', price = 400, label = 'Guitar Wall Mount A' },
        { object = 'dnxprops_music_guitarwallmount01_b', price = 400, label = 'Guitar Wall Mount B' },
        { object = 'dnxprops_music_keyboard01_a_88',     price = 800, label = 'Keyboard 88-Key' },
        { object = 'dnxprops_music_keyboardstand01_a',   price = 200, label = 'Keyboard Stand' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_music, Music)
end)

CreateThread(function()
    local Tech = {
        { object = 'dnxprops_tech_gamingchair01_black',             price = 800,  label = 'Gaming Chair (Black)' },
        { object = 'dnxprops_tech_gamingchair01_blue',              price = 800,  label = 'Gaming Chair (Blue)' },
        { object = 'dnxprops_tech_gamingchair01_green',             price = 800,  label = 'Gaming Chair (Green)' },
        { object = 'dnxprops_tech_gamingchair01_pink',              price = 800,  label = 'Gaming Chair (Pink)' },
        { object = 'dnxprops_tech_gamingchair01_purple',            price = 800,  label = 'Gaming Chair (Purple)' },
        { object = 'dnxprops_tech_gamingchair01_red',               price = 800,  label = 'Gaming Chair (Red)' },
        { object = 'dnxprops_tech_gamingchair01_white',             price = 800,  label = 'Gaming Chair (White)' },
        { object = 'dnxprops_tech_gamingchair01_yellow',            price = 800,  label = 'Gaming Chair (Yellow)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_blue',         price = 150,  label = 'Gaming Keyboard A (Blue)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_cyan',         price = 150,  label = 'Gaming Keyboard A (Cyan)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_green',        price = 150,  label = 'Gaming Keyboard A (Green)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_off',          price = 150,  label = 'Gaming Keyboard A (Off)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_purple',       price = 150,  label = 'Gaming Keyboard A (Purple)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_red',          price = 150,  label = 'Gaming Keyboard A (Red)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_rgb1',         price = 150,  label = 'Gaming Keyboard A (RGB 1)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_rgb2',         price = 150,  label = 'Gaming Keyboard A (RGB 2)' },
        { object = 'dnxprops_tech_gamingkeyboard01_a_yellow',       price = 150,  label = 'Gaming Keyboard A (Yellow)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_blue',         price = 150,  label = 'Gaming Keyboard B (Blue)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_cyan',         price = 150,  label = 'Gaming Keyboard B (Cyan)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_green',        price = 150,  label = 'Gaming Keyboard B (Green)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_off',          price = 150,  label = 'Gaming Keyboard B (Off)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_purple',       price = 150,  label = 'Gaming Keyboard B (Purple)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_red',          price = 150,  label = 'Gaming Keyboard B (Red)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_rgb1',         price = 150,  label = 'Gaming Keyboard B (RGB 1)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_rgb2',         price = 150,  label = 'Gaming Keyboard B (RGB 2)' },
        { object = 'dnxprops_tech_gamingkeyboard01_b_yellow',       price = 150,  label = 'Gaming Keyboard B (Yellow)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_off',        price = 500,  label = 'Monitor A 27" (Off)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wp1',        price = 500,  label = 'Monitor A 27" (WP 1)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wp2',        price = 500,  label = 'Monitor A 27" (WP 2)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom1',  price = 500,  label = 'Monitor A 27" (Custom 1)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom2',  price = 500,  label = 'Monitor A 27" (Custom 2)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom3',  price = 500,  label = 'Monitor A 27" (Custom 3)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom4',  price = 500,  label = 'Monitor A 27" (Custom 4)' },
        { object = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom5',  price = 500,  label = 'Monitor A 27" (Custom 5)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_off',        price = 500,  label = 'Monitor B 27" (Off)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wp1',        price = 500,  label = 'Monitor B 27" (WP 1)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wp2',        price = 500,  label = 'Monitor B 27" (WP 2)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom1',  price = 500,  label = 'Monitor B 27" (Custom 1)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom2',  price = 500,  label = 'Monitor B 27" (Custom 2)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom3',  price = 500,  label = 'Monitor B 27" (Custom 3)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom4',  price = 500,  label = 'Monitor B 27" (Custom 4)' },
        { object = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom5',  price = 500,  label = 'Monitor B 27" (Custom 5)' },
        { object = 'dnxprops_tech_gamingmouse01_a_blue',            price = 100,  label = 'Gaming Mouse A (Blue)' },
        { object = 'dnxprops_tech_gamingmouse01_a_cyan',            price = 100,  label = 'Gaming Mouse A (Cyan)' },
        { object = 'dnxprops_tech_gamingmouse01_a_green',           price = 100,  label = 'Gaming Mouse A (Green)' },
        { object = 'dnxprops_tech_gamingmouse01_a_off',             price = 100,  label = 'Gaming Mouse A (Off)' },
        { object = 'dnxprops_tech_gamingmouse01_a_purple',          price = 100,  label = 'Gaming Mouse A (Purple)' },
        { object = 'dnxprops_tech_gamingmouse01_a_red',             price = 100,  label = 'Gaming Mouse A (Red)' },
        { object = 'dnxprops_tech_gamingmouse01_a_rgb1',            price = 100,  label = 'Gaming Mouse A (RGB 1)' },
        { object = 'dnxprops_tech_gamingmouse01_a_rgb2',            price = 100,  label = 'Gaming Mouse A (RGB 2)' },
        { object = 'dnxprops_tech_gamingmouse01_a_yellow',          price = 100,  label = 'Gaming Mouse A (Yellow)' },
        { object = 'dnxprops_tech_gamingmouse01_b_blue',            price = 100,  label = 'Gaming Mouse B (Blue)' },
        { object = 'dnxprops_tech_gamingmouse01_b_cyan',            price = 100,  label = 'Gaming Mouse B (Cyan)' },
        { object = 'dnxprops_tech_gamingmouse01_b_green',           price = 100,  label = 'Gaming Mouse B (Green)' },
        { object = 'dnxprops_tech_gamingmouse01_b_off',             price = 100,  label = 'Gaming Mouse B (Off)' },
        { object = 'dnxprops_tech_gamingmouse01_b_purple',          price = 100,  label = 'Gaming Mouse B (Purple)' },
        { object = 'dnxprops_tech_gamingmouse01_b_red',             price = 100,  label = 'Gaming Mouse B (Red)' },
        { object = 'dnxprops_tech_gamingmouse01_b_rgb1',            price = 100,  label = 'Gaming Mouse B (RGB 1)' },
        { object = 'dnxprops_tech_gamingmouse01_b_rgb2',            price = 100,  label = 'Gaming Mouse B (RGB 2)' },
        { object = 'dnxprops_tech_gamingmouse01_b_yellow',          price = 100,  label = 'Gaming Mouse B (Yellow)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_blue',         price = 75,   label = 'Mousepad A (Blue)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_cyan',         price = 75,   label = 'Mousepad A (Cyan)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_green',        price = 75,   label = 'Mousepad A (Green)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_off',          price = 75,   label = 'Mousepad A (Off)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_purple',       price = 75,   label = 'Mousepad A (Purple)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_red',          price = 75,   label = 'Mousepad A (Red)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_rgb1',         price = 75,   label = 'Mousepad A (RGB 1)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_rgb2',         price = 75,   label = 'Mousepad A (RGB 2)' },
        { object = 'dnxprops_tech_gamingmousepad01_a_yellow',       price = 75,   label = 'Mousepad A (Yellow)' },
        { object = 'dnxprops_tech_gamingpc01_a_blue',               price = 1500, label = 'Gaming PC A (Blue)' },
        { object = 'dnxprops_tech_gamingpc01_a_cyan',               price = 1500, label = 'Gaming PC A (Cyan)' },
        { object = 'dnxprops_tech_gamingpc01_a_green',              price = 1500, label = 'Gaming PC A (Green)' },
        { object = 'dnxprops_tech_gamingpc01_a_off',                price = 1500, label = 'Gaming PC A (Off)' },
        { object = 'dnxprops_tech_gamingpc01_a_purple',             price = 1500, label = 'Gaming PC A (Purple)' },
        { object = 'dnxprops_tech_gamingpc01_a_red',                price = 1500, label = 'Gaming PC A (Red)' },
        { object = 'dnxprops_tech_gamingpc01_a_rgb1',               price = 1500, label = 'Gaming PC A (RGB 1)' },
        { object = 'dnxprops_tech_gamingpc01_a_rgb2',               price = 1500, label = 'Gaming PC A (RGB 2)' },
        { object = 'dnxprops_tech_gamingpc01_a_yellow',             price = 1500, label = 'Gaming PC A (Yellow)' },
        { object = 'dnxprops_tech_gamingpc01_b_blue',               price = 1500, label = 'Gaming PC B (Blue)' },
        { object = 'dnxprops_tech_gamingpc01_b_cyan',               price = 1500, label = 'Gaming PC B (Cyan)' },
        { object = 'dnxprops_tech_gamingpc01_b_green',              price = 1500, label = 'Gaming PC B (Green)' },
        { object = 'dnxprops_tech_gamingpc01_b_off',                price = 1500, label = 'Gaming PC B (Off)' },
        { object = 'dnxprops_tech_gamingpc01_b_purple',             price = 1500, label = 'Gaming PC B (Purple)' },
        { object = 'dnxprops_tech_gamingpc01_b_red',                price = 1500, label = 'Gaming PC B (Red)' },
        { object = 'dnxprops_tech_gamingpc01_b_rgb1',               price = 1500, label = 'Gaming PC B (RGB 1)' },
        { object = 'dnxprops_tech_gamingpc01_b_rgb2',               price = 1500, label = 'Gaming PC B (RGB 2)' },
        { object = 'dnxprops_tech_gamingpc01_b_yellow',             price = 1500, label = 'Gaming PC B (Yellow)' },
        { object = 'dnxprops_tech_gamingpccase01_a',                price = 300,  label = 'PC Case A' },
        { object = 'dnxprops_tech_gamingpccase01_b',                price = 300,  label = 'PC Case B' },
        { object = 'dnxprops_tech_gamingpcfan01_a',                 price = 100,  label = 'PC Fan A' },
        { object = 'dnxprops_tech_gamingpcfan01_b',                 price = 100,  label = 'PC Fan B' },
        { object = 'dnxprops_tech_gamingpcgpu01_a',                 price = 200,  label = 'GPU A' },
        { object = 'dnxprops_tech_gamingpcgpu01_b',                 price = 200,  label = 'GPU B' },
        { object = 'dnxprops_tech_gamingpcmotherboard01_a',         price = 150,  label = 'Motherboard' },
        { object = 'dnxprops_tech_gamingpcram01_a',                 price = 100,  label = 'RAM A' },
        { object = 'dnxprops_tech_gamingpcram01_b',                 price = 100,  label = 'RAM B' },
        { object = 'dnxprops_tech_gamingpcssd01_a',                 price = 100,  label = 'SSD A' },
        { object = 'dnxprops_tech_gamingpcssd01_b',                 price = 100,  label = 'SSD B' },
        { object = 'dnxprops_tech_gamingpcssd01_c',                 price = 100,  label = 'SSD C' },
        { object = 'dnxprops_tech_gamingpcssd01_d',                 price = 100,  label = 'SSD D' },
        { object = 'dnxprops_tech_pcspeaker01_a',                   price = 200,  label = 'PC Speaker' },
        { object = 'dnxprops_tech_pcsubwoofer01_a',                 price = 300,  label = 'PC Subwoofer' },
    }
    InsertFurniture(FurnitureConfig.Furniture.dnx_tech, Tech)
end)
