Config = {}

-- ─── UI SETTINGS ─────────────────────────────────────────────────────────────
-- Controls which UI library is used and default positioning
Config.UI = {
    useLationUI = true,        -- Set to false to fallback to ox_lib/natives
    textPosition = 'left-center',
    notifyPosition = 'top',
    notifyDuration = 3000,
    progressPosition = 'bottom',
}

-- ─── KEYBINDS ─────────────────────────────────────────────────────────────────
-- TODO: These need to be registered as bindable keybinds in GTA settings
-- so players can remap them from the pause menu
Config.Keys = {
    exit      = 'BACKSPACE',
    interact  = 'MOUSE1',
    secondary = 'MOUSE2',
    confirm   = 'RETURN',
}

-- ─── CONTROL IDs ──────────────────────────────────────────────────────────────
-- Raw GTA control IDs used with DisableControlAction
Config.Controls = {
    exit      = 177,   -- BACKSPACE
    interact  = 24,    -- MOUSE1
    secondary = 25,    -- MOUSE2
    confirm   = 191,   -- RETURN
    look      = 1,     -- Mouse X
    lookY     = 2,     -- Mouse Y
    scroll    = 14,    -- Scroll wheel
}

-- ─── CAMERA ───────────────────────────────────────────────────────────────────
-- TODO: These are fallback defaults only
-- Camera position, rotation and FOV should be configured per minigame via the creator
Config.Camera = {
    defaultFov       = 50.0,
    transitionTime   = 500,    -- ms
    allowLook        = true,
    lookSensitivity  = 2.0,
}

-- ─── MINIGAME TYPES ───────────────────────────────────────────────────────────
-- TODO: Do not expand this section yet -- focus on the creator first
-- Return to add/refine types once the creator is functional
Config.MinigameTypes = {
    ['place'] = {
        description          = 'Click to place props at location',
        requiresPlacementArea = true,
    },
    ['bag'] = {
        description     = 'Click to pick up items, click bag zone to place them',
        requiresTargets = true,
        requiresZones   = true,
    },
}

-- ─── PROP LISTS ───────────────────────────────────────────────────────────────
-- These are selectable lists used by the creator when choosing props
-- TODO: Prop names are placeholders -- verify and replace with correct native 
-- GTA prop names using https://gtahash.ru before using in production
Config.Props = {
    item_props = {    -- Items to be picked up and bagged
        'prop_cs_burger_01',
        'prop_cs_burger_02',
        'prop_cs_burger_03',
    },
    table_props = {   -- Surface that items sit on
        'prop_table_03',
        'prop_table_04',
        'prop_table_05',
    },
    bag_props = {     -- Bag that receives the items
        'prop_paper_bag_small',
        'prop_paper_bag_medium',
        'prop_paper_bag_large',
    },
}