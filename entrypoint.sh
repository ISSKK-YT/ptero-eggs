#!/bin/bash
sleep 1

cd /home/container

# Crear directorios necesarios (por si acaso)
mkdir -p /home/container/tmp /home/container/logs /home/container/nginx/conf.d

# Reemplazar variables en el comando de inicio
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Ejecutar el servidor
exec ${MODIFIED_STARTUP}
