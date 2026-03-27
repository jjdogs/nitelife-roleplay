fx_version 'cerulean'
game 'gta5'

name 'nt_3dminigames'
description '3D Minigame Framework with In-Game Creator'
author 'NiteLife'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/core/camera.lua',
    'client/core/cursor.lua',
    'client/core/raycast.lua',
    'client/core/props.lua',
    'client/core/particles.lua',
    'client/core/zones.lua',
    'client/core/ui.lua',
    'client/main.lua',
    'client/creator/creator.lua',
}

files {
    'data/saved_minigames.lua',
}

dependencies {
    'ox_lib',
    'object_gizmo',
}
