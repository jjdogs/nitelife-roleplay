fx_version 'cerulean'
game 'gta5'

author 'Samuel#0008'
description 'FiveM Crafting System'
version '1.1.5'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/init.lua',
    'bridge/shared.lua',
    'configs/config.lua',
    'configs/recipes.lua',
    'configs/techtrees.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'configs/logs.lua',
    'server/migrations.lua',
    'server/main.lua',
    'server/admin.lua'
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
    'locales/*.json'
}


escrow_ignore { '**/*.lua' }

lua54 'yes'

dependency '/assetpacks'