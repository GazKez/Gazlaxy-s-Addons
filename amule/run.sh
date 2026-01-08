#!/usr/bin/bashio

# Variables de entorno
export PUID=$(bashio::config 'puid')
export PGID=$(bashio::config 'pgid')
export TZ=$(bashio::config 'tz')
export WEBUI_PWD=$(bashio::config 'webui_pwd')
export MOD_AUTO_RESTART_ENABLED=$(bashio::config 'mod_auto_restart_enabled')

if bashio::config.has_value 'gui_pwd'; then export GUI_PWD=$(bashio::config 'gui_pwd'); fi

# Directorios
echo "Preparando directorios en /media/amule..."
mkdir -p /media/amule/incoming
mkdir -p /media/amule/temp

export MOD_AUTO_SHARE_DIRECTORIES="/media/amule/incoming"

echo "Lanzando aMule..."
exec /home/amule/entrypoint.sh
