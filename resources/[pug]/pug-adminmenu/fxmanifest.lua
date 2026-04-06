lua54 'yes'
fx_version 'cerulean'
game 'gta5'

author 'Pug Development'
description 'Pug Admin Menu'
version '1.0.4'

shared_scripts {
    'config/translations/english.lua',
    'config/translations/spanish.lua',
    'config/translations/french.lua',
    'config/translations/polish.lua',
    'config/translations/japanese.lua',
    'config/translations/chinese.lua',
    'config/translations/finnish.lua',

    'config/config-framework.lua',
    'config/config.lua',
    'config/config-permissions.lua',
    'config/config-pedslist.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}
client_scripts { 
    '@ox_lib/init.lua',
    'client/*.lua',
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/sounds/*',
    'html/map/*',
}

escrow_ignore {
    'config/config.lua',
    'config/config-framework.lua',
    'config/config-permissions.lua',
    'config/config-pedslist.lua',
    'config/translations/english.lua',
    'config/translations/spanish.lua',
    'config/translations/french.lua',
    'config/translations/polish.lua',
    'config/translations/japanese.lua',
    'config/translations/chinese.lua',
    'config/translations/finnish.lua',
    'client/open.lua',
}

dependency '/assetpacks'