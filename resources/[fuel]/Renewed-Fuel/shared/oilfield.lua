return {

    maxBlend = 5000,
    maxPump = 1000, -- How much oil can be pumped to the at a time

    fieldTimers = {
        temp = {min = 0, max = 2}, -- how much heat can be added/removed per second
        pump = {min = 1, max = 5} -- how much oil can be pumped per second from storage to controller
    },


    OilFieldTimers = {
        -- This means that every 1 second the temperature of the disterilizer will increase by 1 degree
        heat = {min = 0, max = 2},

        -- This means that every 1 second the temperature of the disterilizer will decrease by 1 degree
        cool = {min = 0, max = 2},

        -- This means that every 1 second the oil will be pumped to/from storage
        pump = {min = 3, max = 6},
    },

    controlProps = `prop_rail_controller`, -- You can put whatever prop you have for this, if you have npas-props use prop_oil_controller
    barrelCost = 500, -- How much does a barrel cost to buy

    Controllers = {
        blendingPool = vector4(1683.74, -1710.29, 111.54, 98.05),
        storage = vector4(1698.73, -1611.52, 111.47, 10.4),
        distillery = vector4(1674.27, -1649.78, 110.32, 11.0)
    },

    ped = {
        coords = vec3(1743.077, -1629.468, 111.430),
        heading = 104.982,
        model = `s_m_y_airworker`,
    },

    Blips = {
        {
            name = 'Oil Storage',
            id = 289,
            colour = 28,
            coords = vector3(1698.73, -1611.52, 111.47),
            scale = 0.6
        },
        {
            name = 'Oil Distillery',
            id = 355,
            colour = 42,
            coords = vector3(1674.27, -1649.78, 110.32),
            scale = 0.6
        },
        {
            name = 'Oil Blending Pool',
            id = 106,
            colour = 26,
            coords = vector3(1683.74, -1710.29, 111.54),
            scale = 0.6
        }
    },


    -- Distillery settings, such as temperature to turn into light/heavy neptha or other gasses
    Distillery = {
        LightNeptha = {
            min = 25,
            max = 150,
            normal = true
        },
        HeavyNeptha = {
            min = 25,
            max = 150,
            premium = true
        },
        other = {
            min = 150,
            max = 350,
            normal = true
        },
    },

    --[[
        Recipes are chosen based off the amount of HeavyNeptha there's in the recipe.
        DO NOT MAKE MOULTIPLE HEAVY NEPTHA RECIPES WITH THE SAME AMOUNT OF HEAVY NEPTHA (EXCEPT FOR WHEN U USE NORMAL AND PREMIUM FUEL)

        the amount of light/normal/heavy ALWAYS needs to be equal to 100

        If you change this around please do thoroguh testing to make sure it works as intended and that it doesn't break the recipes completely so change at your own risk
    ]]
    OilSettings = {
        {
            normal = true,
            LightNeptha = 40,
            HeavyNeptha = 0,
            other = 60,
            fuelType = '86'
        },
        {
            normal = true,
            LightNeptha = 60,
            HeavyNeptha = 10,
            other = 30,
            fuelType = '89'
        },
        {
            normal = true,
            LightNeptha = 30,
            HeavyNeptha = 30,
            other = 40,
            fuelType = '92'
        },
        {
            premium = true,
            LightNeptha = 30,
            HeavyNeptha = 30,
            other = 40,
            fuelType = '95'
        }
    }
}