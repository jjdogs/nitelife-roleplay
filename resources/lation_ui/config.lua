Config = {}

-- Do you want to be notified via server console if an update is available?
-- True if yes, false if no
Config.version = true

Config.notify = {
    -- Play a sound when any notification is shown
    -- This plays a sound for all notifications
    -- This setting is only for enabling sound globally
    -- If false, you can still play a sound for individual notifications
    play_sound = false,

    -- Default sounds for notification types
    -- These can be overridden by passing a "sound" object in the notify data
    -- See docs for more info: https://docs.lationscripts.com/modern-ui/components/notification
    default_sound = {
        info = { bank = '', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET', name = 'SELECT' },
        warning = { bank = '', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET', name = 'SELECT' },
        error = { bank = '', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET', name = 'SELECT' },
        success = { bank = '', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET', name = 'SELECT' },
    }
}

Config.radial = {
    -- Default keybind for opening the radial menu
    -- This can be any valid key (see https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)
    default_key = 'z'
}