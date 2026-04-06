Config = {}

-- Default fallback spawn (used when no other option is available).
Config.DefaultSpawn = vec4(195.17, -933.51, 30.69, 144.0) -- Legion Square

-- Job-specific spawn points.
-- Key must exactly match the job name stored in the players table.
Config.JobSpawns = {
    ['police']    = { label = 'Mission Row PD',        coords = vec4(441.0,  -982.0,  30.7, 90.0)  },
    ['ambulance'] = { label = 'Pillbox Hill Hospital', coords = vec4(295.0,  -1446.0, 29.9, 155.0) },
    ['mechanic']  = { label = 'Mechanic Shop',         coords = vec4(885.66, -1024.47, 27.76, 270.0) },
}

-- RP loading messages shown during new character creation.
-- Displayed one at a time while the player is being set up (up to 15).
-- Each message shows for ~2 seconds, cycling for up to ~30 seconds total.
Config.CreationLoadingMessages = {
    'Processing your identification...',
    'Running a background check...',
    'Setting up your bank account...',
    'Assigning your Citizen ID number...',
    'Issuing your driver\'s license...',
    'Activating your health insurance...',
    'Opening a credit file...',
    'Finding you an apartment...',
    'Getting your keys ready...',
    'Registering your phone number...',
    'Submitting your residency application...',
    'Verifying your citizenship documents...',
    'Processing your utility setup...',
    'Getting you on the phone network...',
    'Almost there...',
}

-- Debug flags — set to true to enable console output for that category.
-- Set All = true to enable everything at once (useful during development).
Config.Debug = {
    Spawn      = false, -- Spawn selection, location fetching, coords
    Properties = false, -- nolag_properties export calls and results
    Jobs       = false, -- Job spawn resolution
    All        = true,  -- Master override — if true, enables all of the above
}

function DebugPrint(category, message)
    if Config.Debug.All or Config.Debug[category] then
        print('[nt_spawn:' .. category .. '] ' .. tostring(message))
    end
end
