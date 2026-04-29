Config = {}
Config.Debug = true
Config.TowCommand = 'towControl'
Config.JobName = 'tow'
Config.Contact = {
    identifier = 'towContact',
    name = 'Naveed Carr',
    avatar = 'https://files.fivemerr.com/images/303c36b5-0730-4d9f-b1c8-e61725a233d3.png',
    coords = vector3(495.82, -1340.88, 29.31), -- vector3(495.82, -1340.88, 29.31)
    description = 'Come talk to me to get started with the world of towing.',
    default = true,
    max = 5,
}
Config.ContactPed = {
    model = `IG_Mechanic_03`,
    coords = vector4(495.82, -1340.88, 28.31, 356.26),
    distance = 33.0,
    freeze = true,
    scenario = 'WORLD_HUMAN_AA_SMOKE',
}

Config.TargetOptions = {
    distance = 2.5,
    options = {
        {
            name = 'towContact',
            icon = 'fas fa-comments',
            label = 'Talk',
            action = function(data)
                exports['sd-dialog']:Open({
                    entity = data,
                    name = Config.Contact.name,
                    role = 'Tow Dispatch',
                    roleColor = '#f59e0b',
                    description = Config.Contact.description,
                    options = {
                        {
                            id = 'start_job',
                            label = 'Start Towing',
                            icon = 'truck',
                            description = 'Get a tow assignment.',
                            -- clientEvent = 'nt_tow:startJob',
                        },
                    },
                })
            end,
        },
    },
}