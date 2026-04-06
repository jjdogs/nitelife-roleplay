return {
    -- Locale Configuration
    -- Defines which language file to use from the locales folder
    -- Available: 'en' (English), 'de' (German)
    Locale = 'en',

    -- Command Names for admin actions
    -- Customize the chat command names for admin actions
    Commands = {
        placeWorkbench = 'placeworkbench', -- Command to place a workbench prop and get config coordinates
        craftAdmin = 'craftadmin', -- Command to open the crafting admin panel
    },

    -- Enable debug prints
    Debug = false,

    -- Enable verbose debug prints (logs every queue tick per second - very noisy)
    DebugVerbose = false,

    -- Maximum Inventory Weight (in grams)
    -- This value is used as a fallback when the script cannot automatically
    -- retrieve the player's max inventory weight from the inventory system.
    -- The script will attempt to get this value from your inventory (ox, qb, qs, codem, origen)
    -- but if it fails, it will default to this value.
    MaxInventoryWeight = 120000, -- 120kg default

    -- Crafting Behavior Settings (Global Defaults)
    -- Controls what happens when the player closes the UI while crafting
    -- NOTE: These are the DEFAULT settings. You can override these per-station (in Stations table)
    -- or per-placeable workbench (in PlaceableWorkbenches table) by adding a CraftingBehavior table.
    -- Station/placeable overrides only need to include the settings you want to change -
    -- any missing settings will fall back to these global defaults.
    CraftingBehavior = {
        preventCloseWhileCrafting = true, -- If true, player cannot close the UI while crafting (must cancel or wait)

        cancelCraftOnClose = false, -- If preventCloseWhileCrafting is false, cancel craft and refund materials when closing

        allowCraftingNearby = {
            enabled = false, -- If true and cancelCraftOnClose is false, crafting continues while player stays nearby
            distance = 5.0, -- Maximum distance from workbench to continue crafting
        },

        -- Allow crafting to continue anywhere after starting (no distance restriction)
        -- If enabled, player can start a craft, close the menu, and go anywhere while it completes
        -- NOTE: When the UI is closed and crafting completes, items go to the crafting stash (player may not be near workbench)
        -- If the player has the UI open when crafting completes, it follows the AddOutputToStash setting instead
        allowCraftingAnywhere = {
            enabled = false, -- Enable crafting anywhere functionality
            notifyPlayer = false, -- If true, notify player when crafting completes even if far away
        },

        sharedCrafting = {
            placed = true, -- If true, crafting queue is shared for placed workbenches
            static = false, -- If true, crafting queue is shared for static workbenches (defined in Stations)
        },
    },

    -- Crafting Output Destination
    -- When true, crafted items are added to the crafting inventory/stash instead of the player's inventory
    -- When false (default), crafted items are given directly to the player
    AddOutputToStash = true,

    -- Fail Chance Behavior
    -- Controls how fail chance is calculated when crafting multiple items at once
    FailChance = {
        -- When true: One roll for the entire batch - all items succeed or all fail together
        -- When false: Roll for each item individually - some may succeed, some may fail
        -- Example with 25% fail chance crafting 10 items:
        --   treatQuantityAsWhole = true  -> Either all 10 succeed or all 10 fail (one 25% roll)
        --   treatQuantityAsWhole = false -> Each item rolls separately, average ~7-8 succeed, ~2-3 fail
        treatQuantityAsWhole = false,
    },

    -- Queue Persistence Settings
    -- When true, crafting time continues to tick down even when the server/script is offline
    -- If a craft completes while the server is offline, items are added to the crafting stash on next start
    -- When false, the queue resumes from where it left off (remaining time stays the same)
    -- NOTE: This only affects server/script restarts. For player disconnects, the server always
    -- continues ticking down craft timers while a player is away (unless CancelCraftOnLeave is true).
    TickDownQueueWhenOffline = false,

    -- When true, if a player disconnects or crashes while crafting, their entire queue is cancelled
    -- and all ingredients are refunded to the station's staging inventory (crafting stash).
    -- When false, the server continues counting down the craft timer while the player is away.
    -- If the craft finishes before the player returns, the output is added to the station's staging inventory.
    -- On reconnect the player is notified how many items completed while they were gone.
    -- Note: Recipe costs (money) are not refunded since the player is offline at time of cancellation.
    -- HIGHLY RECOMMEND LEAVING THIS AS TRUE, OFFLINE CRAFTING CAN CAUSE ERRATIC BEHAVIOUR AND IS CONSIDERED NON-FUNCTIONING.
    CancelCraftOnLeave = true,

    -- Periodic queue saving settings
    -- Queues are ALWAYS saved on player disconnect, server shutdown (txAdmin), and queue completion
    -- This setting controls whether to also save periodically during gameplay
    PeriodicQueueSave = {
        -- Set to true to enable periodic saves. You really only need this on if you're testing and restarting the resource on Live. 
        -- The txAdmin shutdown handler is more than enough to accurately save your Data. Just be aware that without this enabled, restarting the resource (not shutting down server as you would on your Live) will potentially result in data-loss
        -- as onResourceStop is not a reliable handler for large scale data saving. I'd recommend heavily to keep this as false, data saving won't be an issue on your live/public server.
        enabled = false,
        interval = 10,   -- How often to save (in seconds) - only used if enabled
    },

    -- Blueprint system settings
    Blueprints = {
        enabled = true,
        -- Random destruction chance (legacy system - disabled if durability is enabled)
        destroyOnCraft = {
            enabled = false,
            chance = 15
        },
        -- Durability system (ox_inventory exclusive - uses item metadata)
        -- When enabled, blueprints have durability that degrades with each craft
        -- This overrides the destroyOnCraft system when active
        durability = {
            enabled = true, -- Enable durability system (requires ox_inventory)
            defaultDurability = 100, -- Default max durability for new blueprints
            defaultLoss = 10, -- Default durability loss per craft if not specified in recipe (blueprintDurabilityLoss)
        }
    },

    -- Required Tools system settings
    -- Tools are items that must be present in the crafting inventory to craft
    -- Unlike ingredients, tools have configurable consumption behavior
    Tools = {
        enabled = true,
        -- Durability system for tools (ox_inventory exclusive)
        -- When enabled, tools with consumptionType = 'durability' will lose durability per craft
        durability = {
            enabled = true, -- Enable durability consumption for tools (requires ox_inventory)
            defaultDurability = 100, -- Default max durability for tools
            defaultLoss = 10, -- Default durability loss per craft if not specified in recipe
        }
    },

    -- Inventory Panel & Staging System
    -- When enabled, shows the left panel with player inventory and a crafting inventory
    -- where players can stage items for crafting
    InventoryPanel = {
        enabled = true,        -- Show inventory panel with staging functionality
        showAllItems = true,   -- Show all items (true) or only items used in recipes (false)
        maxSlots = 20,          -- Maximum slots in the crafting inventory
        maxWeight = 500000,     -- Maximum weight in crafting inventory (0 = unlimited)
        perWorkbench = {
            placed = true,     -- If true, staged items are shared per-workbench for placed workbenches; if false, per-player
            static = false,     -- If true, staged items are shared per-workbench for static workbenches; if false, per-player
        },
        returnOnClose = false,  -- Return staged items to player inventory when closing UI
    },

    -- Leveling system settings
    Leveling = {
        enabled = true,
        perWorkbenchType = true, -- If true, players have separate levels per workbench type (basic, advanced, etc.)
        defaultXpReward = {
            enabled = true, -- If false, recipes without xpReward specified will give no XP
            amount = 5,    -- Default XP amount when recipe doesn't specify
        },

        -- Default level config (used when perWorkbenchType is false, or as fallback)
        levels = {
            [1] = 0,
            [2] = 100,
            [3] = 250,
            [4] = 500,
            [5] = 850,
            [6] = 1300,
            [7] = 1900,
            [8] = 2650,
            [9] = 3550,
            [10] = 4600,
        },
        maxLevel = 10,

        -- Per-workbench-type level configurations (only used when perWorkbenchType is true)
        -- If a type is not defined here, it uses the default levels/maxLevel above
        workbenchTypes = {
            ['basic'] = {
                levels = {
                    [1] = 0,
                    [2] = 100,
                    [3] = 250,
                    [4] = 500,
                    [5] = 850,
                    [6] = 1300,
                    [7] = 1900,
                    [8] = 2650,
                    [9] = 3550,
                    [10] = 4600,
                },
                maxLevel = 10,
            },
            ['advanced'] = {
                levels = {
                    [1] = 0,
                    [2] = 200,
                    [3] = 500,
                    [4] = 1000,
                    [5] = 1700,
                    [6] = 2600,
                    [7] = 3800,
                    [8] = 5300,
                    [9] = 7100,
                    [10] = 9200,
                    [11] = 11600,
                    [12] = 14300,
                    [13] = 17300,
                    [14] = 20600,
                    [15] = 24200,
                },
                maxLevel = 15,
            },
        },
    },

    -- ==========================================
    -- SHOP PEDS CONFIGURATION
    -- ==========================================
    -- Shop peds that sell workbenches and crafting items
    Shops = {
        ['workbench_vendor'] = {
            label = 'Workbench Vendor',
            coords = vector3(342.95, -1298.04, 32.51), -- Position of the ped
            heading = 159.2, -- Direction the ped faces
            model = 's_m_m_autoshop_02', -- Ped model
            spawnRadius = 50.0, -- Distance at which ped spawns
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- Ped animation/scenario
            useItemImages = false, -- If true, uses item images from inventory. If false, uses the icon defined per item
            blip = {
                enabled = true,
                sprite = 566, -- Wrench/tool icon
                color = 2,
                scale = 0.7,
                label = 'Workbench Vendor'
            },
            -- Items this shop sells
            items = {
                {
                    id = 'workbench',
                    label = 'Basic Workbench',
                    description = 'A small portable workbench for crafting on the go',
                    icon = 'fa-solid fa-toolbox',
                    price = 5000,
                },
                {
                    id = 'advanced_workbench',
                    label = 'Advanced Workbench',
                    description = 'A high-tech workbench with advanced crafting capabilities',
                    icon = 'fa-solid fa-gears',
                    price = 15000,
                },
            }
        },
        -- Example of another shop
        -- ['materials_vendor'] = {
        --     label = 'Materials Vendor',
        --     coords = vector3(100.0, 200.0, 30.0),
        --     heading = 90.0,
        --     model = 's_m_y_construct_01',
        --     spawnRadius = 50.0,
        --     scenario = 'WORLD_HUMAN_CLIPBOARD',
        --     blip = {
        --         enabled = true,
        --         sprite = 478,
        --         color = 5,
        --         scale = 0.7,
        --         label = 'Materials Shop'
        --     },
        --     items = {
        --         {
        --             id = 'metalscrap',
        --             label = 'Metal Scrap',
        --             description = 'Raw metal scraps for crafting',
        --             icon = 'fa-solid fa-cube',
        --             price = 50,
        --             currency = 'cash',
        --         },
        --     }
        -- },
    },

    -- ==========================================
    -- PLACEABLE WORKBENCHES CONFIGURATION
    -- ==========================================
    -- Placement method: true = use object_gizmo, false = use raycast placement (like sd-beekeeping)
    useGizmo = false,
    raycastDistance = 10.0, -- Max distance for raycast placement (only used when useGizmo = false)
    raycastFlags = -1, -- Raycast collision flags (-1 = everything, works with housing shells. Default 339 may not detect shell interiors)

    -- Permissions system for placed workbenches
    -- When enabled, only the owner and players they add can use placed workbenches
    Permissions = {
        enabled = true,
    },

    -- Crafting history for placed workbenches
    -- When enabled, shows a history tab displaying who crafted what
    -- History is ALWAYS saved to database regardless of this setting (only controls UI visibility)
    History = {
        enabled = true, -- Show the history tab in the UI (history still saves to DB even if false)
        maxEntries = 100, -- Maximum history entries per workbench (oldest entries are removed when limit is exceeded)
        ownerOnlyDelete = true, -- If true, only the workbench owner can delete history entries. If false, anyone with access can delete
        dateFormat = 'DMY', -- Date display format: 'DMY' for DD/MM/YYYY or 'MDY' for MM/DD/YYYY
    },

    -- Items that can be placed as portable workbenches
    -- 'recipes' specifies which recipe TABLES to use (from configs/recipes.lua)
    -- e.g., { 'all', 'basic' } = recipes from 'all' table + 'basic' table
    -- 'techTrees' specifies which tech trees to use (from configs/techtrees.lua)
    -- e.g., { 'basic_survival', 'technology' } = tech trees from techtrees.lua
    --
    -- Job/Gang Locking (optional):
    --   job = { name = 'mechanic', minGrade = 0 }  -- Lock to specific job (minGrade is optional, defaults to 0)
    --   gang = 'ballas'                             -- Lock to specific gang (QBCore only)
    --
    -- CraftingBehavior (optional):
    --   Override the global CraftingBehavior settings for this specific workbench type.
    --   Only include the settings you want to override - missing settings use global defaults.
    --   Example: CraftingBehavior = { preventCloseWhileCrafting = false, allowCraftingAnywhere = { enabled = true } }
    PlaceableWorkbenches = {
        ['workbench'] = {
            label = 'Basic Workbench',
            type = 'basic', -- Type of workbench (used for per-workbench leveling)
            prop = 'prop_tool_bench02', -- Prop model to spawn
            recipes = { 'all', 'basic' }, -- Recipe tables: 'all' + 'basic' (from recipes.lua)
            techTrees = { 'basic_survival', 'basic_exploration' }, -- Tech trees from techtrees.lua
            -- job = { name = 'mechanic', minGrade = 0 }, -- Optional: Lock to mechanic job
            -- gang = 'ballas', -- Optional: Lock to gang (QBCore only)
            -- CraftingBehavior = { -- Optional: Override global CraftingBehavior for this workbench (only include what you want to change, if something isn't, then it defaults to main .CraftingBehavior)
            --     preventCloseWhileCrafting = false,
            --     cancelCraftOnClose = false,
            --     allowCraftingNearby = { enabled = true, distance = 10.0 },
            --     allowCraftingAnywhere = { enabled = true, notifyPlayer = true },
            --     sharedCrafting = { placed = true, static = false },
            -- },
        },
        ['advanced_workbench'] = {
            label = 'Advanced Workbench',
            type = 'advanced', -- Type of workbench
            prop = 'gr_prop_gr_bench_04b', -- Advanced workbench prop
            recipes = { 'all', 'basic', 'advanced' }, -- Recipe tables: 'all' + 'basic' + 'advanced' (from recipes.lua)
            techTrees = { 'technology', 'exploration', 'survival', 'engineering' }, -- Tech trees from techtrees.lua
            -- job = { name = 'mechanic', minGrade = 2 }, -- Optional: Lock to mechanic job grade 2+
            -- CraftingBehavior = { -- Optional: Override global CraftingBehavior for this workbench (only include what you want to change, if something isn't, then it defaults to main .CraftingBehavior)
            --     preventCloseWhileCrafting = false,
            --     cancelCraftOnClose = false,
            --     allowCraftingNearby = { enabled = true, distance = 10.0 },
            --     allowCraftingAnywhere = { enabled = true, notifyPlayer = true },
            --     sharedCrafting = { placed = true, static = false },
            -- },
        },
    },

    -- Crafting stations configuration
    -- 'recipes' specifies which recipe TABLES to use (from configs/recipes.lua)
    -- 'techTrees' specifies which tech trees to use (from configs/techtrees.lua)
    --
    -- Job/Gang Locking (optional):
    --   job = { name = 'mechanic', minGrade = 0 }  -- Lock to specific job (minGrade is optional, defaults to 0)
    --   gang = 'ballas'                             -- Lock to specific gang (QBCore only)
    --
    -- CraftingBehavior (optional):
    --   Override the global CraftingBehavior settings for this specific station.
    --   Only include the settings you want to override - missing settings use global defaults.
    --   Example: CraftingBehavior = { preventCloseWhileCrafting = false, allowCraftingAnywhere = { enabled = true } }
    Stations = {
        ['workbench'] = {
            label = 'Workbench',
            type = 'basic', -- Workbench type for per-workbench leveling (basic, advanced, etc.)
            coords = vector3(-1.89, -200.97, 52.74),
            heading = 340.7, -- Heading for the prop
            radius = 2.0,
            recipes = { 'all', 'basic' }, -- Recipe tables to use from configs/recipes.lua
            techTrees = { 'basic_survival', 'basic_exploration' }, -- Tech trees from techtrees.lua
            -- job = { name = 'mechanic', minGrade = 0 }, -- Optional: Lock to mechanic job
            -- gang = 'ballas', -- Optional: Lock to gang (QBCore only)
            -- CraftingBehavior = { -- Optional: Override global CraftingBehavior for this station (only include what you want to change, if something isn't, then it defaults to main .CraftingBehavior)
            --     preventCloseWhileCrafting = false,
            --     cancelCraftOnClose = false,
            --     allowCraftingNearby = { enabled = true, distance = 10.0 },
            --     allowCraftingAnywhere = { enabled = true, notifyPlayer = true },
            --     sharedCrafting = { placed = true, static = false },
            -- },
            prop = {
                enabled = true,
                model = 'prop_tool_bench02',
                spawnRadius = 50.0, -- Distance at which prop spawns
                offset = vector3(0.0, 0.0, -1.0), -- Offset from coords (adjust Z for ground level)
            },
            blip = {
                enabled = true,
                sprite = 566,
                color = 2,
                scale = 0.7,
                label = 'Workbench'
            }
        },
    },

}
