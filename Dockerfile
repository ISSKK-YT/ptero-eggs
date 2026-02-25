FROM alpine:latest

RUN apk --update --no-cache add curl ca-certificates nginx

# Instalar PHP y extensiones base
RUN apk add php8 php8-xml php8-exif php8-fpm php8-session php8-soap php8-openssl php8-gmp php8-pdo_odbc php8-json php8-dom php8-pdo php8-zip php8-mysqli php8-sqlite3 php8-pdo_pgsql php8-bcmath php8-gd php8-odbc php8-pdo_mysql php8-pdo_sqlite php8-gettext php8-xmlreader php8-bz2 php8-iconv php8-pdo_dblib php8-curl php8-ctype php8-phar php8-fileinfo php8-mbstring php8-tokenizer php8-simplexml

# AÑADE ESTAS LÍNEAS PARA LAS EXTENSIONES FALTANTES
RUN apk add php8-ldap php8-sodium php8-intl php8-xmlwriter php8-imagick php8-apcu php8-opcache
# Si deseas Redis (opcional), descomenta la siguiente línea (requiere repositorio community)
# RUN apk add -X http://dl-cdn.alpinelinux.org/alpine/edge/community php8-redis

# Composer
COPY --from=composer:latest  /usr/bin/composer /usr/bin/composer

USER container
ENV  USER container
ENV HOME /home/container

WORKDIR /home/container
COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/ash", "/entrypoint.sh"]
