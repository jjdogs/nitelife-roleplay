fx_version 'cerulean'
lua54 'yes'
game 'gta5'
name 'lation_ui'
author 'iamlation'
version '1.3.0'
description 'A modern UI library for FiveM'

client_scripts {
    'init.lua',
    'client/utils/locale.lua',
    'client/utils/positions.lua',
    'client/components/nui.lua',
    'client/components/notify.lua',
    'client/components/progressbar.lua',
    'client/components/alert.lua',
    'client/components/menu.lua',
    'client/components/skillcheck.lua',
    'client/components/input.lua',
    'client/components/textui.lua',
    'client/components/radial.lua',
    'client/components/timeline.lua'
}

server_script 'version.lua'

shared_script 'config.lua'

files {
	'web/build/**',
    'locales/*.json'
}

ui_page 'web/build/index.html'

escrow_ignore {
    'config.lua',
    'init.lua',
    'locales/*.json',
}

dependency '/assetpacks'