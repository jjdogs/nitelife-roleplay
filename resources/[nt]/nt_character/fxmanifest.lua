fx_version 'cerulean'
game 'gta5'

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

shared_scripts {
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

client_script 'client.lua'

ui_page 'web/dist/index.html'

files {
    'web/dist/**/*'
}

lua54 'yes'