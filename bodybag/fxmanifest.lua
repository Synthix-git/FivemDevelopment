fx_version "bodacious"
game "gta5"
lua54 "yes"

name "bodybag"
author "Synthix"
description "Body Bag - Syn Network"
version "1.1.0"

shared_scripts {
  "shared/config.lua"
}

client_scripts {
  "@vrp/config/Native.lua",   -- 🔧 dá o 'module' no client
  "@vrp/lib/Utils.lua",       -- 🔧 carrega Tunnel/Proxy utils
  "client/client.lua"
}

server_scripts {
  "@vrp/lib/Utils.lua",       -- já tinhas, mantém
  "server/server.lua"
}