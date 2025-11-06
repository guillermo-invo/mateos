#!/bin/bash
set -e

# Script para crear la segunda base de datos "asistente_db"
# Se ejecuta automáticamente al iniciar el contenedor de Postgres

echo "🔧 Creando base de datos asistente_db..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    -- Crear base de datos si no existe
    SELECT 'CREATE DATABASE asistente_db'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'asistente_db')\gexec

    -- Grant permisos
    GRANT ALL PRIVILEGES ON DATABASE asistente_db TO $POSTGRES_USER;
EOSQL

echo "✅ Base de datos asistente_db creada exitosamente"
