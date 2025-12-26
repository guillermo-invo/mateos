# _CONTEXT.md - Automatizaciones (Microservicio IA)

## PROPÓSITO

Microservicio backend independiente para procesamiento de IA. Maneja transcripción de audios, extracción de entidades con GPT, generación de proyectos, y resúmenes automáticos. Se ejecuta como servicio Express.js separado de Next.js.

---

## STACK TÉCNICO ESPECÍFICO

- **Framework:** Express.js 4.18.2
- **Runtime:** Node.js 20+
- **IA/ML:** OpenAI API (GPT-4 Turbo, Whisper)
- **ORM:** Prisma 6.18.0 (⚠️ SOURCE OF TRUTH del schema)
- **Messaging:** node-telegram-bot-api (notificaciones)
- **Scheduler:** node-cron (resúmenes diarios)
- **Logger:** Winston 3.11.0
- **TypeScript:** 5.x

---

## ARQUITECTURA Y DECISIONES

### ¿Por Qué Separado de Next.js?

**Razones:**
1. **Procesamiento largo:** GPT puede tardar 10-30s, no apto para API Routes de Next.js
2. **Webhooks persistentes:** Telegram webhook necesita servidor siempre activo
3. **CRON jobs:** Resúmenes diarios requieren scheduler independiente
4. **Escalabilidad:** Permite escalar IA processing sin afectar frontend
5. **Aislamiento:** Fallas en IA no afectan disponibilidad del frontend

### Comunicación con Next.js

**Next.js → Automatizaciones:**
- Via webhook HTTP: `POST http://automatizaciones:3002/webhook`
- Eventos: `idea.created`, `proyecto.created`, `nota_voz.procesada`

**Automatizaciones → Next.js:**
- Via Prisma (escribe directo a DB)
- Via Telegram (notifica al usuario)

### Flujo de Procesamiento

```
Audio (Telegram)
  → Whisper transcription
  → GPT extraction (entidades, clasificación)
  → Prisma write (ideas, proyectos, tareas)
  → Telegram notification (confirmación)
```

---

## ESTRUCTURA DE ARCHIVOS

```
src/
├── index.ts                      [Servidor Express principal - 15KB]
├── processor.ts                  [Procesador principal de transcripciones]
├── ai-extractor.ts               [Extracción de entidades con GPT]
├── db-writer.ts                  [Escritura a DB con Prisma]
├── keyword-matcher.ts            [Matching por palabras clave]
├── project-creator.ts            [Creador de proyectos - 6KB]
├── daily-summary.ts              [Resumen diario automático - 10KB]
├── historical-summary.ts         [Resumen histórico]
├── scheduler.ts                  [CRON jobs]
├── telegram-client.ts            [Cliente notificaciones Telegram]
├── model-config.ts               [Config modelos IA]
├── types.ts                      [Tipos TypeScript]
└── ia/                           [Módulos de procesamiento IA]
    ├── generador-proyectos.ts    [Generación proyectos con GPT]
    ├── guardar-proyecto.ts       [Persistencia proyectos]
    └── prompts-proyectos.ts      [Prompts GPT - 6KB]
```

---

## REGLAS Y RESTRICCIONES

### Prisma Schema

#### ⚠️ CRÍTICO - SOURCE OF TRUTH
- El schema en `automatizaciones/prisma/schema.prisma` es la ÚNICA fuente de verdad
- `next-app/prisma/schema.prisma` es COPIA sincronizada
- **Proceso de cambios:**
  1. Modificar `automatizaciones/prisma/schema.prisma`
  2. Ejecutar `npx prisma migrate dev --name [nombre-migracion]`
  3. Copiar schema actualizado a `next-app/prisma/schema.prisma`
  4. En `next-app/`: ejecutar `npx prisma generate`

#### ❌ NUNCA:
- Modificar schema en `next-app/` directamente
- Crear migraciones en `next-app/`
- Usar esquemas desincronizados

### OpenAI API

#### ✅ SIEMPRE:
- Usar retry con backoff exponencial (max 3 intentos)
- Validar response con Zod antes de guardar
- Loggear costos (tokens usados)
- Manejar rate limits (500 req/min tier 3)

#### ❌ NUNCA:
- Llamar OpenAI sin retry logic
- Asumir que response tiene formato esperado
- Exponer API key (usar .env)

### CRON Jobs

#### Resumen Diario
- **Schedule:** `0 20 * * *` (20:00 America/Montevideo)
- **Función:** `daily-summary.ts`
- **Qué hace:** Genera resumen del día, envía por Telegram
- **Dependencias:** PostgreSQL, OpenAI API, Telegram

#### ⚠️ IMPORTANTE:
- CRON usa timezone del sistema (configurar en Docker)
- Si CRON falla, NO debe crashear servidor
- Loggear errores de CRON en `logs/cron.log`

---

## ENDPOINTS

### Webhooks

#### POST /webhook
Recibe notificaciones de eventos desde Next.js.

**Body:**
```json
{
  "event": "idea.created",
  "data": {
    "id": "...",
    "titulo": "...",
    ...
  }
}
```

**Eventos soportados:**
- `idea.created`: Nueva idea capturada
- `proyecto.created`: Nuevo proyecto creado
- `nota_voz.procesada`: Nota de voz transcrita y procesada

**Response:**
```json
{
  "success": true,
  "message": "Evento procesado"
}
```

#### POST /telegram-webhook
Webhook de Telegram (usado por bot si está en webhook mode).

**⚠️ Actualmente NO usado:** Bot usa polling mode, no webhook mode.

### Health Check

#### GET /health
```json
{
  "status": "ok",
  "timestamp": "2025-12-26T14:30:00Z",
  "uptime": 123456,
  "services": {
    "database": "connected",
    "openai": "available"
  }
}
```

---

## CONFIGURACIÓN

### Variables de Entorno (.env)

```bash
# Base de datos
DATABASE_URL="postgresql://..."

# OpenAI
OPENAI_API_KEY="sk-..."
OPENAI_ORG_ID="org-..."  # Opcional

# Telegram
TELEGRAM_BOT_TOKEN="..."
TELEGRAM_CHAT_ID="..."   # Para notificaciones

# Servidor
PORT=3002
NODE_ENV=production

# Timezone (importante para CRON)
TZ=America/Montevideo
```

### Docker Compose

**Service name:** `automatizaciones`
**Port:** 3002 (interno Docker network)
**Depends on:** `postgres`
**Restart policy:** `unless-stopped`

---

## NOTAS PARA IA

### ⚠️ Prisma Migrations
- Carpeta `prisma/migrations/` contiene historial completo
- NO eliminar migraciones pasadas (break histórico)
- Migraciones se aplican automáticamente en startup (si `prisma migrate deploy`)

### ⚠️ OpenAI Rate Limits
- Tier 3: 500 req/min, 200K tokens/min
- GPT-4 Turbo más caro que GPT-3.5 pero mejor calidad
- Monitorear costos en OpenAI dashboard

### ⚠️ Error Handling en CRON
```typescript
cron.schedule('0 20 * * *', async () => {
  try {
    await generateDailySummary()
  } catch (error) {
    logger.error('Error en CRON daily summary:', error)
    // NO lanzar error (no crashear servidor)
  }
})
```

### ⚠️ Telegram Notifications
- Cliente en `telegram-client.ts`
- Usa Telegram Bot API (NO Telegram Client API)
- Rate limit: 30 mensajes/segundo (más que suficiente)
- Si falla notificación, NO fallar proceso principal

---

## ARCHIVOS CLAVE

- `src/index.ts`: Servidor Express, rutas, middleware
- `src/processor.ts`: Procesador principal de transcripciones
- `src/ai-extractor.ts`: Lógica extracción GPT
- `src/scheduler.ts`: Configuración CRON jobs
- `prisma/schema.prisma`: ⚠️ SOURCE OF TRUTH del schema

---

## DEPENDENCIAS CRÍTICAS

### Depende de:
- **PostgreSQL:** Base de datos (CRÍTICO - sin DB no funciona)
- **OpenAI API:** Procesamiento IA (CRÍTICO - core functionality)
- **Telegram Bot:** Notificaciones (OPCIONAL - sistema funciona sin él)

### Se ejecuta antes/después de:
- **Después de:** PostgreSQL (docker-compose `depends_on`)
- **Independiente de:** Next.js (pueden correr separados)

---

## TESTING

### Estrategia
- Tests de integración (con DB de prueba)
- Mock de OpenAI API (usar respuestas fijas)
- Tests de CRON (ejecutar manualmente, NO esperar schedule)

### Casos críticos:
- Procesamiento de audio → extracción → guardado en DB
- Retry logic de OpenAI funciona
- CRON jobs se ejecutan correctamente
- Manejo de errores de DB

---

**Última actualización:** 2025-12-26
**Versión:** 1.0
