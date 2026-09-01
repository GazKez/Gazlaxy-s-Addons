#!/bin/sh

set -eu

OPTIONS_FILE="/data/options.json"
ACESTREAM_PID=""
PROXY_PID=""

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

trap cleanup EXIT
trap handle_signal INT TERM HUP

log "=========================================="
log "Gazlaxy AceServe 0.1.1"
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

# BusyBox ash (provided by the Alpine runtime) supports wait -n. Whichever
# service exits first makes the add-on fail, and the EXIT trap stops the other.
process_status=0
wait -n "${ACESTREAM_PID}" "${PROXY_PID}" || process_status="$?"

if ! kill -0 "${ACESTREAM_PID}" 2>/dev/null; then
    log "ERROR: AceStream Engine stopped unexpectedly (status ${process_status})." >&2
elif ! kill -0 "${PROXY_PID}" 2>/dev/null; then
    log "ERROR: HTTPAceProxy stopped unexpectedly (status ${process_status})." >&2
else
    log "ERROR: A managed process stopped unexpectedly (status ${process_status})." >&2
fi

if [ "${process_status}" -eq 0 ]; then
    process_status=1
fi

exit "${process_status}"
