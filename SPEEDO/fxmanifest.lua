fx_version 'cerulean'
game 'gta5'

author 'Hex / Vectra Development'
description 'Speedometer Vectra - Double V + Odomètre persistant'
version '1.0.0'

-- Interface NUI
ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/style.css',
    'html/script.js'
}

-- Scripts
client_script 'client.lua'
server_script 'server.lua'

-- Dépendance base de données
dependency 'oxmysql'
