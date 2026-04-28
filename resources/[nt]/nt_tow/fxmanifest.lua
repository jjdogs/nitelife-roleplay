fx_version 'cerulean'
game 'gta5'

name 'nt_tow'
author 'NightLife'
description 'Tow job for qbox'
version '0.1.0'

lua54 'yes'

files {
	'stream/flatbed.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/flatbed.ytyp'

shared_scripts {
    '@ox_lib/init.lua',
    '@sd_lib/init.lua',
    'shared/config.lua',
    'shared/tow_truck.lua'
}

server_scripts {
--    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

client_scripts {
    'client/*.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    --'oxmysql',
    'av_contacts',
    'sd_lib',
    'sd-dialog',
}