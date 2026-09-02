#!/bin/sh

set -eu

OPTIONS_FILE="/data/options.json"
RESOLV_CONF="/etc/resolv.conf"
ACESTREAM_PID=""
PROXY_PID=""
INGRESS_PID=""

log() {
    printf '%s [gazlaxy-aceserve] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fatal() {
    log "ERROR: $*" >&2
    exit 1
}

stop_process() {
    pid="$1"
    name="$2"

    if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
        log "Stopping ${name} (PID ${pid})..."
        kill -TERM "${pid}" 2>/dev/null || true
        wait "${pid}" 2>/dev/null || true
    fi
}

cleanup() {
    trap - EXIT INT TERM HUP
    stop_process "${INGRESS_PID}" "Home Assistant Ingress proxy"
    stop_process "${PROXY_PID}" "HTTPAceProxy"
    stop_process "${ACESTREAM_PID}" "AceStream Engine"
}

handle_signal() {
    log "Shutdown signal received."
    exit 0
}

read_integer_option() {
    key="$1"
    default_value="$2"
    minimum="$3"
    maximum="$4"

    value="$(
        jq -er \
            --arg key "${key}" \
            --argjson default_value "${default_value}" \
            '(.[$key] // $default_value) | select(type == "number" and floor == .)' \
            "${OPTIONS_FILE}"
    )" || fatal "Option '${key}' must be an integer."

    case "${value}" in
        ''|*[!0-9]*) fatal "Option '${key}' must be a positive integer." ;;
    esac

    if [ "${value}" -lt "${minimum}" ] || [ "${value}" -gt "${maximum}" ]; then
        fatal "Option '${key}' must be between ${minimum} and ${maximum}."
    fi

    printf '%s' "${value}"
}

is_ipv4_address() {
    printf '%s\n' "$1" | awk -F. '
        BEGIN { valid = 1 }
        NF != 4 { valid = 0 }
        {
            for (i = 1; i <= NF; i++) {
                if ($i !~ /^[0-9]+$/ || $i < 0 || $i > 255) {
                    valid = 0
                }
            }
        }
        END { exit(valid ? 0 : 1) }
    '
}

configure_dns() {
    dns_servers_json="$(
        jq -ce '
            (.dns_servers // ["1.1.1.1", "1.0.0.1"])
            | select(
                type == "array"
                and length >= 1
                and length <= 3
                and all(.[]; type == "string")
            )
        ' "${OPTIONS_FILE}"
    )" || fatal "Option 'dns_servers' must contain between one and three addresses."

    ext_servers=""
    while IFS= read -r dns_server; do
        if ! is_ipv4_address "${dns_server}"; then
            fatal "DNS server '${dns_server}' is not a valid IPv4 address."
        fi

        if [ -n "${ext_servers}" ]; then
            ext_servers="${ext_servers} ${dns_server}"
        else
            ext_servers="${dns_server}"
        fi
    done <<EOF
$(printf '%s' "${dns_servers_json}" | jq -r '.[]')
EOF

    if [ ! -r "${RESOLV_CONF}" ]; then
        fatal "DNS configuration file is not readable: ${RESOLV_CONF}"
    fi

    dns_resolv_tmp="/tmp/gazlaxy-resolv.conf"
    : > "${dns_resolv_tmp}"

    # AceStream's Python resolver reads the ExtServers hint, while libcurl and
    # other native components use the nameserver directives. Configure both so
    # every process inside the add-on follows the same DNS policy.
    for dns_server in ${ext_servers}; do
        printf 'nameserver %s\n' "${dns_server}" >> "${dns_resolv_tmp}"
    done

    grep -v \
        -e '^[[:space:]]*nameserver[[:space:]]' \
        -e '^[[:space:]]*# ExtServers:' \
        "${RESOLV_CONF}" >> "${dns_resolv_tmp}" || true
    printf '\n# ExtServers: [%s]\n' "${ext_servers}" >> "${dns_resolv_tmp}"

    if ! cat "${dns_resolv_tmp}" > "${RESOLV_CONF}"; then
        fatal "Could not configure the AceStream DNS servers in ${RESOLV_CONF}."
    fi
    rm -f "${dns_resolv_tmp}"

    log "System and AceStream DNS servers: ${ext_servers}"
}

trap cleanup EXIT
trap handle_signal INT TERM HUP

log "=========================================="
log "Gazlaxy AceServe 0.1.5"
log "AceServe + HTTPAceProxy"
log "Architecture: $(uname -m)"
log "=========================================="

if [ ! -f "${OPTIONS_FILE}" ]; then
    fatal "Home Assistant options file not found: ${OPTIONS_FILE}"
fi

if ! jq -e . "${OPTIONS_FILE}" >/dev/null 2>&1; then
    fatal "Home Assistant options file is not valid JSON."
fi

MAX_CONNECTIONS="$(read_integer_option max_connections 10 1 100)"
MAX_CONCURRENT_CHANNELS="$(read_integer_option max_concurrent_channels 5 1 50)"
configure_dns

export ACEPROXY_HOST="${ACEPROXY_HOST:-0.0.0.0}"
export ACEPROXY_PORT="${ACEPROXY_PORT:-8888}"
export ACESTREAM_HOST="${ACESTREAM_HOST:-127.0.0.1}"
export ACESTREAM_API_PORT="${ACESTREAM_API_PORT:-62062}"
export ACESTREAM_HTTP_PORT="${ACESTREAM_HTTP_PORT:-6878}"
export MAX_CONNECTIONS MAX_CONCURRENT_CHANNELS

log "AceStream HTTP port: ${ACESTREAM_HTTP_PORT}"
log "AceStream API port: ${ACESTREAM_API_PORT}"
log "AceStream P2P port: 8621"
log "HTTPAceProxy port: ${ACEPROXY_PORT}"
log "Max connections: ${MAX_CONNECTIONS}"
log "Max concurrent channels: ${MAX_CONCURRENT_CHANNELS}"

log "Starting AceStream Engine..."
cd /acestream
python main.py \
    --bind-all \
    --live-cache-type memory \
    --live-mem-cache-size 104857600 \
    --disable-sentry \
    --log-stdout \
    --disable-upnp &
ACESTREAM_PID="$!"
log "AceStream Engine PID: ${ACESTREAM_PID}"

log "Waiting up to 120 seconds for AceStream ports 6878 and 62062..."
ready=0
elapsed=0
while [ "${elapsed}" -lt 120 ]; do
    if ! kill -0 "${ACESTREAM_PID}" 2>/dev/null; then
        fatal "AceStream Engine stopped before becoming ready."
    fi

    if nc -z 127.0.0.1 6878 >/dev/null 2>&1 && \
       nc -z 127.0.0.1 62062 >/dev/null 2>&1; then
        ready=1
        break
    fi

    sleep 2
    elapsed=$((elapsed + 2))
    if [ $((elapsed % 10)) -eq 0 ]; then
        log "Still waiting for AceStream (${elapsed}/120 seconds)..."
    fi
done

if [ "${ready}" -ne 1 ]; then
    fatal "AceStream Engine did not expose ports 6878 and 62062 within 120 seconds."
fi

log "AceStream Engine is ready."
log "Starting HTTPAceProxy..."
cd /app
/app/httpaceproxycpp &
PROXY_PID="$!"
log "HTTPAceProxy PID: ${PROXY_PID}"

log "Starting Home Assistant Ingress proxy on internal port 8099..."
nginx -g 'daemon off;' &
INGRESS_PID="$!"
log "Home Assistant Ingress proxy PID: ${INGRESS_PID}"

# BusyBox ash (provided by the Alpine runtime) supports wait -n. Whichever
# service exits first makes the add-on fail, and the EXIT trap stops the other.
process_status=0
wait -n "${ACESTREAM_PID}" "${PROXY_PID}" "${INGRESS_PID}" || process_status="$?"

if ! kill -0 "${ACESTREAM_PID}" 2>/dev/null; then
    log "ERROR: AceStream Engine stopped unexpectedly (status ${process_status})." >&2
elif ! kill -0 "${PROXY_PID}" 2>/dev/null; then
    log "ERROR: HTTPAceProxy stopped unexpectedly (status ${process_status})." >&2
elif ! kill -0 "${INGRESS_PID}" 2>/dev/null; then
    log "ERROR: Home Assistant Ingress proxy stopped unexpectedly (status ${process_status})." >&2
else
    log "ERROR: A managed process stopped unexpectedly (status ${process_status})." >&2
fi

if [ "${process_status}" -eq 0 ]; then
    process_status=1
fi

exit "${process_status}"
