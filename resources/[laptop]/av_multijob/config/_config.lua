Config = Config or {}
Config.Debug = true
Config.Command = "multijob" -- Command used to open menu or false to disable it
Config.MenuKey = "K" -- Key to open menu or false to disable it
Config.AdminGroups = {"group.admin", "group.god"} -- Used for commands /setjob /addjob and /removejob
Config.UnemployedJobName = "unemployed" -- Your unemployed job name, used when someone leaves their current job we will set this one
Config.ToggleAVBusinessDuty = true -- toggle av_business duty service when clock in/out, false if not using av_business OR you prefer the traditional duty zone
Config.IgnoredJobs = { -- Jobs to ignore, won't be shown in the menu and won't be added to player_groups table
    ['unemployed'] = true,
    ['civilian'] = true,
}
Config.RestrictedJobs = { -- Jobs where the player can't toggle duty status or quit directly... for ppl using gangs as jobs (?)
    ['ballas'] = true,
    ['vagos'] = true,
}

function dbug(...)
    if Config.Debug then print ('^3[DEBUG]^7', ...) end
end

function warn(...)
    print ('^1[WARNING]^7', ...)
end