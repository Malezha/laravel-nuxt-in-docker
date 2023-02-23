# syntax=docker/dockerfile:1.2

ARG PHP_VERSION=8
ARG COMPOSER_VERSION=2

# fetch the Composer image, image page: <https://hub.docker.com/_/composer>
FROM composer:${COMPOSER_VERSION} as composer

# build application runtime, image page: <https://hub.docker.com/_/php>
FROM php:${PHP_VERSION}-fpm-alpine as runtime

RUN set -x \
    # install permanent dependencies
    && apk add --no-cache \
        fcgi \
        linux-headers \
        icu-libs \
        libpng libavif libwebp libjpeg-turbo libxpm freetype \
        libzip \
        # postgres
        #postgresql-libs \
        # imap
        #c-client \
    # install build-time dependencies
    && apk add --update --no-cache --virtual .build-deps \
        autoconf openssl make g++ \
        zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libwebp-dev libxpm-dev libavif-dev \
        icu-dev \
        libzip-dev  \
        # postgres
        #postgresql-dev \
        # imap
        #imap-dev openssl-dev \
    # configure
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm --with-avif --enable-gd \
    # imap
    #&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    # install PHP extensions (CFLAGS usage reason - https://bit.ly/3ALS5NU)
    && CFLAGS="$CFLAGS -D_GNU_SOURCE" docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        sockets \
        opcache \
        pcntl \
        bcmath \
        gd \
        intl \
        zip \
        #pdo_pgsql \
        #imap \
        1>/dev/null \
    && pecl install -o redis 1>/dev/null \
    && echo 'extension=redis.so' > ${PHP_INI_DIR}/conf.d/redis.ini \
    # install supercronic (for laravel task scheduling), project page: <https://github.com/aptible/supercronic>
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.1/supercronic-linux-amd64" \
         -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir /etc/supercronic \
    && echo '*/1 * * * * php /app/artisan schedule:run' > /etc/supercronic/laravel \
    # xdebug install but don't enable
    && pecl install -o xdebug 1>/dev/null \
    # make clean up
    && docker-php-source delete \
    && apk del .build-deps \
    && rm -R /tmp/pear \
    # enable opcache for CLI and JIT, docs: <https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit>
    && echo -e "\nopcache.enable=1\nopcache.enable_cli=1\nopcache.jit_buffer_size=32M\nopcache.jit=1235\n" >> \
        ${PHP_INI_DIR}/conf.d/docker-php-ext-opcache.ini \
    # install health checker <https://github.com/renatomefi/php-fpm-healthcheck>
    && wget -O /usr/local/bin/php-fpm-healthcheck \
        https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck \
    # show installed PHP modules
    && php -m

# install composer, image page: <https://hub.docker.com/_/composer>
COPY --from=composer /usr/bin/composer /usr/bin/composer
ENV COMPOSER_HOME="/tmp/composer"

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

# copy composer (json|lock) files for dependencies layer caching
COPY --chown=appuser:appuser ./api/composer.* /app/

# install composer dependencies (autoloader MUST be generated later!)
RUN composer install -n --no-dev --no-cache --no-ansi --no-autoloader --no-scripts --prefer-dist

# copy application sources into image (completely)
COPY --chown=appuser:appuser ./api /app/

RUN set -x \
    # generate composer autoloader and trigger scripts
    && composer dump-autoload -n --optimize \
    # "fix" composer issue "Cannot create cache directory /tmp/composer/cache/..." for docker-compose usage
    && chmod -R 777 ${COMPOSER_HOME}/cache \
    # create the symbolic links configured for the application
    && php ./artisan storage:link

# unset default image entrypoint
ENTRYPOINT []
