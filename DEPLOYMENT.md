# 🚀 Guía de Despliegue - Mateos Extended

Esta guía explica cómo desplegar el sistema completo con el nuevo servicio de automatizaciones.

## 📋 Requisitos Previos

- [x] Servidor con Docker y Docker Compose instalados
- [x] Mateos funcionando (postgres-db, next-app, telegram-bot)
- [x] Acceso a OpenAI API
- [x] Red `involucra-network` creada

## 🗂️ Arquitectura Nueva

```
Mateos (Fuente de Verdad)
├── postgres-db
│   ├── transcripciones_db (existente)
│   └── asistente_db (nueva) ✨
├── next-app
└── telegram-bot

Automatizaciones (nuevo servicio) ✨
└── Procesa transcripciones con IA
```

---

## 📝 Paso 1: Actualizar Variables de Entorno

```bash
cd /home/azureuser/mateos
nano .env
```

Agregar al final:

```bash
# Automatizaciones
CONFIDENCE_THRESHOLD=0.6
OPENAI_MODEL=gpt-4o-mini
OPENAI_TEMPERATURE=0.1
OPENAI_MAX_TOKENS=4000
```

**Verificar** que existe `OPENAI_API_KEY`.

---

## 📝 Paso 2: Detener Servicios (Opcional)

Si Mateos está corriendo:

```bash
docker-compose down
```

O detener solo los servicios que cambiarán:

```bash
docker-compose stop next-app
```

---

## 📝 Paso 3: Construir Nuevo Servicio

```bash
# Construir imagen de automatizaciones
docker-compose build automatizaciones
```

Esto puede tomar 2-5 minutos la primera vez.

---

## 📝 Paso 4: Iniciar Postgres (Crea 2da BD)

```bash
docker-compose up -d postgres-db
```

Esperar a que esté healthy:

```bash
docker-compose ps postgres-db
```

Verificar que creó `asistente_db`:

```bash
docker-compose exec postgres-db psql -U asistente -c "\l"
```

Deberías ver:
- `transcripciones_db` (existente)
- `asistente_db` (nueva) ✅

---

## 📝 Paso 5: Generar Schema de Prisma

```bash
# Entrar al contenedor de automatizaciones
docker-compose run --rm automatizaciones sh

# Dentro del contenedor:
npm run prisma:generate
npm run prisma:migrate

# Salir
exit
```

O desde fuera:

```bash
cd automatizaciones
npm install
npm run prisma:generate
DATABASE_URL="postgresql://asistente:n8npass@localhost:1432/asistente_db" npm run prisma:migrate
cd ..
```

---

## 📝 Paso 6: Iniciar Todos los Servicios

```bash
docker-compose up -d
```

Servicios que deberían estar corriendo:

```bash
docker-compose ps
```

```
transcripcion-postgres   Up (healthy)
transcripcion-api        Up (healthy)
mateos-automatizaciones  Up (healthy) ✨
```

---

## 📝 Paso 7: Verificar Logs

### Logs de Automatizaciones

```bash
docker-compose logs -f automatizaciones
```

Debería mostrar:

```
🚀 ===== MATEOS AUTOMATIZACIONES =====
✅ Servidor iniciado en puerto 3100
🏥 Health check: http://localhost:3100/health
📨 Webhook: http://localhost:3100/webhook
```

### Health Check

```bash
curl http://localhost:1410/health
```

Respuesta esperada:

```json
{
  "status": "ok",
  "service": "mateos-automatizaciones",
  "timestamp": "2025-11-06T..."
}
```

---

## 📝 Paso 8: Modificar next-app ✅ COMPLETADO

**Estado**: ✅ Ya implementado en el código

El código para llamar al webhook ya está agregado en:
- `next-app/src/app/api/process-audio/route.ts` (línea 119-130)
- `next-app/src/lib/automatizaciones-webhook.ts` (helper function)

**Funcionalidad agregada:**
- Llama al webhook después de transcribir exitosamente
- No bloqueante (background)
- Resiliente (no falla si webhook no responde)
- Timeout de 10 segundos
- Logging completo

**Para aplicar los cambios:**

```bash
# Rebuild next-app con el nuevo código
docker-compose up -d --build next-app
```

**Verificar que funcionó:**

```bash
# Ver logs después de enviar audio
docker-compose logs -f next-app

# Deberías ver:
# "Notificando a automatizaciones"
# "Webhook de automatizaciones exitoso"
```

Ver `next-app/CHANGELOG.md` para más detalles.

---

## 🧪 Paso 9: Probar el Sistema

### Test 1: Health Check

```bash
curl http://localhost:1410/health
```

### Test 2: Fuzzy Matching

```bash
curl http://localhost:1410/test/keywords/theo
curl http://localhost:1410/test/keywords/cuando
```

Ver logs para resultados:

```bash
docker-compose logs automatizaciones | tail -20
```

### Test 3: Webhook Simulado

```bash
curl -X POST http://localhost:1410/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "transcripcionId": 999,
    "texto": "Teo llamar a María mañana a las 3pm para revisar el proyecto",
    "archivoUrl": "https://example.com/audio.mp3",
    "fecha": "2025-11-06T10:30:00Z"
  }'
```

Ver logs en tiempo real:

```bash
docker-compose logs -f automatizaciones
```

Deberías ver:

```
🔧 ===== INICIANDO PROCESAMIENTO =====
📋 Transcripción ID: 999
🔍 Paso 1: Detectando tipo...
✅ Keyword detectada: "teo" → "teo" (100% similar) → tipo: tarea
💾 Paso 2: Creando NotaAudio...
🧠 Paso 3: Extrayendo tarea con OpenAI...
💾 Paso 4: Guardando entidades en BD...
✅ ===== PROCESAMIENTO COMPLETADO =====
```

### Test 4: Verificar BD

```bash
docker-compose exec postgres-db psql -U asistente -d asistente_db

-- Ver tablas creadas
\dt

-- Ver notas procesadas
SELECT id, tipo_detectado, procesado FROM notas_audio;

-- Ver tareas creadas
SELECT id, titulo, prioridad FROM tareas;

-- Salir
\q
```

---

## 🎯 Paso 10: Conectar NocoDB

Si tienes NocoDB en involucra-hub:

1. Ir a NocoDB: `http://tu-servidor:8080`
2. Crear nuevo proyecto
3. Conectar a BD existente:
   - **Host**: `transcripcion-postgres` (si está en involucra-network)
   - **Port**: `5432`
   - **Database**: `asistente_db`
   - **Username**: `asistente`
   - **Password**: `n8npass`

4. Explorar tablas:
   - `notas_audio`
   - `tareas`
   - `registros`
   - `compromisos`
   - `ideas`

---

## 🎤 Paso 11: Probar con Telegram

1. Enviar audio a tu bot de Telegram:
   - **Para tarea**: "Teo, llamar a cliente mañana a las 3pm"
   - **Para registro**: "Juan, trabajé 3 horas en el proyecto X con Pedro"
   - **Para idea**: "Ide, crear un dashboard para métricas"
   - **Para compromiso**: "Compa, María me confirmó que envía el reporte el viernes"

2. Ver logs de `next-app`:
   ```bash
   docker-compose logs -f next-app
   ```

3. Ver logs de `automatizaciones`:
   ```bash
   docker-compose logs -f automatizaciones
   ```

4. Verificar en NocoDB que se crearon las entidades

---

## 🔧 Troubleshooting

### Problema: Automatizaciones no inicia

**Síntoma**: `docker-compose ps` muestra "Exit 1"

**Solución**:
```bash
# Ver logs
docker-compose logs automatizaciones

# Posibles causas:
# 1. Falta OPENAI_API_KEY
# 2. No se conecta a BD
# 3. Prisma no generó el cliente

# Regenerar cliente Prisma
docker-compose run --rm automatizaciones npm run prisma:generate
docker-compose up -d automatizaciones
```

### Problema: Base de datos asistente_db no existe

**Síntoma**: Error "database asistente_db does not exist"

**Solución**:
```bash
# Conectar a Postgres
docker-compose exec postgres-db psql -U asistente

# Crear manualmente
CREATE DATABASE asistente_db;
GRANT ALL PRIVILEGES ON DATABASE asistente_db TO asistente;
\q

# Aplicar schema
cd automatizaciones
DATABASE_URL="postgresql://asistente:n8npass@localhost:1432/asistente_db" npm run prisma:migrate
```

### Problema: Webhook no se llama

**Síntoma**: Audio se transcribe pero no se procesa con IA

**Solución**:
1. Verificar que agregaste el código de webhook en `next-app`
2. Verificar que `WEBHOOK_AUTOMATIZACIONES_URL` está en docker-compose
3. Rebuild next-app: `docker-compose up -d --build next-app`

### Problema: OpenAI devuelve error

**Síntoma**: "OpenAI API error" en logs

**Solución**:
```bash
# Verificar API key
docker-compose exec automatizaciones env | grep OPENAI_API_KEY

# Si está vacío, agregar a .env y reiniciar
docker-compose restart automatizaciones
```

---

## 📊 Monitoreo Continuo

```bash
# Ver todos los logs
docker-compose logs -f

# Ver solo automatizaciones
docker-compose logs -f automatizaciones

# Ver últimas 100 líneas
docker-compose logs --tail=100 automatizaciones

# Ver logs con timestamp
docker-compose logs -f -t automatizaciones
```

---

## 🔄 Reiniciar Todo

Si algo sale mal:

```bash
# Detener todo
docker-compose down

# Limpiar (CUIDADO: borra volúmenes)
# docker-compose down -v

# Reconstruir
docker-compose build

# Iniciar
docker-compose up -d

# Verificar
docker-compose ps
```

---

## ✅ Checklist de Verificación

- [ ] Postgres tiene 2 bases de datos (transcripciones_db + asistente_db)
- [ ] Servicio `automatizaciones` está UP y HEALTHY
- [ ] Health check responde: `curl localhost:1410/health`
- [ ] Test de keywords funciona: `curl localhost:1410/test/keywords/teo`
- [ ] Webhook simulado funciona (ver logs)
- [ ] Schema de Prisma aplicado a `asistente_db`
- [ ] NocoDB conectado a `asistente_db`
- [ ] next-app llama al webhook después de transcribir
- [ ] Telegram bot → audio → transcripción → IA → BD → NocoDB (flujo completo)

---

## 📞 Soporte

Si encuentras problemas:

1. **Ver logs**: `docker-compose logs -f automatizaciones`
2. **Verificar BD**: `docker-compose exec postgres-db psql -U asistente -d asistente_db -c "\dt"`
3. **Probar health**: `curl localhost:1410/health`
4. **Revisar variables**: `docker-compose config` (muestra config final)

---

**Última actualización**: 6 de noviembre de 2025
**Versión**: 1.0.0 (MVP - Fase 1)
