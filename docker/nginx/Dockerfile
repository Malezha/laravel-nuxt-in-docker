ARG NGINX_VERSION=mainline

FROM nginx:${NGINX_VERSION}-alpine

RUN set -x \
    # install build-time dependencies
    && apk add --no-cache --virtual .build-deps \
            openssl \
    # generate self-signed SSL key and certificate files
    && openssl req -x509 -nodes -days 1095 -newkey rsa:2048 \
        -subj "/C=CA/ST=QC/O=Company name, Inc./CN=localhost" \
        -addext "subjectAltName=DNS:localhost" \
        -keyout /etc/ssl/private/selfsigned.key \
        -out /etc/ssl/certs/selfsigned.crt \
    && chmod 644 /etc/ssl/private/selfsigned.key \
    && apk del .build-deps

COPY ./docker/nginx/site.conf /etc/nginx/conf.d/default.conf
