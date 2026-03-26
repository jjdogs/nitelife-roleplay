fx_version 'cerulean'
lua54 'yes'
game 'gta5'
name 'lation_shops'
author 'iamlation'
version '1.2.0'
description 'A modern shop resource for FiveM'

client_scripts {
    'bridge/client.lua',
    'client/**/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'config/logs.lua',
    'server/database/init.lua',
    'server/database/queries.lua',
    'server/utils/banking.lua',
    'server/utils/hooks.lua',
    'server/admin.lua',
    'server/shop.lua',
    'server/utils/version.lua',
    'server/utils/logging.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/setup.lua',
    'shared/**/*.lua'
}

files {
	'web/build/**',
    'locales/*.json'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

dependency 'ox_lib'

ui_page 'web/build/index.html'

escrow_ignore {
    'bridge/*.lua',
    'config/*.lua',
    'locales/*.json',
    'server/database/queries.lua',
    'server/utils/banking.lua',
    'server/utils/hooks.lua',
    'server/utils/logging.lua',
    'client/utils/*.lua'
}

dependency '/assetpacks'