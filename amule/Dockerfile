ARG BUILD_FROM
FROM ${BUILD_FROM:-ghcr.io/ngosang/amule:latest}

ENV LANG=C.UTF-8

# Por si necesitas algún script extra
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD [ "/entrypoint.sh" ]
