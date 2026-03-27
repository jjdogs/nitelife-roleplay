fx_version 'cerulean'
game 'gta5'

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

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'nt_character',
}

lua54 'yes'
