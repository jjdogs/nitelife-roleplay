Config = {}

-- UI Settings
Config.UI = {
    useLationUI = true,  -- Set to false to fallback to ox_lib/natives
    
    -- Text UI defaults
    textPosition = 'left-center',
    
    -- Notification defaults
    notifyPosition = 'top',
    notifyDuration = 3000,
    
    -- Progress bar defaults
    progressPosition = 'bottom',
}

-- Keybinds
Config.Keys = {
    exit = 'BACKSPACE',           -- Exit minigame
    interact = 'MOUSE1',          -- Primary action (pour, click, place)
    secondary = 'MOUSE2',         -- Secondary action (rotate camera, cancel)
    confirm = 'RETURN',           -- Confirm action
}

-- Control IDs (for DisableControlAction)
Config.Controls = {
    exit = 177,        -- BACKSPACE
    interact = 24,     -- MOUSE1 (Attack)
    secondary = 25,    -- MOUSE2 (Aim)
    confirm = 191,     -- RETURN
    look = 1,          -- Mouse look X
    lookY = 2,         -- Mouse look Y
    scroll = 14,       -- Scroll wheel
}

-- Camera defaults
Config.Camera = {
    defaultFov = 50.0,
    transitionTime = 500,  -- ms to transition into minigame camera
    allowLook = true,      -- Allow looking around with right-click
    lookSensitivity = 2.0,
}

-- Minigame types
Config.MinigameTypes = {
    ['pour'] = {
        description = 'Move prop to pour/sprinkle onto targets',
        defaultParticle = { dict = 'core', name = 'ent_sht_water' },
        requiresZones = true,
    },
    ['click'] = {
        description = 'Click on targets to interact',
        requiresTargets = true,
    },
    ['collect'] = {
        description = 'Click and hold to collect items',
        requiresTargets = true,
        holdTime = 500,  -- ms to hold for collection
    },
    ['place'] = {
        description = 'Click to place props at location',
        requiresPlacementArea = true,
    },
}

-- Default props (can be overridden per minigame)
Config.DefaultProps = {
    watering_can = 'prop_wateringcan',
    fertilizer = 'prop_cs_fertilizer',
    cheese_bag = 'prop_food_bag1',
    pepperoni = 'prop_cs_sausage_01',
}

-- Particle dictionaries to preload
Config.ParticleDicts = {
    'core',
    'scr_apartment_mp',
    'scr_xs_celebration',
}

-- Creator settings
Config.Creator = {
    enabled = true,
    command = 'minigamecreator',
    freecamSpeed = 0.5,
    markerColor = { r = 0, g = 255, b = 0, a = 150 },
}

-- Saved minigames file
Config.SaveFile = 'data/saved_minigames.lua'
