# --

ARG MARIADB_VERSION="latest"

FROM mariadb:${MARIADB_VERSION} AS importer

WORKDIR /app

# Copy the start scripts
COPY ./importer.sh .

# Data should be mounted as a volume
VOLUME /app/data

CMD [ "./importer.sh" ]
