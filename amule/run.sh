#!/usr/bin/env bashio

# Variables de entorno desde la configuración de HA
export PUID=$(bashio::config 'puid' '1000')
export PGID=$(bashio::config 'pgid' '1000')
export TZ=$(bashio::config 'tz' 'Europe/Madrid')
export WEBUI_PWD=$(bashio::config 'webui_pwd')
export MOD_AUTO_RESTART_ENABLED=$(bashio::config 'mod_auto_restart_enabled' 'true')

# Directorios en /media
echo "Preparando directorios en /media/amule..."
mkdir -p /media/amule/incoming
mkdir -p /media/amule/temp

# Si el usuario es root (0), a veces hay problemas de permisos, 
# pero la imagen de ngosang lo gestiona internamente con PUID/PGID
export MOD_AUTO_SHARE_DIRECTORIES="/media/amule/incoming"

echo "Lanzando aMule..."
exec /home/amule/entrypoint.sh
