fx_version 'cerulean'
game 'gta5'

author 'Ragna'
description 'IMRP Ambulance Job - Advanced EMS System | QBX Core | IMMORTAL ROLEPLAY'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/injuries.lua',
    'shared/items.lua',
    'shared/ranks.lua',
    'shared/vehicles.lua',
    'shared/hospitals.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/injury.lua',
    'client/death.lua',
    'client/treatment.lua',
    'client/hospital.lua',
    'client/dispatch.lua',
    'client/vehicle.lua',
    'client/storage.lua',
    'client/bossmenu.lua',
    'client/commands.lua',
    'client/nui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/injury.lua',
    'server/treatment.lua',
    'server/hospital.lua',
    'server/dispatch.lua',
    'server/mdt.lua',
    'server/billing.lua',
    'server/bossmenu.lua',
    'server/commands.lua'
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
    'qbx_core',
    'pma-voice'
}

lua54 'yes'
