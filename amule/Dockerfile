# Do not use Home Assistant Builder's reserved BUILD_FROM argument here: the
# builder injects its own Alpine base image. This add-on intentionally extends
# the Debian-based upstream aMule image.
ARG AMULE_FROM=ngosang/amule:3.0.1-2
FROM ${AMULE_FROM}

ARG BUILD_ARCH
ARG BUILD_VERSION

LABEL \
    io.hass.name="aMule" \
    io.hass.description="Cliente eD2k/Kad con interfaz web para Home Assistant" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}"

# The upstream image is Debian based. jq is the only additional runtime
# dependency needed to read Home Assistant's /data/options.json file.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 run.sh /run.sh

ENTRYPOINT ["/run.sh"]
