#syntax=docker/dockerfile:1

# This Dockerfile uses the service folder as context.


# --
# Global build arguments

ARG MARIADB_VERSION='lts'


# --
# Upstream images

FROM mariadb:${MARIADB_VERSION} AS mariadb_upstream


# --
# Database image

FROM mariadb_upstream AS app_database
# No changes to the upstream image


# --
# Importer script image

FROM mariadb_upstream AS app_importer

# Set app directory
WORKDIR /app

# Data should be mounted as a volume
VOLUME /app/data

# Start script
COPY --link --chmod=755 ./importer.sh .
CMD [ "./importer.sh" ]
