#!/usr/bin/with-contenv bashio

# Capturar las opciones de HA y exportarlas como variables de entorno
export PUID=$(bashio::config 'puid')
export PGID=$(bashio::config 'pgid')
export TZ=$(bashio::config 'tz')
export WEBUI_PWD=$(bashio::config 'webui_pwd')
export MOD_AUTO_RESTART_ENABLED=$(bashio::config 'mod_auto_restart_enabled')

# Si existen opciones opcionales, las exportamos también
if bashio::config.has_value 'gui_pwd'; then
    export GUI_PWD=$(bashio::config 'gui_pwd')
fi

# Ejecutar el punto de entrada original de la imagen de ngosang
exec /home/amule/entrypoint.sh
