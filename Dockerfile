FROM php:8.3-fpm-alpine

# Instalar Nginx y dependencias de desarrollo necesarias para extensiones
RUN apk add --no-cache nginx \
    zlib-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxpm-dev \
    libwebp-dev \
    libavif-dev \
    icu-dev \
    openldap-dev \
    libsodium-dev \
    imagemagick-dev \
    libzip-dev \
    git \
    unzip

# Configurar y compilar extensiones PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mysqli \
        bcmath \
        gd \
        intl \
        ldap \
        sodium \
        opcache \
        zip \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# Opcional: eliminar dependencias de desarrollo para reducir tamaño
RUN apk del zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libxpm-dev libwebp-dev libavif-dev icu-dev openldap-dev libsodium-dev imagemagick-dev libzip-dev

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear usuario container
RUN adduser -D -h /home/container container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Copiar entrypoint (asegúrate de tener este archivo)
COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/sh", "/entrypoint.sh"]
