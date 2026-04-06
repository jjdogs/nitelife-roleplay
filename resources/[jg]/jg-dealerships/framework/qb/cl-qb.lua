if (Config.Framework == "auto" and GetResourceState("qb-core") == "started") or Config.Framework == "QBCore" then
  -- Player data
  Globals.PlayerData = QBCore.Functions.GetPlayerData()

  RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Globals.PlayerData = QBCore.Functions.GetPlayerData()
    LocalPlayer.state:set("jgDealershipsPlayerLoggedIn", true)
  end)

  RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    LocalPlayer.state:set("jgDealershipsPlayerLoggedIn", false)
  end)

  RegisterNetEvent("QBCore:Client:OnJobUpdate")
  AddEventHandler("QBCore:Client:OnJobUpdate", function(job)
    Globals.PlayerData.job = job
    Locations.Client.RecreatePermissionRestrictedInteractions()
  end)

  RegisterNetEvent("QBCore:Client:OnGangUpdate")
  AddEventHandler("QBCore:Client:OnGangUpdate", function(gang)
    Globals.PlayerData.gang = gang
    Locations.Client.RecreatePermissionRestrictedInteractions()
  end)

  -- For jacksam's job creator
  RegisterNetEvent("jobs_creator:injectJobs", function(jobs)
    QBCore.Jobs = jobs
  end)
end