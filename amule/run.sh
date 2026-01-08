#!/usr/bin/bashio

# 1. Obtener dinámicamente el nombre de la carpeta del addon (ej: 5adad4a7_amule_addon)
# Bashio nos da el slug completo que incluye el ID del repositorio
FULL_SLUG=$(bashio::addon.slug)
HA_CONFIG_BASE="/config/addons_config"
HA_CONFIG_PATH="${HA_CONFIG_BASE}/${FULL_SLUG}"
AMULE_HOME_PATH="/home/amule/.aMule"

echo "Configurando persistencia profesional en: ${HA_CONFIG_PATH}"

# 2. Crear las carpetas base si no existen
if [ ! -d "$HA_CONFIG_PATH" ]; then
    bashio::log.info "Creando carpeta de configuración en /config/addons_config..."
    mkdir -p "$HA_CONFIG_PATH"
fi

# 3. Gestión del Enlace Simbólico (Symlink)
# Si ya existe una carpeta física en el home de amule, movemos su contenido al config persistente
if [ ! -L "$AMULE_HOME_PATH" ]; then
    if [ -d "$AMULE_HOME_PATH" ]; then
        cp -rn "$AMULE_HOME_PATH"/* "$HA_CONFIG_PATH/" 2>/dev/null || true
        rm -rf "$AMULE_HOME_PATH"
    fi
    ln -s "$HA_CONFIG_PATH" "$AMULE_HOME_PATH"
fi

# 4. Exportar variables de configuración (Formulario de HA)
export PUID=$(bashio::config 'puid')
export PGID=$(bashio::config 'pgid')
export TZ=$(bashio::config 'tz')
export WEBUI_PWD=$(bashio::config 'webui_pwd')
export MOD_AUTO_RESTART_ENABLED=$(bashio::config 'mod_auto_restart_enabled')

if bashio::config.has_value 'gui_pwd'; then 
    export GUI_PWD=$(bashio::config 'gui_pwd')
fi

# 5. Configurar carpetas de descarga en /media
echo "Asegurando rutas de descarga en /media/amule..."
mkdir -p /media/amule/incoming
mkdir -p /media/amule/temp

# Ajuste de permisos para que el usuario amule (1000) sea el dueño de los archivos
chown -R 1000:1000 "$HA_CONFIG_PATH"
chown -R 1000:1000 /media/amule

# Definimos las variables que el docker de ngosang usa para las rutas
export MOD_AUTO_SHARE_DIRECTORIES="/media/amule/incoming"

echo "Lanzando aMule..."
exec /home/amule/entrypoint.sh
