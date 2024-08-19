#syntax=docker/dockerfile:1

# This Dockerfile uses the service folder as context.


# --
# Upstream images

ARG MARIADB_VERSION='11.5'

FROM mariadb:${MARIADB_VERSION} AS mariadb_upstream


# --
# Database image

FROM mariadb_upstream AS app_database
# No changes to the upstream image


# --
# Importer script image

FROM mariadb_upstream AS app_importer

WORKDIR /app

# Copy the start scripts
COPY --link ./importer.sh .

# Data should be mounted as a volume
VOLUME /app/data

CMD [ "./importer.sh" ]
