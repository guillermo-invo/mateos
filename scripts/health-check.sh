#!/bin/bash

echo "🔍 Verificando estado de servicios..."
echo ""

# PostgreSQL
echo "1. PostgreSQL:"
if docker-compose exec -T postgres-db pg_isready -U ${DB_USER:-asistente} > /dev/null 2>&1; then
  echo "   ✅ OK - PostgreSQL está funcionando"
else
  echo "   ❌ FAIL - PostgreSQL no responde"
fi

# Next.js API
echo ""
echo "2. Next.js API:"
if curl -f http://localhost:8800/api/health > /dev/null 2>&1; then
  echo "   ✅ OK - Next.js API está funcionando"
  echo "   📊 Respuesta:"
  curl -s http://localhost:8800/api/health | jq '.' 2>/dev/null || curl -s http://localhost:8800/api/health
else
  echo "   ❌ FAIL - Next.js API no responde"
fi

# Telegram Bot
echo ""
echo "3. Telegram Bot:"
if docker-compose logs --tail=10 telegram-bot 2>/dev/null | grep -q "Telegram bot started"; then
  echo "   ✅ OK - Telegram Bot está funcionando"
else
  echo "   ⚠️  WARNING - No se pudo verificar el estado del bot"
  echo "   💡 Verifica los logs con: docker-compose logs telegram-bot"
fi

echo ""
echo "📋 Estado de contenedores:"
docker-compose ps

echo ""
echo "💡 Comandos útiles:"
echo "   Ver logs: docker-compose logs -f [servicio]"
echo "   Reiniciar: docker-compose restart [servicio]"
echo "   Ver DB: docker-compose exec next-app npx prisma studio"
