# 🚀 MATEOS - Guía para Nuevos Desarrolladores

**Para**: Personas que van a trabajar en nuevas funcionalidades de MATEOS
**Requisito previo**: Leer `ARCHITECTURE.md` primero
**Tiempo estimado**: 2-3 horas para entender el proyecto completo

---

## 📚 Orden Recomendado de Lectura

```
┌─────────────────────────────────────┐
│ 1. Este archivo (overview rápido)   │
└────────┬────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│ 2. ARCHITECTURE.md (detalles)       │
└────────┬────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│ 3. Clonar y hacer setup local       │
└────────┬────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│ 4. Leer código de proceso-audio     │
└────────┬────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│ 5. Leer código de automatizaciones  │
└────────┬────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│ 6. Probar con un audio real         │
└─────────────────────────────────────┘
```

---

## 🎯 Lo Más Importante en 5 Minutos

### ¿Qué hace MATEOS?

1. **Usuario manda nota de voz por Telegram** → "Teo, llamar a María"
2. **Bot descarga audio** y lo envía a la API
3. **API transcribe** con OpenAI Whisper y guarda en DB
4. **Automatizaciones procesa** con IA:
   - Detecta keyword "Teo" → es una TAREA
   - Extrae: título, fecha, prioridad
   - Guarda en BD estructurada
5. **Usuario ve resultado** en NocoDB (dashboard)

### Arquitectura Simple

```
Telegram (Usuario)
    ↓
Bot (polling)
    ↓
next-app (API)  ← Principal
    ├→ R2 (storage de audio)
    ├→ OpenAI Whisper (transcribe)
    └→ automatizaciones (webhook)
         ├→ Keyword matching (fuzzy)
         ├→ OpenAI GPT-4o-mini (extrae)
         └→ PostgreSQL asistente_db (guarda)
```

### Tecnologías Clave

| Función | Tech | Por qué |
|---------|------|---------|
| API | Next.js 15.5 | Moderno, rápido, TypeScript |
| BD | PostgreSQL 15 | Confiable, ACID, indices |
| ORM | Prisma | Tipado, migraciones automáticas |
| IA/Extracción | GPT-4o-mini | Barato, rápido, preciso |
| Transcripción | Whisper API | Estado del arte, $0.006/min |
| Storage | R2 | Barato ($0), S3-compatible |
| Servidor | Docker Compose | Local = producción |

---

## 🛠️ Setup Local (15 minutos)

### Requisitos
```bash
node --version          # >= 20.11.0
npm --version           # >= 10.0.0
docker --version        # >= 24.0
docker-compose --version # >= 2.23
```

### Pasos

```bash
# 1. Clonar
git clone <repo> mateos
cd mateos

# 2. Verificar .env tiene credenciales
cat .env | grep OPENAI_API_KEY

# 3. Instalar dependencias (local)
cd next-app && npm install && cd ..
cd automatizaciones && npm install && cd ..
cd telegram-bot && npm install && cd ..

# 4. Build Docker
docker-compose build

# 5. Iniciar servicios
docker-compose up -d

# 6. Esperar 15 segundos a PostgreSQL
sleep 15

# 7. Migraciones
docker-compose exec next-app npx prisma migrate deploy
docker-compose exec automatizaciones npm run prisma:deploy

# 8. Verificar todo está OK
docker-compose ps        # Ver que todos digan "healthy" o "Up"
curl http://localhost:1400/api/health   # next-app
curl http://localhost:1410/health       # automatizaciones
```

### Verificación de Setup

```bash
# ✅ Si ves esto, estás listo:
$ curl http://localhost:1400/api/health
{"status":"ok","service":"transcripcion-api"...}

$ docker-compose ps
NAME              STATUS
transcripcion-postgres   Up (healthy)
transcripcion-api        Up (healthy)
mateos-automatizaciones  Up (healthy)
mateos-telegram-bot      Up
```

---

## 📂 Estructura de Carpetas

```
mateos/
├── next-app/                      # 🌟 API principal
│   ├── src/
│   │   ├── app/api/
│   │   │   ├── process-audio/
│   │   │   │   └── route.ts       # ← AQUÍ EMPIEZA TODO
│   │   │   ├── health/
│   │   │   │   └── route.ts
│   │   │   └── ...
│   │   ├── lib/
│   │   │   ├── prisma.ts          # Cliente Prisma singleton
│   │   │   ├── r2-client.ts       # Upload a Cloudflare R2
│   │   │   ├── whisper-client.ts  # OpenAI Whisper
│   │   │   ├── automatizaciones-webhook.ts  # Llamar automatizaciones
│   │   │   └── logger.ts          # Winston logs
│   │   ├── types/
│   │   │   └── index.ts           # Tipos compartidos
│   │   └── middleware/
│   ├── prisma/
│   │   ├── schema.prisma          # Schema de BD (transcripciones_db)
│   │   └── migrations/            # Historial de cambios
│   └── Dockerfile
│
├── automatizaciones/              # 🤖 Procesamiento IA
│   ├── src/
│   │   ├── index.ts               # Express server + rutas
│   │   ├── processor.ts           # Orquestador (main logic)
│   │   ├── keyword-matcher.ts     # Detecta tipo (fuzzy)
│   │   ├── ai-extractor.ts        # GPT-4o-mini
│   │   ├── db-writer.ts           # Guarda en BD
│   │   ├── scheduler.ts           # Tareas cron
│   │   ├── daily-summary.ts       # Resumen diario
│   │   └── types.ts               # Interfaces
│   ├── prisma/
│   │   ├── schema.prisma          # Schema de BD (asistente_db)
│   │   └── migrations/
│   └── Dockerfile
│
├── telegram-bot/                  # 📱 Bot de Telegram
│   ├── src/
│   │   ├── index.ts               # Polling loop principal
│   │   ├── types.ts
│   │   └── logger.ts
│   └── Dockerfile
│
├── scripts/
│   └── init-db.sh                 # Crear asistente_db al iniciar Postgres
│
├── docker-compose.yml             # 🐳 Orquestación
├── .env                           # 🔐 Credenciales (NO commitear)
├── .env.example                   # Ejemplo de .env
├── README.md                      # Overview simple
├── QUICKSTART.md                  # Setup rápido
├── ARCHITECTURE.md                # 📘 Este documento, pero más detallado
└── DEVELOPER_GUIDE.md             # ← Estás aquí
```

---

## 🎓 Conceptos Clave Explicados

### 1. **Prisma + 2 Esquemas**

MATEOS usa DOS bases de datos independientes:

**next-app/prisma/schema.prisma** → `transcripciones_db`
```prisma
model Transcripcion {
  id Int @id
  texto String        // "Teo, llamar a María..."
  r2_url String       // Link al audio en Cloudflare R2
  estado String       // PROCESANDO, COMPLETADO, ERROR
  telegram_file_id String @unique  // Para deduplicación
  // ...
}
```

**automatizaciones/prisma/schema.prisma** → `asistente_db`
```prisma
model NotaAudio {
  id Int
  transcripcionId Int @unique  // ← Referencia, NO es FK real
  tipoDetectado String         // "tarea", "registro", etc
  // ...
}

model Tarea {
  id Int
  notaAudioId Int  // ← FK real a notas_audio
  titulo String    // "Llamar a María"
  fechaVencimiento DateTime
  // ...
}
```

**¿Por qué dos?**
- Cada servicio independiente
- Escalabilidad
- Si automatizaciones falla, transcripciones intactas
- Auditoría

### 2. **Zod para Validación**

Protege la entrada a los endpoints:

```typescript
// next-app/src/app/api/process-audio/route.ts
const requestSchema = z.object({
  telegramFileId: z.string().min(1),
  userId: z.number().int().positive(),
  messageId: z.number().int().positive(),
  duration: z.number().int().positive().optional(),
});

const metadata = requestSchema.parse(JSON.parse(metadataStr));
// Si falla → ZodError → 400 Bad Request
```

### 3. **Promise.all para Paralelismo**

En lugar de esperar secuencial:

```typescript
// ❌ Lento (secuencial):
const r2Result = await uploadToR2(buffer);
const whisperResult = await transcribeAudio(buffer);
// Total: 10-15 segundos

// ✅ Rápido (paralelo):
const [r2Result, whisperResult] = await Promise.all([
  uploadToR2(buffer),
  transcribeAudio(buffer)
]);
// Total: 5-10 segundos
```

### 4. **Fuzzy Matching con Levenshtein**

Detecta Keywords tolerando errores de transcripción:

```typescript
// automatizaciones/src/keyword-matcher.ts
const distancia = levenshtein("Teo", "teo");  // 0
const confianza = 1 - (distancia / Math.max(len1, len2));
// confianza = 1.0 = 100%

// Si usuario dice "Deo" por error de Whisper:
const distancia = levenshtein("Teo", "Deo");  // 1
const confianza = 1 - (1 / 3) = 0.66 = 66%  // ✅ Todavía válido (>60%)
```

### 5. **Fire-and-Forget Webhook**

next-app NO espera respuesta de automatizaciones:

```typescript
// next-app/src/lib/automatizaciones-webhook.ts
export async function notifyAutomatizaciones(payload: WebhookPayload) {
  try {
    // Enviar pero NO esperar
    fetch(process.env.WEBHOOK_AUTOMATIZACIONES_URL, {
      method: 'POST',
      body: JSON.stringify(payload),
      timeout: 10_000,  // Max 10 segundos
    })
      .catch(err => logger.error('Webhook failed', err))
      // ↑ Log pero no falla
  } catch (err) {
    logger.error('Webhook error', err);
    // Continuar sin bloquear
  }
}

// Usuario ve transcripción AL INSTANTE
// IA procesa EN BACKGROUND (15-25 segundos después)
```

### 6. **Transacciones en Prisma**

Garantizar consistencia:

```typescript
// automatizaciones/src/db-writer.ts
const result = await prisma.$transaction(async (tx) => {
  // Crear NotaAudio
  const notaAudio = await tx.notaAudio.create({ ... });

  // Crear Tarea relacionada
  const tarea = await tx.tarea.create({
    data: { notaAudioId: notaAudio.id, ... }
  });

  return { notaAudio, tarea };
});
// Si falla cualquiera → ROLLBACK automático
```

---

## 🔍 Flow: Rastreando un Request

### Request: Usuario envía "Teo, llamar a María"

```
T+0s: Usuario graba audio en Telegram

T+1s: telegram-bot recibe updatede Telegram
      ├─ getUpdates() → encuentra message.voice
      ├─ getFile() → obtiene file_id
      ├─ downloadFile() → descarga binary
      └─ POST /api/process-audio

T+2s: next-app recibe POST
      const audioFile = formData.get('audio')
      const metadata = requestSchema.parse(...)

T+3s: [PARALELO]
      ├─ uploadToR2(buffer)
      │   └─ @aws-sdk/client-s3
      │       └─ Cloudflare R2
      │           └─ r2://transcripciones/audio_123.ogg
      │
      └─ transcribeAudioWithRetry(buffer)
          └─ OpenAI Whisper API
              └─ "Teo, llamar a María mañana a las 3pm"

T+8s: Ambos terminan
      ├─ prisma.transcripcion.create({
      │   estado: 'PROCESANDO',
      │   texto: '',
      │   ...
      │ })
      │
      └─ prisma.transcripcion.update({
          estado: 'COMPLETADO',
          texto: 'Teo, llamar a María...',
          r2_url: 'https://r2.example.com/...',
          r2_key: 'transcripciones/audio_123.ogg'
        })

T+9s: notifyAutomatizaciones() [FIRE-AND-FORGET]
      POST http://automatizaciones:3100/webhook
      {
        "transcripcionId": 123,
        "texto": "Teo, llamar a María...",
        "archivoUrl": "https://r2.example.com/...",
        "fecha": "2025-12-01T10:30:00Z"
      }

T+9s: Retorna al telegram-bot
      { success: true, transcriptionId: 123, texto: "..." }

T+10s: telegram-bot recibe respuesta
       sendMessage(userId, "✅ Transcripción guardada")

T+10-15s: [BACKGROUND] automatizaciones procesa (asyncrono)
          POST /webhook recibido
          ├─ detectTipoFromTranscription("Teo...")
          │   └─ tipo: "tarea", confianza: 1.0
          │
          ├─ createNotaAudio()
          │   └─ INSERT notas_audio (transcripcionId=123, ...)
          │
          ├─ extractEntities("llamar a María...", "tarea")
          │   └─ OpenAI GPT-4o-mini
          │       └─ { titulo, fechaVencimiento, prioridad, ... }
          │
          └─ saveExtraction()
              └─ INSERT tareas (notaAudioId=45, titulo="Llamar a María", ...)

T+15s: ✅ Todo completado
       - Transcripción en transcripciones_db.transcripciones
       - Tarea en asistente_db.tareas
       - Usuario ve en NocoDB (si está conectado)
```

---

## 🎯 Dónde Agregar Nueva Funcionalidad

### Caso 1: Agregar Nuevo Endpoint a la API

**Archivo**: `next-app/src/app/api/[feature]/route.ts`

```typescript
// next-app/src/app/api/mi-feature/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { logger } from '@/lib/logger';

const schema = z.object({
  param1: z.string(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validated = schema.parse(body);

    logger.info('Mi feature ejecutado', { param1: validated.param1 });

    // Tu lógica aquí

    return NextResponse.json({ success: true });
  } catch (error) {
    logger.error('Mi feature error', error);
    return NextResponse.json(
      { success: false, error: String(error) },
      { status: 500 }
    );
  }
}
```

### Caso 2: Agregar Nuevo Tipo de Extracción

**Archivos a modificar**:
1. `automatizaciones/prisma/schema.prisma` → Nuevo modelo
2. `automatizaciones/src/types.ts` → Nuevo tipo
3. `automatizaciones/src/ai-extractor.ts` → Nuevo prompt
4. `automatizaciones/src/processor.ts` → Nuevo case

**Ejemplo: Agregar "EVENTO"**

```typescript
// 1. schema.prisma
model Evento {
  id Int @id
  titulo String
  fechaEvento DateTime
  ubicacion String?
  notaAudioId Int
  notaAudio NotaAudio @relation(fields: [notaAudioId], references: [id], onDelete: Cascade)
}

// 2. types.ts
export type ExtractionType = 'tarea' | 'registro' | 'idea' | 'compromiso' | 'evento' | 'sin_clasificar';

// 3. ai-extractor.ts
case 'evento':
  return extractEvento(texto);  // Nueva función

async function extractEvento(texto: string) {
  const prompt = `Extrae un evento de: "${texto}"
  JSON: { titulo, fechaEvento, ubicacion? }`;
  // ...
}

// 4. keyword-matcher.ts
// Agregar keyword para evento:
{ input: 'Evento', tipo: 'evento' }

// 5. processor.ts
case 'evento':
  await tx.evento.create({ data: { notaAudioId: notaAudio.id, ...extraccion } });
  break;
```

### Caso 3: Agregar Nueva Tarea Cron

**Archivo**: `automatizaciones/src/scheduler.ts`

```typescript
// Nueva tarea cron: Resumen semanal (viernes 20:00)
new CronJob(
  "0 20 * * 5",  // Viernes a las 20:00
  async () => {
    logger.info('Ejecutando resumen semanal');
    const resumenSemanal = await generateWeeklySummary();
    await telegramClient.sendMessage(
      process.env.TELEGRAM_CHAT_ID,
      resumenSemanal
    );
  },
  null,
  true,
  "America/Montevideo"
);
```

---

## 🧪 Testing Local

### Test 1: Health Checks

```bash
curl http://localhost:1400/api/health
curl http://localhost:1410/health
```

### Test 2: Fuzzy Matching

```bash
# Prueba keywords
curl http://localhost:1410/test/keywords/theo
curl http://localhost:1410/test/keywords/cuando
curl http://localhost:1410/test/keywords/idea
curl http://localhost:1410/test/keywords/compa
```

### Test 3: Webhook Manual

```bash
curl -X POST http://localhost:1410/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "transcripcionId": 999,
    "texto": "Teo, llamar a María mañana a las 3pm",
    "archivoUrl": "https://example.com/audio.ogg",
    "fecha": "2025-12-01T10:30:00Z"
  }'
```

### Test 4: Ver Logs en Vivo

```bash
# Todos los servicios
docker-compose logs -f

# Específico
docker-compose logs -f next-app
docker-compose logs -f automatizaciones
docker-compose logs -f telegram-bot
```

### Test 5: Ver Datos en BD

```bash
# Transcripciones
docker-compose exec postgres-db psql -U asistente -d transcripciones_db -c \
  "SELECT id, LEFT(texto, 50) as texto, estado FROM transcripciones ORDER BY created_at DESC LIMIT 5;"

# Tareas extraídas
docker-compose exec postgres-db psql -U asistente -d asistente_db -c \
  "SELECT id, titulo, prioridad FROM tareas ORDER BY created_at DESC LIMIT 5;"

# O usar Prisma Studio (interfaz gráfica):
docker-compose exec next-app npx prisma studio
# Abre http://localhost:5555
```

---

## 🐛 Debugging

### "Bot no responde"

```bash
# 1. Ver logs del bot
docker-compose logs telegram-bot | tail -50

# 2. Verificar token
echo $TELEGRAM_BOT_TOKEN

# 3. Verificar que next-app está healthy
curl http://localhost:1400/api/health

# 4. Reiniciar
docker-compose restart telegram-bot
```

### "Transcripción lenta"

```bash
# 1. Ver logs de next-app
docker-compose logs next-app | grep -i whisper

# 2. Verificar OpenAI API key
docker-compose exec next-app sh -c 'echo $OPENAI_API_KEY | cut -c 1-10'

# 3. Probar Whisper manualmente (local)
# Crear un script test-whisper.ts...
```

### "Entidades no se guardan"

```bash
# 1. Ver logs de automatizaciones
docker-compose logs automatizaciones | tail -100

# 2. Verificar conexión a asistente_db
docker-compose exec postgres-db pg_isready -U asistente -d asistente_db

# 3. Ver si webhook llega
# Agregar log en /webhook handler

# 4. Verificar que Prisma migrate está corrido
docker-compose exec automatizaciones npm run prisma:deploy
```

---

## 📋 Checklist: Antes de Hacer un PR

- [ ] Código compila sin errores TS
- [ ] Código está formateado (prettier)
- [ ] Logs estructurados con Winston
- [ ] Validación de entrada con Zod
- [ ] Error handling completo (try-catch)
- [ ] Tipo de datos explícitos (no `any`)
- [ ] Test manual en local
- [ ] No hay credenciales en código
- [ ] Documentación actualizada
- [ ] Si cambias BD → Nueva migración Prisma
- [ ] Si cambias .env → Actualizar .env.example

---

## 🎓 Recursos

### Documentación
- [Next.js Docs](https://nextjs.org/docs)
- [Prisma Docs](https://www.prisma.io/docs)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [Zod Documentation](https://zod.dev)
- [OpenAI API](https://platform.openai.com/docs)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)
- [Telegram Bot API](https://core.telegram.org/bots/api)

### Tutoriales Recomendados
- TypeScript: [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- async/await: [JavaScript async-await](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous/Promises)
- PostgreSQL: [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)

---

## ❓ Preguntas Frecuentes

**P: ¿Dónde agrego un nuevo campo a una tarea?**
A:
1. Edita `automatizaciones/prisma/schema.prisma` (modelo `Tarea`)
2. Crea migración: `docker-compose exec automatizaciones npm run prisma:migrate`
3. Actualiza prompt en `ai-extractor.ts`
4. Actualiza `saveExtraction()` en `db-writer.ts`

**P: ¿Cómo agrego soporte para otro idioma?**
A:
1. Cambiar prompts en `ai-extractor.ts` a otro idioma
2. Cambiar keywords en `keyword-matcher.ts`
3. Cambiar configuración de Whisper language a `es`, `en`, etc
4. Probar con audios en ese idioma

**P: ¿Puedo usar la API desde un cliente externo?**
A: Sí, todos los endpoints en `next-app` aceptan CORS (check `middleware`). Pero agrega rate limiting en producción.

**P: ¿Cómo agrego un nuevo tipo de modelo OpenAI?**
A: Edita variables en .env y pasa a los clientes. Ejemplo:
```bash
OPENAI_MODEL=gpt-4-turbo  # En lugar de gpt-4o-mini
```

---

## 🚀 Próximos Pasos

1. **Setup local** → 15 min
2. **Leer ARCHITECTURE.md** → 30 min
3. **Leer código fuente** → 1 hora
   - next-app/src/app/api/process-audio/route.ts
   - automatizaciones/src/processor.ts
   - automatizaciones/src/ai-extractor.ts
4. **Probar con un audio real** → 10 min
5. **Agregar tu primera feature** → depende

---

**¡Bienvenido al equipo MATEOS!** 🚀
