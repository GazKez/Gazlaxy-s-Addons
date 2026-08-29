# ============================================================
# Build HTTPAceProxy C++
# ============================================================

FROM ubuntu:24.04 AS httpaceproxy-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        libcurl4-openssl-dev \
        zlib1g-dev \
        git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --depth 1 https://github.com/jopsis/HTTPAceProxy.git .

RUN cmake \
        -S /src/httpaceproxycpp \
        -B /build \
        -DCMAKE_BUILD_TYPE=Release \
        -DHTTPACEPROXYCPP_BUILD_TESTS=OFF && \
    cmake --build /build -j"$(nproc)"


# ============================================================
# Final image: AceServe
# ============================================================

FROM jopsis/aceserve:latest

USER root

# Runtime dependencies required by HTTPAceProxy
RUN apk add --no-cache \
        libcurl \
        zlib \
        curl

WORKDIR /app

# HTTPAceProxy executable
COPY --from=httpaceproxy-build \
    /build/httpaceproxycpp \
    /app/httpaceproxycpp

# HTTPAceProxy web/plugin resources
COPY --from=httpaceproxy-build \
    /src/httpaceproxycpp/http \
    /app/http

# Default configuration
ENV ACEPROXY_HOST=0.0.0.0
ENV ACEPROXY_PORT=8888

ENV ACESTREAM_HOST=127.0.0.1
ENV ACESTREAM_API_PORT=62062
ENV ACESTREAM_HTTP_PORT=6878

ENV MAX_CONNECTIONS=10
ENV MAX_CONCURRENT_CHANNELS=5

ENV ENABLED_PLUGINS=newera,elcano,acepl,af1c1onados,aio,stat,statplugin
ENV AIO_PLUGINS=newera,elcano,acepl,af1c1onados

EXPOSE 6878
EXPOSE 8621
EXPOSE 62062
EXPOSE 8888

COPY run.sh /run.sh

RUN chmod +x /run.sh

CMD ["/run.sh"]
