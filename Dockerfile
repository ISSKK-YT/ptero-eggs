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
    postgresql-dev \
    # --- Asegurar que los binarios de PostgreSQL estén disponibles ---
    # (Si no se instalan con postgresql-dev, quizás necesitemos esto explícitamente)
    # postgresql-client

# Bloque 2: Configurar y compilar extensiones PHP
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
RUN apk del zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libxpm-dev libwebp-dev \
    libavif-dev icu-dev openldap-dev libsodium-dev imagemagick-dev libzip-dev \
    autoconf build-base git unzip \
    postgresql-dev

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración de Nginx: copiar archivo de configuración personalizado
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Crear usuario container
RUN adduser -D -h /home/container container

# Copiar entrypoint y dar permisos de ejecución
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --- Configurar PHP-FPM ---
# Bloque 3: Lógica para configurar PHP-FPM
RUN PHP_FPM_POOL_CONF="/etc/php8/php-fpm.d/www.conf" \
    && echo "Configurando PHP-FPM para el usuario 'container'..." \
    && if [ -f "$PHP_FPM_POOL_CONF" ]; then \
        echo "Modificando '$PHP_FPM_POOL_CONF'..." \
        && sed -i 's/log_level = notice/log_level = debug/' "$PHP_FPM_POOL_CONF" \
        && sed -i 's/;listen.owner = www-data/listen.owner = container/' "$PHP_FPM_POOL_CONF" \
        && sed -i 's/;listen.group = www-data/listen.group = container/' "$PHP_FPM_POOL_CONF" \
        && sed -i 's/;listen.mode = 0660/listen.mode = 0660/' "$PHP_FPM_POOL_CONF" \
        && sed -i 's/user = www-data/user = container/' "$PHP_FPM_POOL_CONF" \
        && sed -i 's/group = www-data/group = container/' "$PHP_FPM_POOL_CONF"; \
        echo "Configuración de PHP-FPM aplicada." \
    else \
        echo "ADVERTENCIA: El archivo de configuración '$PHP_FPM_POOL_CONF' no se encontró. No se aplicaron las configuraciones de PHP-FPM." \
        echo "Podría ser necesario ajustar la ruta del archivo de configuración de PHP-FPM para esta imagen Alpine." \
    fi

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Asegurarse de que el directorio de trabajo y sus subdirectorios tengan los permisos correctos
RUN chown -R container:container /home/container

# CMD para iniciar el entrypoint script
CMD ["/bin/sh", "/entrypoint.sh"]
