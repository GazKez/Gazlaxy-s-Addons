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

COPY --chmod=755 addon-config.sh /home/amule/amule-addon-config.sh
COPY webui/amuleweb-adaptable /usr/share/amule/webserver/amuleweb-adaptable

# The pinned upstream image logs both clear-text passwords and has no
# environment variable for selecting a web theme. Patch only those known lines
# and fail the build if a future base image changes their shape.
RUN grep -Fq 'Remote GUI password: %s' /home/amule/amule-config.sh \
    && grep -Fq 'Web UI password: %s' /home/amule/amule-config.sh \
    && sed -i 's/Remote GUI password: %s\\n" "${AMULE_GUI_PWD}"/Remote GUI password: [REDACTED]\\n"/g' /home/amule/amule-config.sh \
    && sed -i 's/Web UI password: %s\\n" "${AMULE_WEBUI_PWD}"/Web UI password: [REDACTED]\\n"/g' /home/amule/amule-config.sh \
    && ! grep -Fq 'password: %s' /home/amule/amule-config.sh \
    && grep -Fxq '. /home/amule/amule-config.sh' /home/amule/entrypoint.sh \
    && sed -i '\|^\. /home/amule/amule-config.sh$|a . /home/amule/amule-addon-config.sh' /home/amule/entrypoint.sh \
    && grep -Fxq '. /home/amule/amule-addon-config.sh' /home/amule/entrypoint.sh

COPY --chmod=755 run.sh /run.sh

ENTRYPOINT ["/run.sh"]
