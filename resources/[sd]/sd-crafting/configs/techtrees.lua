-- ==========================================
-- TECH TREES (Organized by Tree ID)
-- ==========================================
-- Tech trees are organized into named tables within 'Trees' (e.g., 'basic_survival', 'technology').
-- In config.lua, each station or placeable workbench specifies which trees to use via the 'techTrees' field:
--
--   STATIC STATIONS (Config.Stations):
--     ['my_station'] = { techTrees = { 'basic_survival', 'technology' }, ... }
--
--   PLACEABLE WORKBENCHES (Config.PlaceableWorkbenches):
--     ['portable_bench'] = { techTrees = { 'basic_survival', 'exploration' }, ... }
--
-- You can create any tree IDs you want and mix/match them per workbench.
--
-- IMPORTANT: If a recipe is listed as a tech tree unlock (via recipeId (or just id in recipes.lua) in a node), it will NOT
-- appear in the crafting menu until unlocked - even if it's in a recipes table assigned to that
-- workbench/station. The tech tree acts as a gate for those recipes.
--
-- Tree Structure:
-- ['tree_id'] = {
--     label = 'Display Name',       -- Name shown in UI
--     icon = 'icon-name',           -- Lucide icon name (https://lucide.dev/icons)
--     color = '#hex',               -- Color for the tree in UI
--     nodes = {                     -- Array of unlock nodes
--         {
--             id = 'node_id',       -- Unique identifier for the node
--             recipeId = 'recipe',  -- Recipe ID this node unlocks (from recipes.lua)
--             cost = 10,            -- Tech points required to unlock
--             prerequisites = {},   -- Array of node IDs that must be unlocked first
--             position = { row = 1, col = 1 }  -- Grid position in the tree UI
--         },
--     }
-- }

return {
    enabled = true,
    perWorkbenchType = true, -- If true, players have separate tech points and unlocks per workbench type
    defaultTechPointsPerCraft = {
        enabled = false, -- If false, recipes without techPoints specified will give no tech points
        amount = 1,     -- Default tech points amount when recipe doesn't specify
    },

    -- Shared tech tree for placed workbenches
    -- When enabled, all players using the same placed workbench share tech points and unlocked nodes
    -- This does NOT affect static workbenches (defined in Config.Stations) - those are always per-player
    sharedPlacedWorkbench = {
        enabled = true, -- If true, placed workbenches share tech progress between all users
    },

    -- ==========================================
    -- TECH TREES
    -- ==========================================
    -- All available tech trees. Assign them to stations/workbenches in config.lua
    -- using techTrees = { 'tree_id_1', 'tree_id_2' }
    Trees = {
        -- ==========================================
        -- BASIC SURVIVAL TREE
        -- ==========================================
        ['basic_survival'] = {
            label = 'Basic Survival',
            icon = 'heart-pulse',
            color = '#ef4444',
            nodes = {
                {
                    id = 'firstaid_node',
                    recipeId = 'firstaid',
                    cost = 5,
                    prerequisites = {},
                    position = { row = 1, col = 2 },
                },
                {
                    id = 'hunting_bait_2_node',
                    recipeId = 'hunting_bait_2',
                    cost = 3,
                    prerequisites = {},
                    position = { row = 1, col = 4 },
                },
                {
                    id = 'splint_node',
                    recipeId = 'splint',
                    cost = 8,
                    prerequisites = { 'firstaid_node' },
                    position = { row = 2, col = 2 },
                },
                {
                    id = 'hunting_bait_3_node',
                    recipeId = 'hunting_bait_3',
                    cost = 8,
                    prerequisites = { 'hunting_bait_2_node' },
                    position = { row = 2, col = 4 },
                },
                {
                    id = 'hunting_trap_node',
                    recipeId = 'hunting_trap',
                    cost = 10,
                    prerequisites = { 'hunting_bait_2_node' },
                    position = { row = 2, col = 5 },
                },
            }
        },

        -- ==========================================
        -- BASIC EXPLORATION TREE
        -- ==========================================
        ['basic_exploration'] = {
            label = 'Basic Exploration',
            icon = 'compass',
            color = '#06b6d4',
            nodes = {
                {
                    id = 'metaldetector_1_node',
                    recipeId = 'metaldetector_1',
                    cost = 6,
                    prerequisites = {},
                    position = { row = 1, col = 2 },
                },
                {
                    id = 'diving_gear_1_node',
                    recipeId = 'diving_gear_1',
                    cost = 8,
                    prerequisites = {},
                    position = { row = 1, col = 4 },
                },
            }
        },

        -- ==========================================
        -- TOOLS & TECHNOLOGY (17 nodes)
        -- ==========================================
        ['technology'] = {
            label = 'Tools & Technology',
            icon = 'microchip',
            color = '#3b82f6',
            nodes = {
                -- Row 1: Entry Points
                {
                    id = 'repair_advanced',
                    recipeId = 'advancedrepairkit',
                    cost = 8,
                    prerequisites = {},
                    position = { row = 1, col = 3 },
                },
                {
                    id = 'radio_node',
                    recipeId = 'radio',
                    cost = 6,
                    prerequisites = {},
                    position = { row = 1, col = 5 },
                },
                {
                    id = 'cryptostick_node',
                    recipeId = 'cryptostick',
                    cost = 10,
                    prerequisites = {},
                    position = { row = 1, col = 7 },
                },

                -- Row 2: Tier 2
                {
                    id = 'drill_node',
                    recipeId = 'drill',
                    cost = 15,
                    prerequisites = {},
                    position = { row = 2, col = 1 },
                },
                {
                    id = 'powersaw_node',
                    recipeId = 'powersaw',
                    cost = 15,
                    prerequisites = { 'repair_advanced' },
                    position = { row = 2, col = 3 },
                },
                {
                    id = 'binoculars_node',
                    recipeId = 'binoculars',
                    cost = 12,
                    prerequisites = { 'repair_advanced' },
                    position = { row = 2, col = 4 },
                },
                {
                    id = 'jammer_node',
                    recipeId = 'jammer',
                    cost = 18,
                    prerequisites = { 'radio_node' },
                    position = { row = 2, col = 5 },
                },
                {
                    id = 'trojan_usb_node',
                    recipeId = 'trojan_usb',
                    cost = 18,
                    prerequisites = { 'cryptostick_node' },
                    position = { row = 2, col = 7 },
                },

                -- Row 3: Tier 3 - Convergence
                {
                    id = 'welding_torch_node',
                    recipeId = 'welding_torch',
                    cost = 25,
                    prerequisites = { 'drill_node', 'powersaw_node' },
                    position = { row = 3, col = 2 },
                },
                {
                    id = 'signal_scanner_node',
                    recipeId = 'signal_scanner',
                    cost = 25,
                    prerequisites = { 'jammer_node', 'trojan_usb_node' },
                    position = { row = 3, col = 6 },
                },

                -- Row 4: Tier 4
                {
                    id = 'plasma_cutter_node',
                    recipeId = 'plasma_cutter',
                    cost = 35,
                    prerequisites = { 'welding_torch_node' },
                    position = { row = 4, col = 2 },
                },
                {
                    id = 'night_vision_node',
                    recipeId = 'night_vision',
                    cost = 30,
                    prerequisites = { 'binoculars_node', 'signal_scanner_node' },
                    position = { row = 4, col = 4 },
                },
                {
                    id = 'gatecrack_node',
                    recipeId = 'gatecrack',
                    cost = 40,
                    prerequisites = { 'signal_scanner_node' },
                    position = { row = 4, col = 6 },
                },

                -- Row 5: Ultimate
                {
                    id = 'master_toolkit_node',
                    recipeId = 'master_toolkit',
                    cost = 60,
                    prerequisites = { 'plasma_cutter_node', 'gatecrack_node' },
                    position = { row = 5, col = 4 },
                },
            }
        },

        -- ==========================================
        -- EXPLORATION (15 nodes)
        -- ==========================================
        ['exploration'] = {
            label = 'Exploration',
            icon = 'compass',
            color = '#06b6d4',
            nodes = {
                -- Row 1: Entry points
                {
                    id = 'metaldetector_2_node',
                    recipeId = 'metaldetector_2',
                    cost = 8,
                    prerequisites = {},
                    position = { row = 1, col = 2 },
                },
                {
                    id = 'diving_gear_2_node',
                    recipeId = 'diving_gear_2',
                    cost = 10,
                    prerequisites = {},
                    position = { row = 1, col = 5 },
                },

                -- Row 2
                {
                    id = 'metaldetector_3_node',
                    recipeId = 'metaldetector_3',
                    cost = 15,
                    prerequisites = { 'metaldetector_2_node' },
                    position = { row = 2, col = 2 },
                },
                {
                    id = 'gps_tracker_node',
                    recipeId = 'gps_tracker',
                    cost = 20,
                    prerequisites = { 'metaldetector_2_node', 'diving_gear_2_node' },
                    position = { row = 2, col = 3 },
                },
                {
                    id = 'diving_gear_3_node',
                    recipeId = 'diving_gear_3',
                    cost = 18,
                    prerequisites = { 'diving_gear_2_node' },
                    position = { row = 2, col = 5 },
                },
                {
                    id = 'diving_fill_node',
                    recipeId = 'diving_fill',
                    cost = 12,
                    prerequisites = { 'diving_gear_2_node' },
                    position = { row = 2, col = 6 },
                },

                -- Row 3
                {
                    id = 'metaldetector_4_node',
                    recipeId = 'metaldetector_4',
                    cost = 25,
                    prerequisites = { 'metaldetector_3_node' },
                    position = { row = 3, col = 2 },
                },
                {
                    id = 'diving_gear_4_node',
                    recipeId = 'diving_gear_4',
                    cost = 28,
                    prerequisites = { 'diving_gear_3_node' },
                    position = { row = 3, col = 5 },
                },
                {
                    id = 'underwater_flashlight_node',
                    recipeId = 'underwater_flashlight',
                    cost = 15,
                    prerequisites = { 'diving_fill_node' },
                    position = { row = 3, col = 6 },
                },

                -- Row 4
                {
                    id = 'metaldetector_5_node',
                    recipeId = 'metaldetector_5',
                    cost = 40,
                    prerequisites = { 'metaldetector_4_node' },
                    position = { row = 4, col = 2 },
                },
                {
                    id = 'sonar_device_node',
                    recipeId = 'sonar_device',
                    cost = 35,
                    prerequisites = { 'gps_tracker_node', 'underwater_flashlight_node' },
                    position = { row = 4, col = 4 },
                },
                {
                    id = 'diving_gear_5_node',
                    recipeId = 'diving_gear_5',
                    cost = 45,
                    prerequisites = { 'diving_gear_4_node' },
                    position = { row = 4, col = 5 },
                },

                -- Row 5: Ultimate
                {
                    id = 'treasure_hunter_kit_node',
                    recipeId = 'treasure_hunter_kit',
                    cost = 60,
                    prerequisites = { 'metaldetector_5_node', 'diving_gear_5_node', 'sonar_device_node' },
                    position = { row = 5, col = 4 },
                },
            }
        },

        -- ==========================================
        -- SURVIVAL (18 nodes)
        -- ==========================================
        ['survival'] = {
            label = 'Survival',
            icon = 'heart-pulse',
            color = '#ef4444',
            nodes = {
                -- Row 1: Entry points (3 branches)
                {
                    id = 'ifak_node',
                    recipeId = 'ifaks',
                    cost = 10,
                    prerequisites = {},
                    position = { row = 1, col = 1 },
                },
                {
                    id = 'hunting_bait_4_node',
                    recipeId = 'hunting_bait_4',
                    cost = 12,
                    prerequisites = {},
                    position = { row = 1, col = 4 },
                },
                {
                    id = 'parachute_node',
                    recipeId = 'parachute',
                    cost = 15,
                    prerequisites = {},
                    position = { row = 1, col = 7 },
                },

                -- Row 2
                {
                    id = 'trauma_kit_node',
                    recipeId = 'trauma_kit',
                    cost = 20,
                    prerequisites = { 'ifak_node' },
                    position = { row = 2, col = 1 },
                },
                {
                    id = 'hunting_bait_5_node',
                    recipeId = 'hunting_bait_5',
                    cost = 20,
                    prerequisites = { 'hunting_bait_4_node' },
                    position = { row = 2, col = 4 },
                },
                {
                    id = 'ghillie_suit_node',
                    recipeId = 'ghillie_suit',
                    cost = 18,
                    prerequisites = { 'hunting_bait_4_node' },
                    position = { row = 2, col = 5 },
                },
                {
                    id = 'armour_node',
                    recipeId = 'armour',
                    cost = 30,
                    prerequisites = { 'parachute_node' },
                    position = { row = 2, col = 7 },
                },

                -- Row 3
                {
                    id = 'field_surgery_kit_node',
                    recipeId = 'field_surgery_kit',
                    cost = 35,
                    prerequisites = { 'trauma_kit_node' },
                    position = { row = 3, col = 1 },
                },
                {
                    id = 'master_hunter_node',
                    recipeId = 'master_hunter_kit',
                    cost = 40,
                    prerequisites = { 'hunting_bait_5_node', 'ghillie_suit_node' },
                    position = { row = 3, col = 4 },
                },
                {
                    id = 'heavy_armour_node',
                    recipeId = 'heavy_armour',
                    cost = 45,
                    prerequisites = { 'armour_node' },
                    position = { row = 3, col = 7 },
                },

                -- Row 4: Convergence
                {
                    id = 'combat_medic_kit_node',
                    recipeId = 'combat_medic_kit',
                    cost = 50,
                    prerequisites = { 'field_surgery_kit_node', 'heavy_armour_node' },
                    position = { row = 4, col = 4 },
                },

                -- Row 5: Ultimate
                {
                    id = 'survivalist_pack_node',
                    recipeId = 'survivalist_pack',
                    cost = 70,
                    prerequisites = { 'master_hunter_node', 'combat_medic_kit_node' },
                    position = { row = 5, col = 4 },
                },
            }
        },

        -- ==========================================
        -- ENGINEERING (11 nodes)
        -- ==========================================
        ['engineering'] = {
            label = 'Engineering',
            icon = 'gears',
            color = '#f97316',
            nodes = {
                -- Row 1: Entry points
                {
                    id = 'jerry_can_node',
                    recipeId = 'jerry_can',
                    cost = 10,
                    prerequisites = {},
                    position = { row = 1, col = 2 },
                },
                {
                    id = 'thermite_node',
                    recipeId = 'thermite',
                    cost = 35,
                    prerequisites = {},
                    position = { row = 1, col = 5 },
                },

                -- Row 2
                {
                    id = 'nitrous_node',
                    recipeId = 'nitrous',
                    cost = 25,
                    prerequisites = { 'jerry_can_node' },
                    position = { row = 2, col = 1 },
                },
                {
                    id = 'fuel_additive_node',
                    recipeId = 'fuel_additive',
                    cost = 18,
                    prerequisites = { 'jerry_can_node' },
                    position = { row = 2, col = 3 },
                },
                {
                    id = 'shaped_charge_node',
                    recipeId = 'shaped_charge',
                    cost = 45,
                    prerequisites = { 'thermite_node' },
                    position = { row = 2, col = 5 },
                },
                {
                    id = 'det_cord_node',
                    recipeId = 'det_cord',
                    cost = 30,
                    prerequisites = { 'thermite_node' },
                    position = { row = 2, col = 6 },
                },

                -- Row 3
                {
                    id = 'turbo_kit_node',
                    recipeId = 'turbo_kit',
                    cost = 40,
                    prerequisites = { 'nitrous_node', 'fuel_additive_node' },
                    position = { row = 3, col = 2 },
                },
                {
                    id = 'breaching_charge_node',
                    recipeId = 'breaching_charge',
                    cost = 55,
                    prerequisites = { 'shaped_charge_node', 'det_cord_node' },
                    position = { row = 3, col = 5 },
                },

                -- Row 4
                {
                    id = 'performance_kit_node',
                    recipeId = 'performance_kit',
                    cost = 55,
                    prerequisites = { 'turbo_kit_node' },
                    position = { row = 4, col = 2 },
                },
                {
                    id = 'demolition_kit_node',
                    recipeId = 'demolition_kit',
                    cost = 70,
                    prerequisites = { 'breaching_charge_node' },
                    position = { row = 4, col = 5 },
                },

                -- Row 5: Ultimate
                {
                    id = 'master_engineer_kit_node',
                    recipeId = 'master_engineer_kit',
                    cost = 80,
                    prerequisites = { 'performance_kit_node', 'demolition_kit_node' },
                    position = { row = 5, col = 3 },
                },
            }
        },
    },
}
