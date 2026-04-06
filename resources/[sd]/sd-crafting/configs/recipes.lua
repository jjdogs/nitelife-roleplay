-- ==========================================
-- CRAFTING RECIPES (Organized by Table Name)
-- ==========================================
-- Recipes are organized into named tables (e.g., 'all', 'basic', 'advanced', 'weapons').
-- In config.lua, each station or placeable workbench specifies which tables to use via the 'recipes' field:
--
--   STATIC STATIONS (Config.Stations):
--     ['my_station'] = { recipes = { 'all', 'basic' }, ... }  --> Uses ['all'] + ['basic'] tables
--
--   PLACEABLE WORKBENCHES (Config.PlaceableWorkbenches):
--     ['portable_bench'] = { recipes = { 'all', 'weapons' }, ... }  --> Uses ['all'] + ['weapons'] tables
--
-- The 'all' table is commonly included to provide universal recipes available at any workbench.
-- You can create any table names you want and mix/match them per workbench.
--
-- TECH TREE GATING: If a recipe is listed as a tech tree unlock (via recipeId in techtrees.lua),
-- it will NOT appear in the crafting menu until unlocked - even if it's in a recipes table
-- assigned to that workbench/station.
--
-- LABELS ARE OPTIONAL:
-- Recipe and ingredient labels are automatically fetched from your inventory system.
-- You only need to specify a 'label' if you want to override the default name.
--
-- Recipe Structure:
-- {
--     id = 'unique_id',           -- Unique identifier for the recipe
--     name = 'item_name',         -- The item name in your inventory system
--     craftTime = 5,              -- Time in seconds to craft
--     ingredients = { ... },      -- List of required items (see ingredients section below)
--
--     -- All fields below are OPTIONAL --
--     label = 'Custom Name',      -- Override the auto-fetched label
--     category = 'tools',         -- Category for filtering
--     xpReward = 10,              -- XP reward for crafting (uses config default if not set)
--     techPointsReward = 1,       -- Tech points reward for crafting
--     levelRequired = 1,          -- Minimum level required to craft
--     cost = 500,                 -- Money cost to craft
--     failChance = 25,            -- Percentage chance (0-100) to fail and lose materials
--     blueprint = 'blueprint_x',  -- Required blueprint item name
--     blueprintDurabilityLoss = 5, -- Durability lost per craft (ox_inventory only, uses config default if not set)
--     outputAmount = 1,           -- Amount of items produced per craft (defaults to 1)
--     tools = { ... },            -- List of required tools (see tools section below)
--     image = 'nui://ox_inventory/web/images/custom.png', -- By default, images are auto-fetched from your inventory system. You can override the recipe image in the crafting UI.
--
--     -- METADATA (optional) --
--     -- Applied to the crafted item. Works with ox_inventory, qb, qs, codem, origen.
--     -- metadata = { description = 'A custom item', quality = 'Master' },
--     -- showMetadata = { quality = 'Quality' },  -- ox_inventory only: shows "Quality: Master" in tooltip
-- }
--
-- INGREDIENTS:
--     ingredients = {
--         { item = 'wood', amount = 5 },
--         { item = 'iron', amount = 2 },
--         -- { item = 'special', amount = 1, label = 'Custom Label' },  -- label is optional
--     },
--
-- TOOLS (optional):
--     tools = {
--         { item = 'hammer', amount = 1, consumptionType = 'none' },  -- Never consumed
--         { item = 'drill', amount = 1, consumptionType = 'durability', durabilityLoss = 5 },  -- Loses durability (ox_inventory)
--         { item = 'sandpaper', amount = 1, consumptionType = 'chance', consumeChance = 25 },  -- 25% chance to break
--         { item = 'glue', amount = 1, consumptionType = 'consume' },  -- Always consumed
--     },
--
-- METADATA SPECIAL PROPERTIES (ox_inventory):
-- These metadata keys have special behavior in ox_inventory:
--     label       - Display name of the item
--     description - Description shown in item tooltip
--     weight      - Override item weight
--     image       - Image path for the item (also used for recipe display in crafting UI)
--     imageurl    - URL to image for the item (also used for recipe display in crafting UI)
--
-- IMAGE PRIORITY: recipe.image > metadata.image > metadata.imageurl > auto-detected
--
-- Example with custom image via metadata:
--     {
--         id = 'custom_boombox',
--         name = 'boombox',
--         craftTime = 10,
--         metadata = {
--             description = 'Low volume, range and quality.',
--             imageurl = 'https://example.com/boombox.png',  -- Shows in crafting UI AND on crafted item
--         },
--         ingredients = { { item = 'plastic', amount = 5 } },
--     },

return {
    ['all'] = {
        -- Materials (very basic, no tech points)
        {
            id = 'wood_planks',
            name = 'wood_planks',
            craftTime = 3,
            category = 'materials',
            outputAmount = 25,
            levelRequired = 1,
            -- failChance = 50,
            ingredients = {
                { item = 'wood', amount = 2 },
            }
        },
        -- Varying metadata examples for different wood_planks variants.
        --[[{
            id = 'premium_wood_planks',
            name = 'wood_planks',
            label = 'Premium Wood Planks',
            craftTime = 5,
            category = 'materials',
            outputAmount = 50,
            levelRequired = 3,
            -- image = 'nui://ox_inventory/web/images/premium_planks.png',  -- Optional: override recipe image
            metadata = {
                description = 'Master-crafted premium wooden planks of exceptional quality',
                quality = 'Master',
                crafted = 'Yes',
                grade = 'Premium',
                -- imageurl = 'https://example.com/premium_planks.png',  -- Also shows in crafting UI
            },
            showMetadata = {
                quality = 'Quality',
                crafted = 'Handmade',
                grade = 'Grade',
            },
            ingredients = {
                { item = 'wood', amount = 5 },
            }
        },
        {
            id = 'oak_wood_planks',
            name = 'wood_planks',
            label = 'Oak Wood Planks',
            craftTime = 4,
            category = 'materials',
            outputAmount = 30,
            levelRequired = 2,
            metadata = {
                description = 'Sturdy oak planks known for their durability',
                quality = 'Standard',
                crafted = 'Yes',
                woodType = 'Oak',
            },
            showMetadata = {
                quality = 'Quality',
                crafted = 'Handmade',
                woodType = 'Wood Type',
            },
            ingredients = {
                { item = 'wood', amount = 3 },
            }
        },
        {
            id = 'mahogany_wood_planks',
            name = 'wood_planks',
            label = 'Mahogany Wood Planks',
            craftTime = 6,
            category = 'materials',
            outputAmount = 20,
            levelRequired = 5,
            metadata = {
                description = 'Rare mahogany planks with a rich, dark finish',
                quality = 'Exotic',
                crafted = 'Yes',
                woodType = 'Mahogany',
                rare = 'Yes',
            },
            showMetadata = {
                quality = 'Quality',
                crafted = 'Handmade',
                woodType = 'Wood Type',
                rare = 'Rare Item',
            },
            ingredients = {
                { item = 'wood', amount = 4 },
            }
        }, ]]
        {
            id = 'rubber_parts',
            name = 'rubber',
            craftTime = 4,
            category = 'materials',
            xpReward = 8,
            levelRequired = 1,
            ingredients = {
                { item = 'plastic', amount = 3 },
            }
        },

        -- Basic consumables (no tech points)
        {
            id = 'joint',
            name = 'joint',
            craftTime = 2,
            category = 'consumables',
            xpReward = 3,
            ingredients = {
                { item = 'rolling_paper', amount = 1 },
                { item = 'weed_ak47', amount = 1 },
            }
        },
    },

    ['basic'] = {
        -- Materials (basic, 1 tech point)
        {
            id = 'refined_metal',
            name = 'steel',
            craftTime = 5,
            category = 'materials',
            xpReward = 10,
            techPointsReward = 1,
            levelRequired = 1,
            ingredients = {
                { item = 'metalscrap', amount = 3 },
                { item = 'iron', amount = 2 },
            }
        },
        {
            id = 'refined_leather',
            name = 'deerhide',
            craftTime = 8,
            category = 'materials',
            xpReward = 12,
            techPointsReward = 1,
            ingredients = {
                { item = 'coyotepelt', amount = 2 },
            }
        },

        -- Basic Tools (1 tech point for simple, 2 for moderate)
        {
            id = 'lockpick',
            name = 'lockpick',
            craftTime = 5,
            category = 'tools',
            xpReward = 10,
            techPointsReward = 1,
            cost = 500,
            ingredients = {
                { item = 'metalscrap', amount = 2 },
                { item = 'iron', amount = 1 },
            }
        },
        {
            id = 'screwdriverset',
            name = 'screwdriverset',
            craftTime = 6,
            category = 'tools',
            xpReward = 12,
            techPointsReward = 1,
            ingredients = {
                { item = 'steel', amount = 2 },
                { item = 'plastic', amount = 1 },
                { item = 'rubber', amount = 1 },
            }
        },
        {
            id = 'repairkit',
            name = 'repairkit',
            craftTime = 8,
            category = 'tools',
            xpReward = 15,
            techPointsReward = 2,
            ingredients = {
                { item = 'metalscrap', amount = 3 },
                { item = 'steel', amount = 2 },
                { item = 'rubber', amount = 2 },
            }
        },
        {
            id = 'cleaningkit',
            name = 'cleaningkit',
            craftTime = 5,
            category = 'tools',
            xpReward = 8,
            techPointsReward = 1,
            ingredients = {
                { item = 'plastic', amount = 2 },
                { item = 'water', amount = 1 },
            }
        },
        {
            id = 'garden_shovel',
            name = 'garden_shovel',
            craftTime = 5,
            category = 'tools',
            xpReward = 10,
            techPointsReward = 1,
            ingredients = {
                { item = 'wood', amount = 2 },
                { item = 'steel', amount = 1 },
            }
        },
        {
            id = 'detecting_shovel',
            name = 'detecting_shovel',
            craftTime = 6,
            category = 'tools',
            xpReward = 12,
            techPointsReward = 1,
            ingredients = {
                { item = 'wood', amount = 2 },
                { item = 'steel', amount = 2 },
                { item = 'rubber', amount = 1 },
            }
        },
        {
            id = 'lighter',
            name = 'lighter',
            craftTime = 3,
            category = 'tools',
            xpReward = 5,
            ingredients = {
                { item = 'metalscrap', amount = 1 },
                { item = 'plastic', amount = 1 },
            }
        },
        {
            id = 'flashlight',
            name = 'flashlight',
            craftTime = 5,
            category = 'tools',
            xpReward = 10,
            techPointsReward = 1,
            ingredients = {
                { item = 'plastic', amount = 2 },
                { item = 'glass', amount = 1 },
                { item = 'copper', amount = 1 },
            }
        },
        {
            id = 'walking_stick',
            name = 'walking_stick',
            craftTime = 4,
            category = 'tools',
            xpReward = 8,
            ingredients = {
                { item = 'wood', amount = 3 },
                { item = 'rubber', amount = 1 },
            }
        },

        -- Basic Medical (1-2 tech points)
        {
            id = 'bandage',
            name = 'bandage',
            craftTime = 3,
            category = 'medical',
            xpReward = 5,
            ingredients = {
                { item = 'deerhide', amount = 1 },
            }
        },
        {
            id = 'firstaid',
            name = 'firstaid',
            craftTime = 8,
            category = 'medical',
            xpReward = 20,
            techPointsReward = 2,
            levelRequired = 2,
            ingredients = {
                { item = 'bandage', amount = 3 },
                { item = 'painkillers', amount = 1 },
                { item = 'plastic', amount = 1 },
            }
        },
        {
            id = 'splint',
            name = 'splint',
            craftTime = 6,
            category = 'medical',
            xpReward = 15,
            techPointsReward = 1,
            levelRequired = 3,
            ingredients = {
                { item = 'wood', amount = 2 },
                { item = 'bandage', amount = 2 },
                { item = 'deerhide', amount = 1 },
            }
        },

        -- Basic Hunting (1-2 tech points)
        {
            id = 'hunting_bait_1',
            name = 'hunting_bait_1',
            craftTime = 3,
            category = 'hunting',
            xpReward = 5,
            ingredients = {
                { item = 'boarmeat', amount = 1 },
            }
        },
        {
            id = 'hunting_bait_2',
            name = 'hunting_bait_2',
            craftTime = 5,
            category = 'hunting',
            xpReward = 12,
            techPointsReward = 1,
            levelRequired = 2,
            ingredients = {
                { item = 'hunting_bait_1', amount = 2 },
                { item = 'bee-honey', amount = 1 },
            }
        },
        {
            id = 'hunting_bait_3',
            name = 'hunting_bait_3',
            craftTime = 8,
            category = 'hunting',
            xpReward = 25,
            techPointsReward = 2,
            levelRequired = 3,
            ingredients = {
                { item = 'hunting_bait_2', amount = 2 },
                { item = 'bee-honey', amount = 2 },
                { item = 'boarmeat', amount = 1 },
            }
        },
        {
            id = 'hunting_trap',
            name = 'hunting_trap',
            craftTime = 10,
            category = 'hunting',
            xpReward = 25,
            techPointsReward = 2,
            levelRequired = 3,
            ingredients = {
                { item = 'steel', amount = 3 },
                { item = 'iron', amount = 2 },
                { item = 'wood', amount = 2 },
            }
        },

        -- Basic Protection (2 tech points)
        {
            id = 'harness',
            name = 'harness',
            craftTime = 8,
            category = 'protection',
            xpReward = 18,
            techPointsReward = 2,
            ingredients = {
                { item = 'deerhide', amount = 2 },
                { item = 'steel', amount = 2 },
                { item = 'rubber', amount = 1 },
            }
        },

        -- Basic Exploration (2 tech points)
        {
            id = 'metaldetector_1',
            name = 'metaldetector_1',
            craftTime = 10,
            category = 'exploration',
            xpReward = 20,
            techPointsReward = 2,
            levelRequired = 2,
            ingredients = {
                { item = 'electronickit', amount = 1 },
                { item = 'copper', amount = 2 },
                { item = 'plastic', amount = 2 },
                { item = 'iron', amount = 1 },
            }
        },
        {
            id = 'diving_gear_1',
            name = 'diving_gear_1',
            craftTime = 10,
            category = 'exploration',
            xpReward = 20,
            techPointsReward = 2,
            levelRequired = 2,
            ingredients = {
                { item = 'rubber', amount = 3 },
                { item = 'plastic', amount = 2 },
                { item = 'glass', amount = 1 },
                { item = 'steel', amount = 1 },
            }
        },

        -- Basic Misc (1-2 tech points)
        {
            id = 'bee_hive',
            name = 'bee-hive',
            craftTime = 12,
            category = 'misc',
            xpReward = 25,
            techPointsReward = 2,
            ingredients = {
                { item = 'wood_planks', amount = 5 },
                { item = 'bee-wax', amount = 2 },
            }
        },
        {
            id = 'empty_evidence_bag',
            name = 'empty_evidence_bag',
            craftTime = 2,
            category = 'misc',
            xpReward = 3,
            ingredients = {
                { item = 'plastic', amount = 2 },
            }
        },
    },

    -- Labels are auto-fetched from inventory. Add 'label' only to override.
    ['advanced'] = {
        -- Advanced Materials (2 tech points)
        {
            id = 'electronic_parts',
            name = 'electronickit',
            craftTime = 6,
            category = 'materials',
            xpReward = 15,
            techPointsReward = 2,
            levelRequired = 2,
            ingredients = {
                { item = 'copper', amount = 2 },
                { item = 'plastic', amount = 1 },
                { item = 'glass', amount = 1 },
            }
        },
        {
            id = 'gunpowder',
            name = 'gunpowder',
            craftTime = 6,
            category = 'materials',
            xpReward = 15,
            techPointsReward = 2,
            levelRequired = 3,
            ingredients = {
                { item = 'charcoal', amount = 2 },
                { item = 'sulfur', amount = 1 },
                { item = 'iron', amount = 1 },
            }
        },

        -- Advanced Tools (3-8 tech points)
        {
            id = 'advancedlockpick',
            name = 'advancedlockpick',
            craftTime = 10,
            category = 'tools',
            xpReward = 35,
            techPointsReward = 3,
            levelRequired = 4,
            blueprint = 'blueprint_advancedlockpick',
            ingredients = {
                { item = 'lockpick', amount = 1 },
                { item = 'steel', amount = 2 },
                -- { item = 'aluminium', amount = 1 },
            }
        },
        {
            id = 'advancedrepairkit',
            name = 'advancedrepairkit',
            craftTime = 12,
            category = 'tools',
            xpReward = 40,
            techPointsReward = 4,
            levelRequired = 4,
            ingredients = {
                { item = 'repairkit', amount = 1 },
                { item = 'steel', amount = 3 },
                { item = 'electronickit', amount = 1 },
            }
        },
        {
            id = 'drill',
            name = 'drill',
            craftTime = 15,
            category = 'tools',
            xpReward = 50,
            techPointsReward = 5,
            levelRequired = 5,
            ingredients = {
                { item = 'steel', amount = 3 },
                { item = 'electronickit', amount = 1 },
                { item = 'copper', amount = 2 },
            }
        },
        -- Example recipe with required tools (all consumption types demonstrated)
        -- Uncomment to test the tools feature
        --[[{
            id = 'precision_drill',
            name = 'drill',
            label = 'Precision Drill',
            craftTime = 20,
            category = 'tools',
            xpReward = 75,
            techPointsReward = 6,
            levelRequired = 6,
            ingredients = {
                { item = 'steel', amount = 5 },
                { item = 'electronickit', amount = 2 },
                { item = 'copper', amount = 3 },
            },
            tools = {
                {
                    item = 'screwdriverset',
                    amount = 1,
                    consumptionType = 'none', -- Never consumed, just needs to be present
                },
                {
                    item = 'drill',
                    amount = 1,
                    consumptionType = 'durability', -- Loses durability each craft (ox_inventory only)
                    durabilityLoss = 5,
                },
                {
                    item = 'sandpaper',
                    amount = 1,
                    consumptionType = 'chance', -- 25% chance to break per craft
                    consumeChance = 25,
                },
                {
                    item = 'cutting_fluid',
                    amount = 1,
                    consumptionType = 'consume', -- Always consumed like an ingredient
                },
            }
        },]]
        {
            id = 'powersaw',
            name = 'powersaw',
            craftTime = 15,
            category = 'tools',
            xpReward = 50,
            techPointsReward = 5,
            levelRequired = 5,
            ingredients = {
                { item = 'steel', amount = 4 },
                { item = 'electronickit', amount = 1 },
                { item = 'rubber', amount = 2 },
                { item = 'plastic', amount = 2 },
            }
        },
        {
            id = 'welding_torch',
            name = 'welding_torch',
            craftTime = 20,
            category = 'tools',
            xpReward = 75,
            techPointsReward = 6,
            levelRequired = 6,
            ingredients = {
                { item = 'steel', amount = 3 },
                { item = 'copper', amount = 4 },
                { item = 'aluminium', amount = 2 },
                { item = 'rubber', amount = 2 },
            }
        },
        {
            id = 'plasma_cutter',
            name = 'plasma_cutter',
            craftTime = 25,
            category = 'tools',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 8,
            ingredients = {
                { item = 'welding_torch', amount = 1 },
                { item = 'electronickit', amount = 3 },
                { item = 'copper', amount = 5 },
                { item = 'aluminium', amount = 3 },
            }
        },
        {
            id = 'binoculars',
            name = 'binoculars',
            craftTime = 10,
            category = 'tools',
            xpReward = 30,
            techPointsReward = 3,
            levelRequired = 3,
            ingredients = {
                { item = 'glass', amount = 4 },
                { item = 'plastic', amount = 2 },
                { item = 'rubber', amount = 1 },
            }
        },
        {
            id = 'night_vision',
            name = 'nvg',
            craftTime = 30,
            category = 'tools',
            xpReward = 120,
            techPointsReward = 9,
            levelRequired = 9,
            ingredients = {
                { item = 'binoculars', amount = 1 },
                { item = 'electronickit', amount = 4 },
                { item = 'glass', amount = 3 },
                { item = 'copper', amount = 5 },
            }
        },
        {
            id = 'master_toolkit',
            name = 'master_toolkit',
            craftTime = 40,
            category = 'tools',
            xpReward = 200,
            techPointsReward = 10,
            levelRequired = 10,
            ingredients = {
                { item = 'plasma_cutter', amount = 1 },
                { item = 'gatecrack', amount = 1 },
                { item = 'advancedrepairkit', amount = 2 },
                { item = 'electronickit', amount = 5 },
            }
        },

        -- Electronics (2-8 tech points)
        {
            id = 'radiocell',
            name = 'radiocell',
            craftTime = 4,
            category = 'electronics',
            xpReward = 8,
            techPointsReward = 1,
            ingredients = {
                { item = 'copper', amount = 1 },
                { item = 'iron', amount = 1 },
                { item = 'plastic', amount = 1 },
            }
        },
        {
            id = 'radio',
            name = 'radio',
            craftTime = 10,
            category = 'electronics',
            xpReward = 25,
            techPointsReward = 3,
            levelRequired = 3,
            ingredients = {
                { item = 'electronickit', amount = 1 },
                { item = 'copper', amount = 2 },
                { item = 'plastic', amount = 2 },
                { item = 'radiocell', amount = 1 },
            }
        },
        {
            id = 'jammer',
            name = 'jammer',
            craftTime = 20,
            category = 'electronics',
            xpReward = 60,
            techPointsReward = 5,
            levelRequired = 5,
            ingredients = {
                { item = 'radio', amount = 1 },
                { item = 'electronickit', amount = 2 },
                { item = 'copper', amount = 4 },
                { item = 'aluminium', amount = 2 },
            }
        },
        {
            id = 'cryptostick',
            name = 'cryptostick',
            craftTime = 12,
            category = 'electronics',
            xpReward = 35,
            techPointsReward = 4,
            levelRequired = 4,
            ingredients = {
                { item = 'electronickit', amount = 2 },
                { item = 'plastic', amount = 1 },
                { item = 'copper', amount = 2 },
            }
        },
        {
            id = 'trojan_usb',
            name = 'trojan_usb',
            craftTime = 15,
            category = 'electronics',
            xpReward = 50,
            techPointsReward = 5,
            levelRequired = 5,
            ingredients = {
                { item = 'cryptostick', amount = 1 },
                { item = 'electronickit', amount = 1 },
                { item = 'plastic', amount = 1 },
            }
        },
        {
            id = 'signal_scanner',
            name = 'signal_scanner',
            craftTime = 20,
            category = 'electronics',
            xpReward = 70,
            techPointsReward = 6,
            levelRequired = 6,
            ingredients = {
                { item = 'jammer', amount = 1 },
                { item = 'trojan_usb', amount = 1 },
                { item = 'electronickit', amount = 2 },
                { item = 'copper', amount = 3 },
            }
        },
        {
            id = 'gatecrack',
            name = 'gatecrack',
            craftTime = 25,
            category = 'electronics',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 7,
            ingredients = {
                { item = 'signal_scanner', amount = 1 },
                { item = 'electronickit', amount = 3 },
                { item = 'copper', amount = 5 },
                { item = 'aluminium', amount = 2 },
            }
        },

        -- Advanced Exploration (3-10 tech points)
        {
            id = 'metaldetector_2',
            name = 'metaldetector_2',
            craftTime = 12,
            category = 'exploration',
            xpReward = 30,
            techPointsReward = 3,
            levelRequired = 3,
            ingredients = {
                { item = 'metaldetector_1', amount = 1 },
                { item = 'electronickit', amount = 1 },
                { item = 'copper', amount = 2 },
                { item = 'aluminium', amount = 1 },
            }
        },
        {
            id = 'metaldetector_3',
            name = 'metaldetector_3',
            craftTime = 15,
            category = 'exploration',
            xpReward = 45,
            techPointsReward = 4,
            levelRequired = 4,
            ingredients = {
                { item = 'metaldetector_2', amount = 1 },
                { item = 'electronickit', amount = 2 },
                { item = 'copper', amount = 3 },
                { item = 'aluminium', amount = 2 },
            }
        },
        {
            id = 'metaldetector_4',
            name = 'metaldetector_4',
            craftTime = 18,
            category = 'exploration',
            xpReward = 65,
            techPointsReward = 6,
            levelRequired = 6,
            ingredients = {
                { item = 'metaldetector_3', amount = 1 },
                { item = 'electronickit', amount = 2 },
                { item = 'copper', amount = 4 },
                { item = 'glass', amount = 2 },
            }
        },
        {
            id = 'metaldetector_5',
            name = 'metaldetector_5',
            craftTime = 22,
            category = 'exploration',
            xpReward = 90,
            techPointsReward = 8,
            levelRequired = 8,
            ingredients = {
                { item = 'metaldetector_4', amount = 1 },
                { item = 'electronickit', amount = 3 },
                { item = 'copper', amount = 5 },
                { item = 'aluminium', amount = 3 },
                { item = 'md_goldnugget', amount = 1 },
            }
        },
        {
            id = 'diving_gear_2',
            name = 'diving_gear_2',
            craftTime = 14,
            category = 'exploration',
            xpReward = 35,
            techPointsReward = 3,
            levelRequired = 3,
            ingredients = {
                { item = 'diving_gear_1', amount = 1 },
                { item = 'rubber', amount = 2 },
                { item = 'aluminium', amount = 2 },
                { item = 'glass', amount = 1 },
            }
        },
        {
            id = 'diving_gear_3',
            name = 'diving_gear_3',
            craftTime = 18,
            category = 'exploration',
            xpReward = 50,
            techPointsReward = 5,
            levelRequired = 5,
            ingredients = {
                { item = 'diving_gear_2', amount = 1 },
                { item = 'rubber', amount = 3 },
                { item = 'aluminium', amount = 2 },
                { item = 'electronickit', amount = 1 },
            }
        },
        {
            id = 'diving_gear_4',
            name = 'diving_gear_4',
            craftTime = 22,
            category = 'exploration',
            xpReward = 70,
            techPointsReward = 6,
            levelRequired = 7,
            ingredients = {
                { item = 'diving_gear_3', amount = 1 },
                { item = 'rubber', amount = 3 },
                { item = 'aluminium', amount = 3 },
                { item = 'electronickit', amount = 1 },
                { item = 'steel', amount = 2 },
            }
        },
        {
            id = 'diving_gear_5',
            name = 'diving_gear_5',
            craftTime = 28,
            category = 'exploration',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 9,
            ingredients = {
                { item = 'diving_gear_4', amount = 1 },
                { item = 'rubber', amount = 4 },
                { item = 'aluminium', amount = 4 },
                { item = 'electronickit', amount = 2 },
                { item = 'dendrogyra_coral', amount = 1 },
            }
        },
        {
            id = 'diving_fill',
            name = 'diving_fill',
            craftTime = 8,
            category = 'exploration',
            xpReward = 15,
            techPointsReward = 2,
            levelRequired = 3,
            ingredients = {
                { item = 'aluminium', amount = 2 },
                { item = 'rubber', amount = 1 },
                { item = 'plastic', amount = 1 },
            }
        },
        {
            id = 'underwater_flashlight',
            name = 'underwater_flashlight',
            craftTime = 12,
            category = 'exploration',
            xpReward = 25,
            techPointsReward = 3,
            levelRequired = 4,
            ingredients = {
                { item = 'flashlight', amount = 1 },
                { item = 'rubber', amount = 2 },
                { item = 'glass', amount = 2 },
            }
        },
        {
            id = 'gps_tracker',
            name = 'gps_tracker',
            craftTime = 15,
            category = 'exploration',
            xpReward = 40,
            techPointsReward = 4,
            levelRequired = 5,
            ingredients = {
                { item = 'electronickit', amount = 2 },
                { item = 'copper', amount = 3 },
                { item = 'plastic', amount = 2 },
                { item = 'glass', amount = 1 },
            }
        },
        {
            id = 'sonar_device',
            name = 'sonar_device',
            craftTime = 25,
            category = 'exploration',
            xpReward = 80,
            techPointsReward = 7,
            levelRequired = 7,
            ingredients = {
                { item = 'gps_tracker', amount = 1 },
                { item = 'underwater_flashlight', amount = 1 },
                { item = 'electronickit', amount = 3 },
                { item = 'copper', amount = 5 },
            }
        },
        {
            id = 'treasure_hunter_kit',
            name = 'treasure_hunter_kit',
            craftTime = 35,
            category = 'exploration',
            xpReward = 150,
            techPointsReward = 10,
            levelRequired = 10,
            ingredients = {
                { item = 'metaldetector_5', amount = 1 },
                { item = 'diving_gear_5', amount = 1 },
                { item = 'sonar_device', amount = 1 },
                { item = 'electronickit', amount = 5 },
            }
        },

        -- Advanced Medical (4-10 tech points)
        {
            id = 'ifaks',
            name = 'ifaks',
            craftTime = 15,
            category = 'medical',
            xpReward = 45,
            techPointsReward = 4,
            levelRequired = 5,
            ingredients = {
                { item = 'firstaid', amount = 1 },
                { item = 'bandage', amount = 2 },
                { item = 'painkillers', amount = 2 },
            }
        },
        {
            id = 'trauma_kit',
            name = 'trauma_kit',
            craftTime = 20,
            category = 'medical',
            xpReward = 65,
            techPointsReward = 6,
            levelRequired = 6,
            ingredients = {
                { item = 'ifaks', amount = 1 },
                { item = 'splint', amount = 2 },
                { item = 'bandage', amount = 3 },
                { item = 'painkillers', amount = 2 },
            }
        },
        {
            id = 'field_surgery_kit',
            name = 'field_surgery_kit',
            craftTime = 30,
            category = 'medical',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 8,
            ingredients = {
                { item = 'trauma_kit', amount = 1 },
                { item = 'screwdriverset', amount = 1 },
                { item = 'steel', amount = 2 },
                { item = 'bandage', amount = 5 },
            }
        },
        {
            id = 'combat_medic_kit',
            name = 'combat_medic_kit',
            craftTime = 40,
            category = 'medical',
            xpReward = 150,
            techPointsReward = 10,
            levelRequired = 10,
            ingredients = {
                { item = 'field_surgery_kit', amount = 1 },
                { item = 'heavy_armour', amount = 1 },
                { item = 'ifaks', amount = 3 },
                { item = 'painkillers', amount = 5 },
            }
        },

        -- Advanced Hunting (4-8 tech points)
        {
            id = 'hunting_bait_4',
            name = 'hunting_bait_4',
            craftTime = 12,
            category = 'hunting',
            xpReward = 40,
            techPointsReward = 4,
            levelRequired = 5,
            ingredients = {
                { item = 'hunting_bait_3', amount = 2 },
                { item = 'bee-honey', amount = 2 },
                { item = 'mtlionfang', amount = 1 },
            }
        },
        {
            id = 'hunting_bait_5',
            name = 'hunting_bait_5',
            craftTime = 15,
            category = 'hunting',
            xpReward = 60,
            techPointsReward = 5,
            levelRequired = 7,
            ingredients = {
                { item = 'hunting_bait_4', amount = 2 },
                { item = 'bee-honey', amount = 3 },
                { item = 'mtlionpelt', amount = 1 },
            }
        },
        {
            id = 'ghillie_suit',
            name = 'ghillie_suit',
            craftTime = 20,
            category = 'hunting',
            xpReward = 50,
            techPointsReward = 5,
            levelRequired = 6,
            ingredients = {
                { item = 'deerhide', amount = 4 },
                { item = 'coyotepelt', amount = 3 },
                { item = 'wood', amount = 5 },
            }
        },
        {
            id = 'master_hunter_kit',
            name = 'master_hunter_kit',
            craftTime = 30,
            category = 'hunting',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 9,
            ingredients = {
                { item = 'hunting_bait_5', amount = 2 },
                { item = 'ghillie_suit', amount = 1 },
                { item = 'hunting_trap', amount = 2 },
                { item = 'binoculars', amount = 1 },
            }
        },

        -- Advanced Protection (5-10 tech points)
        {
            id = 'parachute',
            name = 'parachute',
            craftTime = 20,
            category = 'protection',
            xpReward = 70,
            techPointsReward = 6,
            levelRequired = 6,
            ingredients = {
                { item = 'deerhide', amount = 5 },
                { item = 'coyotepelt', amount = 3 },
                { item = 'rubber', amount = 4 },
                { item = 'steel', amount = 2 },
            }
        },
        {
            id = 'armour',
            name = 'armour',
            craftTime = 25,
            category = 'protection',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 7,
            blueprint = 'blueprint_armour',
            ingredients = {
                { item = 'steel', amount = 5 },
                { item = 'deerhide', amount = 3 },
                { item = 'rubber', amount = 3 },
                { item = 'aluminium', amount = 2 },
            }
        },
        {
            id = 'heavy_armour',
            name = 'heavy_armour',
            craftTime = 35,
            category = 'protection',
            xpReward = 150,
            techPointsReward = 9,
            levelRequired = 9,
            ingredients = {
                { item = 'armour', amount = 1 },
                { item = 'steel', amount = 8 },
                { item = 'aluminium', amount = 5 },
                { item = 'rubber', amount = 3 },
            }
        },
        {
            id = 'survivalist_pack',
            name = 'survivalist_pack',
            craftTime = 45,
            category = 'protection',
            xpReward = 200,
            techPointsReward = 10,
            levelRequired = 10,
            ingredients = {
                { item = 'master_hunter_kit', amount = 1 },
                { item = 'combat_medic_kit', amount = 1 },
                { item = 'heavy_armour', amount = 1 },
                { item = 'electronickit', amount = 3 },
            }
        },

        -- Engineering (3-10 tech points)
        {
            id = 'jerry_can',
            name = 'jerry_can',
            craftTime = 10,
            category = 'engineering',
            xpReward = 25,
            techPointsReward = 3,
            levelRequired = 3,
            ingredients = {
                { item = 'steel', amount = 3 },
                { item = 'rubber', amount = 2 },
                { item = 'plastic', amount = 1 },
            }
        },
        {
            id = 'nitrous',
            name = 'nitrous',
            craftTime = 18,
            category = 'engineering',
            xpReward = 55,
            techPointsReward = 5,
            levelRequired = 6,
            ingredients = {
                { item = 'jerry_can', amount = 1 },
                { item = 'aluminium', amount = 3 },
                { item = 'copper', amount = 2 },
                { item = 'electronickit', amount = 1 },
            }
        },
        {
            id = 'fuel_additive',
            name = 'fuel_additive',
            craftTime = 12,
            category = 'engineering',
            xpReward = 35,
            techPointsReward = 4,
            levelRequired = 4,
            ingredients = {
                { item = 'jerry_can', amount = 1 },
                { item = 'plastic', amount = 2 },
                { item = 'aluminium', amount = 1 },
            }
        },
        {
            id = 'turbo_kit',
            name = 'turbo_kit',
            craftTime = 25,
            category = 'engineering',
            xpReward = 80,
            techPointsReward = 7,
            levelRequired = 7,
            ingredients = {
                { item = 'nitrous', amount = 1 },
                { item = 'fuel_additive', amount = 1 },
                { item = 'steel', amount = 4 },
                { item = 'aluminium', amount = 3 },
            }
        },
        {
            id = 'performance_kit',
            name = 'performance_kit',
            craftTime = 35,
            category = 'engineering',
            xpReward = 120,
            techPointsReward = 9,
            levelRequired = 9,
            ingredients = {
                { item = 'turbo_kit', amount = 1 },
                { item = 'electronickit', amount = 3 },
                { item = 'steel', amount = 5 },
                { item = 'copper', amount = 4 },
            }
        },
        {
            id = 'thermite',
            name = 'thermite',
            craftTime = 20,
            category = 'engineering',
            xpReward = 80,
            techPointsReward = 7,
            levelRequired = 7,
            blueprint = 'blueprint_thermite',
            ingredients = {
                { item = 'aluminium', amount = 4 },
                { item = 'iron', amount = 4 },
                { item = 'md_ironnugget', amount = 3 },
            }
        },
        {
            id = 'shaped_charge',
            name = 'shaped_charge',
            craftTime = 25,
            category = 'engineering',
            xpReward = 100,
            techPointsReward = 8,
            levelRequired = 8,
            ingredients = {
                { item = 'thermite', amount = 1 },
                { item = 'steel', amount = 3 },
                { item = 'copper', amount = 3 },
                { item = 'gunpowder', amount = 2 },
            }
        },
        {
            id = 'det_cord',
            name = 'det_cord',
            craftTime = 15,
            category = 'engineering',
            xpReward = 60,
            techPointsReward = 5,
            levelRequired = 6,
            ingredients = {
                { item = 'thermite', amount = 1 },
                { item = 'plastic', amount = 3 },
                { item = 'copper', amount = 2 },
            }
        },
        {
            id = 'breaching_charge',
            name = 'breaching_charge',
            craftTime = 30,
            category = 'engineering',
            xpReward = 130,
            techPointsReward = 9,
            levelRequired = 9,
            ingredients = {
                { item = 'shaped_charge', amount = 1 },
                { item = 'det_cord', amount = 2 },
                { item = 'electronickit', amount = 2 },
                { item = 'gunpowder', amount = 3 },
            }
        },
        {
            id = 'demolition_kit',
            name = 'demolition_kit',
            craftTime = 40,
            category = 'engineering',
            xpReward = 180,
            techPointsReward = 10,
            levelRequired = 10,
            ingredients = {
                { item = 'breaching_charge', amount = 2 },
                { item = 'thermite', amount = 3 },
                { item = 'det_cord', amount = 3 },
                { item = 'electronickit', amount = 3 },
            }
        },
        {
            id = 'master_engineer_kit',
            name = 'master_engineer_kit',
            craftTime = 50,
            category = 'engineering',
            xpReward = 250,
            techPointsReward = 10,
            levelRequired = 10,
            ingredients = {
                { item = 'performance_kit', amount = 1 },
                { item = 'demolition_kit', amount = 1 },
                { item = 'welding_torch', amount = 1 },
                { item = 'electronickit', amount = 5 },
            }
        },
    },
}
