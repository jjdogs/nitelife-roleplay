local setup = require 'config.setup'

-- Auto-detect banking system
local function DetectBankingSystem()
    if GetResourceState('okokBanking') == 'started' then
        return 'okokBanking'
    elseif GetResourceState('Renewed-Banking') == 'started' then
        return 'Renewed-Banking'
    elseif GetResourceState('fd_banking') == 'started' then
        return 'fd_banking'
    elseif GetResourceState('tgg-banking') == 'started' then
        return 'tgg-banking'
    elseif GetResourceState('wasabi_banking') == 'started' then
        return 'wasabi_banking'
    end

    if Framework == 'qb' then
        if GetResourceState('qb-banking') == 'started' then
            local version = GetResourceMetadata('qb-banking', 'version', 0)
            if version and tonumber(string.sub(version, 1, 3)) >= 2 then
                return 'qb-banking'
            end
        end
        if GetResourceState('qb-management') == 'started' then
            return 'qb-management'
        end
    elseif Framework == 'esx' then
        if GetResourceState('esx_society') == 'started' then
            return 'esx_addonaccount'
        end
    end

    print('^1[ERROR]: No banking system auto-detected.^0')
    return nil
end

-- Get the banking system to use
local banking = setup.banking == 'auto' and DetectBankingSystem() or setup.banking

-- Get society account balance
--- @param society string Society name
--- @param shopId string|nil Shop ID for tracking
--- @return number
local function GetSocietyBalance(society, shopId)
    if banking == 'qb-banking' then
        return exports['qb-banking']:GetAccountBalance(society) or 0
    elseif banking == 'qb-management' then
        return exports['qb-management']:GetAccount(society) or 0
    elseif banking == 'esx_addonaccount' then
        local balance = promise.new()
        TriggerEvent("esx_society:getSociety", society, function(data)
            if not data then return balance:resolve(0) end

            TriggerEvent("esx_addonaccount:getSharedAccount", data.account, function(account)
                return balance:resolve(account.money)
            end)
        end)
        return Citizen.Await(balance)
    elseif banking == 'Renewed-Banking' then
        return exports['Renewed-Banking']:getAccountMoney(society) or 0
    elseif banking == 'okokBanking' then
        return exports.okokBanking:GetAccount(society) or 0
    elseif banking == 'fd_banking' then
        return exports.fd_banking:GetAccount(society) or 0
    elseif banking == 'tgg-banking' then
        return exports['tgg-banking']:GetSocietyAccountMoney(society) or 0
    elseif banking == 'wasabi_banking' then
        return exports.wasabi_banking:GetAccountBalance(society, 'society') or 0
    else
        -- Add custom banking here
    end
    return 0
end

-- Add money to society account
--- @param society string Society name
--- @param amount number Amount to add
--- @param shopId string|nil Shop ID for tracking
local function AddSocietyMoney(society, amount, shopId)
    if banking == 'qb-banking' then
        exports['qb-banking']:AddMoney(society, amount)
    elseif banking == 'qb-management' then
        exports['qb-management']:AddMoney(society, amount)
    elseif banking == 'esx_addonaccount' then
        TriggerEvent("esx_society:getSociety", society, function(data)
            TriggerEvent("esx_addonaccount:getSharedAccount", data.account, function(account)
                account.addMoney(amount)
            end)
        end)
    elseif banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:addAccountMoney(society, amount)
    elseif banking == 'okokBanking' then
        exports.okokBanking:AddMoney(society, amount)
    elseif banking == 'fd_banking' then
        exports.fd_banking:AddMoney(society, amount)
    elseif banking == 'tgg-banking' then
        exports['tgg-banking']:AddSocietyMoney(society, amount)
    elseif banking == 'wasabi_banking' then
        exports.wasabi_banking:AddMoney('society', society, amount)
    else
        -- Add custom banking here
    end
end

-- Remove money from society account
--- @param society string Society name
--- @param amount number Amount to remove
--- @param shopId string|nil Shop ID for tracking
local function RemoveSocietyMoney(society, amount, shopId)
    if banking == 'qb-banking' then
        exports['qb-banking']:RemoveMoney(society, amount)
    elseif banking == 'qb-management' then
        exports['qb-management']:RemoveMoney(society, amount)
    elseif banking == 'esx_addonaccount' then
        TriggerEvent("esx_society:getSociety", society, function(data)
            TriggerEvent("esx_addonaccount:getSharedAccount", data.account, function(account)
                account.removeMoney(amount)
            end)
        end)
    elseif banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:removeAccountMoney(society, amount)
    elseif banking == 'okokBanking' then
        exports.okokBanking:RemoveMoney(society, amount)
    elseif banking == 'fd_banking' then
        exports.fd_banking:RemoveMoney(society, amount)
    elseif banking == 'tgg-banking' then
        exports['tgg-banking']:RemoveSocietyMoney(society, amount)
    elseif banking == 'wasabi_banking' then
        exports.wasabi_banking:RemoveMoney('society', society, amount)
    else
        -- Add custom banking here
    end
end

-- Get custom payment method balance
--- @param source number Player ID
--- @param paymentId string Payment method ID
--- @param shopId string|nil Shop ID for tracking
--- @return number Balance
local function GetCustomBalance(source, paymentId, shopId)
    -- Example: Handle special custom payment methods here
    -- By default, paymentId is treated as an item name

    if paymentId == 'example_special_currency' then
        -- return exports.your_resource:GetBalance(source) or 0
    else
        -- Use paymentId as item name (e.g., 'black_money', 'crypto', 'gold')
        return GetItemCount(source, paymentId) or 0
    end

    return 0
end

-- Remove custom payment method
--- @param source number Player ID
--- @param paymentId string Payment method ID
--- @param amount number Amount to remove
--- @param shopId string|nil Shop ID for tracking
local function RemoveCustomMoney(source, paymentId, amount, shopId)
    -- Example: Handle special custom payment methods here
    -- By default, paymentId is treated as an item name

    if paymentId == 'example_special_currency' then
        -- exports.your_resource:RemoveMoney(source, amount)
    else
        -- Use paymentId as item name (e.g., 'black_money', 'crypto', 'gold')
        RemoveItem(source, paymentId, amount)
    end
end

return {
    GetSocietyBalance = GetSocietyBalance,
    AddSocietyMoney = AddSocietyMoney,
    RemoveSocietyMoney = RemoveSocietyMoney,
    GetCustomBalance = GetCustomBalance,
    RemoveCustomMoney = RemoveCustomMoney
}
