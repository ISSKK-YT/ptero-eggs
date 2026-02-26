# Utiliza la imagen base de PHP 8.3 Alpine
FROM php:8.3-fpm-alpine

# --- Instalar dependencias del sistema (runtime + desarrollo) ---
# Bloque 1: Solo instalación de paquetes del sistema
RUN apk add --no-cache \
    # === Bibliotecas runtime ===
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
    # === Dependencias de desarrollo ===
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
    nginx \
    # === Dependencias de PostgreSQL ===
    postgresql-dev

# Bloque 2: Configurar y compilar extensiones PHP (incluyendo PostgreSQL)
# IMPORTANTE: Esto debe ir en una instrucción RUN SEPARADA de 'apk add'
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
        # === Instalar extensiones PostgreSQL ===
        pdo_pgsql \
        pgsql \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# --- Eliminar paquetes de desarrollo ---
# Bloque 3: Eliminar dependencias de desarrollo
RUN apk del zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libxpm-dev libwebp-dev \
    libavif-dev icu-dev openldap-dev libsodium-dev imagemagick-dev libzip-dev \
    autoconf build-base git unzip \
    postgresql-dev # Elimina las dependencias de desarrollo de PostgreSQL

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración de Nginx: copiar archivo de configuración personalizado
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Crear usuario container
RUN adduser -D -h /home/container container

# Copiar entrypoint y dar permisos de ejecución
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar PHP-FPM para que el usuario 'container' pueda acceder a él
RUN sed -i 's/log_level = notice/log_level = debug/' /etc/php83/php-fpm.conf \
    && sed -i 's/;listen.owner = www-data/listen.owner = container/' /etc/php83/php-fpm.conf \
    && sed -i 's/;listen.group = www-data/listen.group = container/' /etc/php83/php-fpm.conf \
    && sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php83/php-fpm.conf \
    && sed -i 's/user = www-data/user = container/' /etc/php83/php-fpm.conf \
    && sed -i 's/group = www-data/group = container/' /etc/php83/php-fpm.conf

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Asegurarse de que el directorio de trabajo y sus subdirectorios tengan los permisos correctos
RUN chown -R container:container /home/container

# CMD para iniciar el entrypoint script
CMD ["/bin/sh", "/entrypoint.sh"]
