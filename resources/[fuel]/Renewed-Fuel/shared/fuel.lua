return {
    engineBlowUp = {
        canBlow  = true, -- Can blow if the vehicle engine is on while refueling?
        chance   = 0.03,  -- Chance of blowing up 3% (This is calculated per tick so its 3% per tick, and there's always 100 ticks per refuel)
    },

    blipSize = 0.8, -- Size of the blip for the gas station
    useGasStationCategory = true, -- Group all gas stations under the same category
    gasStationName = false, -- If you want all gas stations to use a certain name you can replace gasStationName with any name such as gasStationName = 'Gas Station'
    adminPerms = 'group.admin',

    electricCars = {
        `surge`,
        `iwagen`,
        `voltic`,
        `voltic2`,
        `raiden`,
        `cyclone`,
        `tezeract`,
        `neon`,
        `omnisegt`,
        `caddy`,
        `caddy2`,
        `caddy3`,
        `airtug`,
        `rcbandito`,
        `imorgon`,
        `dilettante`,
        `khamelion`
    },

    -- The higher the number the higher the car is throttling and the higher fuel composition is used.
    vehicleRpm = {
        [1.0] = 1.0,
        [0.9] = 0.8,
        [0.8] = 0.6,
        [0.7] = 0.5,
        [0.6] = 0.4,
        [0.5] = 0.3,
        [0.4] = 0.2,
        [0.3] = 0.1,
        [0.2] = 0.05,
        [0.1] = 0.05,
        [0.0] = 0.05,
	},

    --[[
        Buffs are the things that can affect the vehicle (like speed, acceleration, etc) all done via handling.
        To create a buff simply have the key be the handling type you want to modify.
        and the value be the amount you want to modify it by.

        example:
        Adder - fInitialDriveMaxFlatVel is 180, and if the fuel adds 120, it becomes 300.
    ]]

    fuelTypes = {
        ['86'] = {
            usage = 1.0, -- 100% of normal usage
            buffs = {

            }
        },
        ['89'] = {
            usage = 0.8, -- 80% of normal usage
            buffs = {
                fInitialDriveMaxFlatVel = 30.0,
            }
        },
        ['92'] = {
            usage = 0.6, -- 60% of normal usage
            buffs = {
                fInitialDriveMaxFlatVel = 60.0,
            }
        },
        ['95'] = {
            usage = 0.4, -- 40% of normal usage
            buffs = {
                fInitialDriveMaxFlatVel = 90.0,
            }
        },
        ['100'] = {
            usage = 0.1, -- 10% of normal usage (This one is meant for electric cars)
        }
    },


    --[[
        vehicles config, here you can make specific fuel consumption for each vehicle.
        usage is the same usage as the classes below, but this is for specific vehicles.
        rpm is the same as vehicleRpm but for specific vehicles.
        MAKE SURE TO USE `` INSTEAD OF "" OR '' FOR VEHICLE NAMES!
    ]]
    vehicles = {
        [`maverick`] = {
            usage = 0.1,
            rpm = {
                [1.0] = 1.0,
                [0.9] = 0.8,
                [0.8] = 0.6,
                [0.7] = 0.5,
                [0.6] = 0.4,
                [0.5] = 0.3,
                [0.4] = 0.2,
                [0.3] = 0.1,
                [0.2] = 0.05,
                [0.1] = 0.05,
                [0.0] = 0.05,
            }
        },
    },

    classes = {
        0.7, -- Compacts
        0.7, -- Sedans
        0.7, -- SUVs
        0.7, -- Coupes
        0.7, -- Muscle
        0.7, -- Sports Classics
        0.7, -- Sports
        0.7, -- Super
        0.7, -- Motorcycles
        0.7, -- Off-road
        0.7, -- Industrial
        0.7, -- Utility
        0.7, -- Vans
        0.0, -- Cycles
        1.0, -- Boats
        1.0, -- Helicopters
        0.7, -- Planes
        0.7, -- Service
        0.7, -- Emergency
        0.7, -- Military
        0.7, -- Commercial
        0.7, -- Trains
        0.7, -- Open Wheel
    }
}