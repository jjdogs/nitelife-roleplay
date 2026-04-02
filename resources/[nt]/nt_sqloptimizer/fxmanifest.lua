fx_version 'cerulean'
game 'gta5'

name        'nt_sqloptimizer'
description 'NiteLife RP - Runs ANALYZE and OPTIMIZE on all tables at server startup'
author      'NiteLife'
version     '1.0.0'

server_script '@oxmysql/lib/MySQL.lua'
server_script 'server/main.lua'
