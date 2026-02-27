#!/bin/sh
# Pterodactyl Entrypoint para Alpine
sleep 1
cd /home/container

# Reemplazar variables de inicio
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
MODIFIED_STARTUP=$(eval echo ${MODIFIED_STARTUP})

echo ":/home/container$ ${MODIFIED_STARTUP}"

# Ejecutar el comando de inicio
exec ${MODIFIED_STARTUP}
