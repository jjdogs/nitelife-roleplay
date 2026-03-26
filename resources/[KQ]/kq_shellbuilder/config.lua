Config = {}

-- Enabling this will add additional prints and debug systems
Config.debug = false

--
Config.locale = 'en'

Config.sql = {
    driver = 'oxmysql', -- oxmysql or ghmattimysql or mysql
    -- If you're using an older version of oxmysql set this to false
    newOxMysql = true,
}

-- Whether to allow holding mouse down to quick edit
-- Allows to quickly paint/texture large areas. Players will be required to click on each tile when disabled
Config.allowMouseHoldToEdit = true

-- The command used to open the shell creator menu
Config.command = 'shellcreator'

Config.thumbnails = {
    -- Whether to save thumbnails for the shells (Requires screenshot-basic. A CFX resource)
    -- https://github.com/citizenfx/screenshot-basic
    enabled = true,
}

-- Prop limit per shell. (100 - 1500)
Config.propLimit = 1000

-- Whether to freeze vehicles inside shells upon the shells de-spawning (to prevent them from falling down)
-- (You may want to disable this option when using advanced-parking)
Config.freezeVehiclesOnDespawn = true

-- Whether to disable weather sync systems when entering the shells
Config.disableWeatherSyncWhenIndoors = true

-- Type, Scale, Color and alpha of the teleport markers
-- https://docs.fivem.net/docs/game-references/markers/
Config.markers = {
    type = 1, -- The scale of the marker
    scale = 1.0, -- The size of the marker
    r = 0,
    g = 255,
    b = 100,
    a = 100,
}

Config.permissions = {
    -- Whether users are able to see (and possibly edit) shells made by others (In the menu)
    showShellsOfOtherUsers = true
}

-- Whether to fully disable the custom textures system
Config.disableCustomTextures = false

-- Whether to use latent server events for saving of shells
Config.useLatentEvents = false

-- Full UI customization via RGB color values
Config.uiStyling = {
    ['color-background'] = '29, 29, 51',
    ['color-background-light'] = '41, 41, 66',

    ['color-primary-dark'] = '58, 11, 204',
    ['color-primary'] = '106, 60, 255',
    ['color-primary-light'] = '139, 103, 255',
    ['color-primary-lighter'] = '180, 156, 255',

    ['color-secondary'] = '23, 23, 23',
    ['color-secondary-light'] = '81, 81, 81',

    ['color-white'] = '255, 255, 255',
    ['color-black'] = '5, 5, 5',
}
