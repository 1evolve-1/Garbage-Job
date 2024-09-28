fx_version 'cerulean'
game 'gta5'

author '1Evolve Development'
description 'garbagejob'
version '1.0.0'
lua54 'yes'

-- Dipendenze
dependencies {
    'es_extended',
    'ox_inventory',
    'ox_target',
    'ox_lib'
}

shared_script {
    '@es_extended/imports.lua',
    'config.lua'
}

-- File client e server
client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
