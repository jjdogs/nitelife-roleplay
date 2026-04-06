return {

    speed = 250, -- 250ms per gallon

    GasPumpModels = {
        [`prop_gas_pump_1d`] = true,
        [`prop_gas_pump_1a`] = true,
        [`prop_gas_pump_1b`] = true,
        [`prop_gas_pump_1c`] = true,
        [`prop_vintage_pump`] = true,
        [`prop_gas_pump_old2`] = true,
        [`prop_gas_pump_old3`] = true,
        [`denis3d_prop_gas_pump`] = true,
    },

    bones = {
        'petrolcap',
        'petroltank',
        'petroltank_l',
        'hub_lr',
        'engine',
    },

    upgrades = {
        {
            price = 0,
            speed = 1.0
        },
        {
            price = 10000,
            speed = 0.95 -- 5% faster
        },
        {
            price = 20000,
            speed = 0.9 -- 10% faster
        },
        {
            price = 40000,
            speed = 0.85 -- 15% faster
        },
        {
            price = 80000,
            speed = 0.8 -- 20% faster
        },
        {
            price = 160000,
            speed = 0.7 -- 30% faster
        },
        {
            price = 320000,
            speed = 0.6 -- 40% faster
        },
    }
}