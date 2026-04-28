local contactPed = SD.Ped.CreatePedAtPoint({
    model = Config.ContactPed.model,
    coords = Config.ContactPed.coords,
    distance = Config.ContactPed.distance,
    freeze = Config.ContactPed.freeze,
    scenario = Config.ContactPed.scenario,
    interactionType = 'target',
    targetOptions = Config.TargetOptions
})
