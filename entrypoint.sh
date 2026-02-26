#!/bin/bash

echo "--- Entrypoint Script Personalizado ---"

# --- Configuración de PostgreSQL ---
# Si PostgreSQL se está ejecutando en el mismo contenedor PHP/Nginx (menos recomendado)
# O si PostgreSQL está en un contenedor separado y solo necesitas configurar la conexión.
# Si PostgreSQL está en el mismo contenedor, necesitas iniciar su servicio aquí.

# Directorios para PostgreSQL (si se ejecuta en este contenedor)
PG_BASE_DIR="/home/container/postgres"
PG_DATA_DIR="$PG_BASE_DIR/data"
PG_LOG_DIR="$PG_BASE_DIR/logs"
PG_LOG_FILE="$PG_LOG_DIR/postgres.log"
PG_PORT="${SERVER_PORT:-5432}" # Asume que Pterodactyl define SERVER_PORT para la base de datos
PG_USER="postgres"
PG_CONF_FILE="$PG_BASE_DIR/postgresql.conf"
PG_CUSTOM_HBA="$PG_BASE_DIR/pg_hba.conf"
PG_RUNTIME_DIR="$PG_BASE_DIR/run"

# Binarios de PostgreSQL (verifica estas rutas en tu imagen)
INITDB_CMD="/usr/bin/initdb"
PG_CTL_CMD="/usr/bin/pg_ctl"

# Contraseña para el superusuario de PostgreSQL
# ¡¡¡ REEMPLAZA ESTO CON TU CONTRASEÑA SEGURA !!!
POSTGRES_ROOT_PASSWORD='tu_contraseña_segura_root'

# --- Iniciar PostgreSQL (Si se ejecuta en este contenedor) ---
# Solo si la imagen Docker tiene las herramientas de PostgreSQL instaladas.
# Si PostgreSQL está en un contenedor separado, este bloque se omite.

if command -v pg_ctl &> /dev/null; then
    echo "PostgreSQL binarios encontrados. Intentando iniciar servicio de base de datos..."

    # 1. Crear directorios y asignar permisos
    echo "Creando directorios y asignando permisos para PostgreSQL..."
    mkdir -p "$PG_DATA_DIR" && chown -R "$PG_USER":"$PG_USER" "$PG_DATA_DIR" || { echo "ERROR: Fallo al crear o asignar permisos a '$PG_DATA_DIR'"; exit 1; }
    mkdir -p "$PG_LOG_DIR" && chown -R "$PG_USER":"$PG_USER" "$PG_LOG_DIR" || { echo "ERROR: Fallo al crear o asignar permisos a '$PG_LOG_DIR'"; exit 1; }
    mkdir -p "$PG_RUNTIME_DIR" && chown -R "$PG_USER":"$PG_USER" "$PG_RUNTIME_DIR" || { echo "ERROR: Fallo al crear o asignar permisos a '$PG_RUNTIME_DIR'"; exit 1; }
    mkdir -p "$PG_BASE_DIR" && chown -R "$PG_USER":"$PG_USER" "$PG_BASE_DIR" || { echo "ERROR: Fallo al crear o asignar permisos a '$PG_BASE_DIR'"; exit 1; }
    echo "Directorios de PostgreSQL creados y permisos asignados."

    # 2. Crear archivo de configuración de PostgreSQL
    echo "Creando archivo de configuración de PostgreSQL..."
    echo "# Configuración personalizada de PostgreSQL" > "$PG_CONF_FILE" || { echo "ERROR: Fallo al escribir en '$PG_CONF_FILE'"; exit 1; }
    echo "data_directory = '$PG_DATA_DIR'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir data_directory"; exit 1; }
    echo "log_directory = '$PG_LOG_DIR'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir log_directory"; exit 1; }
    echo "logging_collector = on" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir logging_collector"; exit 1; }
    echo "log_filename = 'postgres.log'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir log_filename"; exit 1; }
    echo "unix_socket_directories = '$PG_RUNTIME_DIR'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir unix_socket_directories"; exit 1; }
    echo "port = $PG_PORT" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir port"; exit 1; }
    echo "listen_addresses = '0.0.0.0'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir listen_addresses"; exit 1; }
    echo "host_based_authentication = 'trust'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir host_based_authentication"; exit 1; } # Temporal para inicialización
    echo "shared_buffers = '128MB'" >> "$PG_CONF_FILE" || { echo "ERROR: Fallo al añadir shared_buffers"; exit 1; }

    # 3. Crear archivo pg_hba.conf personalizado
    echo "Creando archivo de autenticación pg_hba.conf..."
    echo "# Archivo pg_hba.conf personalizado" > "$PG_CUSTOM_HBA" || { echo "ERROR: Fallo al escribir en '$PG_CUSTOM_HBA'"; exit 1; }
    echo "local   all             postgres                                trust" >> "$PG_CUSTOM_HBA" || { echo "ERROR: Fallo al añadir local postgres trust"; exit 1; }
    echo "host    all             postgres        127.0.0.1/32            trust" >> "$PG_CUSTOM_HBA" || { echo "ERROR: Fallo al añadir host 127.0.0.1 postgres trust"; exit 1; }
    echo "host    all             postgres        ::1/128                 trust" >> "$PG_CUSTOM_HBA" || { echo "ERROR: Fallo al añadir host ::1 postgres trust"; exit 1; }
    # Permitir conexión para el usuario que HumHub usará. Ajusta el nombre de usuario y la base de datos.
    echo "host    all             humhub_user     0.0.0.0/0               md5" >> "$PG_CUSTOM_HBA" || { echo "ERROR: Fallo al añadir host 0.0.0.0 humhub_user md5"; exit 1; }
    echo "Archivo pg_hba.conf creado."

    # 4. Inicializar PostgreSQL si no está inicializado
    if [ ! -f "$PG_DATA_DIR/PG_VERSION" ]; then
        echo "Directorio de datos no inicializado. Ejecutando initdb..."
        if eval "$INITDB_CMD" --username="$PG_USER" --pwfile=<(echo "$POSTGRES_ROOT_PASSWORD") --locale=en_US.UTF-8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8 --data-checksums -D "$PG_DATA_DIR" -c config_file="$PG_CONF_FILE"; then
            echo "initdb completado."
            chown -R "$PG_USER":"$PG_USER" "$PG_DATA_DIR" "$PG_LOG_DIR" "$PG_RUNTIME_DIR" "$PG_BASE_DIR"
            chown "$PG_USER":"$PG_USER" "$PG_CONF_FILE" "$PG_CUSTOM_HBA"
        else
            echo "ERROR: initdb falló."
            exit 1
        fi
    else
        echo "Directorio de datos ya inicializado."
    fi

    # 5. Iniciar el servidor PostgreSQL
    echo "Iniciando el servidor PostgreSQL..."
    # Ejecutamos pg_ctl start para que Pterodactyl lo monitorice
    # Importante: pg_ctl start puede salir si el servidor ya está corriendo,
    # necesitamos algo que mantenga el proceso vivo en primer plano o que Pterodactyl detecte.
    # Una forma común es usar 'pg_ctl runcon' o ejecutar directamente 'postgres' con argumentos.
    # Pero si el comando MODIFIED_STARTUP es para la app principal, debemos ejecutarlo DESPUÉS.

    # Iniciamos PostgreSQL en background para que el script pueda continuar
    pg_ctl start \
      -D "$PG_DATA_DIR" \
      -l "$PG_LOG_FILE" \
      -c "config_file='$PG_CONF_FILE'" \
      -c "hba_file='$PG_CUSTOM_HBA'" \
      -o "-p $PG_PORT -h 0.0.0.0"

    # Verificamos si PostgreSQL inició correctamente
    if ! pg_isready -h 127.0.0.1 -p $PG_PORT -q -U $PG_USER; then
        echo "ERROR: PostgreSQL no inició correctamente."
        cat "$PG_LOG_FILE" # Muestra los logs si falla
        exit 1
    fi
    echo "Servidor PostgreSQL iniciado."

else
    echo "AVISO: Binarios de PostgreSQL no encontrados. Se asume que PostgreSQL se ejecuta en otro contenedor."
    # Si PostgreSQL está en otro contenedor, este script no lo inicia.
    # HumHub solo necesita poder conectarse al servicio de BD externo.
fi

# --- Procesar y ejecutar el comando de inicio de la aplicación principal ---
cd /home/container

# Crear directorios necesarios para la aplicación (si no los crea el comando MODIFIED_STARTUP)
mkdir -p /home/container/tmp /home/container/logs /home/container/nginx/conf.d

echo "Procesando comando de inicio de la aplicación..."
# Reemplazar variables en el comando de inicio de la aplicación principal
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Ejecutar el comando de inicio de la aplicación principal
# Si MODIFIED_STARTUP inicia un servidor que debe permanecer vivo (ej. Nginx, PHP-FPM),
# este 'exec' lo maneja. Si necesita iniciar multiples procesos, puede que necesites un supervisor.
exec ${MODIFIED_STARTUP}
