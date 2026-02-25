FROM alpine:latest

# Habilitar el repositorio community (necesario para PHP)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories

# Actualizar e instalar Nginx y PHP 8.3 (o 8.2) con todas las extensiones
RUN apk update && apk add --no-cache nginx \
    php83 \
    php83-fpm \
    php83-xml \
    php83-exif \
    php83-session \
    php83-soap \
    php83-openssl \
    php83-gmp \
    php83-pdo_odbc \
    php83-json \
    php83-dom \
    php83-pdo \
    php83-zip \
    php83-mysqli \
    php83-sqlite3 \
    php83-pdo_pgsql \
    php83-bcmath \
    php83-gd \
    php83-odbc \
    php83-pdo_mysql \
    php83-pdo_sqlite \
    php83-gettext \
    php83-xmlreader \
    php83-bz2 \
    php83-iconv \
    php83-pdo_dblib \
    php83-curl \
    php83-ctype \
    php83-phar \
    php83-fileinfo \
    php83-mbstring \
    php83-tokenizer \
    php83-simplexml \
    php83-ldap \
    php83-sodium \
    php83-intl \
    php83-xmlwriter \
    php83-imagick \
    php83-apcu \
    php83-opcache

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Usuario y entorno
RUN adduser -D -h /home/container container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Entrypoint
COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/sh", "/entrypoint.sh"]
