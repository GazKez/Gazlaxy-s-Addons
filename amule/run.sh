#!/usr/bin/bashio

# 1. Obtener el Slug de forma manual si la función falla
# Home Assistant guarda el slug en /data/options.json o podemos sacarlo del entorno
FULL_SLUG=$(jq --raw-output '.slug' /data/options.json 2>/dev/null)

# Si por lo que sea está vacío, usamos una ruta genérica pero dentro de addons_config
if [ -z "$FULL_SLUG" ] || [ "$FULL_SLUG" == "null" ]; then
    # Intentamos obtenerlo del nombre del host (que en HA Addons suele ser el slug)
    FULL_SLUG=$(hostname)
fi

HA_CONFIG_PATH="/config/addons_config/${FULL_SLUG}"
AMULE_HOME_PATH="/home/amule/.aMule"

bashio::log.info "Configurando persistencia en: ${HA_CONFIG_PATH}"

# 2. Crear carpetas
if [ ! -d "$HA_CONFIG_PATH" ]; then
    mkdir -p "$HA_CONFIG_PATH"
fi

# 3. Enlace simbólico (Symlink)
if [ ! -L "$AMULE_HOME_PATH" ]; then
    if [ -d "$AMULE_HOME_PATH" ]; then
        cp -rn "$AMULE_HOME_PATH"/* "$HA_CONFIG_PATH/" 2>/dev/null || true
        rm -rf "$AMULE_HOME_PATH"
    fi
    ln -s "$HA_CONFIG_PATH" "$AMULE_HOME_PATH"
fi

# 4. Variables de entorno (Configuración de la UI)
export PUID=$(bashio::config 'puid')
export PGID=$(bashio::config 'pgid')
export TZ=$(bashio::config 'tz')
export WEBUI_PWD=$(bashio::config 'webui_pwd')
export MOD_AUTO_RESTART_ENABLED=$(bashio::config 'mod_auto_restart_enabled')

if bashio::config.has_value 'gui_pwd'; then 
    export GUI_PWD=$(bashio::config 'gui_pwd')
fi

# 5. Descargas en /media
mkdir -p /media/amule/incoming
mkdir -p /media/amule/temp

# Permisos para el usuario amule (1000)
chown -R 1000:1000 "$HA_CONFIG_PATH"
chown -R 1000:1000 /media/amule

export MOD_AUTO_SHARE_DIRECTORIES="/media/amule/incoming"

bashio::log.info "Lanzando aMule..."
exec /home/amule/entrypoint.sh
