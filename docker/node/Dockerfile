# syntax=docker/dockerfile:1.2

ARG NODE_VERSION=lts
ARG NPM_VERSION=latest

FROM node:${NODE_VERSION}-alpine

RUN set -x \
    && npm install -g npm@${NPM_VERSION} \
    && apk add --no-cache \
        curl

ARG APP_UID=10001
ARG APP_GID=10001

RUN set -x \
    # delete exists user ang group with selected UID and GID
    && if getent passwd ${APP_UID} &> /dev/null; then deluser --remove-home $(getent passwd ${APP_UID} | cut -d: -f1); fi \
    && if getent group ${APP_GID} &> /dev/null; then delgroup $(getent group ${APP_GID} | cut -d: -f1); fi \
    # create unprivileged user
    && addgroup \
        --gid ${APP_GID}  \
        appuser \
    && adduser \
        --disabled-password \
        --shell "/sbin/nologin" \
        --home "/nonexistent" \
        --no-create-home \
        --uid ${APP_UID} \
        --gecos "" \
        -G appuser \
        appuser \
    # create directory for application sources
    && mkdir /app \
    && chown -R appuser:appuser /app

# use an unprivileged user by default
USER appuser:appuser

# use directory with application sources by default
WORKDIR /app

# copy application sources into image (completely)
COPY --chown=appuser:appuser ./web /app/

ENV npm_config_cache=/tmp/npmdir/cache
ENV npm_config_userconfig=/tmp/npmdir/.npmrc

RUN set -x \
    && mkdir -p /tmp/npmdir/cache \
    && chmod -R 777 /tmp/npmdir \
    && npm install \
    && rm -rf /tmp/npmdir/cache/*

ENTRYPOINT []
CMD []
