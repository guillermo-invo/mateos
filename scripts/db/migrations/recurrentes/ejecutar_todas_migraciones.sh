#!/bin/bash
# ============================================
# Script Master de Migraciones
# ============================================
# Ejecuta todas las migraciones en orden de prioridad
# Autor: Sistema Mateos
# Fecha: 2025-12-24
# ============================================

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
DB_NAME="${DB_NAME:-mateos}"
DB_USER="${DB_USER:-postgres}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/home/azureuser/mateos/logs/migraciones_$(date +%Y%m%d_%H%M%S).log"

# Crear directorio de logs si no existe
mkdir -p /home/azureuser/mateos/logs

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Sistema Mateos - Ejecución de Migraciones${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Base de datos: $DB_NAME"
echo "Usuario: $DB_USER"
echo "Directorio: $SCRIPT_DIR"
echo "Log: $LOG_FILE"
echo ""

# Función para ejecutar SQL
ejecutar_sql() {
  local archivo=$1
  local descripcion=$2
  local prioridad=$3

  echo -e "${YELLOW}[$prioridad]${NC} Ejecutando: $descripcion"
  echo "Archivo: $archivo"

  if [ ! -f "$archivo" ]; then
    echo -e "${RED}ERROR: Archivo no encontrado: $archivo${NC}"
    return 1
  fi

  if psql -U "$DB_USER" -d "$DB_NAME" -f "$archivo" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓ Completado${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}✗ Error al ejecutar $archivo${NC}"
    echo "Ver logs en: $LOG_FILE"
    return 1
  fi
}

# Función para verificar conexión
verificar_conexion() {
  echo "Verificando conexión a la base de datos..."
  if psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conexión exitosa${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}✗ No se pudo conectar a la base de datos${NC}"
    echo "Verifica que PostgreSQL esté corriendo y las credenciales sean correctas"
    return 1
  fi
}

# Verificar conexión antes de empezar
if ! verificar_conexion; then
  exit 1
fi

# Preguntar al usuario qué migraciones ejecutar
echo "¿Qué migraciones deseas ejecutar?"
echo "1) Solo ALTA prioridad (recomendado para empezar)"
echo "2) ALTA + MEDIA prioridad"
echo "3) Todas (ALTA + MEDIA + BAJA)"
echo "4) Solo queries útiles (sin modificar estructura)"
echo ""
read -p "Selecciona una opción [1-4]: " opcion

echo ""
echo "Iniciando migraciones..."
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo ""

case $opcion in
  1)
    echo -e "${BLUE}=== EJECUTANDO: ALTA PRIORIDAD ===${NC}"
    echo ""
    ejecutar_sql "$SCRIPT_DIR/01_alta_prioridad_tareas_recurrentes.sql" \
                 "Creación de tablas: tareas_recurrentes, instancias_tareas_recurrentes, disponibilidad_semanal" \
                 "ALTA"
    ejecutar_sql "$SCRIPT_DIR/02_alta_prioridad_vistas.sql" \
                 "Creación de vistas de disponibilidad y carga semanal" \
                 "ALTA"
    ;;

  2)
    echo -e "${BLUE}=== EJECUTANDO: ALTA + MEDIA PRIORIDAD ===${NC}"
    echo ""
    ejecutar_sql "$SCRIPT_DIR/01_alta_prioridad_tareas_recurrentes.sql" \
                 "Creación de tablas: tareas_recurrentes, instancias_tareas_recurrentes, disponibilidad_semanal" \
                 "ALTA"
    ejecutar_sql "$SCRIPT_DIR/02_alta_prioridad_vistas.sql" \
                 "Creación de vistas de disponibilidad y carga semanal" \
                 "ALTA"
    ejecutar_sql "$SCRIPT_DIR/03_media_prioridad_modificaciones.sql" \
                 "Modificaciones a tareas_estrategicas y creación de bloques_tiempo_planificados" \
                 "MEDIA"
    ;;

  3)
    echo -e "${BLUE}=== EJECUTANDO: TODAS LAS MIGRACIONES ===${NC}"
    echo ""
    ejecutar_sql "$SCRIPT_DIR/01_alta_prioridad_tareas_recurrentes.sql" \
                 "Creación de tablas: tareas_recurrentes, instancias_tareas_recurrentes, disponibilidad_semanal" \
                 "ALTA"
    ejecutar_sql "$SCRIPT_DIR/02_alta_prioridad_vistas.sql" \
                 "Creación de vistas de disponibilidad y carga semanal" \
                 "ALTA"
    ejecutar_sql "$SCRIPT_DIR/03_media_prioridad_modificaciones.sql" \
                 "Modificaciones a tareas_estrategicas y creación de bloques_tiempo_planificados" \
                 "MEDIA"
    ejecutar_sql "$SCRIPT_DIR/04_baja_prioridad_configuracion.sql" \
                 "Creación de tabla configuracion_personal" \
                 "BAJA"
    ejecutar_sql "$SCRIPT_DIR/../queries_utiles.sql" \
                 "Creación de vistas y funciones útiles" \
                 "EXTRA"
    ;;

  4)
    echo -e "${BLUE}=== EJECUTANDO: SOLO QUERIES ÚTILES ===${NC}"
    echo ""
    ejecutar_sql "$SCRIPT_DIR/../queries_utiles.sql" \
                 "Creación de vistas y funciones útiles" \
                 "EXTRA"
    ;;

  *)
    echo -e "${RED}Opción inválida${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✓ Migraciones completadas exitosamente${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Próximos pasos:"
echo "1. Verificar que las tablas se crearon:"
echo "   psql -U $DB_USER -d $DB_NAME -c \"\\dt tareas_recurrentes instancias_tareas_recurrentes disponibilidad_semanal\""
echo ""
echo "2. Configurar disponibilidad semanal con tus horas reales:"
echo "   psql -U $DB_USER -d $DB_NAME -c \"SELECT * FROM disponibilidad_semanal ORDER BY dia_semana;\""
echo ""
echo "3. Crear tareas recurrentes de prueba (ver README.md)"
echo ""
echo "4. Ejecutar generador de instancias:"
echo "   python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --dry-run"
echo ""
echo "5. Configurar cron job para ejecución automática (ver README.md)"
echo ""
echo "Ver logs completos en: $LOG_FILE"
echo ""
