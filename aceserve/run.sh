#!/usr/bin/with-contenv bashio

set -e

bashio::log.info "=========================================="
bashio::log.info " Gazlaxy AceServe"
bashio::log.info " AceServe + HTTPAceProxy"
bashio::log.info "=========================================="

bashio::log.info "Architecture: $(uname -m)"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

export ACEPROXY_HOST="${ACEPROXY_HOST:-0.0.0.0}"
export ACEPROXY_PORT="${ACEPROXY_PORT:-8888}"

export ACESTREAM_HOST="${ACESTREAM_HOST:-127.0.0.1}"
export ACESTREAM_API_PORT="${ACESTREAM_API_PORT:-62062}"
export ACESTREAM_HTTP_PORT="${ACESTREAM_HTTP_PORT:-6878}"

export MAX_CONNECTIONS="${MAX_CONNECTIONS:-10}"
export MAX_CONCURRENT_CHANNELS="${MAX_CONCURRENT_CHANNELS:-5}"

bashio::log.info "AceStream HTTP port: ${ACESTREAM_HTTP_PORT}"
bashio::log.info "AceStream API port: ${ACESTREAM_API_PORT}"
bashio::log.info "AceStream P2P port: 8621"

bashio::log.info "HTTPAceProxy port: ${ACEPROXY_PORT}"
bashio::log.info "Max connections: ${MAX_CONNECTIONS}"
bashio::log.info "Max concurrent channels: ${MAX_CONCURRENT_CHANNELS}"

# ------------------------------------------------------------
# Start AceServe
# ------------------------------------------------------------

bashio::log.info "Starting AceStream Engine..."

python /acestream/main.py \
    --bind-all \
    --live-cache-type memory \
    --live-mem-cache-size 104857600 \
    --disable-sentry \
    --log-stdout \
    --disable-upnp \
    > /dev/stdout 2>&1 &

ACESTREAM_PID=$!

bashio::log.info "AceStream Engine PID: ${ACESTREAM_PID}"

# ------------------------------------------------------------
# Wait for AceServe
# ------------------------------------------------------------

bashio::log.info "Waiting for AceStream Engine..."

for i in $(seq 1 60); do
    if curl -fsS http://127.0.0.1:6878/ >/dev/null 2>&1; then
        bashio::log.info "AceStream Engine is ready."
        break
    fi

    if ! kill -0 "${ACESTREAM_PID}" 2>/dev/null; then
        bashio::log.error "AceStream Engine stopped unexpectedly."
        exit 1
    fi

    sleep 2
done

if ! curl -fsS http://127.0.0.1:6878/ >/dev/null 2>&1; then
    bashio::log.error "AceStream Engine did not become ready."
    exit 1
fi

# ------------------------------------------------------------
# Start HTTPAceProxy
# ------------------------------------------------------------

bashio::log.info "Starting HTTPAceProxy..."

exec /app/httpaceproxycpp
