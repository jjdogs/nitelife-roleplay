-- Spawn ped
--- @param model string Model
--- @param position vector4 Position
--- @return number Ped entity
local function SpawnPed(model, position)
    lib.requestModel(model)
    local ped = CreatePed(0, model, position.x, position.y, position.z - 1.0, position.w, false, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    return ped
end

-- Delete ped
--- @param ped number Ped entity
local function DeletePed(ped)
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

return {
    SpawnPed = SpawnPed,
    DeletePed = DeletePed
}