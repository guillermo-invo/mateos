#!/bin/bash
# ============================================
# QUICK START - Mateos Extended
# ============================================
# Ejecuta este script en el servidor para desplegar todo
# Ubicación: /home/azureuser/mateos
# ============================================

set -e  # Exit on error

echo "🚀 ===== MATEOS EXTENDED - QUICK START ====="
echo ""

# ============================================
# 1. Verificar que estamos en el directorio correcto
# ============================================
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml no encontrado"
    echo "   Asegúrate de estar en /home/azureuser/mateos"
    exit 1
fi

echo "✅ Directorio correcto"

# ============================================
# 2. Verificar que .env existe y tiene OPENAI_API_KEY
# ============================================
if [ ! -f ".env" ]; then
    echo "⚠️  Creando .env desde .env.example..."
    cp .env.example .env
    echo "❌ ERROR: Edita .env y agrega tu OPENAI_API_KEY"
    echo "   Luego ejecuta este script de nuevo"
    exit 1
fi

if ! grep -q "^OPENAI_API_KEY=sk-" .env; then
    echo "❌ ERROR: OPENAI_API_KEY no configurado en .env"
    echo "   Edita .env y agrega tu API key"
    exit 1
fi

echo "✅ Variables de entorno configuradas"

# ============================================
# 3. Detener servicios existentes (opcional)
# ============================================
echo ""
read -p "¿Detener servicios existentes? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⏸️  Deteniendo servicios..."
    docker-compose down
else
    echo "⏭️  Manteniendo servicios corriendo"
fi

# ============================================
# 4. Build de todos los servicios
# ============================================
echo ""
echo "🔨 Construyendo imágenes Docker..."
docker-compose build --no-cache

echo "✅ Build completado"

# ============================================
# 5. Iniciar Postgres primero
# ============================================
echo ""
echo "🗄️  Iniciando PostgreSQL..."
docker-compose up -d postgres-db

echo "⏳ Esperando a que Postgres esté listo..."
sleep 10

# Verificar que está healthy
for i in {1..30}; do
    if docker-compose ps postgres-db | grep -q "healthy"; then
        echo "✅ Postgres está listo"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout esperando Postgres"
        exit 1
    fi
    sleep 2
done

# ============================================
# 6. Verificar que asistente_db se creó
# ============================================
echo ""
echo "🔍 Verificando base de datos asistente_db..."

DB_EXISTS=$(docker-compose exec -T postgres-db psql -U asistente -lqt | grep asistente_db | wc -l)

if [ "$DB_EXISTS" -eq "0" ]; then
    echo "⚠️  Base de datos asistente_db no existe, creándola..."
    docker-compose exec -T postgres-db psql -U asistente <<-EOSQL
        CREATE DATABASE asistente_db;
        GRANT ALL PRIVILEGES ON DATABASE asistente_db TO asistente;
EOSQL
    echo "✅ Base de datos asistente_db creada"
else
    echo "✅ Base de datos asistente_db ya existe"
fi

# ============================================
# 7. Iniciar todos los servicios
# ============================================
echo ""
echo "🚀 Iniciando todos los servicios..."
docker-compose up -d

echo "⏳ Esperando a que todos los servicios estén listos..."
sleep 15

# ============================================
# 8. Aplicar schema de Prisma
# ============================================
echo ""
echo "📋 Aplicando schema de Prisma a asistente_db..."

# Generar cliente
docker-compose exec -T automatizaciones npm run prisma:generate

# Aplicar migraciones
docker-compose exec -T automatizaciones npx prisma db push --skip-generate

echo "✅ Schema aplicado"

# ============================================
# 9. Verificar que todo está corriendo
# ============================================
echo ""
echo "🔍 Verificando servicios..."

SERVICES=("transcripcion-postgres" "transcripcion-api" "mateos-automatizaciones")

for service in "${SERVICES[@]}"; do
    if docker ps | grep -q "$service"; then
        echo "  ✅ $service está corriendo"
    else
        echo "  ❌ $service NO está corriendo"
        docker-compose logs --tail=50 "$service"
        exit 1
    fi
done

# ============================================
# 10. Health checks
# ============================================
echo ""
echo "🏥 Verificando health checks..."

# next-app
echo -n "  next-app: "
if curl -sf http://localhost:1400/api/process-audio > /dev/null; then
    echo "✅"
else
    echo "❌ (pero puede ser normal si el endpoint requiere POST)"
fi

# automatizaciones
echo -n "  automatizaciones: "
if curl -sf http://localhost:1410/health > /dev/null; then
    echo "✅"
else
    echo "❌"
    docker-compose logs --tail=20 automatizaciones
    exit 1
fi

# ============================================
# 11. Verificar tablas en BD
# ============================================
echo ""
echo "📊 Verificando tablas en asistente_db..."

TABLES=$(docker-compose exec -T postgres-db psql -U asistente -d asistente_db -t -c "\dt" | wc -l)

if [ "$TABLES" -ge 5 ]; then
    echo "✅ Tablas creadas correctamente ($TABLES tablas)"
    docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "\dt"
else
    echo "⚠️  Algunas tablas pueden faltar ($TABLES tablas encontradas)"
fi

# ============================================
# 12. Test de fuzzy matching
# ============================================
echo ""
echo "🧪 Test de fuzzy matching..."

curl -s http://localhost:1410/test/keywords/theo > /dev/null
echo "  ✅ Ver logs para resultados: docker-compose logs --tail=10 automatizaciones"

# ============================================
# RESUMEN FINAL
# ============================================
echo ""
echo "═══════════════════════════════════════════"
echo "✅ DESPLIEGUE COMPLETADO"
echo "═══════════════════════════════════════════"
echo ""
echo "📊 Estado de servicios:"
docker-compose ps
echo ""
echo "🔗 URLs:"
echo "  • next-app:         http://localhost:1400"
echo "  • automatizaciones: http://localhost:1410"
echo "  • postgres:         localhost:1432"
echo ""
echo "🧪 Próximos pasos:"
echo "  1. Enviar audio de prueba al bot de Telegram"
echo "  2. Ver logs: docker-compose logs -f"
echo "  3. Verificar BD: docker-compose exec postgres-db psql -U asistente -d asistente_db"
echo "  4. Conectar NocoDB (opcional)"
echo ""
echo "📚 Documentación:"
echo "  • DEPLOYMENT.md        - Guía detallada paso a paso"
echo "  • INTEGRATION_SUMMARY.md - Resumen de cambios"
echo "  • automatizaciones/README.md - Docs del servicio"
echo ""
echo "🎉 ¡Listo para usar!"
echo ""
