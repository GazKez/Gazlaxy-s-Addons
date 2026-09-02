# syntax=docker/dockerfile:1

# Build HTTPAceProxy against musl so it is ABI-compatible with AceServe's
# Alpine runtime image.
FROM alpine:3.21 AS httpaceproxy-build

ARG HTTPACEPROXY_REF=31b23d86a58a1bcb07404553e97954397bce87ed

RUN apk add --no-cache \
        build-base \
        ca-certificates \
        cmake \
        curl-dev \
        git \
        zlib-dev

WORKDIR /src/HTTPAceProxy

# Fetch a pinned upstream revision to keep add-on builds reproducible.
RUN git init . && \
    git remote add origin https://github.com/jopsis/HTTPAceProxy.git && \
    git fetch --depth 1 origin "${HTTPACEPROXY_REF}" && \
    git checkout --detach FETCH_HEAD

# HTTPAceProxy's dashboards use root-relative links. Home Assistant Ingress
# mounts applications below a session-specific path, so make internal links
# relative while preserving normal direct access on port 8888.
COPY ingress-paths.sed /tmp/ingress-paths.sed
RUN sed -i -f /tmp/ingress-paths.sed \
        /src/HTTPAceProxy/httpaceproxycpp/http/index.html \
        /src/HTTPAceProxy/httpaceproxycpp/http/statplugin/index.html && \
    rm -f /tmp/ingress-paths.sed

RUN cmake \
        -S /src/HTTPAceProxy/httpaceproxycpp \
        -B /build \
        -DCMAKE_BUILD_TYPE=Release \
        -DHTTPACEPROXYCPP_BUILD_TESTS=ON && \
    cmake --build /build -j"$(nproc)" && \
    ctest --test-dir /build --output-on-failure


# AceServe runtime. This image is Alpine-based for amd64.
FROM jopsis/aceserve:latest

USER root

RUN apk add --no-cache \
        ca-certificates \
        curl \
        jq \
        libcurl \
        libstdc++ \
        nginx \
        zlib && \
    rm -f /etc/nginx/http.d/default.conf && \
    mkdir -p /run/nginx

WORKDIR /app

COPY --from=httpaceproxy-build /build/httpaceproxycpp /app/httpaceproxycpp
COPY --from=httpaceproxy-build /src/HTTPAceProxy/httpaceproxycpp/http /app/http
COPY ingress.conf /etc/nginx/http.d/aceserve-ingress.conf

ENV ACEPROXY_HOST=0.0.0.0 \
    ACEPROXY_PORT=8888 \
    ACESTREAM_HOST=127.0.0.1 \
    ACESTREAM_API_PORT=62062 \
    ACESTREAM_HTTP_PORT=6878 \
    MAX_CONNECTIONS=10 \
    MAX_CONCURRENT_CHANNELS=5 \
    ENABLED_PLUGINS=newera,elcano,acepl,af1c1onados,aio,stat,statplugin \
    AIO_PLUGINS=newera,elcano,acepl,af1c1onados

EXPOSE 6878 8621 62062 8888 8099

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

CMD ["/run.sh"]
