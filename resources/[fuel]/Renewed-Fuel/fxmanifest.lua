fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'
author 'FjamZoo#0001 & uShifty#1733'
description 'Renewed Scripts Fuel System'
version '1.2.4'

shared_scripts {
    '@ox_lib/init.lua',
	'@Renewed-Lib/init.lua',
}

client_scripts {
	'client.lua',
	'compat.lua',
	'station/client/main.lua',
	'station/client/admin.lua',
	'station/client/fuelstorage.lua',
	'station/client/tablet.lua',
	'station/client/fuelpump.lua',
	'oilfield/client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server.lua',
	'dependencies.lua',
	'station/server/main.lua',
	'station/server/fuelstorage.lua',
	'station/server/tablet.lua',
	'station/server/fuelpump.lua',
	'station/server/admin.lua',
	'oilfield/server/oilfields.lua',
	'oilfield/server/oilrigs.lua',
}

escrow_ignore {
	'read/*.*',
	'shared/*.lua',
	'station/client/stations.lua',
	'station/server/stations.lua',
	'oilfield/server/players.lua',
	'modules/**/*.lua'
}

provide 'cdn-fuel'
provide 'ps-fuel'
provide 'LegacyFuel'
provide 'qb-sna-fuel'
provide 'qb-fuel'
provide 'lj-fuel'

files {
	'locales/*.json',
    'modules/**/client.lua',
	'station/client/stations.lua',
	'shared/*.lua'
}

dependencies {
	'ox_lib',
	'Renewed-Lib',
}
dependency '/assetpacks'