fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'KuzQuality | Kuzkay'
description 'Shell builder by KuzQuality'
version '1.8.2'

ui_page 'nui/dist/nui.html'

shared_scripts {
    'shared/linkCheck.lua',
    'config.lua',
    'settings.lua',
    'shared/privSettings.lua',
    'shared/locale.lua',
    'shared/cache.lua',
    'shared/utils.lua',
    'shared/shared.lua',
}

client_scripts {
    'client/editable/editable.lua',

    'client/utils.lua',

    'client/nui.lua',
    'client/functions.lua',
    'client/builder/main.lua',
    'client/builder/functions.lua',
    'client/builder/tile/main.lua',
    'client/builder/tile/functions.lua',
    'client/builder/tile/parts/floor.lua',
    'client/builder/tile/parts/walls.lua',
    'client/builder/tile/parts/doors.lua',
    'client/builder/tile/parts/stairs.lua',
    'client/builder/tile/parts/decor.lua',
    'client/builder/tile/previews.lua',
    'client/builder/camera.lua',
    'client/builder/interact.lua',
    'client/builder/undo.lua',

    'client/gizmo/kqGizmo.lua',

    'client/spawner/shell.lua',
    'client/spawner/main.lua',
    'client/spawner/propBased.lua',

    'client/customs.lua',
}

server_scripts {
    'server/editable/init.lua',

    'server/editable/editable.lua',
    'server/editable/sql.lua',

    'server/server.lua',
    'server/manager.lua',
}

files {
    'locales/*.json',
    'nui/dist/nui.html',
    'nui/dist/app.js',
    'nui/dist/app.css',
    'nui/dist/assets/*.*',
    'custom_textures/**.*',

    'client/builder/functions.lua',
    'client/customs.lua',
    'shared/privSettings.lua',
    'shared/utils.lua',
}

escrow_ignore {
    'config.lua',
    'settings.lua',
    'client/editable/*.*',
    'server/editable/*.*',
    'locales/*.json',
}

dependencies {
    'kq_link',
    'kq_shellbuilder_props',
}

dependency '/assetpacks'