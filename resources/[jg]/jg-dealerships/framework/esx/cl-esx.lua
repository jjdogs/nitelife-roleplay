if (Config.Framework == "auto" and GetResourceState("es_extended") == "started") or Config.Framework == "ESX" then
  -- Player data
  Globals.PlayerData = ESX.GetPlayerData()

  local function onPlayerLoad(xPlayer)
    if xPlayer then Globals.PlayerData = xPlayer end

    lib.waitFor(function()
      return Globals.PlayerData and cache.ped
    end, "Ped has not loaded or GetPlayerData returned false (waited 30 seconds)", 30000)

    LocalPlayer.state:set("jgDealershipsPlayerLoggedIn", true)
  end

  RegisterNetEvent("esx:playerLoaded", onPlayerLoad)
  RegisterNetEvent("esx:onPlayerSpawn", onPlayerLoad)
  RegisterNetEvent("esx:onPlayerLogout", function()
    LocalPlayer.state:set("jgDealershipsPlayerLoggedIn", false)
  end)

  RegisterNetEvent("esx:setJob")
  AddEventHandler("esx:setJob", function(job)
    Globals.PlayerData.job = job
    Locations.Client.RecreatePermissionRestrictedInteractions()
  end)
end
