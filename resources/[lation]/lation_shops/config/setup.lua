return {

    -- Use only if needed, directed by support or know what you're doing
    -- Notice: enabling debug features will significantly increase resmon
    -- And should always be disabled in production
    debug = false,

    -- Set your interaction system below
    -- Available options are: 'auto', 'ox_target', 'qb-target', 'interact' & 'custom'
    -- 'auto' will automatically detect and use the available interaction system
    -- 'custom' needs to be added to client/utils/interact.lua
    interact = 'auto',

    -- Set your notification system below
    -- Available options are: 'lation_ui', 'ox_lib', 'esx', 'qb', 'okok', 'sd-notify', 'wasabi_notify' & 'custom'
    -- 'custom' needs to be added to client/utils/notify.lua
    notify = 'lation_ui',

    -- Do you want to be notified via server console if an update is available?
    -- True if yes, false if no
    version = true,

    -- Set your society banking system below
    -- Available options are: 'auto', 'qb-banking', 'qb-management', 'esx_addonaccount', 'Renewed-Banking',
    -- 'okokBanking', 'fd_banking', 'tgg-banking' or 'custom'
    -- 'auto' will automatically detect based on your framework and available banking resources
    -- 'custom' needs to be added to server/utils/banking.lua
    banking = 'auto',
}