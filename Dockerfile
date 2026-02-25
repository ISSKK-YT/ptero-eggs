FROM php:8.3-fpm-alpine

# Instalar Nginx y extensiones adicionales
RUN apk add --no-cache nginx && \
    docker-php-ext-install pdo_mysql mysqli bcmath gd intl ldap sodium opcache zip

# Instalar imagick (requiere ImageMagick y la extensión PECL)
RUN apk add --no-cache imagemagick imagemagick-dev && \
    pecl install imagick && \
    docker-php-ext-enable imagick

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
