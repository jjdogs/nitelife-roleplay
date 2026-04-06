Config.Progress = {
    ["dna_swab"] = {
        progressbar = "Swabbing DNA",
        progresstime = 5000,
        dictionary = "amb@world_human_stand_mobile@male@text@enter",
        animname = "enter",
    },
    ["pick_evidence"] = {
        progressbar = "Picking up evidence",
        progresstime = 1200,
        dictionary = "random@domestic",
        animname = "pickup_low",
    },
    ["cleanup_evidence"] = {
        progressbar = "Cleaning up evidence",
        progresstime = 2000,
        dictionary = "random@domestic",
        animname = "pickup_low",
    },

    ["cleanup_car_evidence"] = {
        progressbar = "Cleaning up evidence",
        progresstime = 25000,
        animname = "base",
        dictionary = "timetable@floyd@clean_kitchen@base",
        disable = {
            car = true,
            move = true,
        },
        prop = {
            {
                bone = 28422,
                model = 'prop_sponge_01',
                pos = vec3(0.0, 0.0, -0.01),
                rot = vec3(90.0, 0.0, 0.0),
            },
        },
    },
    ["clear_nearby"] = {
        progressbar = "Clearing nearby scene",
        progresstime = 8000,
        animname = 'base',
        dictionary = 'anim@amb@drug_field_workers@rake@male_a@base',
        prop = {
            {
                bone = 28422,
                model = 'prop_tool_broom',
                pos = vec3(-0.01, 0.04, -0.03),
                rot = vec3(0.0, 0.0, 0.0),
            },
        },
    },
    ["access_vehicle"] = {
        progressbar = "Accessing Vehicle",
        progresstime = 5000,
        dictionary = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        animname = "machinic_loop_mechandplayer",
    },

    ["checking_gsr"] = {
        progressbar = "Checking GSR",
        progresstime = 5000,
        dictionary = "amb@world_human_stand_mobile@male@text@enter",
        animname = "enter",
    },

    ["cleaning_gsr"] = {
        progressbar = "Cleaning GSR",
        progresstime = 5000,
        dictionary = "missheist_agency3aig_23",
        animname = "urinal_sink_loop",
    },

    ["fingerprint_scanner"] = {
        progressbar = "Scanning Fingerprints",
        progresstime = 5000,
        dictionary = "amb@world_human_stand_mobile@male@text@enter",
        animname = "enter",
    },
}