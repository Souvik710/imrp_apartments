fx_version 'cerulean'
game 'gta5'

author 'Ragna'
description 'IMRP Apartments System - QBox Framework'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'locales/*.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'ox_inventory'
}

lua54 'yes'