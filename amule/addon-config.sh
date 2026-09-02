#!/usr/bin/env sh

# This file is sourced by the upstream entrypoint immediately after it creates
# or updates amule.conf and remote.conf.
case "${WEBUI_THEME:-responsive}" in
    responsive)
        webui_template="amuleweb-adaptable"
        ;;
    default)
        webui_template=""
        ;;
    *)
        printf '[INIT] ERROR: Unsupported Web UI theme: %s\n' "${WEBUI_THEME}" >&2
        return 1
        ;;
esac

if ! grep -q '^Template=' "${AMULE_CONF}" || ! grep -q '^Template=' "${REMOTE_CONF}"; then
    printf '[INIT] ERROR: Template setting not found in aMule configuration\n' >&2
    return 1
fi

sed -i "s/^Template=.*/Template=${webui_template}/" "${AMULE_CONF}" "${REMOTE_CONF}"
printf '[INIT] Web UI theme: %s\n' "${WEBUI_THEME:-responsive}"
