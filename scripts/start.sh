#!/bin/bash
set -e

echo "🚀 Iniciando sistema de transcripción..."
echo ""

# Verificar que existe el archivo .env
if [ ! -f .env ]; then
  echo "❌ Error: No existe el archivo .env"
  echo "💡 Copia .env.example a .env y configura tus credenciales"
  exit 1
fi

# Build y start
echo "🔨 Construyendo imágenes Docker..."
docker-compose build

echo ""
echo "🚀 Iniciando servicios..."
docker-compose up -d

echo ""
echo "⏳ Esperando a que los servicios estén listos..."
sleep 10

echo ""
echo "🔍 Verificando estado..."
bash scripts/health-check.sh

echo ""
echo "✅ Sistema iniciado correctamente"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Verifica que todo funcione: bash scripts/health-check.sh"
echo "   2. Inicializa la base de datos: bash scripts/init-db.sh"
echo "   3. Envía un mensaje de voz a tu bot de Telegram"
echo ""
echo "📊 Ver logs en tiempo real:"
echo "   docker-compose logs -f"
