#!/usr/bin/env sh

set -eu

OPTIONS_FILE="/data/options.json"
AMULE_STATE="/data/.aMule"
AMULE_HOME="/home/amule/.aMule"

log_info() {
    printf '[amule-addon] %s\n' "$*"
}

log_error() {
    printf '[amule-addon] ERROR: %s\n' "$*" >&2
}

read_option() {
    jq --exit-status --raw-output ".${1}" "${OPTIONS_FILE}"
}

read_option_default() {
    jq --raw-output --arg default "$2" ".${1} // \$default" "${OPTIONS_FILE}"
}

validate_data_path() {
    path="$1"
    option="$2"

    case "${path}" in
        /media/*|/share/*) ;;
        *)
            log_error "${option} debe estar dentro de /media o /share: ${path}"
            exit 1
            ;;
    esac

    case "/${path#/}/" in
        */../*|*/./*)
            log_error "${option} no puede contener segmentos '.' o '..': ${path}"
            exit 1
            ;;
    esac
}

export PUID="$(read_option puid)"
export PGID="$(read_option pgid)"
export UMASK="$(read_option umask)"
export TZ="$(read_option tz)"
export GUI_PWD="$(read_option gui_pwd)"
export WEBUI_PWD="$(read_option webui_pwd)"
export WEBUI_THEME="$(read_option_default webui_theme responsive)"
export INCOMING_DIR="$(read_option incoming_dir)"
export TEMP_DIR="$(read_option temp_dir)"
export FIX_PERMISSIONS="$(read_option fix_permissions)"
export MOD_AUTO_RESTART_ENABLED="$(read_option mod_auto_restart_enabled)"
export MOD_AUTO_RESTART_CRON="$(read_option mod_auto_restart_cron)"
export MOD_AUTO_SHARE_ENABLED="$(read_option mod_auto_share_enabled)"
export MOD_AUTO_SHARE_DIRECTORIES="$(read_option mod_auto_share_directories)"

validate_data_path "${INCOMING_DIR}" "incoming_dir"
validate_data_path "${TEMP_DIR}" "temp_dir"

if [ "${INCOMING_DIR%/}" = "${TEMP_DIR%/}" ]; then
    log_error "incoming_dir y temp_dir deben ser directorios diferentes"
    exit 1
fi

mkdir -p "${AMULE_STATE}" "${INCOMING_DIR}" "${TEMP_DIR}"

# /data is Home Assistant's private, writable and backed-up add-on volume.
# Preserve files restored at the upstream path before creating the link.
if [ ! -L "${AMULE_HOME}" ]; then
    if [ -d "${AMULE_HOME}" ]; then
        cp -a "${AMULE_HOME}/." "${AMULE_STATE}/"
        rm -rf "${AMULE_HOME}"
    fi
    ln -s "${AMULE_STATE}" "${AMULE_HOME}"
fi

# Numeric ownership works before the upstream entrypoint creates or resolves
# the configured user. The private state must always be writable by aMule.
chown -R "${PUID}:${PGID}" "${AMULE_STATE}"
if [ "${FIX_PERMISSIONS}" = "true" ]; then
    chown -R "${PUID}:${PGID}" "${INCOMING_DIR}" "${TEMP_DIR}"
fi

log_info "Configuración persistente: ${AMULE_STATE}"
log_info "Descargas completadas: ${INCOMING_DIR}"
log_info "Descargas temporales: ${TEMP_DIR}"
log_info "Iniciando aMule y su interfaz web"

exec /home/amule/entrypoint.sh
