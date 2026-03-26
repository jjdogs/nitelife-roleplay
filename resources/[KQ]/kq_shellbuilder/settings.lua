Settings = {}


Settings.timecycles = {
    ['none'] = {
        name = 'None',
        timecycle = nil,
    },
    ['warm'] = {
        name = 'Warm',
        timecycle = 'MP_lowgarage',
    },
    ['apartment'] = {
        name = 'Apartment #1',
        timecycle = 'franklinsAUNTS_new',
    },
    ['apartment2'] = {
        name = 'Apartment #2',
        timecycle = 'NewMichael',
    },
    ['garage'] = {
        name = 'Garage #1',
        timecycle = 'DLC_Casino_Garage',
    },
    ['garage2'] = {
        name = 'Garage #2',
        timecycle = 'garage',
    },
    ['vagos'] = {
        name = 'Vagos',
        timecycle = 'Vagos',
    },
    ['cops'] = {
        name = 'Cold',
        timecycle = 'cops',
    },
    ['bikers'] = {
        name = 'Bikers',
        timecycle = 'Bikers',
    },
    ['vignette'] = {
        name = 'Vignette',
        timecycle = 'Hint_cam',
    },
    ['strip'] = {
        name = 'Strip club',
        timecycle = 'V_strip_nofog',
    },
    ['bright'] = {
        name = 'Bright #1',
        timecycle = 'winning_room',
    },
    ['bright2'] = {
        name = 'Bright #2',
        timecycle = 'casino_brightroom',
    },
    ['mall'] = {
        name = 'Mall',
        timecycle = 'INT_mall',
    },
    ['desat'] = {
        name = 'Destaurated',
        timecycle = 'hud_def_desat_switch',
    },
    ['dark'] = {
        name = 'Dark',
        timecycle = 'phone_cam6',
    },
    ['superdark'] = {
        name = 'Super Dark',
        timecycle = 'MadrazoBackyard',
    },
}

Settings.walls = {
    ['0'] = {
        name = 'Brick wall',
        model = 1,
    },
    ['1'] = {
        name = 'Smooth wall',
        model = 2,
    },
    ['2'] = {
        name = 'Breeze wall',
        model = 3,
    },
    ['3'] = {
        name = 'Wooden wall #1',
        model = 4,
    },
    ['4'] = {
        name = 'Wooden wall #2',
        model = 7,
    },
    ['5'] = {
        name = 'Tiled wall',
        model = 5,
    },
    ['6'] = {
        name = 'Scuffed Tiled wall',
        model = 6,
    },
    ['7'] = {
        name = 'Concrete wall',
        model = 8,
    },
    ['8'] = {
        name = 'Leather wall',
        model = 9,
    },
    ['9'] = {
        name = 'Honeycomb Tiles wall',
        model = 10,
    },
    ['10'] = {
        name = 'Wallpaper wall #1',
        model = 11,
    },
    ['11'] = {
        name = 'Wallpaper wall #2',
        model = 12,
    },
    ['12'] = {
        name = 'Wallpaper wall #3',
        model = 13,
    },
    ['14'] = {
        name = 'Glass wall',
        model = 14,
    },
    ['15'] = {
        name = 'Wooden wall #3',
        model = 15,
    },
    ['16'] = {
        name = 'Metal wall',
        model = 16,
    },
}

Settings.floors = {
    ['none'] = {
        name = 'None',
        model = 1,
    },
    ['0'] = {
        name = 'Concrete floor #1',
        model = 1,
    },
    ['10'] = {
        name = 'Concrete floor #2',
        model = 11,
    },
    ['1'] = {
        name = 'Wooden floor #1',
        model = 2,
    },
    ['2'] = {
        name = 'Wooden floor #2',
        model = 3,
    },
    ['3'] = {
        name = 'Wooden floor #3',
        model = 4,
    },
    ['4'] = {
        name = 'Wooden floor #4',
        model = 5,
    },
    ['5'] = {
        name = 'Carpet floor #1',
        model = 6,
        offset = vec3(0, 0, 0.01)
    },
    ['14'] = {
        name = 'Carpet floor #2',
        model = 15,
        offset = vec3(0, 0, 0.01)
    },
    ['6'] = {
        name = 'Tiled floor #1',
        model = 7,
    },
    ['7'] = {
        name = 'Tiled floor #2',
        model = 8,
    },
    ['9'] = {
        name = 'Tiled floor #3',
        model = 10,
    },
    ['16'] = {
        name = 'Tiled floor #4',
        model = 17,
    },
    ['8'] = {
        name = 'Vinyl floor',
        model = 9,
    },
    ['11'] = {
        name = 'Concrete panels floor',
        model = 12,
    },
    ['12'] = {
        name = 'Honeycomb tiles floor',
        model = 13,
    },
    ['13'] = {
        name = 'Shiny smooth floor',
        model = 14,
    },
    ['15'] = {
        name = 'Metal floor',
        model = 16,
        offset = vec3(0, 0, 0.007)
    },
    ['17'] = {
        name = 'Automotive floor',
        model = 18,
        offset = vec3(0, 0, 0.007)
    },
    ['19'] = {
        name = 'Industrial floor',
        model = 19,
    },
    ['20'] = {
        name = 'Wooden floor #5',
        model = 20,
    },
    ['21'] = {
        name = 'Tiled floor #5',
        model = 21,
    },
    ['22'] = {
        name = 'Glass floor',
        model = 22,
    },
}

Settings.ceilings = {
    ['0'] = {
        name = 'Smooth ceiling',
        model = 'kq_sb_ceil',
    },
    ['1'] = {
        name = 'Panel ceiling #1',
        model = 'kq_sb_ceil_2',
    },
    ['1b'] = {
        name = 'Panel ceiling #1 (Broken A)',
        model = 'kq_sb_ceil_3',
    },
    ['1c'] = {
        name = 'Panel ceiling #1 (Broken B)',
        model = 'kq_sb_ceil_3',
        offset = {
            pos = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90)
        }
    },
    ['2'] = {
        name = 'Wooden beams ceiling',
        model = 'kq_sb_ceil_4',
    },
    ['3'] = {
        name = 'Steel beams ceiling #1',
        model = 'kq_sb_ceil_5',
    },
    ['5'] = {
        name = 'Panel ceiling #2',
        model = 'kq_sb_ceil_6',
    },
    ['6'] = {
        name = 'Steel beams ceiling #2',
        model = 'kq_sb_ceil_7',
    },
    ['f1'] = {
        name = 'Concrete ceiling',
        model = 'kq_sb_tile_11',
        offset = {
            pos = vec3(0, 0, 2.997),
            rotation = vec3(180, 0, 0)
        }
    },
    ['f2'] = {
        name = 'Wooden ceiling',
        model = 'kq_sb_tile_4',
        offset = {
            pos = vec3(0, 0, 2.997),
            rotation = vec3(180, 0, 0)
        }
    },
    ['f3'] = {
        name = 'Concrete panel ceiling',
        model = 'kq_sb_tile_12',
        offset = {
            pos = vec3(0, 0, 2.997),
            rotation = vec3(180, 0, 0)
        }
    },
    ['f4'] = {
        name = 'Glass ceiling',
        model = 'kq_sb_tile_22',
        offset = {
            pos = vec3(0, 0, 2.997),
            rotation = vec3(180, 0, 0)
        }
    },
}

Settings.doorframes = {
    ['0'] = {
        name = 'Wooden Doorframe',
        model = 1,
        icon = 'wall_2',
    },
}

Settings.stairs = {
    ['0'] = {
        name = 'Wooden stairs #1',
        model = 'kq_sb_stairs_1',
    },
    ['1'] = {
        name = 'Wooden stairs #2',
        model = 'kq_sb_stairs_2',
    },
    ['2'] = {
        name = 'Wooden stairs #3',
        model = 'kq_sb_stairs_3',
    },
}


Settings.windows = {
    ['0'] = {
        name = 'Window #1',
        model = 'kq_sb_window_1',
        icon = 'kq_sb_window_1',
    },
    ['0b'] = {
        name = 'Window #1 (See-through)',
        model = 'kq_sb_window_1b',
        icon = 'kq_sb_window_1',
    },
    ['1'] = {
        name = 'Window #2',
        model = 'kq_sb_window_2',
        icon = 'kq_sb_window_2',
    },
    ['1b'] = {
        name = 'Window #2 (See-through)',
        model = 'kq_sb_window_2b',
        icon = 'kq_sb_window_2',
    },
    ['2'] = {
        name = 'Window #3',
        model = 'kq_sb_window_3',
        icon = 'kq_sb_window_3',
    },
    ['2b'] = {
        name = 'Window #3 (See-through)',
        model = 'kq_sb_window_3b',
        icon = 'kq_sb_window_3',
    },
    ['3'] = {
        name = 'Window #4',
        model = 'kq_sb_window_4',
        icon = 'kq_sb_window_4',
    },
    ['3b'] = {
        name = 'Window #4 (See-through)',
        model = 'kq_sb_window_4b',
        icon = 'kq_sb_window_4',
    },
    ['4'] = {
        name = 'Window #5',
        model = 'kq_sb_window_5',
        icon = 'kq_sb_window_5',
    },
    ['4b'] = {
        name = 'Window #5 (See-through)',
        model = 'kq_sb_window_5b',
        icon = 'kq_sb_window_5',
    },
}


Settings.exporters = {
    ['vec3'] = {
        name = '- Coords (vector3)',
        data = 'vec3({full_x}, {full_y}, {full_z})',
    },
    ['vec4'] = {
        name = '- Coords (vector4)',
        data = 'vec4({full_x}, {full_y}, {full_z}, {heading})',
    },
    ['table'] = {
        name = '- Coords (table)',
        data = '{x = {full_x}, y = {full_y}, z = {full_z}, heading = {heading}}',
    },
    ['esx_property_ipl'] = {
        name = 'esx_property (IPL)',
        data = [[
{
  label = "{name}",
  value = "kq_sbx_shell_{id}",
  positions = {
    Wardrobe = vec3({full_x}, {full_y}, {full_z}), -- Change these manually
    Storage = vec3({full_x}, {full_y}, {full_z}), -- Change these manually
  },
  type = "ipl",
  pos = vector3({full_x}, {full_y}, {full_z})
},
    ]],
    },
    ['esx_property_shell'] = {
        name = 'esx_property (Shell)',
        flipped = true,
        data = [[
{
  label = "{name}",
  value = "kq_sbx_shell_{id}",
  positions = {
    Wardrobe = vec3({x}, {y}, {z}), -- Change these manually
    Storage = vec3({x}, {y}, {z}), -- Change these manually
  },
  type = "shell",
  pos = vector3({x}, {y}, {z})
},
    ]],
    },
    ['ps_housing'] = {
        name = 'ps-housing (Shell)',
        data = [[
["{name}"] = {
    label = "{name}",
    hash = `kq_sbx_shell_{id}`,
    doorOffset = { x = {x}, y = {y}, z = {z}, h = {heading}, width = 1.5 },
    stash = {
        maxweight = 100000,
        slots = 12,
    },
    imgs = {},
},
    ]],
    },
    ['qs_housing_ipl'] = {
        name = 'qs-housing 4.0 (IPL)',
        data = [[
	{
		-- {name}
		exitCoords = vec3({full_x}, {full_y}, {full_z}),
		iplCoords = vec3({full_x}, {full_y}, {full_z}),
		stash = {
			maxweight = 1000000,
			slots = 10,
		},
	},
    ]],
    },
    ['qs_housing_shell'] = {
        name = 'qs-housing 4.0 (Shell)',
        data = [[
["{id}"] = { -- Replace with correct index
    model = `kq_sbx_shell_{id}`,
    stash = {
        maxweight = 100000,
        slots = 12,
    },
    imgs = {}
},
    ]],
    },
    ['rx_housing'] = {
        name = 'RxHousing (Shell)',
        data = [[
["kq_sbx_shell_{id}"] = {
    offsets = {
        door = vector3({x}, {y}, {z}),
        doorHeading = {heading},
        laptop = vector3({x}, {y}, {z}), -- You must change this
        laptopHeading = {heading}, -- You must change this
        stash = vector3({x}, {y}, {z}), -- You must change this
        clothing = vector3({x}, {y}, {z}), -- You must change this
    },
},
    ]],
    },
    ['origen_housing_ipl'] = {
        name = 'origen_housing (IPL)',
        data = [[
{
    model = '{name}',
    cam = vector4({full_x}, {full_y}, {full_z}, {heading}),
    enter = vector4({full_x}, {full_y}, {full_z}, {heading}),
    label = '{name}',
},
    ]],
    },
    ['origen_housing_shell'] = {
        name = 'origen_housing (Shell)',
        data = [[
{
    model = 'kq_sbx_shell_{id}',
    label = '{name}',
    offset = vector3({x}, {y}, {z})
},
    ]],
    },
    ['nolag_properties'] = {
        name = 'nolag_properties (Shell)',
        data = [[
["{name}"] = {
    label = "{name}",
    hash = `kq_sbx_shell_{id}`,
    doorOffset = { x = {x}, y = {y}, z = {z}, h = {heading}, width = 2.0 },
    stash = {
        maxweight = 80000000,
        slots = 120,
    },
    imgs = {}
},
    ]],
    },
    ['loaf_housing_shell'] = {
        name = 'loaf-housing (Shell)',
        data = [[
["{name}"] = {
    object = `kq_sbx_shell_{id}`,
    category = "highend_house", -- Change to fit
    doorOffset = vector3({z}, {y}, {z}),
    doorHeading = {heading},
},
    ]],
    },
    ['loaf_housing_ipl'] = {
        name = 'loaf-housing (IPL)',
        data = [[
["{name}"] = {
    label = "{name}",
    coords = vector3({full_x}, {full_y}, {full_z}),
    ipl = "kq_sbx_shell_{id}",
    disableFurnishing = false,
    lockpick = 1,
    locations = {
        -- Set the storage locations to fit
        ["location_1"] = {
            coords = vector3({full_x}, {full_y}, {full_z}),
            scale = vector3(2.0, 2.0, 0.5),
            storage = true,
            wardrobe = false,
            weight = 50000,
        },
    },
},
    ]],
    },
    ['bcs_housing_ipl'] = {
        name = 'bcs-housing (IPL)',
        data = [[
{
    label = "{name}",
    name = "kq_sbx_shell_{id}",
    entry = vec4({full_x}, {full_y}, {full_z}, {heading}),
},
    ]],
    },
    ['bcs_housing_shell'] = {
        name = 'bcs-housing (Shell)',
        data = [[
["kq_sbx_shell_{id}"] = vec4({x}, {y}, {z}, {heading}),
    ]],
    },
    ['ak47_shell'] = {
        name = 'ak47_housing (Shell)',
        data = [[
["kq_sbx_shell_{id}"] = {
    name = "{name}",
    price = {minimum = 1000, maximum = 5000}, -- Change these,
    weight = {minimum = 100, maximum = 5000}, -- Change these,
},
    ]],
    },
    ['vms_housing_shell'] = {
        name = 'vms_housing (Shell)',
        data = [[
['kq_sbx_shell_{id}'] = {
    label = '{name}',

    tags = {'empty', 'kuzquality'},
    rooms = 1, -- Change this

    model = 'kq_sbx_shell_{id}',

    doors = {
        x = {x},
        y = {y},
        z = {z},
        heading = {heading},
    },

    images = {},
},
    ]],
    },
    ['kq_weed_growop'] = {
        name = 'kq_weed (Grow Op)',
        data = [[
    ['kq_sbx_shell_{id}'] = {
        interior = {
            model = 'kq_sbx_shell_{id}',
            offset = vec3({x}, {y}, {z}),
            rotation = vec3(0, 0, {heading})
        },

        shellZOffset = 600.0,

        locations = {
            {
                coords = vec3(2515.96, 4220.33, 38.93), -- CHANGE ME
                rotation = vec3(0, 0, 57), -- CHANGE ME
                color = 0,
            },
            -- ADD MORE LOCATIONS HERE AS NEEDED
        },

       -- use `/kq_weed:tableOffset` while inside the grow op to easily retrieve the offset coordinates
        tables = {
            {
                coords = vec3(0, 7, -5.25), -- CHANGE ME
                rotation = vec3(0, 0, 0),
            },
            -- ADD MORE TABLES HERE AS NEEDED
        },
       -- use `/kq_weed:pressOffset` while inside the grow op to easily retrieve the offset coordinates
        presses = {
            {
                coords = vec3(0, 9, -5.25), -- CHANGE ME
                rotation = vec3(0, 0, 0),
            },
            -- ADD MORE PRESSES HERE AS NEEDED
        },
        -- use `/kq_weed:potOffset` while inside the grow op to easily retrieve the offset coordinates
        pots = {
            { optimal = true, showTent = false, autoWatering = true, coords = vec3(0, 5, -5.25), rotation = vec3(0, 0, 0) }, -- CHANGE ME
            -- ADD MORE POTS HERE AS NEEDED
        },
    },
        ]]
    },
    ['sn_properties_shell'] = {
        name = 'SN Properties (Shell)',
        data = [[
{
  model = 'kq_sbx_shell_{id}',
  size = 'medium', -- CHANGE ME
  entrance = vec4({x}, {y}, {z}, {heading}}),
},
    ]]
    },
    ['tk_housing_shell'] = {
        name = 'TK Housing (Shell)',
        data = [[
{
    model = `kq_sbx_shell_{id}`,
    label = '{name}',
    exits = {
        {label = 'Main door', coords = vec4({x}, {y}, {z}, {heading}), dist = 1.5},
    },
},
    ]]
    },
    ['rtx_housing_ipl'] = {
        name = 'RTX Housing (IPL)',
        data = [[
["kq_{id}"] = {
    label = "{name}",
    tags = {"Empty", "KuzQuality"},
    exitcoords = {coords = vec3({full_x}, {full_y}, {full_z} + 1.0), heading = {heading}},
    managmentcoords = {coords = vec3({full_x}, {full_y}, {full_z})}, -- CHANGE ME
    wardrobecoords = {coords = vec3({full_x}, {full_y}, {full_z})}, -- CHANGE ME
    storagecoords = {coords = vec3({full_x}, {full_y}, {full_z})}, -- CHANGE ME
    cookcoords = {coords = vector3(0.0, 0.0, 0.0)}, -- CHANGE ME
    sinkcoords = {}, -- CHANGE ME
    showercoords = {}, -- CHANGE ME
    cleanpoints = {}, -- CHANGE ME
    images = {
        {url = "img/previewimages/default.webp"},
    },
    themes = {
        {
            id = "default",
            label = "Default",
            ipl = "",
            interiorId = 0
        },
    },
},
    ]]
    },
}

Settings.decor = {
    ['lamp_1'] = {
        name = 'Spotlight',
        model = 'kq_sb_light_1',
        tag = 'Lights',
        colorPicker = true,
    },
    ['lamp_2'] = { -- x
        name = 'Industrial light',
        model = 'xs_prop_x18_hangar_light_c',
        offset = {
            pos = vec3(0, 0, 2.98),
        },
        tag = 'Lights',
        colorPicker = true,
    },
    ['lamp_3'] = { -- x
        name = 'Pendant light',
        model = 'xs_prop_x18_hangar_light_b',
        offset = {
            pos = vec3(0, 0, 2.98),
        },
        tag = 'Lights',
        colorPicker = true,
    },
    ['lamp_4'] = { -- x
        name = 'Halogen light',
        model = 'h4_prop_x17_sub_lampa_small_blue',
        offset = {
            pos = vec3(0, 0, 2.98),
        },
        tag = 'Lights',
        colorPicker = true,
    },
    ['lamp_5'] = {
        name = 'Tube lights',
        model = 'kq_sb_light_2',
        tag = 'Lights',
        colorPicker = true,
    },
    ['lamp_6'] = {
        name = 'Light panel',
        model = 'kq_sb_light_3',
        tag = 'Lights',
        colorPicker = true,
        offset = {
            pos = vec3(0, 0, -0.02),
        },
    },

    ['wall_trim'] = {
        name = 'Wall trim',
        model = 'kq_sb_trim',
        tag = 'Wall extras',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['wall_trimt'] = {
        name = 'Wall trim upper',
        model = 'kq_sb_trim',
        tag = 'Wall extras',
        offset = {
            pos = vec3(0, 0, 2.91),
            heading = 270,
        },
        colorPicker = true,
    },
    ['wall_trim_d'] = {
        name = 'Wall trim (door)',
        model = 'kq_sb_trim_door',
        tag = 'Wall extras',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['wall_panel_1'] = {
        name = 'Wall siding - Breeze',
        model = 'kq_sb_quartwall_3',
        tag = 'Wall extras',
        offset = {
            pos = vec3(0, -0.01, 0.02),
            heading = 270,
        },
        colorPicker = true,
    },
    ['wall_panel_2'] = {
        name = 'Wall siding - Wood',
        model = 'kq_sb_quartwall_4',
        tag = 'Wall extras',
        offset = {
            pos = vec3(0, -0.015, 0.02),
            heading = 270,
        },
        colorPicker = true,
    },
    ['shower'] = {
        name = 'Shower',
        model = 'kq_sb_shower',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 90,
        },
    },
    ['bar_1'] = {
        name = 'Bar counter',
        model = 'kq_sb_bar_tile_1',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 90,
        },
        colorPicker = true,
    },
    ['bar_1_edge'] = {
        name = 'Bar counter corner',
        model = 'kq_sb_bar_edge_1',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 90,
        },
        colorPicker = true,
    },
    ['kitch_1'] = {
        name = 'Kitchen counter',
        model = 'kq_sb_kitchen_counter',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['kitch_cook_1'] = {
        name = 'Kitchen cooker',
        model = 'kq_sb_kitchen_cooker',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['kitch_corner_1'] = {
        name = 'Kitchen corner',
        model = 'kq_sb_kitchen_corner',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['kitch_fridge_1'] = {
        name = 'Kitchen fridge',
        model = 'kq_sb_kitchen_fridge',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['kitch_sink_1'] = {
        name = 'Kitchen sink',
        model = 'kq_sb_kitchen_sink',
        tag = 'Counters',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
        colorPicker = true,
    },
    ['shelf_1'] = { -- x
        name = 'Store shelves #1',
        model = 'v_ind_cf_shelf',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.54, 0),
            heading = 0,
        },
    },
    ['shelf_2'] = {
        name = 'Store shelves #2',
        model = 'v_ret_fh_shelf_04',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.54, 0),
            heading = 0,
        },
    },
    ['shelf_3'] = { -- x
        name = 'Store shelves #3',
        model = 'v_ret_ml_shelfrk',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.69, 1),
            heading = 0,
        },
    },
    ['shelf_4'] = { -- x
        name = 'Store shelves #4',
        model = 'v_ret_ml_liqshelfe',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.69, 1),
            heading = 0,
        },
    },
    ['shelf_5'] = { -- x
        name = 'Store shelves #5',
        model = 'apa_mp_h_str_shelffreel_01',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['shelf_6'] = { -- x
        name = 'Store shelves #6',
        model = 'v_corp_offshelfclo',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['shelf_7'] = { -- x
        name = 'Store shelves #7',
        model = 'v_corp_offshelf',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['shelf_8'] = {
        name = 'Store shelves #8',
        model = 'v_ret_ml_liqshelfa',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.72, 1),
            heading = 0,
        },
    },
    ['shelf_9'] = {
        name = 'Store shelves #9',
        model = 'v_ret_ml_liqshelfc',
        tag = 'Shelves',
        offset = {
            pos = vec3(0, 0.72, 1),
            heading = 0,
        },
    },
    ['desk_1'] = {
        name = 'Desk #1', -- x
        model = 'tr_prop_tr_officedesk_01a',
        tag = 'Office',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['desk_2'] = {
        name = 'Desk #2',
        model = 'xm_prop_base_staff_desk_01',
        tag = 'Office',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['desk_3'] = { -- x
        name = 'Desk #3',
        model = 'v_corp_officedesk2',
        tag = 'Office',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['desk_4'] = { -- x
        name = 'Desk #4',
        model = 'v_corp_deskseta',
        tag = 'Office',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['server_rack'] = { -- x
        name = 'Server rack',
        model = 'm23_1_prop_m31_server_01a',
        tag = 'Office',
        offset = {
            pos = vec3(0, 0.72, 0),
            heading = 0,
        },
    },
    ['rack_1'] = {
        name = 'Storage Rack #1',
        model = 'imp_prop_impexp_rack_01a',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, -0.3, 0),
            heading = 270,
        },
    },
    ['rack_2'] = {
        name = 'Storage Rack #2',
        model = 'imp_prop_impexp_parts_rack_05a',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, -0.2, 0),
            heading = 270,
        },
    },
    ['rack_3'] = {
        name = 'Storage Rack #3',
        model = 'imp_prop_impexp_parts_rack_01a',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, -0.2, 0),
            heading = 270,
        },
    },
    ['rack_4'] = {
        name = 'Storage Rack #4',
        model = 'imp_prop_impexp_parts_rack_02a',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, -0.3, 0),
            heading = 270,
        },
    },
    ['car_rack'] = {
        name = 'Car Lift Rack',
        model = 'imp_prop_impexp_carrack',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, -0.3, 0),
            heading = 0,
        },
    },
    ['t_rack'] = { -- x
        name = 'Tire Rack',
        model = 'v_ret_csr_tyresale',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.44, 1.1),
            heading = 0,
        },
    },
    ['w_drawers'] = { -- x
        name = 'Workshop drawers #1',
        model = 'xs_prop_x18_tool_draw_01e',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.5, 0),
            heading = 0,
        },
    },
    ['w_drawers2'] = {
        name = 'Workshop drawers #2',
        model = 'prop_toolchest_05',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.5, 0),
            heading = 0,
        },
    },
    ['workbench_1'] = { -- x
        name = 'Workbench #1',
        model = 'xm3_prop_xm3_bench_04b',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.5, 0),
            heading = 0,
        },
    },
    ['workbench_2'] = { -- x
        name = 'Workbench #2',
        model = 'xm3_prop_xm3_bench_03b',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.5, 0),
            heading = 0,
        },
    },
    ['garage_door_1'] = {
        name = 'Garage door #1',
        model = 'v_ilev_spraydoor',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.92, 1.26),
            heading = 0,
        },
    },
    ['garage_door_2'] = {
        name = 'Garage door #2',
        model = 'prop_sc1_21_g_door_01',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.94, 1.22),
            heading = 0,
        },
    },
    ['garage_door_3'] = {
        name = 'Garage door #3',
        model = 'prop_cs4_10_tr_gd_01',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.94, 1.15),
            heading = 0,
        }
    },
    ['garage_door_4'] = {
        name = 'Garage door #4',
        model = 'v_ilev_finale_shut01',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.92, 1.18),
            heading = 0,
        }
    },
    ['garage_door_5'] = {
        name = 'Garage door #5',
        model = 'prop_ch2_07b_20_g_door',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.945, 1.315),
            heading = 0,
        }
    },
    ['garage_door_6'] = {
        name = 'Garage door #6',
        model = 'v_ilev_carmod3door',
        tag = 'Workshop',
        offset = {
            pos = vec3(0, 0.945, 1.89),
            heading = 0,
        }
    },
    ['pot_rack'] = {
        name = 'Hanging pots',
        model = 'prop_pot_rack',
        tag = 'Ceiling decor',
        offset = {
            pos = vec3(0, 0.5, 2.48),
            heading = 90,
        }
    },
    --['bugzap'] = { -- Not reliable
    --    name = 'Bug zapper',
    --    model = 'v_ind_cf_bugzap',
    --    tag = 'Wall decor',
    --    offset = {
    --        pos = vec3(0, 0.852, 2.35),
    --        heading = 0,
    --    },
    --    colorPicker = true,
    --},
    --['socket'] = { -- Not reliable
    --    name = 'Wall plug',
    --    model = 'v_res_tre_plugsocket',
    --    tag = 'Wall decor',
    --    offset = {
    --        pos = vec3(0, 0.93, 0.25),
    --        heading = 0,
    --    }
    --},
    ['wvent'] = {
        name = 'Wall vent low',
        model = 'prop_wall_vent_03',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.93, 0.33),
            heading = 0,
        }
    },
    ['wvent_H'] = {
        name = 'Wall vent high',
        model = 'prop_wall_vent_03',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.93, 2.64),
            heading = 0,
        }
    },
    ['elevator_door'] = { -- x
        name = 'Elevator Door',
        model = 'm23_2_prop_m32_door_elev_01a',
        tag = 'Wall extras',
        offset = {
            pos = vec3(0, 0.8, 0),
            heading = 0,
        }
    },
    ['fusebox'] = { -- x
        name = 'Fusebox',
        model = 'ch_prop_ch_fuse_box_01a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.87, 1.65),
            heading = 0,
        }
    },
    ['elecbox'] = { -- x
        name = 'Electric box',
        model = 'm23_1_prop_m31_electricbox_01a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.81, 0.32),
            heading = 0,
        }
    },
    ['dartboard'] = {
        name = 'Dartboard',
        model = 'prop_dart_bd_cab_01',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.94, 1.65),
            heading = 0,
        }
    },
    --['radiator'] = { -- Not reliable
    --    name = 'Wall radiator',
    --    model = 'v_ret_fh_radiator',
    --    tag = 'Wall decor',
    --    offset = {
    --        pos = vec3(0, 0.775, 0.44),
    --        heading = 0,
    --    }
    --},
    ['coat_hook'] = {
        name = 'Coat hanger #1',
        model = 'prop_coathook_01',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.87, 1.4),
            heading = 0,
        }
    },
    ['whips_hang'] = { -- x
        name = 'Whips',
        model = 'v_res_d_whips',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.88, 1.4),
            heading = 0,
        }
    },
    ['neon_blarneys'] = {
        name = 'Neon Blarneys',
        model = 'v_ret_neon_blarneys',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.91, 2.1),
            heading = 0,
        },
        colorPicker = true,
    },
    ['neon_logg'] = {
        name = 'Neon Logger',
        model = 'prop_loggneon',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.935, 1.9),
            heading = 0,
        },
        colorPicker = true,
    },
    ['neon_rag'] = {
        name = 'Neon Palm Beer',
        model = 'prop_ragganeon',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.93, 1.9),
            heading = 0,
        },
        colorPicker = true,
    },
    ['dimmer'] = { -- x
        name = 'Wall Dimmer',
        model = 'h4_prop_club_dimmer',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.93, 1.4),
            heading = 0,
        },
    },
    ['control_panel'] = { -- x
        name = 'Control Panel',
        model = 'm23_1_prop_m31_control_panel_01a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.93, 1.4),
            heading = 0,
        },
    },
    ['tp_roll'] = { -- x
        name = 'Toilet paper roll #1',
        model = 'v_res_m_wctoiletroll',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.93, 0.9),
            heading = 0,
        },
    },
    ['tp_roll_2'] = {
        name = 'Toilet paper roll #2',
        model = 'prop_toilet_roll_02',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.93, 0.9),
            heading = 0,
        },
    },
    ['toilet_1'] = {
        name = 'Toilet #1',
        model = 'prop_toilet_01',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.62, 0),
            heading = 0,
        },
    },
    ['toilet_2'] = {
        name = 'Toilet #2',
        model = 'prop_toilet_02',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.62, 0),
            heading = 0,
        },
    },
    ['toilet_3'] = {
        name = 'Toilet Nasty',
        model = 'prop_ld_toilet_01',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.58, 0.33),
            heading = 0,
        },
    },
    ['towel_rail'] = {
        name = 'Towel rail',
        model = 'prop_towel_rail_02',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.93, 0.9),
            heading = 0,
        },
    },
    ['sink_1'] = {
        name = 'Sink #1',
        model = 'prop_sink_05',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.93, 0.9),
            heading = 0,
        },
    },
    ['sink_2'] = {
        name = 'Sink #2',
        model = 'v_res_mbsink',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.73, 0.9),
            heading = 0,
        },
    },
    ['sink_3'] = { -- x
        name = 'Sink #3',
        model = 'v_ind_sinkhand',
        tag = 'Bathroom',
        offset = {
            pos = vec3(0, 0.63, 0),
            heading = 0,
        },
    },
    ['whiteboard'] = { -- x
        name = 'Whiteboard',
        model = 'ch_prop_whiteboard',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.45),
            heading = 0,
        },
    },
    ['chalkboard'] = {
        name = 'Chalkboard',
        model = 'prop_b_board_blank',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.45),
            heading = 0,
        },
    },
    ['cig_disp'] = {
        name = 'Cigarette dispenser',
        model = 'prop_vend_fags_01',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.8, 1.45),
            heading = 0,
        },
    },
    ['parking_sign'] = { -- x
        name = 'Parking sign',
        model = 'reh_prop_reh_plague_sf_01a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1),
            heading = 0,
        },
    },
    ['floor_hatch'] = { -- x
        name = 'Floor hatch',
        model = 'm23_2_prop_m32_hatch_01a',
        tag = 'Floor decor',
    },
    ['rug_1'] = {
        name = 'Rug #1',
        model = 'apa_mp_h_acc_rugwools_01',
        tag = 'Floor decor',
    },
    ['rug_2'] = {
        name = 'Rug #2',
        model = 'apa_mp_h_acc_rugwools_03',
        tag = 'Floor decor',
    },
    ['rug_3'] = {
        name = 'Rug #3',
        model = 'ex_mp_h_acc_rugwoolm_04',
        tag = 'Floor decor',
    },
    ['cctv'] = {
        name = 'CCTV Camera',
        model = 'prop_cctv_cam_06a',
        tag = 'Ceiling decor',
        offset = {
            pos = vec3(0, 0.65, 2.92),
            heading = 0,
        },
    },
    ['painting_1'] = { -- x
        name = 'Painting #1',
        model = 'ch_prop_vault_painting_01e',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.2),
            heading = 0,
        },
    },
    ['painting_2'] = { -- x
        name = 'Painting #2',
        model = 'ch_prop_vault_painting_01j',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.2),
            heading = 0,
        },
    },
    ['painting_3'] = { -- x
        name = 'Painting #3',
        model = 'ch_prop_vault_painting_01f',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.2),
            heading = 0,
        },
    },
    ['painting_4'] = { -- x
        name = 'Painting #4',
        model = 'ch_prop_vault_painting_01h',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.2),
            heading = 0,
        },
    },
    ['painting_5'] = { -- x
        name = 'Painting #5',
        model = 'ch_prop_vault_painting_01g',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.2),
            heading = 0,
        },
    },
    ['painting_6'] = { -- x
        name = 'Painting #6',
        model = 'ch_prop_vault_painting_01d',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.2),
            heading = 0,
        },
    },
    ['painting_7'] = {
        name = 'Painting #7',
        model = 'v_res_picture_frame',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_1'] = { -- x
        name = 'Wall Art #1',
        model = 'vw_prop_vw_wallart_57a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_2'] = { -- x
        name = 'Wall Art #2',
        model = 'vw_prop_vw_wallart_141a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_3'] = { -- x
        name = 'Wall Art #3',
        model = 'vw_prop_vw_wallart_156a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_4'] = { -- x
        name = 'Wall Art #4',
        model = 'vw_prop_vw_wallart_111a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_5'] = { -- x
        name = 'Wall Art #5',
        model = 'vw_prop_vw_wallart_20a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_6'] = { -- x
        name = 'Wall Art #6',
        model = 'vw_prop_vw_wallart_129a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_7'] = {
        name = 'Wall Art #7',
        model = 'v_med_p_wallhead',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 2),
            heading = 0,
        },
    },
    ['wart_8'] = { -- x
        name = 'Wall Art #8',
        model = 'vw_prop_vw_wallart_137a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['wart_9'] = { -- x
        name = 'Wall Art #9',
        model = 'vw_prop_vw_wallart_131a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.7),
            heading = 0,
        },
    },
    ['pic_1'] = { -- x
        name = 'Picture #1',
        model = 'v_med_wallpicture2',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.89, 1.6),
            heading = 0,
        },
    },
    ['pic_2'] = { -- x
        name = 'Picture #2',
        model = 'vw_prop_vw_wallart_134a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['pic_3'] = { -- x
        name = 'Picture #3',
        model = 'vw_prop_vw_wallart_132a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['pic_4'] = {
        name = 'Picture #4',
        model = 'prop_cs_photoframe_01',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['post_1'] = { -- x
        name = 'Poster #1',
        model = 'm23_2_prop_m32_poster_01a',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['post_2'] = {
        name = 'Poster #2',
        model = 'hei_prop_dlc_heist_map',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0.91, 1.65),
            heading = 180,
        },
    },
    ['spill_1'] = {
        name = 'Spill 1',
        model = 'kq_dirt_spill_1',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_2'] = {
        name = 'Spill 2',
        model = 'kq_dirt_spill_2',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_3'] = {
        name = 'Spill 3',
        model = 'kq_dirt_spill_3',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_4'] = {
        name = 'Spill 4',
        model = 'kq_dirt_spill_4',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_5'] = {
        name = 'Spill 5',
        model = 'kq_dirt_spill_5',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_6'] = {
        name = 'Spill 6',
        model = 'kq_dirt_spill_6',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_7'] = {
        name = 'Spill 7',
        model = 'kq_dirt_spill_7',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_8'] = {
        name = 'Spill 8',
        model = 'kq_dirt_spill_8',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['spill_9'] = {
        name = 'Spill 9',
        model = 'kq_dirt_spill_9',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['dedge_1'] = {
        name = 'Wall dirt edge #1',
        model = 'kq_sb_dirt_edge_1',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },
    ['dedge_2'] = {
        name = 'Wall dirt edge #2',
        model = 'kq_sb_dirt_edge_2',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },
    ['dedge_3'] = {
        name = 'Wall dirt edge #3',
        model = 'kq_sb_dirt_edge_3',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0, -0.04),
            heading = 270,
        },
    },
    ['wspill_1'] = {
        name = 'Wall Spill 1',
        model = 'kq_dirt_spill_1',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 0.7),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_2'] = {
        name = 'Wall Spill 2',
        model = 'kq_dirt_spill_2',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 2.1),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_3'] = {
        name = 'Wall Spill 3',
        model = 'kq_dirt_spill_3',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 1.1),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_4'] = {
        name = 'Wall Spill 4',
        model = 'kq_dirt_spill_4',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 2.2),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_5'] = {
        name = 'Wall Spill 5',
        model = 'kq_dirt_spill_5',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 1.7),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_6'] = {
        name = 'Wall Spill 6',
        model = 'kq_dirt_spill_6',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 1.5),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_7'] = {
        name = 'Wall Spill 7',
        model = 'kq_dirt_spill_7',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 1.2),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_8'] = {
        name = 'Wall Spill 8',
        model = 'kq_dirt_spill_8',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 0.5),
            rot = vec3(90, 0, 0),
        },
    },
    ['wspill_9'] = {
        name = 'Wall Spill 9',
        model = 'kq_dirt_spill_9',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.93, 1),
            rot = vec3(90, 0, 0),
        },
    },
    ['litter_1'] = {
        name = 'Litter 1',
        model = 'prop_rub_litter_04b',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['litter_2'] = {
        name = 'Litter 2',
        model = 'prop_rub_litter_07',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['litter_3'] = {
        name = 'Litter 3',
        model = 'prop_rub_litter_02',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['litter_4'] = {
        name = 'Litter 4',
        model = 'prop_rub_litter_03b',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['litter_5'] = {
        name = 'Litter 5',
        model = 'prop_rub_litter_01',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['litter_6'] = {
        name = 'Litter 6',
        model = 'v_res_tt_litter3',
        tag = 'Clutter',
        offset = {
            pos = vec3(0.3, 0, 0.02),
            heading = 0,
        },
    },
    ['litter_7'] = {
        name = 'Litter 7',
        model = 'proc_litter_02',
        tag = 'Clutter',
        randomizeOffset = true,
    },
    ['wdecal_1'] = { -- x
        name = 'Wall clutter #1',
        model = 'xm3_prop_xm3_board_decal_01a',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.91, 1.35),
            heading = 0,
        },
    },
    ['wdecal_2'] = { -- x
        name = 'Wall clutter #2',
        model = 'ba_prop_club_dressing_posters_01',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['wdecal_3'] = { -- x
        name = 'Wall clutter #3',
        model = 'ba_prop_club_dressing_posters_02',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['wdecal_4'] = { -- x
        name = 'Wall clutter #4',
        model = 'ba_prop_club_dressing_poster_01',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['wdecal_5'] = { -- x
        name = 'Wall clutter #5',
        model = 'ba_prop_club_dressing_poster_02',
        tag = 'Clutter',
        offset = {
            pos = vec3(0, 0.92, 1.6),
            heading = 0,
        },
    },
    ['banner_1'] = {
        name = 'Wall banner #1',
        model = 'kq_sb_banner_1',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, -0.5),
            heading = 270,
        },
    },
    ['banner_2'] = {
        name = 'Wall banner #2',
        model = 'kq_sb_banner_2',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, -0.5),
            heading = 270,
        },
    },
    ['banner_3'] = {
        name = 'Wall banner #3',
        model = 'kq_sb_banner_3',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, -0.5),
            heading = 270,
        },
    },
    ['banner_4'] = {
        name = 'Wall banner #4',
        model = 'kq_sb_banner_4',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, -0.5),
            heading = 270,
        },
    },
    ['graff_1'] = {
        name = 'Graffiti #1',
        model = 'kq_sb_graffiti_1',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },
    ['graff_2'] = {
        name = 'Graffiti #2',
        model = 'kq_sb_graffiti_2',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },
    ['graff_3'] = {
        name = 'Graffiti #3',
        model = 'kq_sb_graffiti_3',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },
    ['graff_4'] = {
        name = 'Graffiti #4',
        model = 'kq_sb_graffiti_4',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },
    ['graff_5'] = {
        name = 'Graffiti #5',
        model = 'kq_sb_graffiti_5',
        tag = 'Wall decor',
        offset = {
            pos = vec3(0, 0, 0),
            heading = 270,
        },
    },

    -- DNX Addon Props - Buildings
    ['dnx_bld_bulletinboard_a'] = { name = 'Bulletin Board (Full)', model = 'dnxprops_buildings_bulletinboard01_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_bulletinboard_empty'] = { name = 'Bulletin Board (Empty)', model = 'dnxprops_buildings_bulletinboard01_empty', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_canopy01'] = { name = 'Canopy Small #1', model = 'dnxprops_buildings_canopysmall01_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_canopy02'] = { name = 'Canopy Small #2', model = 'dnxprops_buildings_canopysmall02_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_canopy03'] = { name = 'Canopy Small #3', model = 'dnxprops_buildings_canopysmall03_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_canopy04'] = { name = 'Canopy Small #4', model = 'dnxprops_buildings_canopysmall04_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_canopy05'] = { name = 'Canopy Small #5', model = 'dnxprops_buildings_canopysmall05_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_canopy06'] = { name = 'Canopy Small #6', model = 'dnxprops_buildings_canopysmall06_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_gasboiler01'] = { name = 'Gas Boiler #1', model = 'dnxprops_buildings_gasboiler01', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_gasboiler02'] = { name = 'Gas Boiler #2', model = 'dnxprops_buildings_gasboiler02', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_gasboiler03'] = { name = 'Gas Boiler #3', model = 'dnxprops_buildings_gasboiler03', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_gasboiler04'] = { name = 'Gas Boiler #4', model = 'dnxprops_buildings_gasboiler04', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_privacyscreen'] = { name = 'Privacy Screen', model = 'dnxprops_buildings_privacyscreen01_a', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_privacyscreen_hedge'] = { name = 'Privacy Screen (Hedge)', model = 'dnxprops_buildings_privacyscreen01_a_hedge', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_bld_watertank'] = { name = 'Water Tank', model = 'dnxprops_buildings_watertank01', tag = 'DNX Buildings', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Effects
    ['dnx_fx_campfire'] = { name = 'Campfire', model = 'dnxprops_effects_fire_campfire', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_fireplace'] = { name = 'Fireplace', model = 'dnxprops_effects_fire_fireplace', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_smoke_acvent'] = { name = 'AC Vent Smoke', model = 'dnxprops_effects_smoke_acvent', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_smoke_factory'] = { name = 'Factory Smoke', model = 'dnxprops_effects_smoke_factory', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_smoke_roofvent'] = { name = 'Roof Vent Smoke', model = 'dnxprops_effects_smoke_roofvent', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_water_drips_med'] = { name = 'Water Drips (Med)', model = 'dnxprops_effects_water_drips_med', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_water_drips_small'] = { name = 'Water Drips (Small)', model = 'dnxprops_effects_water_drips_small', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_water_drips_tap'] = { name = 'Tap Drips', model = 'dnxprops_effects_water_drips_tap', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_water_fountain'] = { name = 'Water Fountain', model = 'dnxprops_effects_water_fountain_single', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fx_water_rain'] = { name = 'Rain Pour', model = 'dnxprops_effects_water_pour_short_rain', tag = 'DNX Effects', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Electronics
    ['dnx_elec_arrowbtn_a'] = { name = 'Arrow Button A', model = 'dnxprops_electronics_arrowbutton01_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_arrowbtn_b'] = { name = 'Arrow Button B', model = 'dnxprops_electronics_arrowbutton01_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_a'] = { name = 'Doorbell A', model = 'dnxprops_electronics_doorbell01_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_a_c1'] = { name = 'Doorbell A Custom #1', model = 'dnxprops_electronics_doorbell01_a_custom01', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_a_c2'] = { name = 'Doorbell A Custom #2', model = 'dnxprops_electronics_doorbell01_a_custom02', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_a_c3'] = { name = 'Doorbell A Custom #3', model = 'dnxprops_electronics_doorbell01_a_custom03', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_a_c4'] = { name = 'Doorbell A Custom #4', model = 'dnxprops_electronics_doorbell01_a_custom04', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_a_c5'] = { name = 'Doorbell A Custom #5', model = 'dnxprops_electronics_doorbell01_a_custom05', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_b'] = { name = 'Doorbell B', model = 'dnxprops_electronics_doorbell01_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_b_c1'] = { name = 'Doorbell B Custom #1', model = 'dnxprops_electronics_doorbell01_b_custom01', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_b_c2'] = { name = 'Doorbell B Custom #2', model = 'dnxprops_electronics_doorbell01_b_custom02', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_b_c3'] = { name = 'Doorbell B Custom #3', model = 'dnxprops_electronics_doorbell01_b_custom03', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_b_c4'] = { name = 'Doorbell B Custom #4', model = 'dnxprops_electronics_doorbell01_b_custom04', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_doorbell_b_c5'] = { name = 'Doorbell B Custom #5', model = 'dnxprops_electronics_doorbell01_b_custom05', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_intercom'] = { name = 'Intercom', model = 'dnxprops_electronics_intercom01_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_lightbtn_a'] = { name = 'Light Button A', model = 'dnxprops_electronics_lightbutton01_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_lightbtn_b'] = { name = 'Light Button B', model = 'dnxprops_electronics_lightbutton01_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_socketsw_a'] = { name = 'Socket/Switch Combo A', model = 'dnxprops_electronics_socketswitchus01_combo1_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_socketsw_b'] = { name = 'Socket/Switch Combo B', model = 'dnxprops_electronics_socketswitchus01_combo1_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_socket_double_a'] = { name = 'Double Socket A', model = 'dnxprops_electronics_socketus01_double_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_socket_double_b'] = { name = 'Double Socket B', model = 'dnxprops_electronics_socketus01_double_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_socket_single_a'] = { name = 'Single Socket A', model = 'dnxprops_electronics_socketus01_single_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_socket_single_b'] = { name = 'Single Socket B', model = 'dnxprops_electronics_socketus01_single_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_switch_double_a'] = { name = 'Double Switch A', model = 'dnxprops_electronics_switch01_double_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_switch_double_b'] = { name = 'Double Switch B', model = 'dnxprops_electronics_switch01_double_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_switch_single_a'] = { name = 'Single Switch A', model = 'dnxprops_electronics_switch01_single_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_switch_single_b'] = { name = 'Single Switch B', model = 'dnxprops_electronics_switch01_single_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_switch_triple_a'] = { name = 'Triple Switch A', model = 'dnxprops_electronics_switch01_triple_a', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_switch_triple_b'] = { name = 'Triple Switch B', model = 'dnxprops_electronics_switch01_triple_b', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_elec_tvantenna'] = { name = 'TV Antenna', model = 'dnxprops_electronics_tvantenna01', tag = 'DNX Electronics', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Entertainment
    ['dnx_ent_manga_a'] = { name = 'Manga #1', model = 'dnxprops_entertainment_manga01_a', tag = 'DNX Entertainment', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_ent_manga_b'] = { name = 'Manga #2', model = 'dnxprops_entertainment_manga01_b', tag = 'DNX Entertainment', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_ent_manga_c'] = { name = 'Manga #3', model = 'dnxprops_entertainment_manga01_c', tag = 'DNX Entertainment', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_ent_manga_d'] = { name = 'Manga #4', model = 'dnxprops_entertainment_manga01_d', tag = 'DNX Entertainment', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_ent_manga_e'] = { name = 'Manga #5', model = 'dnxprops_entertainment_manga01_e', tag = 'DNX Entertainment', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Fire Safety
    ['dnx_fire_extinguisher1'] = { name = 'Fire Extinguisher #1', model = 'dnxprops_fire_extinguisher1', tag = 'DNX Fire Safety', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fire_extinguisher2'] = { name = 'Fire Extinguisher #2', model = 'dnxprops_fire_extinguisher2', tag = 'DNX Fire Safety', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fire_bracket_a'] = { name = 'Extinguisher Bracket A', model = 'dnxprops_fire_extinguisherbracket01_a', tag = 'DNX Fire Safety', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_fire_bracket_b'] = { name = 'Extinguisher Bracket B', model = 'dnxprops_fire_extinguisherbracket01_b', tag = 'DNX Fire Safety', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Bathroom Furniture
    ['dnx_furn_bathcab_a'] = { name = 'Bathroom Cabinet A', model = 'dnxprops_furniture_bathroomcabinet01_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bathcab_b'] = { name = 'Bathroom Cabinet B', model = 'dnxprops_furniture_bathroomcabinet01_b', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bathcab_c'] = { name = 'Bathroom Cabinet C', model = 'dnxprops_furniture_bathroomcabinet01_c', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bathsink'] = { name = 'Bathroom Sink', model = 'dnxprops_furniture_bathroomsink01_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bathtub'] = { name = 'Bathtub', model = 'dnxprops_furniture_bathtub02_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bidet'] = { name = 'Bidet', model = 'dnxprops_furniture_bidet', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_shower01'] = { name = 'Shower #1', model = 'dnxprops_furniture_shower01_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_shower02'] = { name = 'Shower #2', model = 'dnxprops_furniture_shower02_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_shower03'] = { name = 'Shower #3', model = 'dnxprops_furniture_shower03_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_toilet_a'] = { name = 'Toilet A', model = 'dnxprops_furniture_toilet01_a', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_toilet_b'] = { name = 'Toilet B', model = 'dnxprops_furniture_toilet01_b', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_toilet_c'] = { name = 'Toilet C', model = 'dnxprops_furniture_toilet01_c', tag = 'DNX Bathroom', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Bookshelves
    ['dnx_furn_bookshelf_a'] = { name = 'Bookshelf A', model = 'dnxprops_furniture_bookshelf01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bookshelf_b'] = { name = 'Bookshelf B', model = 'dnxprops_furniture_bookshelf01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bookshelf_books'] = { name = 'Bookshelf (Books)', model = 'dnxprops_furniture_bookshelf01_books', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bookshelf_c'] = { name = 'Bookshelf C', model = 'dnxprops_furniture_bookshelf01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bookshelf_lg_a'] = { name = 'Large Bookshelf A', model = 'dnxprops_furniture_bookshelflarge01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bookshelf_lg_b'] = { name = 'Large Bookshelf B', model = 'dnxprops_furniture_bookshelflarge01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_bookshelf_lg_c'] = { name = 'Large Bookshelf C', model = 'dnxprops_furniture_bookshelflarge01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Coat Rack
    ['dnx_furn_coatrack_a'] = { name = 'Coat Rack A', model = 'dnxprops_furniture_coatrack01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_coatrack_b'] = { name = 'Coat Rack B', model = 'dnxprops_furniture_coatrack01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_coatrack_c'] = { name = 'Coat Rack C', model = 'dnxprops_furniture_coatrack01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Desks
    ['dnx_furn_desk01_a'] = { name = 'Desk #1 A', model = 'dnxprops_furniture_desk01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk01_b'] = { name = 'Desk #1 B', model = 'dnxprops_furniture_desk01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk01_c'] = { name = 'Desk #1 C', model = 'dnxprops_furniture_desk01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk02_a'] = { name = 'Desk #2 A', model = 'dnxprops_furniture_desk02_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk02_b'] = { name = 'Desk #2 B', model = 'dnxprops_furniture_desk02_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk02_c'] = { name = 'Desk #2 C', model = 'dnxprops_furniture_desk02_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk03_a'] = { name = 'Desk #3 A', model = 'dnxprops_furniture_desk03_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk03_b'] = { name = 'Desk #3 B', model = 'dnxprops_furniture_desk03_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk03_c'] = { name = 'Desk #3 C', model = 'dnxprops_furniture_desk03_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk04_a'] = { name = 'Desk #4 A', model = 'dnxprops_furniture_desk04_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk04_b'] = { name = 'Desk #4 B', model = 'dnxprops_furniture_desk04_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk04_c'] = { name = 'Desk #4 C', model = 'dnxprops_furniture_desk04_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk05_a'] = { name = 'Desk #5 A', model = 'dnxprops_furniture_desk05_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk05_b'] = { name = 'Desk #5 B', model = 'dnxprops_furniture_desk05_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk05_c'] = { name = 'Desk #5 C', model = 'dnxprops_furniture_desk05_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk06_a'] = { name = 'Desk #6 A', model = 'dnxprops_furniture_desk06_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk06_b'] = { name = 'Desk #6 B', model = 'dnxprops_furniture_desk06_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk06_c'] = { name = 'Desk #6 C', model = 'dnxprops_furniture_desk06_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk07_a'] = { name = 'Desk #7 A', model = 'dnxprops_furniture_desk07_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk07_b'] = { name = 'Desk #7 B', model = 'dnxprops_furniture_desk07_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk07_c'] = { name = 'Desk #7 C', model = 'dnxprops_furniture_desk07_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk08_a'] = { name = 'Desk #8 A', model = 'dnxprops_furniture_desk08_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk08_b'] = { name = 'Desk #8 B', model = 'dnxprops_furniture_desk08_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk08_c'] = { name = 'Desk #8 C', model = 'dnxprops_furniture_desk08_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk09_a'] = { name = 'Desk #9 A', model = 'dnxprops_furniture_desk09_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk09_b'] = { name = 'Desk #9 B', model = 'dnxprops_furniture_desk09_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk09_c'] = { name = 'Desk #9 C', model = 'dnxprops_furniture_desk09_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk10_a'] = { name = 'Desk #10 A', model = 'dnxprops_furniture_desk10_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk10_b'] = { name = 'Desk #10 B', model = 'dnxprops_furniture_desk10_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk10_c'] = { name = 'Desk #10 C', model = 'dnxprops_furniture_desk10_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk11_a'] = { name = 'Desk #11 A', model = 'dnxprops_furniture_desk11_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk11_b'] = { name = 'Desk #11 B', model = 'dnxprops_furniture_desk11_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk11_c'] = { name = 'Desk #11 C', model = 'dnxprops_furniture_desk11_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk12_a'] = { name = 'Desk #12 A', model = 'dnxprops_furniture_desk12_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk12_b'] = { name = 'Desk #12 B', model = 'dnxprops_furniture_desk12_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk12_c'] = { name = 'Desk #12 C', model = 'dnxprops_furniture_desk12_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk13_a'] = { name = 'Desk #13 A', model = 'dnxprops_furniture_desk13_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk13_b'] = { name = 'Desk #13 B', model = 'dnxprops_furniture_desk13_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_desk13_c'] = { name = 'Desk #13 C', model = 'dnxprops_furniture_desk13_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_deskwood_a'] = { name = 'Wood Desk A', model = 'dnxprops_furniture_deskwood01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_deskwood_b'] = { name = 'Wood Desk B', model = 'dnxprops_furniture_deskwood01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_deskwood_c'] = { name = 'Wood Desk C', model = 'dnxprops_furniture_deskwood01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Dining & Storage
    ['dnx_furn_diningtable01_a'] = { name = 'Dining Table #1 A', model = 'dnxprops_furniture_dinningtable01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_diningtable01_b'] = { name = 'Dining Table #1 B', model = 'dnxprops_furniture_dinningtable01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_diningtable02_a'] = { name = 'Dining Table #2 A', model = 'dnxprops_furniture_dinningtable02_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_diningtable02_b'] = { name = 'Dining Table #2 B', model = 'dnxprops_furniture_dinningtable02_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_filecab_a'] = { name = 'File Cabinet A', model = 'dnxprops_furniture_filecabinetlarge01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_filecab_b'] = { name = 'File Cabinet B', model = 'dnxprops_furniture_filecabinetlarge01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_filecab_c'] = { name = 'File Cabinet C', model = 'dnxprops_furniture_filecabinetlarge01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_shelf_a'] = { name = 'Shelf A', model = 'dnxprops_furniture_shelf01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_shelf_b'] = { name = 'Shelf B', model = 'dnxprops_furniture_shelf01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Kitchen
    ['dnx_kit_cab01_a'] = { name = 'Kitchen Cabinet #1 A', model = 'dnxprops_furniture_kitchencabinet01_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab01_b'] = { name = 'Kitchen Cabinet #1 B', model = 'dnxprops_furniture_kitchencabinet01_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab02_a'] = { name = 'Kitchen Cabinet #2 A', model = 'dnxprops_furniture_kitchencabinet02_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab02_b'] = { name = 'Kitchen Cabinet #2 B', model = 'dnxprops_furniture_kitchencabinet02_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab03_a'] = { name = 'Kitchen Cabinet #3 A', model = 'dnxprops_furniture_kitchencabinet03_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab03_b'] = { name = 'Kitchen Cabinet #3 B', model = 'dnxprops_furniture_kitchencabinet03_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab04_a'] = { name = 'Kitchen Cabinet #4 A', model = 'dnxprops_furniture_kitchencabinet04_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab04_b'] = { name = 'Kitchen Cabinet #4 B', model = 'dnxprops_furniture_kitchencabinet04_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab05_a'] = { name = 'Kitchen Cabinet #5 A', model = 'dnxprops_furniture_kitchencabinet05_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab05_b'] = { name = 'Kitchen Cabinet #5 B', model = 'dnxprops_furniture_kitchencabinet05_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab06_a'] = { name = 'Kitchen Cabinet #6 A', model = 'dnxprops_furniture_kitchencabinet06_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab06_b'] = { name = 'Kitchen Cabinet #6 B', model = 'dnxprops_furniture_kitchencabinet06_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab07_a'] = { name = 'Kitchen Cabinet #7 A', model = 'dnxprops_furniture_kitchencabinet07_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab07_b'] = { name = 'Kitchen Cabinet #7 B', model = 'dnxprops_furniture_kitchencabinet07_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab08_a'] = { name = 'Kitchen Cabinet #8 A', model = 'dnxprops_furniture_kitchencabinet08_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab08_b'] = { name = 'Kitchen Cabinet #8 B', model = 'dnxprops_furniture_kitchencabinet08_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab09_a'] = { name = 'Kitchen Cabinet #9 A', model = 'dnxprops_furniture_kitchencabinet09_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab09_b'] = { name = 'Kitchen Cabinet #9 B', model = 'dnxprops_furniture_kitchencabinet09_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab10_a'] = { name = 'Kitchen Cabinet #10 A', model = 'dnxprops_furniture_kitchencabinet10_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab10_b'] = { name = 'Kitchen Cabinet #10 B', model = 'dnxprops_furniture_kitchencabinet10_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab11_a'] = { name = 'Kitchen Cabinet #11 A', model = 'dnxprops_furniture_kitchencabinet11_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab11_b'] = { name = 'Kitchen Cabinet #11 B', model = 'dnxprops_furniture_kitchencabinet11_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab12_a'] = { name = 'Kitchen Cabinet #12 A', model = 'dnxprops_furniture_kitchencabinet12_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab12_b'] = { name = 'Kitchen Cabinet #12 B', model = 'dnxprops_furniture_kitchencabinet12_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab13_a'] = { name = 'Kitchen Cabinet #13 A', model = 'dnxprops_furniture_kitchencabinet13_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_cab13_b'] = { name = 'Kitchen Cabinet #13 B', model = 'dnxprops_furniture_kitchencabinet13_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_dishwasher_a'] = { name = 'Dishwasher A', model = 'dnxprops_furniture_kitchendishwasher_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_dishwasher_b'] = { name = 'Dishwasher B', model = 'dnxprops_furniture_kitchendishwasher_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_fridge'] = { name = 'Large Fridge', model = 'dnxprops_furniture_kitchenfridgelarge01_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_oven01_a'] = { name = 'Oven #1 A', model = 'dnxprops_furniture_kitchenoven01_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_oven01_b'] = { name = 'Oven #1 B', model = 'dnxprops_furniture_kitchenoven01_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_oven02_a'] = { name = 'Oven #2 A', model = 'dnxprops_furniture_kitchenoven02_a', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_kit_oven02_b'] = { name = 'Oven #2 B', model = 'dnxprops_furniture_kitchenoven02_b', tag = 'DNX Kitchen', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Wardrobes
    ['dnx_furn_wdrawer_a'] = { name = 'Wardrobe Drawer A', model = 'dnxprops_furniture_wardrobedrawer01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wdrawer_b'] = { name = 'Wardrobe Drawer B', model = 'dnxprops_furniture_wardrobedrawer01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wdrawer_c'] = { name = 'Wardrobe Drawer C', model = 'dnxprops_furniture_wardrobedrawer01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wardrobe_lg_a'] = { name = 'Large Wardrobe A', model = 'dnxprops_furniture_wardrobelarge01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wardrobe_lg_b'] = { name = 'Large Wardrobe B', model = 'dnxprops_furniture_wardrobelarge01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wardrobe_lg_c'] = { name = 'Large Wardrobe C', model = 'dnxprops_furniture_wardrobelarge01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wardrobe_sm_a'] = { name = 'Small Wardrobe A', model = 'dnxprops_furniture_wardrobesmall01_a', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wardrobe_sm_b'] = { name = 'Small Wardrobe B', model = 'dnxprops_furniture_wardrobesmall01_b', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_furn_wardrobe_sm_c'] = { name = 'Small Wardrobe C', model = 'dnxprops_furniture_wardrobesmall01_c', tag = 'DNX Furniture', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Home
    ['dnx_home_aftershave'] = { name = 'Aftershave', model = 'dnxprops_home_aftershave01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_barberbrush'] = { name = 'Barber Brush', model = 'dnxprops_home_barberbrush01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_bathorganizer'] = { name = 'Bathroom Organizer', model = 'dnxprops_home_bathroomorganizer01_a_empty', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_ceramicbowl_a'] = { name = 'Ceramic Bowl A', model = 'dnxprops_home_ceramicbowl01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_ceramicbowl_b'] = { name = 'Ceramic Bowl B', model = 'dnxprops_home_ceramicbowl01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_ceramicbowl_c'] = { name = 'Ceramic Bowl C', model = 'dnxprops_home_ceramicbowl01_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_contactcase'] = { name = 'Contact Lens Case', model = 'dnxprops_home_contactlensescase', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_deskorg01_a'] = { name = 'Desk Organizer #1 A', model = 'dnxprops_home_deskorganizer01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_deskorg01_b'] = { name = 'Desk Organizer #1 B', model = 'dnxprops_home_deskorganizer01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_deskorg01_c'] = { name = 'Desk Organizer #1 C', model = 'dnxprops_home_deskorganizer01_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_deskorg02_a'] = { name = 'Desk Organizer #2 A', model = 'dnxprops_home_deskorganizer02_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_deskorg02_b'] = { name = 'Desk Organizer #2 B', model = 'dnxprops_home_deskorganizer02_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_deskorg02_c'] = { name = 'Desk Organizer #2 C', model = 'dnxprops_home_deskorganizer02_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_diecastrhino'] = { name = 'Diecast Rhino', model = 'dnxprops_home_diecastrhino', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_bathscale_a'] = { name = 'Bathroom Scale A', model = 'dnxprops_home_digitalbathroomscale01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_bathscale_b'] = { name = 'Bathroom Scale B', model = 'dnxprops_home_digitalbathroomscale01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_jarcoffee_a'] = { name = 'Coffee Jar A', model = 'dnxprops_home_jarcoffee01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_jarcoffee_b'] = { name = 'Coffee Jar B', model = 'dnxprops_home_jarcoffee01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_jarsalt_a'] = { name = 'Salt Jar A', model = 'dnxprops_home_jarsalt01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_jarsalt_b'] = { name = 'Salt Jar B', model = 'dnxprops_home_jarsalt01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_jarsugar_a'] = { name = 'Sugar Jar A', model = 'dnxprops_home_jarsugar01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_jarsugar_b'] = { name = 'Sugar Jar B', model = 'dnxprops_home_jarsugar01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_lantern01'] = { name = 'Lantern #1', model = 'dnxprops_home_lantern01_a_empty', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_lantern02'] = { name = 'Lantern #2', model = 'dnxprops_home_lantern02_a_empty', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_liquidsoap'] = { name = 'Liquid Soap', model = 'dnxprops_home_liquidsoap01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror01_a'] = { name = 'Mirror #1 A', model = 'dnxprops_home_mirror01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror01_b'] = { name = 'Mirror #1 B', model = 'dnxprops_home_mirror01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror01_c'] = { name = 'Mirror #1 C', model = 'dnxprops_home_mirror01_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror02_a'] = { name = 'Mirror #2 A', model = 'dnxprops_home_mirror02_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror02_b'] = { name = 'Mirror #2 B', model = 'dnxprops_home_mirror02_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror02_c'] = { name = 'Mirror #2 C', model = 'dnxprops_home_mirror02_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror03_a'] = { name = 'Mirror #3 A', model = 'dnxprops_home_mirror03_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror03_b'] = { name = 'Mirror #3 B', model = 'dnxprops_home_mirror03_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror03_c'] = { name = 'Mirror #3 C', model = 'dnxprops_home_mirror03_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror04_a'] = { name = 'Mirror #4 A', model = 'dnxprops_home_mirror04_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror04_b'] = { name = 'Mirror #4 B', model = 'dnxprops_home_mirror04_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mirror04_c'] = { name = 'Mirror #4 C', model = 'dnxprops_home_mirror04_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_mouthwash'] = { name = 'Mouthwash', model = 'dnxprops_home_mouthwash01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_picture01'] = { name = 'Picture #1', model = 'dnxprops_home_picture01', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_picture02'] = { name = 'Picture #2', model = 'dnxprops_home_picture02', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_picture03'] = { name = 'Picture #3', model = 'dnxprops_home_picture03', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_picture04'] = { name = 'Picture #4', model = 'dnxprops_home_picture04', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_picture05'] = { name = 'Picture #5', model = 'dnxprops_home_picture05', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_picture06'] = { name = 'Picture #6', model = 'dnxprops_home_picture06', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_strawcup'] = { name = 'Straw Cup', model = 'dnxprops_home_strawcup', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_toiletbrush01'] = { name = 'Toilet Brush #1', model = 'dnxprops_home_toiletbrush01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_toiletbrush02'] = { name = 'Toilet Brush #2', model = 'dnxprops_home_toiletbrush02_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_towelrail_a'] = { name = 'Towel Rail A', model = 'dnxprops_home_towelrail01_a', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_towelrail_b'] = { name = 'Towel Rail B', model = 'dnxprops_home_towelrail01_b', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_towelrail_c'] = { name = 'Towel Rail C', model = 'dnxprops_home_towelrail01_c', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_home_umbrellastand'] = { name = 'Umbrella Stand', model = 'dnxprops_home_umbrellastand01', tag = 'DNX Home', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Lighting
    ['dnx_light_ceiling01'] = { name = 'Ceiling Light #1', model = 'dnxprops_lighting_ceilinglight01_a', tag = 'DNX Lighting', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_light_ceiling01_24h'] = { name = 'Ceiling Light #1 (24h)', model = 'dnxprops_lighting_ceilinglight01_a_24h', tag = 'DNX Lighting', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_light_ceiling02'] = { name = 'Ceiling Light #2', model = 'dnxprops_lighting_ceilinglight02_a', tag = 'DNX Lighting', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_light_picket01'] = { name = 'Picket Light #1', model = 'dnxprops_lighting_picketlight01_a', tag = 'DNX Lighting', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_light_picket02'] = { name = 'Picket Light #2', model = 'dnxprops_lighting_picketlight02_a', tag = 'DNX Lighting', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Music
    ['dnx_music_guitar_a'] = { name = 'Guitar Wall Mount A', model = 'dnxprops_music_guitarwallmount01_a', tag = 'DNX Music', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_music_guitar_b'] = { name = 'Guitar Wall Mount B', model = 'dnxprops_music_guitarwallmount01_b', tag = 'DNX Music', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_music_keyboard'] = { name = 'Keyboard (88 Keys)', model = 'dnxprops_music_keyboard01_a_88', tag = 'DNX Music', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_music_kbstand'] = { name = 'Keyboard Stand', model = 'dnxprops_music_keyboardstand01_a', tag = 'DNX Music', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Gaming Chairs
    ['dnx_tech_chair_black'] = { name = 'Gaming Chair (Black)', model = 'dnxprops_tech_gamingchair01_black', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_blue'] = { name = 'Gaming Chair (Blue)', model = 'dnxprops_tech_gamingchair01_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_green'] = { name = 'Gaming Chair (Green)', model = 'dnxprops_tech_gamingchair01_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_pink'] = { name = 'Gaming Chair (Pink)', model = 'dnxprops_tech_gamingchair01_pink', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_purple'] = { name = 'Gaming Chair (Purple)', model = 'dnxprops_tech_gamingchair01_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_red'] = { name = 'Gaming Chair (Red)', model = 'dnxprops_tech_gamingchair01_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_white'] = { name = 'Gaming Chair (White)', model = 'dnxprops_tech_gamingchair01_white', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_chair_yellow'] = { name = 'Gaming Chair (Yellow)', model = 'dnxprops_tech_gamingchair01_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Gaming Keyboards
    ['dnx_tech_kb_a_blue'] = { name = 'Gaming Keyboard A (Blue)', model = 'dnxprops_tech_gamingkeyboard01_a_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_cyan'] = { name = 'Gaming Keyboard A (Cyan)', model = 'dnxprops_tech_gamingkeyboard01_a_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_green'] = { name = 'Gaming Keyboard A (Green)', model = 'dnxprops_tech_gamingkeyboard01_a_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_off'] = { name = 'Gaming Keyboard A (Off)', model = 'dnxprops_tech_gamingkeyboard01_a_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_purple'] = { name = 'Gaming Keyboard A (Purple)', model = 'dnxprops_tech_gamingkeyboard01_a_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_red'] = { name = 'Gaming Keyboard A (Red)', model = 'dnxprops_tech_gamingkeyboard01_a_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_rgb1'] = { name = 'Gaming Keyboard A (RGB #1)', model = 'dnxprops_tech_gamingkeyboard01_a_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_rgb2'] = { name = 'Gaming Keyboard A (RGB #2)', model = 'dnxprops_tech_gamingkeyboard01_a_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_a_yellow'] = { name = 'Gaming Keyboard A (Yellow)', model = 'dnxprops_tech_gamingkeyboard01_a_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_blue'] = { name = 'Gaming Keyboard B (Blue)', model = 'dnxprops_tech_gamingkeyboard01_b_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_cyan'] = { name = 'Gaming Keyboard B (Cyan)', model = 'dnxprops_tech_gamingkeyboard01_b_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_green'] = { name = 'Gaming Keyboard B (Green)', model = 'dnxprops_tech_gamingkeyboard01_b_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_off'] = { name = 'Gaming Keyboard B (Off)', model = 'dnxprops_tech_gamingkeyboard01_b_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_purple'] = { name = 'Gaming Keyboard B (Purple)', model = 'dnxprops_tech_gamingkeyboard01_b_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_red'] = { name = 'Gaming Keyboard B (Red)', model = 'dnxprops_tech_gamingkeyboard01_b_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_rgb1'] = { name = 'Gaming Keyboard B (RGB #1)', model = 'dnxprops_tech_gamingkeyboard01_b_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_rgb2'] = { name = 'Gaming Keyboard B (RGB #2)', model = 'dnxprops_tech_gamingkeyboard01_b_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_kb_b_yellow'] = { name = 'Gaming Keyboard B (Yellow)', model = 'dnxprops_tech_gamingkeyboard01_b_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Gaming Monitors
    ['dnx_tech_mon_a_off'] = { name = 'Gaming Monitor A (Off)', model = 'dnxprops_tech_gamingmonitor01_a_27_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wp1'] = { name = 'Gaming Monitor A (WP1)', model = 'dnxprops_tech_gamingmonitor01_a_27_wp1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wp2'] = { name = 'Gaming Monitor A (WP2)', model = 'dnxprops_tech_gamingmonitor01_a_27_wp2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wpc1'] = { name = 'Gaming Monitor A (Custom #1)', model = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wpc2'] = { name = 'Gaming Monitor A (Custom #2)', model = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wpc3'] = { name = 'Gaming Monitor A (Custom #3)', model = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom3', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wpc4'] = { name = 'Gaming Monitor A (Custom #4)', model = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom4', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_a_wpc5'] = { name = 'Gaming Monitor A (Custom #5)', model = 'dnxprops_tech_gamingmonitor01_a_27_wpcustom5', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_off'] = { name = 'Gaming Monitor B (Off)', model = 'dnxprops_tech_gamingmonitor01_b_27_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wp1'] = { name = 'Gaming Monitor B (WP1)', model = 'dnxprops_tech_gamingmonitor01_b_27_wp1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wp2'] = { name = 'Gaming Monitor B (WP2)', model = 'dnxprops_tech_gamingmonitor01_b_27_wp2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wpc1'] = { name = 'Gaming Monitor B (Custom #1)', model = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wpc2'] = { name = 'Gaming Monitor B (Custom #2)', model = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wpc3'] = { name = 'Gaming Monitor B (Custom #3)', model = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom3', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wpc4'] = { name = 'Gaming Monitor B (Custom #4)', model = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom4', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mon_b_wpc5'] = { name = 'Gaming Monitor B (Custom #5)', model = 'dnxprops_tech_gamingmonitor01_b_27_wpcustom5', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Gaming Mice
    ['dnx_tech_mouse_a_blue'] = { name = 'Gaming Mouse A (Blue)', model = 'dnxprops_tech_gamingmouse01_a_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_cyan'] = { name = 'Gaming Mouse A (Cyan)', model = 'dnxprops_tech_gamingmouse01_a_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_green'] = { name = 'Gaming Mouse A (Green)', model = 'dnxprops_tech_gamingmouse01_a_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_off'] = { name = 'Gaming Mouse A (Off)', model = 'dnxprops_tech_gamingmouse01_a_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_purple'] = { name = 'Gaming Mouse A (Purple)', model = 'dnxprops_tech_gamingmouse01_a_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_red'] = { name = 'Gaming Mouse A (Red)', model = 'dnxprops_tech_gamingmouse01_a_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_rgb1'] = { name = 'Gaming Mouse A (RGB #1)', model = 'dnxprops_tech_gamingmouse01_a_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_rgb2'] = { name = 'Gaming Mouse A (RGB #2)', model = 'dnxprops_tech_gamingmouse01_a_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_a_yellow'] = { name = 'Gaming Mouse A (Yellow)', model = 'dnxprops_tech_gamingmouse01_a_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_blue'] = { name = 'Gaming Mouse B (Blue)', model = 'dnxprops_tech_gamingmouse01_b_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_cyan'] = { name = 'Gaming Mouse B (Cyan)', model = 'dnxprops_tech_gamingmouse01_b_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_green'] = { name = 'Gaming Mouse B (Green)', model = 'dnxprops_tech_gamingmouse01_b_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_off'] = { name = 'Gaming Mouse B (Off)', model = 'dnxprops_tech_gamingmouse01_b_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_purple'] = { name = 'Gaming Mouse B (Purple)', model = 'dnxprops_tech_gamingmouse01_b_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_red'] = { name = 'Gaming Mouse B (Red)', model = 'dnxprops_tech_gamingmouse01_b_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_rgb1'] = { name = 'Gaming Mouse B (RGB #1)', model = 'dnxprops_tech_gamingmouse01_b_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_rgb2'] = { name = 'Gaming Mouse B (RGB #2)', model = 'dnxprops_tech_gamingmouse01_b_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_mouse_b_yellow'] = { name = 'Gaming Mouse B (Yellow)', model = 'dnxprops_tech_gamingmouse01_b_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Gaming Mousepads
    ['dnx_tech_pad_blue'] = { name = 'Gaming Mousepad (Blue)', model = 'dnxprops_tech_gamingmousepad01_a_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_cyan'] = { name = 'Gaming Mousepad (Cyan)', model = 'dnxprops_tech_gamingmousepad01_a_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_green'] = { name = 'Gaming Mousepad (Green)', model = 'dnxprops_tech_gamingmousepad01_a_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_off'] = { name = 'Gaming Mousepad (Off)', model = 'dnxprops_tech_gamingmousepad01_a_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_purple'] = { name = 'Gaming Mousepad (Purple)', model = 'dnxprops_tech_gamingmousepad01_a_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_red'] = { name = 'Gaming Mousepad (Red)', model = 'dnxprops_tech_gamingmousepad01_a_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_rgb1'] = { name = 'Gaming Mousepad (RGB #1)', model = 'dnxprops_tech_gamingmousepad01_a_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_rgb2'] = { name = 'Gaming Mousepad (RGB #2)', model = 'dnxprops_tech_gamingmousepad01_a_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pad_yellow'] = { name = 'Gaming Mousepad (Yellow)', model = 'dnxprops_tech_gamingmousepad01_a_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - Gaming PCs
    ['dnx_tech_pc_a_blue'] = { name = 'Gaming PC A (Blue)', model = 'dnxprops_tech_gamingpc01_a_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_cyan'] = { name = 'Gaming PC A (Cyan)', model = 'dnxprops_tech_gamingpc01_a_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_green'] = { name = 'Gaming PC A (Green)', model = 'dnxprops_tech_gamingpc01_a_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_off'] = { name = 'Gaming PC A (Off)', model = 'dnxprops_tech_gamingpc01_a_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_purple'] = { name = 'Gaming PC A (Purple)', model = 'dnxprops_tech_gamingpc01_a_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_red'] = { name = 'Gaming PC A (Red)', model = 'dnxprops_tech_gamingpc01_a_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_rgb1'] = { name = 'Gaming PC A (RGB #1)', model = 'dnxprops_tech_gamingpc01_a_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_rgb2'] = { name = 'Gaming PC A (RGB #2)', model = 'dnxprops_tech_gamingpc01_a_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_a_yellow'] = { name = 'Gaming PC A (Yellow)', model = 'dnxprops_tech_gamingpc01_a_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_blue'] = { name = 'Gaming PC B (Blue)', model = 'dnxprops_tech_gamingpc01_b_blue', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_cyan'] = { name = 'Gaming PC B (Cyan)', model = 'dnxprops_tech_gamingpc01_b_cyan', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_green'] = { name = 'Gaming PC B (Green)', model = 'dnxprops_tech_gamingpc01_b_green', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_off'] = { name = 'Gaming PC B (Off)', model = 'dnxprops_tech_gamingpc01_b_off', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_purple'] = { name = 'Gaming PC B (Purple)', model = 'dnxprops_tech_gamingpc01_b_purple', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_red'] = { name = 'Gaming PC B (Red)', model = 'dnxprops_tech_gamingpc01_b_red', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_rgb1'] = { name = 'Gaming PC B (RGB #1)', model = 'dnxprops_tech_gamingpc01_b_rgb1', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_rgb2'] = { name = 'Gaming PC B (RGB #2)', model = 'dnxprops_tech_gamingpc01_b_rgb2', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pc_b_yellow'] = { name = 'Gaming PC B (Yellow)', model = 'dnxprops_tech_gamingpc01_b_yellow', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

    -- DNX Addon Props - PC Parts
    ['dnx_tech_pccase_a'] = { name = 'PC Case A', model = 'dnxprops_tech_gamingpccase01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pccase_b'] = { name = 'PC Case B', model = 'dnxprops_tech_gamingpccase01_b', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcfan_a'] = { name = 'PC Fan A', model = 'dnxprops_tech_gamingpcfan01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcfan_b'] = { name = 'PC Fan B', model = 'dnxprops_tech_gamingpcfan01_b', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcgpu_a'] = { name = 'GPU A', model = 'dnxprops_tech_gamingpcgpu01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcgpu_b'] = { name = 'GPU B', model = 'dnxprops_tech_gamingpcgpu01_b', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcmboard'] = { name = 'Motherboard', model = 'dnxprops_tech_gamingpcmotherboard01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcram_a'] = { name = 'RAM A', model = 'dnxprops_tech_gamingpcram01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcram_b'] = { name = 'RAM B', model = 'dnxprops_tech_gamingpcram01_b', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcssd_a'] = { name = 'SSD A', model = 'dnxprops_tech_gamingpcssd01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcssd_b'] = { name = 'SSD B', model = 'dnxprops_tech_gamingpcssd01_b', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcssd_c'] = { name = 'SSD C', model = 'dnxprops_tech_gamingpcssd01_c', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_pcssd_d'] = { name = 'SSD D', model = 'dnxprops_tech_gamingpcssd01_d', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_speaker'] = { name = 'PC Speaker', model = 'dnxprops_tech_pcspeaker01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },
    ['dnx_tech_subwoofer'] = { name = 'PC Subwoofer', model = 'dnxprops_tech_pcsubwoofer01_a', tag = 'DNX Tech', offset = { pos = vec3(0,0,0), heading = 0 } },

}

Settings.doors = {
    ['0'] = {
        name = 'Apartment door #1',
        model = 'v_ilev_j2_door',
    },
    ['1'] = {
        name = 'Apartment door #2',
        model = 'v_ilev_ra_door2',
    },
    ['2'] = {
        name = 'Apartment door #3',
        model = 'v_ilev_housedoor1',
        flipped = true,
    },
    ['3'] = {
        name = 'Apartment door #4',
        model = 'ex_p_mp_door_office_door01',
        flipped = true,
    },
    ['4'] = {
        name = 'Apartment door #5',
        model = 'sum_p_mp_yacht_door_01',
        flipped = true,
    },
    ['5'] = {
        name = 'Apartment door #6',
        model = 'ex_p_mp_door_apart_door_black',
        flipped = true,
    },
    ['6'] = {
        name = 'White door #1',
        model = 'v_ilev_janitor_frontdoor',
    },
    ['7'] = {
        name = 'Hi-sec Door',
        model = 'v_ilev_gtdoor02',
    },
    ['8'] = {
        name = 'Glass door #1',
        model = 'v_ilev_ph_gendoor002',
        flipped = true,
    },
    ['9'] = {
        name = 'Glass door #2',
        model = 'xm_prop_facility_door_01',
    },
    ['10'] = {
        name = 'Padded Door',
        model = 'ba_prop_door_club_edgy_generic',
    },
    ['11'] = {
        name = 'Bathroom Door',
        model = 'ba_prop_door_club_trad_wc',
    },
    ['12'] = {
        name = 'Bathroom Door #2',
        model = 'h4_prop_door_club_glam_wc',
    },
    ['13'] = {
        name = 'Scuffed Door #1',
        model = 'v_ilev_ss_door02',
        flipped = true,
    },
    ['14'] = {
        name = 'Scuffed Door #2',
        model = 'v_ilev_vagostoiletdoor',
    },
    ['15'] = {
        name = 'Scuffed Door #3',
        model = 'v_ilev_trev_doorfront',
        flipped = true,
    },
    ['16'] = {
        name = 'Staff Door',
        model = 'vw_prop_vw_casino_door_01c',
    },
    ['17'] = {
        name = 'Private Door',
        model = 'v_ilev_mldoor02',
        flipped = true,
    },

    ['18'] = {
        name = 'Workshop Door',
        model = 'xs_prop_x18_garagedoor02',
    },
    ['19'] = {
        name = 'Black Door',
        model = 'tr_prop_tr_door3',
        flipped = true,
    },
    ['20'] = {
        name = 'Generic Door',
        model = 'ba_prop_door_club_trad_generic',
    },
    ['21'] = {
        name = 'Scuffed Door #4',
        model = 'prop_ret_door_02',
        flipped = true,
    },
}
