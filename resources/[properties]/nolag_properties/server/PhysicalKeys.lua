--[[
    Physical Keys Module for nolag_properties
    
    This module handles physical key items that can be given to players
    to unlock specific doors, interactable points, or as master keys.
    
    Bitting Code Format:
    - Property ID (padded to 6 digits) + Lock Type (1 char) + Lock ID (padded to 4 digits) + Random Code (5 digits)
    - Example: 000001_E_0000_63323 (Property 1, Entrance, Lock 0, Code 63323)
    
    Lock Types:
    - E = Main Entrance (Shell/IPL)
    - P = Interactable Point
    - D = Door (MLO)
    - M = Master Key
]]

PhysicalKeys = {}

-- Check if physical keys are enabled and validate requirements
local physicalKeysEnabled = false
local physicalKeysError = nil

local function validatePhysicalKeysConfig()
    if not Config.PhysicalKeys or not Config.PhysicalKeys.Enabled then
        return false, nil
    end

    -- Check if ox_inventory is the configured inventory
    if Config.Inventory ~= 'ox_inventory' then
        return false, 'Physical keys require ox_inventory. Current inventory: ' .. tostring(Config.Inventory) .. '. Physical keys have been automatically disabled.'
    end

    -- Check if ox_inventory is running
    if GetResourceState('ox_inventory') ~= 'started' then
        return false, 'Physical keys require ox_inventory to be started. Physical keys have been automatically disabled.'
    end

    return true, nil
end

--- Register the key wax swap hook for ox_inventory
--- Allows players to create key wax impressions by combining blank wax with a housing key
---@return number|nil hookId The hook ID if registered, nil otherwise
function PhysicalKeys.RegisterKeyWaxHook()
    local keyWaxConfig = Config.PhysicalKeys.KeyWax
    if not keyWaxConfig or not keyWaxConfig.Enabled then
        return nil
    end
    
    local blankWaxItem = keyWaxConfig.BlankItemName or 'key_wax'
    local usedWaxItem = keyWaxConfig.UsedItemName or 'key_wax_used'
    local housingKeyItem = Config.PhysicalKeys.ItemName or 'housing_key'
    
    local itemFilter = {
        [blankWaxItem] = true,
        [housingKeyItem] = true,
    }
    
    return exports.ox_inventory:registerHook('swapItems', function(payload)
        -- Only process swap actions between player inventories
        if payload.action ~= 'swap' then return true end
        if payload.toType ~= 'player' or payload.fromType ~= 'player' then return true end
        
        local fromName = payload.fromSlot.name
        local toName = payload.toSlot.name
        
        -- Check if this is a blank_wax + housing_key combination (either direction)
        local isKeyWaxAndHousingKey = (fromName == blankWaxItem and toName == housingKeyItem) or
                                      (fromName == housingKeyItem and toName == blankWaxItem)
        
        if not isKeyWaxAndHousingKey then return true end
        
        -- Identify which slot contains which item
        local keyWax = fromName == blankWaxItem and payload.fromSlot or payload.toSlot
        local housingKey = fromName == housingKeyItem and payload.fromSlot or payload.toSlot
        
        -- Prompt user for confirmation
        local confirmed = lib.callback.await('nolag_properties:client:physicalKeys:keyWaxConfirm', payload.source)
        if not confirmed then return true end
        
        -- Validate that the housing key has metadata with a bitting code
        if not housingKey.metadata or not housingKey.metadata.bittingCode then
            lib.print.warn(('[PHYSICAL KEYS] Player %s attempted to use key wax on a housing key without valid metadata'):format(payload.source))
            return true
        end
        
        -- Remove the blank key wax
        local removed = exports.ox_inventory:RemoveItem(payload.source, keyWax.name, 1, nil, keyWax.slot)
        if not removed then return true end
        
        -- Create the used key wax with the bitting code imprint
        local keyLabel = housingKey.metadata.label or 'Unknown Key'
        local bittingCode = housingKey.metadata.bittingCode
        
        local added = exports.ox_inventory:AddItem(payload.source, usedWaxItem, 1, {
            bittingCode = bittingCode,
            description = ("Key wax impression of %s (Bitting: %s)"):format(keyLabel, bittingCode),
            issuedAt = os.date('%Y-%m-%d %H:%M:%S'),
        }, keyWax.slot)
        
        -- Rollback: restore the blank key wax if adding the used wax failed
        if not added then
            local restored = exports.ox_inventory:AddItem(payload.source, blankWaxItem, 1, nil, keyWax.slot)
            if not restored then
                lib.print.error(('[PHYSICAL KEYS] Failed to rollback blank key wax for player %s - item may be lost!'):format(payload.source))
            end
            return true
        end
        
        return true
    end, {
        print = false,
        itemFilter = itemFilter,
        typeFilter = {
            player = true,
            stash = false,
            container = false,
            drop = false,
        }
    })
end

-- Initialize physical keys on resource start
AddEventHandler('onResourceStart', function(r)
    if r ~= GetCurrentResourceName() then return end

    local enabled, error = validatePhysicalKeysConfig()
    physicalKeysEnabled = enabled
    physicalKeysError = error

    if error then
        lib.print.error('^1[PHYSICAL KEYS ERROR]^0 ' .. error)
    elseif enabled then
        -- Register key wax hook if enabled
        PhysicalKeys.keyWaxHookId = PhysicalKeys.RegisterKeyWaxHook()
        -- if PhysicalKeys.keyWaxHookId then
        --     lib.print.info('^2[PHYSICAL KEYS]^0 Key wax system initialized.')
        -- end
        -- lib.print.info('^2[PHYSICAL KEYS]^0 Physical key system initialized successfully.')
    end
end)

--- Check if physical keys are enabled
---@return boolean
function PhysicalKeys.IsEnabled()
    return physicalKeysEnabled
end

--- Generate a random bitting code portion
---@param length number
---@return string
local function generateRandomCode(length)
    length = length or Config.PhysicalKeys.BittingCodeLength or 5
    local code = ''
    for i = 1, length do
        code = code .. tostring(math.random(0, 9))
    end
    return code
end

--- Generate a full bitting code
---@param propertyId number
---@param lockType string 'E' (entrance), 'P' (point), 'D' (door), 'M' (master)
---@param lockId number|nil
---@return string
function PhysicalKeys.GenerateBittingCode(propertyId, lockType, lockId)
    local propIdStr = string.format('%06d', propertyId)
    local lockIdStr = string.format('%04d', lockId or 0)
    local codeLength = Config.PhysicalKeys and Config.PhysicalKeys.BittingCodeLength or 5
    local randomCode = generateRandomCode(codeLength)

    return propIdStr .. '_' .. lockType .. '_' .. lockIdStr .. '_' .. randomCode
end

--- Parse a bitting code to extract its components
---@param bittingCode string
---@return table|nil
function PhysicalKeys.ParseBittingCode(bittingCode)
    if not bittingCode or type(bittingCode) ~= 'string' then
        return nil
    end

    local propId, lockType, lockId, randomCode = bittingCode:match('^(%d+)_([EPDMF])_(%d+)_(%d+)$')

    if not propId then
        return nil
    end

    return {
        propertyId = tonumber(propId),
        lockType = lockType,
        lockId = tonumber(lockId),
        randomCode = randomCode,
        fullCode = bittingCode
    }
end

--- Get lock type label
---@param lockType string
---@return string
function PhysicalKeys.GetLockTypeLabel(lockType)
    local labels = {
        E = 'Main Entrance',
        P = 'Interactable Point',
        D = 'Door',
        F = 'Furniture',
        M = 'Master Key'
    }
    return labels[lockType] or 'Unknown'
end

--- Store bitting codes for a property in metadata
---@param propertyId number
---@return table
function PhysicalKeys.GetPropertyBittingCodes(propertyId)
    local property = LoadedProperties[propertyId]
    if not property then
        return {}
    end

    -- Initialize bitting codes in metadata if not exists
    if not property.propertyData.metadata.bittingCodes then
        property.propertyData.metadata.bittingCodes = {}
    end

    return property.propertyData.metadata.bittingCodes
end

--- Set or update a bitting code for a specific lock
---@param propertyId number
---@param lockType string
---@param lockId number|nil
---@param bittingCode string|nil If nil, generates a new code
---@return string|nil The bitting code
function PhysicalKeys.SetBittingCode(propertyId, lockType, lockId, bittingCode)
    local property = LoadedProperties[propertyId]
    if not property then
        return nil
    end

    -- Initialize bitting codes in metadata if not exists
    if not property.propertyData.metadata.bittingCodes then
        property.propertyData.metadata.bittingCodes = {}
    end

    local codeKey = lockType .. '_' .. tostring(lockId or 0)

    if not bittingCode then
        bittingCode = PhysicalKeys.GenerateBittingCode(propertyId, lockType, lockId)
    end

    property.propertyData.metadata.bittingCodes[codeKey] = bittingCode
    property:save('metadata')

    return bittingCode
end

--- Get the bitting code for a specific lock
---@param propertyId number
---@param lockType string
---@param lockId number|nil
---@return string|nil
function PhysicalKeys.GetBittingCode(propertyId, lockType, lockId)
    local property = LoadedProperties[propertyId]
    if not property then
        return nil
    end

    local codes = PhysicalKeys.GetPropertyBittingCodes(propertyId)
    local codeKey = lockType .. '_' .. tostring(lockId or 0)

    -- Generate code if it doesn't exist
    if not codes[codeKey] then
        return PhysicalKeys.SetBittingCode(propertyId, lockType, lockId)
    end

    return codes[codeKey]
end

--- Re-key a lock (generate new bitting code)
---@param propertyId number
---@param lockType string
---@param lockId number|nil
---@return string|nil newCode, string|nil error
function PhysicalKeys.RekeyLock(propertyId, lockType, lockId)
    if not Config.PhysicalKeys.AllowRekey then
        return nil, locale('physical_keys_rekey_disabled')
    end

    local newCode = PhysicalKeys.GenerateBittingCode(propertyId, lockType, lockId)
    local result = PhysicalKeys.SetBittingCode(propertyId, lockType, lockId, newCode)

    if result then
        return result, nil
    else
        return nil, locale('physical_keys_rekey_failed')
    end
end

--- Validate if a key item matches a lock
---@param keyMetadata table The metadata from the key item
---@param propertyId number
---@param lockType string
---@param lockId number|nil
---@return boolean
function PhysicalKeys.ValidateKey(keyMetadata, propertyId, lockType, lockId)
    if not keyMetadata or not keyMetadata.bittingCode then
        return false
    end

    local parsed = PhysicalKeys.ParseBittingCode(keyMetadata.bittingCode)
    if not parsed then
        return false
    end

    -- Check if it's a master key for this property
    if parsed.lockType == 'M' and parsed.propertyId == propertyId then
        local masterCode = PhysicalKeys.GetBittingCode(propertyId, 'M', 0)
        return keyMetadata.bittingCode == masterCode
    end

    -- Check exact match
    if parsed.propertyId ~= propertyId or parsed.lockType ~= lockType then
        return false
    end

    if lockId and parsed.lockId ~= lockId then
        return false
    end

    -- Verify the bitting code matches the stored code
    local storedCode = PhysicalKeys.GetBittingCode(propertyId, lockType, lockId)
    return keyMetadata.bittingCode == storedCode
end

--- Check if a player has a valid physical key for a lock
---@param source number
---@param propertyId number
---@param lockType string
---@param lockId number|nil
---@return boolean
function PhysicalKeys.PlayerHasKey(source, propertyId, lockType, lockId)
    if not physicalKeysEnabled then
        return false
    end

    -- Get player's inventory items
    local items = exports.ox_inventory:GetInventoryItems(source)
    if not items then
        return false
    end

    local keyItemName = Config.PhysicalKeys.ItemName

    for _, item in pairs(items) do
        if item.name == keyItemName then
            if item.metadata and PhysicalKeys.ValidateKey(item.metadata, propertyId, lockType, lockId) then
                return true
            end
        end
    end

    return false
end

--- Issue a physical key to a player
---@param source number
---@param propertyId number
---@param lockType string
---@param lockId number|nil
---@param keyLabel string|nil Custom label for the key
---@return boolean success, string|nil error
function PhysicalKeys.IssueKey(source, propertyId, lockType, lockId, keyLabel)
    if not physicalKeysEnabled then
        return false, locale('physical_keys_disabled')
    end

    local property = LoadedProperties[propertyId]
    if not property then
        return false, locale('property_not_found')
    end

    local bittingCode = PhysicalKeys.GetBittingCode(propertyId, lockType, lockId)
    if not bittingCode then
        return false, locale('physical_keys_code_generation_failed')
    end

    -- Build key label
    local label = keyLabel
    if not label then
        if lockType == 'M' then
            label = locale('physical_keys_master_key_label', property.propertyData.label)
        elseif lockType == 'E' then
            label = locale('physical_keys_entrance_key_label', property.propertyData.label)
        elseif lockType == 'P' then
            local pointLabel = 'Point #' .. tostring(lockId)
            if property.propertyData.metadata.points and property.propertyData.metadata.points[lockId] then
                pointLabel = property.propertyData.metadata.points[lockId].label or pointLabel
            end
            label = locale('physical_keys_point_key_label', pointLabel, property.propertyData.label)
        elseif lockType == 'D' then
            label = locale('physical_keys_door_key_label', tostring(lockId), property.propertyData.label)
        elseif lockType == 'F' then
            label = locale('physical_keys_furniture_key_label', tostring(lockId), property.propertyData.label)
        end
    end

    local metadata = {
        bittingCode = bittingCode,
        propertyId = propertyId,
        propertyName = property.propertyData.label,
        lockType = lockType,
        lockId = lockId,
        label = label,
        issuedAt = os.date('%Y-%m-%d %H:%M:%S'),
    }

    local success, response = exports.ox_inventory:AddItem(source, Config.PhysicalKeys.ItemName, 1, metadata)

    if not success then
        if response == 'inventory_full' then
            return false, locale('physical_keys_inventory_full')
        end
        return false, locale('physical_keys_issue_failed')
    end

    lib.print.debug(('Issued physical key to player %s for property %s, lock type %s, lock id %s'):format(source, propertyId, lockType, tostring(lockId)))

    return true, nil
end


function PhysicalKeys.IssueKeyByBittingCode(source, bittingCode)
    if not physicalKeysEnabled then
        return false, locale('physical_keys_disabled')
    end

    local parsed = PhysicalKeys.ParseBittingCode(bittingCode)
    if not parsed then
        return false, 'Invalid bitting code'
    end

    local success, error = PhysicalKeys.IssueKey(source, parsed.propertyId, parsed.lockType, parsed.lockId)
    if not success then
        return false, error
    end

    return true, 'Key issued successfully with bitting code: ' .. bittingCode
end

--- Get all locks available for key issuance for a property
---@param propertyId number
---@return table
function PhysicalKeys.GetAvailableLocks(propertyId)
    local property = LoadedProperties[propertyId]
    if not property then
        return {}
    end

    local locks = {}
    local propertyType = property.propertyData.type

    -- Main entrance key (for Shell and IPL)
    if (propertyType == 'shell' or propertyType == 'ipl') and Config.PhysicalKeys.KeyTypes.MainEntrance then
        locks[#locks + 1] = {
            type = 'E',
            id = 0,
            label = locale('physical_keys_main_entrance'),
            bittingCode = PhysicalKeys.GetBittingCode(propertyId, 'E', 0)
        }
    end

    -- Additional locks
    if property.propertyData.additionalLocks then
        -- print('Additional locks: ' .. json.encode(property.propertyData.additionalLocks, { indent = true }))
        for _, lock in pairs(property.propertyData.additionalLocks) do
            -- print('Lock: ' .. json.encode(lock, { indent = true }))
            locks[#locks + 1] = {
                type = 'F',
                id = tonumber(lock.id:match('^furni_(%d+)$')),
                label = lock.label,
                bittingCode = PhysicalKeys.GetBittingCode(propertyId, 'F', tonumber(lock.id:match('^furni_(%d+)$')))
            }
        end
    end

    -- Interactable points
    if Config.PhysicalKeys.KeyTypes.InteractablePoints and property.propertyData.metadata.points then
        for pointId, point in pairs(property.propertyData.metadata.points) do
            locks[#locks + 1] = {
                type = 'P',
                id = pointId,
                label = point.label or ('Point #' .. tostring(pointId)),
                bittingCode = PhysicalKeys.GetBittingCode(propertyId, 'P', pointId)
            }
        end
    end

    -- Doors (for MLO properties)
    if Config.PhysicalKeys.KeyTypes.Doors and property.doors then
        for _, door in pairs(property.doors) do
            locks[#locks + 1] = {
                type = 'D',
                id = door.id,
                label = door.name or ('Door #' .. tostring(door.id)),
                bittingCode = PhysicalKeys.GetBittingCode(propertyId, 'D', door.id)
            }
        end
    end

    -- Master key
    if Config.PhysicalKeys.KeyTypes.MasterKey then
        locks[#locks + 1] = {
            type = 'M',
            id = 0,
            label = locale('physical_keys_master_key'),
            bittingCode = PhysicalKeys.GetBittingCode(propertyId, 'M', 0)
        }
    end

    return locks
end

-- Server callbacks and events

lib.callback.register('nolag_properties:server:physicalKeys:isEnabled', function(source)
    return physicalKeysEnabled
end)

lib.callback.register('nolag_properties:server:physicalKeys:getAvailableLocks', function(source, propertyId)
    if not physicalKeysEnabled then
        return {}
    end

    local player = Framework.GetPlayerFromId(source)
    if not player then
        return {}
    end

    local property = LoadedProperties[propertyId]
    if not property then
        return {}
    end

    -- Check if player has permission to manage keys
    if not property:playerHaveKey(player, 'manage_property_physical_keys') then
        return {}
    end

    return PhysicalKeys.GetAvailableLocks(propertyId)
end)

lib.callback.register('nolag_properties:server:physicalKeys:issueKey', function(source, propertyId, lockType, lockId, targetSource)
    if not physicalKeysEnabled then
        return false, locale('physical_keys_disabled')
    end

    local player = Framework.GetPlayerFromId(source)
    if not player then
        return false, locale('invalid_player')
    end

    local property = LoadedProperties[propertyId]
    if not property then
        return false, locale('property_not_found')
    end

    -- Check if player has permission to manage keys
    if not property:playerHaveKey(player, 'manage_property_physical_keys') then
        return false, locale('no_keys')
    end

    -- Target defaults to the requesting player if not specified
    targetSource = targetSource or source

    local success, error = PhysicalKeys.IssueKey(targetSource, propertyId, lockType, lockId)
    
    if success then
        Logs.IssuePhysicalKey(player.identifier, propertyId, lockType, lockId, targetSource)
    end
    
    return success, error
end)

lib.callback.register('nolag_properties:server:physicalKeys:rekeyLock', function(source, propertyId, lockType, lockId)
    if not physicalKeysEnabled then
        return false, locale('physical_keys_disabled')
    end

    local player = Framework.GetPlayerFromId(source)
    if not player then
        return false, locale('invalid_player')
    end

    local property = LoadedProperties[propertyId]
    if not property then
        return false, locale('property_not_found')
    end

    -- Check if player has permission to manage keys
    if not property:playerHaveKey(player, 'manage_property_physical_keys') then
        return false, locale('no_keys')
    end

    -- Check rekey cost
    local rekeyPrice = Config.PhysicalKeys.RekeyPrice or 0
    if rekeyPrice > 0 then
        local ownerType = property.propertyData.ownerType
        local owner = property.propertyData.owner

        if not RemoveMoney(ownerType, owner, rekeyPrice, player.identifier, 'Rekey lock for property ' .. propertyId) then
            return false, locale('not_enough_money')
        end
    end

    local newCode, error = PhysicalKeys.RekeyLock(propertyId, lockType, lockId)

    if newCode then
        -- Log the rekey action
        Logs.RekeyLock(player.identifier, propertyId, lockType, lockId)

        -- Notify about rekey (all existing keys for this lock are now invalid)
        TriggerClientEvent('nolag_properties:client:notify', source, {
            title = locale('physical_keys_title'),
            description = locale('physical_keys_rekey_success'),
            type = 'success',
            duration = 5000
        })

        return true, newCode
    else
        return false, error
    end
end)

lib.callback.register('nolag_properties:server:physicalKeys:validateKey', function(source, propertyId, lockType, lockId)
    if not physicalKeysEnabled then
        return false
    end

    return PhysicalKeys.PlayerHasKey(source, propertyId, lockType, lockId)
end)



-- Locksmith callbacks for key duplication

--- Get all housing keys from player's inventory
---@param source number
---@return table
function PhysicalKeys.GetPlayerKeys(source)
    if not physicalKeysEnabled then
        return {}
    end

    local items = exports.ox_inventory:GetInventoryItems(source)
    if not items then
        return {}
    end

    local keys = {}
    local keyItemName = Config.PhysicalKeys.ItemName

    for _, item in pairs(items) do
        if item.name == keyItemName and item.metadata and item.metadata.bittingCode then
            keys[#keys + 1] = {
                slot = item.slot,
                label = item.metadata.label or 'Unknown Key',
                bittingCode = item.metadata.bittingCode,
                propertyId = item.metadata.propertyId,
                propertyName = item.metadata.propertyName or 'Unknown Property',
                lockType = item.metadata.lockType,
                lockId = item.metadata.lockId
            }
        end
    end

    return keys
end

--- Duplicate a key by bitting code (locksmith functionality)
---@param source number
---@param bittingCode string
---@param duplicateByBittingCode boolean -- If true, the key is created by entering a bitting code manually
---@param keyPrice number|nil -- Price for the key (from locksmith config), uses default if nil
---@param createInvalidKeys boolean|nil -- Whether to allow creating invalid keys (from locksmith config)
---@return boolean success, string|nil error
function PhysicalKeys.DuplicateKey(source, bittingCode, duplicateByBittingCode, keyPrice, createInvalidKeys)
    if not physicalKeysEnabled then
        return false, locale('physical_keys_disabled')
    end

    -- Parse the bitting code
    local parsed = PhysicalKeys.ParseBittingCode(bittingCode)
    if not parsed then
        return false, locale('locksmith_invalid_bitting_code')
    end

    local property = LoadedProperties[parsed.propertyId]

    -- Use provided createInvalidKeys setting or fall back to first locksmith config for backwards compatibility
    local allowInvalidKeys = createInvalidKeys
    if allowInvalidKeys == nil then
        local firstLocksmith = Config.PhysicalKeys.LockSmiths and Config.PhysicalKeys.LockSmiths[1]
        allowInvalidKeys = firstLocksmith and firstLocksmith.CreateInvalidKeys or false
    end
    local createInvalidKey = duplicateByBittingCode and allowInvalidKeys

    -- If not creating invalid keys and property doesn't exist, return error
    if not property and not createInvalidKey then
        return false, locale('property_not_found')
    end

    -- If not creating invalid keys, verify the bitting code matches the stored code
    lib.print.debug(('createInvalidKey: %s, property: %s'):format(tostring(createInvalidKey), tostring(property)))
    if not createInvalidKey and property then
        local storedCode = PhysicalKeys.GetBittingCode(parsed.propertyId, parsed.lockType, parsed.lockId)
        if storedCode ~= bittingCode then
            return false, locale('locksmith_invalid_bitting_code')
        end
    end

    -- Use provided keyPrice or fall back to first locksmith config for backwards compatibility
    if not keyPrice then
        local firstLocksmith = Config.PhysicalKeys.LockSmiths and Config.PhysicalKeys.LockSmiths[1]
        if firstLocksmith then
            keyPrice = duplicateByBittingCode and firstLocksmith.KeyByBittingCodePrice or firstLocksmith.KeyPrice
        else
            keyPrice = 1000 -- Default fallback
        end
    end

    local player = Framework.GetPlayerFromId(source)
    if not player then
        return false, locale('invalid_player')
    end

    -- Check if player has enough money (cash)
    local playerMoney = player.getAccount('money').money
    if playerMoney < keyPrice then
        return false, locale('not_enough_money')
    end

    -- Remove money from player
    player.removeAccountMoney('money', keyPrice, 'Locksmith key duplication')

    -- Build key label based on lock type
    local label
    local propertyLabel = property and property.propertyData.label or locale('locksmith_unknown_property')

    if parsed.lockType == 'M' then
        label = locale('physical_keys_master_key_label', propertyLabel)
    elseif parsed.lockType == 'E' then
        label = locale('physical_keys_entrance_key_label', propertyLabel)
    elseif parsed.lockType == 'P' then
        local pointLabel = 'Point #' .. tostring(parsed.lockId)
        if property and property.propertyData.metadata.points and property.propertyData.metadata.points[parsed.lockId] then
            pointLabel = property.propertyData.metadata.points[parsed.lockId].label or pointLabel
        end
        label = locale('physical_keys_point_key_label', pointLabel, propertyLabel)
    elseif parsed.lockType == 'D' then
        label = locale('physical_keys_door_key_label', tostring(parsed.lockId), propertyLabel)
    elseif parsed.lockType == 'F' then
        label = locale('physical_keys_furniture_key_label', tostring(parsed.lockId), propertyLabel)
    end

    local metadata = {
        bittingCode = bittingCode,
        propertyId = parsed.propertyId,
        propertyName = propertyLabel,
        lockType = parsed.lockType,
        lockId = parsed.lockId,
        label = label,
        issuedAt = os.date('%Y-%m-%d %H:%M:%S'),
    }

    local success, response = exports.ox_inventory:AddItem(source, Config.PhysicalKeys.ItemName, 1, metadata)

    if not success then
        -- Refund the player if key creation failed
        player.addAccountMoney('money', keyPrice, 'Locksmith key duplication refund')
        if response == 'inventory_full' then
            return false, locale('physical_keys_inventory_full')
        end
        return false, locale('physical_keys_issue_failed')
    end

    lib.print.debug(('Locksmith duplicated key for player %s with bitting code %s (invalid key: %s)'):format(source, bittingCode, tostring(createInvalidKey and (not property or PhysicalKeys.GetBittingCode(parsed.propertyId, parsed.lockType, parsed.lockId) ~= bittingCode))))

    return true, nil
end

-- Server callback for locksmith to get player's keys
lib.callback.register('nolag_properties:server:locksmith:getPlayerKeys', function(source)
    return PhysicalKeys.GetPlayerKeys(source)
end)

-- Server callback for locksmith to duplicate a key by bitting code
lib.callback.register('nolag_properties:server:locksmith:duplicateKeyByCode', function(source, bittingCode, keyPrice, createInvalidKeys)
    return PhysicalKeys.DuplicateKey(source, bittingCode, true, keyPrice, createInvalidKeys)
end)

lib.callback.register('nolag_properties:server:locksmith:duplicateKey', function(source, bittingCode, keyPrice)
    return PhysicalKeys.DuplicateKey(source, bittingCode, false, keyPrice, nil)
end)

-- Export functions for external use
exports('PhysicalKeys_IsEnabled', PhysicalKeys.IsEnabled)
exports('PhysicalKeys_PlayerHasKey', PhysicalKeys.PlayerHasKey)
exports('PhysicalKeys_IssueKey', PhysicalKeys.IssueKey)
exports('PhysicalKeys_ValidateKey', PhysicalKeys.ValidateKey)
exports('PhysicalKeys_RekeyLock', PhysicalKeys.RekeyLock)
exports('PhysicalKeys_GetAvailableLocks', PhysicalKeys.GetAvailableLocks)
exports('PhysicalKeys_GetPlayerKeys', PhysicalKeys.GetPlayerKeys)
exports('PhysicalKeys_DuplicateKey', PhysicalKeys.DuplicateKey)

