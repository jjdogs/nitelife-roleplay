if (Config.Framework == "auto" and GetResourceState("qbx_core") == "started") or Config.Framework == "Qbox" then
  -- Player data
  Globals.PlayerData = exports.qbx_core:GetPlayerData()

  AddStateBagChangeHandler("isLoggedIn", ("player:%s"):format(cache.serverId), function(_, _, loggedIn)
    if loggedIn then
      DebugPrint("[QBX] isLoggedIn state bag changed to true")
      Globals.PlayerData = exports.qbx_core:GetPlayerData()
    end
    LocalPlayer.state:set("jgDealershipsPlayerLoggedIn", loggedIn)
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
end