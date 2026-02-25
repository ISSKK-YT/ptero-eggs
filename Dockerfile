FROM alpine:latest

# Instalar Nginx y PHP 8.2 (o 8.3) con TODAS las extensiones necesarias
RUN apk add --no-cache nginx php82 php82-fpm php82-xml php82-exif \
    php82-session php82-soap php82-openssl php82-gmp php82-pdo_odbc \
    php82-json php82-dom php82-pdo php82-zip php82-mysqli php82-sqlite3 \
    php82-pdo_pgsql php82-bcmath php82-gd php82-odbc php82-pdo_mysql \
    php82-pdo_sqlite php82-gettext php82-xmlreader php82-bz2 php82-iconv \
    php82-pdo_dblib php82-curl php82-ctype php82-phar php82-fileinfo \
    php82-mbstring php82-tokenizer php82-simplexml \
    # EXTENSIONES CRÍTICAS PARA HUMHUB:
    php82-ldap php82-sodium php82-intl php82-xmlwriter php82-imagick php82-apcu php82-opcache

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar usuario y entrypoint (ajusta según tu egg)
RUN adduser -D -h /home/container container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/sh", "/entrypoint.sh"]
