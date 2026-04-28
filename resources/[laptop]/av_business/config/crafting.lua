Config = Config or {}
-- Default Crafting Options
Config.NeedsAllItems = false -- true: requires all ingredients; false: requires at least one
Config.CraftingLabel = Lang['crafting'] -- Default label for progressbar
Config.CraftingTime = 5000 -- Default 5 seconds
Config.CraftingDict = "anim@amb@business@coc@coc_unpack_cut@" -- Default Animation dictionary
Config.CraftAnimation = "fullcut_cycle_v6_cokecutter" -- Default Animation

Config.MaxItemsPerCraft = { -- Max items player can craft at the same time
    -- boxes need a serial number, if u craft more than 1 at the same time the serial will be duplicated, to prevent it we need to craft 1 box at the time
    ['box'] = 1,
}