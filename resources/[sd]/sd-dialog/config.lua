return {
    ---@type number Default number of options shown per page (default: 3)
    itemsPerPage = 3,

    ---@type table[] Entity configurations for dialog NPCs
    entities = {
        --[[
        {
            model = 'csb_mweather',
            coords = vector4(195.17, -933.77, 29.69, 144.04),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            spawnDistance = 50.0,
            invincible = true,
            freeze = true,

            dialog = {
                targetIcon = 'fas fa-comments',
                targetLabel = 'Talk to Marcus',
                targetDistance = 2.5,

                name = 'Marcus Webb',
                role = 'FIXER',
                roleColor = '#f59e0b',
                description = "You look like someone who gets things done.",

                options = {
                    {
                        id = 'option1',
                        label = 'First Option',
                        icon = 'briefcase',
                        description = 'Description of the first option.',
                        serverEvent = { 'myResource:option1', 'arg1', 'arg2' },
                    },
                    {
                        id = 'option2',
                        label = 'Second Option',
                        icon = 'package',
                        description = 'Description of the second option.',
                        clientEvent = 'myResource:option2',
                    },
                    {
                        id = 'submenu',
                        label = 'More Options',
                        icon = 'list',
                        description = 'View additional options.',
                        menu = {
                            description = 'Choose an option:',
                            options = {
                                {
                                    id = 'sub1',
                                    label = 'Sub Option 1',
                                    icon = 'circle',
                                    serverEvent = 'myResource:subOption1',
                                },
                                {
                                    id = 'sub2',
                                    label = 'Sub Option 2',
                                    icon = 'square',
                                    serverEvent = 'myResource:subOption2',
                                },
                            },
                        },
                    },
                },
            },
        },
        ]]
    },

    ---@type table[] Model configurations for dialog interactions
    models = {
        --[[
        {
            model = 'cs_bankman',

            dialog = {
                targetIcon = 'fas fa-comments',
                targetLabel = 'Speak',
                targetDistance = 2.0,

                name = 'Bank Teller',
                role = 'EMPLOYEE',
                roleColor = '#3b82f6',
                description = "Welcome to the bank. How may I assist you?",

                options = {
                    {
                        id = 'deposit',
                        label = 'Deposit',
                        icon = 'arrow-down-to-line',
                        description = 'Deposit money into your account.',
                        clientEvent = 'bank:deposit',
                    },
                    {
                        id = 'withdraw',
                        label = 'Withdraw',
                        icon = 'arrow-up-from-line',
                        description = 'Withdraw money from your account.',
                        clientEvent = 'bank:withdraw',
                    },
                },
            },
        },
        ]]
    },
}
