-- =========================================
-- Role-Based Admin Permissions
-- =========================================

-- Roles you support (order matters for “at least” comparisons)
Config.Roles = {
    god       = { label = "God",       level = 4 },
    admin     = { label = "Admin",     level = 3 },
    moderator = { label = "Moderator", level = 2 },
    trialmod  = { label = "Trial Mod", level = 1 },
}

-- Action permissions by role.
-- Use the same action IDs your UI sends and server handles (warn_player, ban_player, etc.)
Config.RolePermissions = {
    -- God: everything 
    god = { 
        ["*"] = true, -- SYMBOL FOR EVERYTHING
    },

    -- Admin: everything except role management (you can still allow it if you want)
    admin = {
        -- =====================
        -- Role management
        -- =====================
        set_perms = true,

        -- =====================
        -- Dashboard / Global
        -- =====================
        open_dashboard = true,
        send_announce = true,
        view_server_stats = true,

        -- =====================
        -- Resource management
        -- =====================
        view_resources = true,
        start_resource = true,
        stop_resource = true,
        restart_resource = true,

        -- =====================
        -- Bans / Logs
        -- =================
        view_player_logs = true,
        -- =====================
        -- Quick actions
        -- =====================
        revive_self = true,
        fix_vehicle = true,
        teleport_marker = true,
        godmode = true,

        -- =====================
        -- Developer
        -- =====================
        dev_noclip = true,
        dev_laser = true,
        dev_copy_vec4 = true,
        dev_copy_vec3 = true,
        dev_copy_vec2 = true,
        dev_copy_heading = true,
        dev_copy_hash = true,
        dev_toggle_coords = true,
        dev_super_jump = true,
        dev_night_vision = true,
        dev_thermal_vision = true,

        -- =====================
        -- Inventory / Stash
        -- =====================
        open_inventory = true,
        view_inventory = true,
        clear_inventory = true,
        clear_inventory_offline = true,
        open_stash = true,
        view_stash = true,

        -- =====================
        -- Vehicle
        -- =====================
        spawn_vehicle = true,
        admin_car = true,
        give_car = true,
        delete_vehicle = true,
        fix_vehicle_player = true,
        refuel_vehicle = true,
        max_vehicle_mods = true,
        open_trunk = true,
        set_vehicle_garage_state = true,
        change_plate = true,
        get_vehicle_keys = true,
        view_player_vehicles = true,
        upgrade_vehicle = true,
        open_glovebox = true,

        -- =====================
        -- Player
        -- =====================
        revive_player = true,
        kill_player = true,
        give_clothing_menu = true,
        teleport_to_player = true,
        bring_player = true,
        kick_player = true,
        ban_player = true,
        ban_offline = true,
        warn_player = true,
        spectate_player = true,
        screenshot_player = true,
        send_message = true,
        remove_stress = true,
        toggle_cuffs = true,
        toggle_duty = true,
        set_job = true,
        set_gang = true,
        set_ped = true,
        get_routing_bucket = true,
        set_routing_bucket = true,
        force_logout = true,

        -- =====================
        -- Money / Items
        -- =====================
        give_money = true,
        give_money_all = true,
        remove_money = true,
        give_item = true,
        give_item_all = true,

        -- =====================
        -- World / Utility
        -- =====================
        clear_area = true,
        toggle_names = true,
        revive_radius = true,
        revive_all = true,
        change_time = true,
        change_weather = true,
        toggle_blackout = true,
        toggle_blips = true,
        play_sound = true,
        freeze_time = true,

        -- =====================
        -- Teleport
        -- =====================
        teleport_back = true,
        teleport_coords = true,
        teleport_location = true,

        -- =====================
        -- Combat
        -- =====================
        infinite_ammo = true,
        invisible = true,
        set_ammo = true,

        -- =====================
        -- Troll
        -- =====================
        freeze_player = true,
        make_player_drunk = true,
        monkey_swarm = true,
        set_player_on_fire = true,
        ragdoll_player = true,
        set_jailbox = true,
        drop_from_sky = true,
        force_slash_me = true,

        -- =====================
        -- Player details UI
        -- =====================
        copy_coords = true,
    },


    -- Moderator: most staff actions, no bans, no money/items, no dev tools
    moderator = {

        -- =====================
        -- Player moderation
        -- =====================
        warn_player = true,
        kick_player = true,

        -- =====================
        -- Player control
        -- =====================
        freeze_player = true,
        bring_player = true,

        -- =====================
        -- Health
        -- =====================
        revive_player = true,
        revive_radius = true,

        -- =====================
        -- Teleport / utility
        -- =====================
        spectate_player = true,      -- client-side
        screenshot_player = true,
        teleport_to_player = true,   -- client-side
        teleport_marker = true,      -- client-side
        teleport_back = true,        -- client-side

        -- =====================
        dev_noclip = true,
        delete_vehicle = true,
        set_vehicle_garage_state = true,
        get_vehicle_keys = true,
        send_message = true,
        give_clothing_menu = true,
        clear_inventory = true,
        clear_inventory_offline = true,
        remove_stress = true,
        set_job = true,
        set_gang = true,
        open_glovebox = true,
        open_trunk = true,
        clear_area = true,
        toggle_names = true,
        revive_all = true,
        teleport_coords = true,
        teleport_location = true,
        invisible = true,
        set_jailbox = true,
        drop_from_sky = true,
        force_slash_me = true,
        ragdoll_player = true,
    },

    -- Trial Mod: very basic permissions
    trialmod = {

        -- =====================
        -- Player moderation
        -- =====================
        warn_player = true,

    },

}
