--- Framework detection and initialization
--- Detects and initializes the supported framework (QBCore or ESX)

local DetectFramework = function()
    if GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    end

    if GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end

    return nil, nil
end

local framework, core = DetectFramework()

if not framework then
    error([[
        ^1CRITICAL ERROR: No supported framework detected!^0
        ^3This resource requires one of the following frameworks:^0
        - QBCore (qb-core)
        - ESX (es_extended)

        Please ensure your framework is started before this resource.
    ]])
    return
end

Framework = framework
Core = core

-- Set framework-specific globals for compatibility
if Framework == 'qb' then
    QBCore = Core
elseif Framework == 'esx' then
    ESX = Core
end

print(string.format("^2[SD-CRAFTING]^0 Framework detected: ^3%s^0", Framework))
