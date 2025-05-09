#syntax=docker/dockerfile:1

# This Dockerfile uses the service folder as context.


# --
# Global build arguments

ARG POSTGRES_IMAGE='bitnami/postgresql'
ARG POSTGRES_VERSION='latest'


# --
# Upstream images

FROM ${POSTGRES_IMAGE}:${POSTGRES_VERSION} AS postgres_upstream


# --
# Database image

FROM postgres_upstream AS app_database
# No changes to the upstream image


# --
# Importer script image

FROM postgres_upstream AS app_importer

# Set app directory
WORKDIR /app

# Data should be mounted as a volume
VOLUME /app/data

# Start script
COPY --link --chmod=755 ./importer.sh .
CMD [ "./importer.sh" ]
