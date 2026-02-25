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
    libzip-dev \      # <-- AÑADE ESTA LÍNEA
    git \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
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
    && docker-php-ext-enable imagick \
    && apk del zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev libxpm-dev libwebp-dev libavif-dev icu-dev openldap-dev libsodium-dev imagemagick-dev libzip-dev
