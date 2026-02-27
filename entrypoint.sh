#!/bin/sh

# 1. Inicializar MariaDB en /home/container si no existe
if [ ! -d "/home/container/mysql_data" ]; then
    echo "📦 Inicializando base de datos en /home/container/mysql_data..."
    mysql_install_db --user=container --datadir=/home/container/mysql_data --basedir=/usr
fi

# 2. Arrancar MariaDB en segundo plano apuntando a la zona escribible
/usr/bin/mariadbd --user=container \
    --datadir=/home/container/mysql_data \
    --run-as-user=container \
    --port=3306 \
    --bind-address=127.0.0.1 \
    --socket=/home/container/mysql.sock &

exec ${MODIFIED_STARTUP}
