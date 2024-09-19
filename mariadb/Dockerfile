# --

ARG MARIADB_VERSION="latest"

FROM mariadb:${MARIADB_VERSION} AS app_importer

WORKDIR /app

# Data should be mounted as a volume
VOLUME /app/data

# Start script
COPY --chmod=755 ./importer.sh .
CMD [ "./importer.sh" ]
