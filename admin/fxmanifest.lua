fx_version "bodacious"
game "gta5"
lua54 "yes"

-- NUI para copiar para o clipboard
ui_page "web-side/index.html"

files {
  "web-side/*"
}

client_scripts {
  "@vrp/config/Native.lua",
  "@vrp/lib/Utils.lua",
  "client-side/*"
}

server_scripts {
  "@vrp/config/Item.lua",
  "@vrp/config/Vehicle.lua",
  "@vrp/lib/Utils.lua",
  "@vrp/config/Global.lua",
  "server-side/*"
}

-- Exporta a função de copiar (client-side)
exports {
  "Copy"
}

-- Mantidos do teu resource (server-side)
server_exports {
  "Embed",
  "Content",
  "Webhook"
}
