#!/bin/bash
# Health Check Script for MATEOS V2
# Monitors service health and logs issues

LOG_FILE="/home/azureuser/mateos/logs/health-check.log"
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Starting health check..." >> "$LOG_FILE"

# Check Docker services
SERVICES=$(docker-compose -f /home/azureuser/mateos/docker-compose.yml ps --services --filter "status=running" | wc -l)
EXPECTED_SERVICES=4

if [ "$SERVICES" -eq "$EXPECTED_SERVICES" ]; then
  echo "[$TIMESTAMP] ✅ All $SERVICES services running" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] ⚠️ Only $SERVICES/$EXPECTED_SERVICES services running" >> "$LOG_FILE"
  docker-compose -f /home/azureuser/mateos/docker-compose.yml ps >> "$LOG_FILE"
fi

# Check automatizaciones health endpoint
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1410/health)
if [ "$HTTP_CODE" -eq 200 ]; then
  echo "[$TIMESTAMP] ✅ Automatizaciones health check OK" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] ❌ Automatizaciones health check failed (HTTP $HTTP_CODE)" >> "$LOG_FILE"
fi

# Check database connectivity
DB_CHECK=$(docker-compose -f /home/azureuser/mateos/docker-compose.yml exec -T postgres-db \
  psql -U asistente -d asistente_db -c "SELECT 1" 2>&1 | grep -c "1 row")
if [ "$DB_CHECK" -eq 1 ]; then
  echo "[$TIMESTAMP] ✅ Database connectivity OK" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] ❌ Database connectivity failed" >> "$LOG_FILE"
fi

echo "[$TIMESTAMP] Health check completed" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
