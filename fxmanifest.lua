fx_version 'cerulean'
game 'gta5'

author 'Marwan'
description 'Burger Shot Job for QBCore'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',  -- Make sure this exists!
    'locales/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/menu.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',  -- Make sure this is here
    'qb-target',
    'qb-menu'
}

lua54 'yes'