fx_version 'cerulean'
game 'gta5'

name 'sd-dialog'
author 'Samuel Development'
description 'Cinematic dialog system with NPC interactions'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/main.lua',
}

ui_page 'web/build/index.html'

files {
    'config.lua',
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
}
