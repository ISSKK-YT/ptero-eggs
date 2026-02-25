FROM php:8.3-fpm-alpine

# Instalar dependencias del sistema (runtime + desarrollo)
RUN apk add --no-cache \
    # === Bibliotecas runtime (necesarias para que las extensiones funcionen) ===
    libpng \
    libjpeg-turbo \
    freetype \
    libxpm \
    libwebp \
    libavif \
    icu-libs \
    openldap \
    libsodium \
    imagemagick \
    libzip \
    libgomp \
    # === Dependencias de desarrollo (solo para compilar) ===
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
    unzip \
    autoconf \
    build-base \
    nginx

# Configurar y compilar extensiones PHP (incluyendo exif)
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
        exif \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# Eliminar solo los paquetes de desarrollo (las librerías runtime se conservan)
RUN apk del zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libxpm-dev libwebp-dev \
    libavif-dev icu-dev openldap-dev libsodium-dev imagemagick-dev libzip-dev \
    autoconf build-base git unzip

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración de Nginx: copiar archivo de configuración personalizado
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Crear usuario container
RUN adduser -D -h /home/container container

# Copiar entrypoint y dar permisos de ejecución
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

CMD ["/bin/sh", "/entrypoint.sh"]
