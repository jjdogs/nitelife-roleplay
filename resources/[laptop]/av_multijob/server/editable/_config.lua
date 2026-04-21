Config = Config or {}
-- Max number of jobs a player can have simultaneously.
-- If you are not using Qbox, simply change the fallback value (3) to your desired limit.
Config.DefaultMaxJobs = GetConvarInt('qbx:max_jobs_per_player', 3)
Config.CustomMaxJobs = { -- Player identifier to overwrite the default max jobs
    ["F197ZVW4"] = 6,
}