games {'gta5'}

fx_version 'cerulean'

description 'Garbage Collector Job'
version '0.0.1'

client_scripts {
  'client/*.lua'
}

shared_scripts {
  '@ox_lib/init.lua',
  'shared/config.lua',
  'shared/framework.lua'
}

server_scripts {
  'server/*.lua'
}

files {
  'locales/*.json'
}

dependencies {
  'ox_lib',
  'ox_inventory',
  'ox_target'
}

client_exports {
    'useGarbageBag'
}
