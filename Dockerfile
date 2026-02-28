# Utiliza la imagen base de PHP 8.3 Alpine
FROM php:8.3-fpm-alpine
USER root
# --- Instalar dependencias del sistema (runtime + desarrollo) ---
RUN apk add --no-cache \
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
    # --- Dependencias de MariaDB (Opción 2) ---
    mariadb \
    mariadb-client \
    # --- Dependencias de compilación ---
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
    postgresql-dev \
    postgresql-client

# Bloque 2: Configurar y compilar extensiones PHP (MySQL ELIMINADO)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        intl \
        ldap \
        sodium \
        opcache \
        zip \
        exif \
        pdo_pgsql \
        pgsql \
        pdo_mysql \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# --- Eliminar paquetes de desarrollo ---
RUN apk del zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libxpm-dev libwebp-dev \
    libavif-dev icu-dev openldap-dev libsodium-dev imagemagick-dev libzip-dev \
    autoconf build-base git unzip postgresql-dev

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración de Nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Crear usuario container y preparar directorios para MariaDB en /home/container
RUN adduser -D -h /home/container container \
    && mkdir -p /run/mysqld \
    && chown -R container:container /run/mysqld

# Copiar entrypoint y dar permisos
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --- Configurar PHP-FPM (Ruta corregida para imágenes oficiales de PHP) ---
RUN PHP_FPM_POOL_CONF="/usr/local/etc/php-fpm.d/www.conf" \
    && if [ -f "$PHP_FPM_POOL_CONF" ]; then \
        sed -i 's/user = www-data/user = container/' "$PHP_FPM_POOL_CONF" ; \
        sed -i 's/group = www-data/group = container/' "$PHP_FPM_POOL_CONF" ; \
        sed -i 's/;listen.owner = www-data/listen.owner = container/' "$PHP_FPM_POOL_CONF" ; \
        sed -i 's/;listen.group = www-data/listen.group = container/' "$PHP_FPM_POOL_CONF" ; \
    fi

ENV USER=container HOME=/home/container
WORKDIR /home/container

# Asegurarse de que el directorio de trabajo tenga los permisos correctos antes de arrancar
# (Nota: En Dockerfile, RUN chown con USER container solo funciona si el origen es root, 
# pero aquí lo hacemos para asegurar la persistencia en el montaje de volumen)

CMD ["/bin/sh", "/entrypoint.sh"]
