
-- You can customize the permissions here


POLICY = {
    -- Whether the player can open the shell editor
    CanPlayerOpenEditor = function(player)
        return IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether the player can open the shell editor
    CanPlayerDeleteShells = function(player)
        return IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether a player can view all shells in the menu (when false they'll only be able to access their own shells)
    CanPlayerSeeAllShells = function(player, shellId)
        return Config.permissions.showShellsOfOtherUsers and IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether a player can create shells in general
    CanPlayerCreateShells = function(player)
        return IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether a player can create a shell with specific information
    CanPlayerCreateShell = function(player, shellData)
        return IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether a player can update a specific shell
    CanPlayerUpdateShell = function(player, shellId)
        return IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether a player can set coordinates of a shell
    CanPlayerMoveShell = function(player, shellId, newCoords)
        return IsPlayerAceAllowed(player, 'command')
    end,
    
    -- Whether a player can manage teleporters of a shell
    CanPlayerManageTeleporters = function(player, shellId)
        return IsPlayerAceAllowed(player, 'command')
    end,
}

-- Returns a list of policies per shell
local function GetClientShellPolicies(player, shellId)
    local shellData = GetShellById(shellId)
    
    return {
        view = POLICY.CanPlayerSeeAllShells(player) or (shellData.user and shellData.user.id == GetPlayerIdentifierByType(player, 'license')),
        update = POLICY.CanPlayerUpdateShell(player, shellId),
        move = POLICY.CanPlayerMoveShell(player, shellId),
        teleports = POLICY.CanPlayerManageTeleporters(player, shellId),
        delete = POLICY.CanPlayerDeleteShells(player),
    }
end

-- Returns a list of all shells and their policies
local function GetClientPoliciesForAllShells(player)
    local shells = {}
    
    for k, id in pairs(GetAllShellIds()) do
        shells[id] = GetClientShellPolicies(player, id)
    end
    
    return shells
end


RegisterCommand(Config.command or 'shellcreator', function(player)
    if not POLICY.CanPlayerOpenEditor(player) then
        TriggerClientEvent('kq_link:client:notify', player, 'You do not have the permissions to use the Shell Creator', 'error')
        return
    end
    
    TriggerClientEvent('kq_shellbuilder:client:openEditor', player, {
        canCreate = POLICY.CanPlayerCreateShells(player),
        shells = GetClientPoliciesForAllShells(player),
    })
end, true)

