-- Business blips, players can toggle on/off their own blip to let know other players if the business is open/closed
Config = Config or {}
Config.Blips = {
    -- index key needs to be named exactly like the job name
    -- blips sprites and colors: https://docs.fivem.net/docs/game-references/blips/
    -- online means the blip will be enable/disable by default
    ['burgershot'] = { x = -1194.764, y = -895.92, z = 13.89, label = "Burgershot", sprite = 536, color = 6, online = true },
}

