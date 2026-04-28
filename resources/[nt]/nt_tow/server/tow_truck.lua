RegisterNetEvent('nt_tow:bedCreated', function(vehicleNetId, bedNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    Entity(vehicle).state:set('bedProp', bedNetId, true)
end)

AddEventHandler('entityRemoved', function(entity)
    local bedNetId = Entity(entity).state.bedProp
    if not bedNetId then return end
    local bedEntity = NetworkGetEntityFromNetworkId(bedNetId)
    if DoesEntityExist(bedEntity) then DeleteEntity(bedEntity) end
end)
