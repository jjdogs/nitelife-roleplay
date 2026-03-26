--[[
    Saved Minigame Configurations
    Add your minigames here or use the in-game creator
]]

-- This file is loaded by main.lua to register saved minigames
-- Use: exports['nt_3dminigames']:StartMinigame('minigame_name')

return {
    -- Example: Watering Plants
    ['water_plants'] = {
        type = 'pour',
        name = 'Water Plants',
        description = 'Water all the plants to help them grow',
        holdProp = 'prop_wateringcan',
        holdPropOffset = vector3(0, 0, 0.1),
        particle = { dict = 'core', name = 'ent_sht_water', scale = 0.5 },
        pourRate = 2.0,
        winCondition = { coverage = 100 },
        instructions = {
            { key = 'LMB', text = 'Pour Water' },
            { key = 'RMB', text = 'Look Around' },
            { key = 'BACKSPACE', text = 'Exit' },
        },
        -- Camera and zones are set relative to activation point
        cameraOffset = vector3(0, 2, 2),
        cameraRot = vector3(-30, 0, 180),
        zonePattern = {
            { offset = vector3(-0.5, 1, 0), size = vector3(0.3, 0.3, 0.1), maxProgress = 50 },
            { offset = vector3(0, 1, 0), size = vector3(0.3, 0.3, 0.1), maxProgress = 50 },
            { offset = vector3(0.5, 1, 0), size = vector3(0.3, 0.3, 0.1), maxProgress = 50 },
        },
    },
    
    -- Example: Fertilize Plants
    ['fertilize_plants'] = {
        type = 'click',
        name = 'Fertilize Plants',
        description = 'Click on each plant to fertilize',
        targetModel = 'prop_cs_fertilizer',
        clickEffect = { dict = 'core', name = 'ent_dst_gen_gobject' },
        instructions = {
            { key = 'LMB', text = 'Click Target' },
            { key = 'RMB', text = 'Look Around' },
            { key = 'BACKSPACE', text = 'Exit' },
        },
        cameraOffset = vector3(0, 2, 2),
        cameraRot = vector3(-30, 0, 180),
        targetPattern = {
            { offset = vector3(-0.5, 1, 0) },
            { offset = vector3(0, 1, 0) },
            { offset = vector3(0.5, 1, 0) },
        },
    },
    
    -- Example: Harvest Buds
    ['harvest_buds'] = {
        type = 'collect',
        name = 'Harvest Buds',
        description = 'Hold click on each bud to harvest',
        targetModel = 'prop_weed_01',
        holdTime = 800,
        collectEffect = { dict = 'scr_xs_celebration', name = 'scr_xs_confetti_burst' },
        instructions = {
            { key = 'Hold LMB', text = 'Harvest' },
            { key = 'RMB', text = 'Look Around' },
            { key = 'BACKSPACE', text = 'Exit' },
        },
        cameraOffset = vector3(0, 2, 2),
        cameraRot = vector3(-30, 0, 180),
        targetPattern = {
            { offset = vector3(-0.3, 0.8, 0.2) },
            { offset = vector3(0.1, 1.0, 0.3) },
            { offset = vector3(0.4, 0.9, 0.2) },
            { offset = vector3(-0.2, 1.2, 0.25) },
            { offset = vector3(0.3, 1.1, 0.35) },
        },
    },
    
    -- Example: Sprinkle Cheese
    ['sprinkle_cheese'] = {
        type = 'pour',
        name = 'Sprinkle Cheese',
        description = 'Cover the pizza with cheese',
        holdProp = 'prop_food_bag1',
        holdPropOffset = vector3(0, 0, 0.15),
        particle = { dict = 'core', name = 'ent_dst_rocks', scale = 0.3 },
        pourRate = 3.0,
        fixedHeight = 1.0,  -- Table height
        winCondition = { coverage = 80 },
        instructions = {
            { key = 'LMB', text = 'Sprinkle Cheese' },
            { key = 'BACKSPACE', text = 'Exit' },
        },
        cameraOffset = vector3(0, 0.5, 1.5),
        cameraRot = vector3(-60, 0, 180),
        zonePattern = {
            -- Pizza is a single circular zone
            { offset = vector3(0, 0.5, 0), radius = 0.25, type = 'sphere', maxProgress = 100 },
        },
    },
    
    -- Example: Place Pepperoni
    ['place_pepperoni'] = {
        type = 'place',
        name = 'Place Pepperoni',
        description = 'Place pepperoni slices on the pizza',
        holdProp = 'prop_cs_sausage_01',
        placementModel = 'prop_cs_sausage_01',
        placementOffset = vector3(0, 0, 0.01),
        requiredPlacements = 8,
        requireZone = true,
        fixedHeight = 1.0,
        instructions = {
            { key = 'LMB', text = 'Place Pepperoni' },
            { key = 'Scroll', text = 'Rotate' },
            { key = 'BACKSPACE', text = 'Exit' },
        },
        cameraOffset = vector3(0, 0.5, 1.5),
        cameraRot = vector3(-60, 0, 180),
        zonePattern = {
            { offset = vector3(0, 0.5, 0), radius = 0.25, type = 'sphere' },
        },
    },
}
