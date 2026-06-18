fx_version 'cerulean'
game 'gta5'

author 'Ragna'
description 'IMRP Apartments System - QBX Core | Routing Bucket Instancing'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/target.lua',
    'client/nui.lua',
    'client/wardrobe.lua',
    'client/garage.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/commands.lua',
    'server/expiry.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'locales/*.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
    'qbx_core'
}

lua54 'yes'
