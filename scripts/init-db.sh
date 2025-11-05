#!/bin/bash
set -e

echo "🔄 Esperando a que PostgreSQL esté listo..."
until docker-compose exec -T postgres-db pg_isready -U ${DB_USER:-asistente}; do
  echo "⏳ PostgreSQL no está listo aún... esperando 2 segundos"
  sleep 2
done

echo "✅ PostgreSQL está listo"
echo "🔄 Ejecutando migraciones de Prisma..."

docker-compose exec next-app npx prisma migrate deploy

echo "✅ Base de datos inicializada correctamente"
echo ""
echo "📊 Para ver los datos, ejecuta:"
echo "   docker-compose exec next-app npx prisma studio"
