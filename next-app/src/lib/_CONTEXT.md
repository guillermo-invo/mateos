# _CONTEXT.md - Lib (Utilidades y Clientes)

## PROPÓSITO

Utilidades compartidas, clientes externos, y configuración de servicios. Incluye singletons de Prisma, loggers, clientes de APIs externas (OpenAI, R2, Whisper).

---

## STACK TÉCNICO ESPECÍFICO

- **Prisma:** 6.18.0 (ORM)
- **Winston:** 3.11.0 (Logger)
- **AWS SDK S3:** Para Cloudflare R2 (S3-compatible)
- **OpenAI:** API client (Whisper)

---

## ARCHIVOS Y SU PROPÓSITO

### prisma.ts (Singleton Prisma Client)

**Propósito:** Cliente Prisma compartido en toda la aplicación.

**Pattern:**
```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = global as unknown as { prisma: PrismaClient }

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

**Razón del singleton:**
- Next.js en desarrollo hace hot reload
- Cada reload crearía nueva conexión a DB
- Singleton previene "too many connections"

**Uso:**
```typescript
import { prisma } from '@/lib/prisma'

const users = await prisma.user.findMany()
```

**⚠️ CRÍTICO:**
- NUNCA crear `new PrismaClient()` en otros archivos
- SIEMPRE importar desde `@/lib/prisma`

---

### logger.ts (Winston Logger)

**Propósito:** Logger centralizado para toda la aplicación.

**Configuración:**
```typescript
import winston from 'winston'

const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
})

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }))
}

export default logger
```

**Uso:**
```typescript
import logger from '@/lib/logger'

logger.info('Usuario creado', { userId: '123' })
logger.error('Error en API', { error: err.message, stack: err.stack })
logger.warn('Rate limit alcanzado', { ip: req.ip })
logger.debug('Query ejecutado', { query: 'SELECT * FROM...' })
```

**Niveles (prioridad ascendente):**
1. `debug`: Info detallada para desarrollo
2. `info`: Info general de operaciones
3. `warn`: Situaciones anormales pero recuperables
4. `error`: Errores que requieren atención

**⚠️ NO loggear:**
- Passwords, tokens, API keys
- PII (Personally Identifiable Information) sin necesidad
- Cada request (crear ruido)

---

### r2-client.ts (Cloudflare R2 Client)

**Propósito:** Cliente para almacenar archivos en Cloudflare R2 (S3-compatible storage).

**Uso principal:** Almacenar audios de notas de voz.

**Configuración:**
```typescript
import { S3Client } from '@aws-sdk/client-s3'

export const r2Client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
})
```

**Ejemplo de uso:**
```typescript
import { r2Client } from '@/lib/r2-client'
import { PutObjectCommand } from '@aws-sdk/client-s3'

const command = new PutObjectCommand({
  Bucket: process.env.R2_BUCKET_NAME,
  Key: `audios/${Date.now()}-${filename}`,
  Body: fileBuffer,
  ContentType: 'audio/ogg', // o audio/mpeg, etc.
})

await r2Client.send(command)
```

**⚠️ Límites Cloudflare R2 (free tier):**
- 10GB storage
- 100 req/min (rate limit)
- NO tiene egress fees (a diferencia de AWS S3)

**⚠️ Gotchas:**
- Region DEBE ser `'auto'` para R2
- Endpoint incluye account ID
- Keys en `.env`, NUNCA commitear

---

### whisper-client.ts (OpenAI Whisper API Client)

**Propósito:** Cliente para transcribir audios de notas de voz con Whisper.

**Configuración:**
```typescript
import OpenAI from 'openai'

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

export async function transcribeAudio(audioBuffer: Buffer, filename: string): Promise<string> {
  const file = new File([audioBuffer], filename, { type: 'audio/ogg' })

  const transcription = await openai.audio.transcriptions.create({
    file: file,
    model: 'whisper-1',
    language: 'es', // Español
  })

  return transcription.text
}
```

**Modelo:**
- `whisper-1` (único modelo disponible actualmente)

**Límites:**
- Max file size: 25MB
- Formatos soportados: mp3, mp4, mpeg, mpga, m4a, wav, webm, ogg
- Language: especificar `'es'` para mejor precisión en español

**⚠️ Gotcha CRÍTICO:**
```typescript
// ⚠️ Whisper retorna "undefined" si audio < 0.1 segundos
// SIEMPRE validar duración del audio ANTES de enviar

if (audioDuration < 0.1) {
  throw new Error('Audio demasiado corto para transcribir')
}
```

**Costos:**
- $0.006 / minuto de audio
- Monitorear uso en `logs/openai-usage.log`

---

### model-config.ts (Configuración de Modelos IA)

**Propósito:** Configuración centralizada de modelos de IA (GPT, Whisper).

**Contenido típico:**
```typescript
export const MODEL_CONFIG = {
  gpt: {
    model: 'gpt-4-turbo-preview',
    temperature: 0.7,
    max_tokens: 4096,
  },
  whisper: {
    model: 'whisper-1',
    language: 'es',
  },
}
```

**Uso:**
```typescript
import { MODEL_CONFIG } from '@/lib/model-config'

const completion = await openai.chat.completions.create({
  model: MODEL_CONFIG.gpt.model,
  temperature: MODEL_CONFIG.gpt.temperature,
  messages: [...],
})
```

---

### serializePrisma.ts (Serialización de Datos Prisma)

**Propósito:** Convertir tipos especiales de Prisma (Decimal, Date, BigInt) a tipos serializables en JSON.

**Problema:** Prisma devuelve `Decimal` como objetos que se serializan a strings en JSON.

**Solución:**
```typescript
import { Prisma } from '@prisma/client'

function convertPrismaValue(value: unknown): unknown {
  if (value === null || value === undefined) return value
  
  if (typeof value === 'bigint') return Number(value)
  
  if (value instanceof Prisma.Decimal) return value.toNumber()
  
  if (value instanceof Date) return value
  
  if (Array.isArray(value)) {
    return value.map(item => convertPrismaValue(item))
  }
  
  if (typeof value === 'object') {
    const converted: Record<string, unknown> = {}
    for (const [key, val] of Object.entries(value)) {
      converted[key] = convertPrismaValue(val)
    }
    return converted
  }
  
  return value
}

export function serializePrismaData<T>(data: T): T {
  return convertPrismaValue(data) as T
}
```

**Uso:**
```typescript
import { serializePrismaData } from '@/lib/serializePrisma'

const proyecto = await prisma.proyectoEstrategico.findUnique({ where: { id } })
const serialized = serializePrismaData(proyecto)

return NextResponse.json({ success: true, data: serialized })
```

**⚠️ IMPORTANTE:**
- Usar en API routes ANTES de `NextResponse.json()`
- Convierte Decimals a números, no a strings
- Maneja objetos anidados y arrays recursivamente

---

### automatizaciones-webhook.ts (Cliente Webhook Automatizaciones)

**Propósito:** Cliente para notificar eventos al microservicio de automatizaciones.

**Uso:**
```typescript
export async function notifyAutomatizaciones(event: string, data: any) {
  const url = process.env.AUTOMATIZACIONES_WEBHOOK_URL

  try {
    await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ event, data }),
    })
  } catch (error) {
    logger.error('Error notificando automatizaciones:', error)
    // NO lanzar error, automatizaciones es opcional
  }
}
```

**Eventos típicos:**
- `idea.created`: Nueva idea capturada
- `proyecto.created`: Nuevo proyecto creado
- `nota_voz.procesada`: Nota de voz transcrita

**⚠️ IMPORTANTE:**
- El webhook es OPCIONAL (el sistema funciona sin automatizaciones)
- NO lanzar error si falla (solo loggear)
- Timeout: 5s (automatizaciones no debe bloquear frontend)

---

## REGLAS Y RESTRICCIONES

### Singleton Pattern

#### ✅ SIEMPRE usar singleton para:
- Prisma Client (`prisma.ts`)
- Winston Logger (`logger.ts`)
- Clientes externos (OpenAI, R2)

#### ❌ NUNCA:
- Crear múltiples instancias de Prisma
- Crear loggers ad-hoc (usar logger centralizado)

### Environment Variables

#### ✅ SIEMPRE:
- Validar que existen al inicio (lanzar error si falta)
- Usar `process.env.VAR_NAME` con `!` si es required
- Documentar en `.env.example`

```typescript
if (!process.env.OPENAI_API_KEY) {
  throw new Error('OPENAI_API_KEY no está definida en .env')
}
```

#### ❌ NUNCA:
- Commitear `.env` al repo
- Hardcodear valores (usar .env)
- Asumir que variable existe (validar)

### Error Handling en Clientes Externos

#### ✅ SIEMPRE:
- Wrap llamadas a APIs externas en try/catch
- Loggear errores con contexto
- Retornar error amigable al usuario (NO exponer detalles de API)
- Implementar retry con backoff para errores transitorios

```typescript
import logger from '@/lib/logger'

export async function transcribeAudio(buffer: Buffer): Promise<string> {
  try {
    const result = await openai.audio.transcriptions.create({...})
    return result.text
  } catch (error) {
    logger.error('Error transcribiendo audio:', {
      error: error.message,
      stack: error.stack,
    })
    throw new Error('Error al transcribir audio. Intenta de nuevo.')
  }
}
```

---

## NOTAS PARA IA

### ⚠️ Prisma Schema Sync
- Schema en `next-app/prisma/schema.prisma` es COPIA
- Source of truth: `automatizaciones/prisma/schema.prisma`
- Proceso:
  1. Modificar schema en automatizaciones
  2. Ejecutar `npx prisma migrate dev` en automatizaciones
  3. Copiar schema a next-app
  4. Ejecutar `npx prisma generate` en next-app

### ⚠️ Hot Reload en Desarrollo
- Singleton pattern previene múltiples conexiones DB
- Si ves error "too many connections", revisar que se use singleton

### ⚠️ Cloudflare R2 vs AWS S3
- R2 es S3-compatible pero NO es S3
- Endpoint es diferente: `https://[account-id].r2.cloudflarestorage.com`
- Region DEBE ser `'auto'`
- NO usar AWS S3 SDK v2 (usar v3: `@aws-sdk/client-s3`)

### ⚠️ Whisper Audio Duration
```typescript
// Validar duración ANTES de llamar Whisper
// Usar biblioteca como `mp3-duration` o `get-audio-duration`
import { getAudioDurationInSeconds } from 'get-audio-duration'

const duration = await getAudioDurationInSeconds(audioPath)
if (duration < 0.1) {
  throw new Error('Audio demasiado corto')
}
```

---

## TESTING

### Mocking de Clientes

**En tests e2e, mockear:**
- OpenAI API (usar respuestas fijas)
- Cloudflare R2 (usar filesystem temporal)
- Automatizaciones webhook (no llamar realmente)

**Ejemplo con Playwright:**
```typescript
await page.route('**/openai.com/**', route => {
  route.fulfill({
    status: 200,
    body: JSON.stringify({ text: 'Transcripción de prueba' }),
  })
})
```

---

## CAMBIOS RECIENTES

### 2026-01-07: Serialización de Decimals

**Agregado:**
- `serializePrisma.ts`: Helper para convertir Decimals a números
- Soluciona problema de campos `scoreMotivacional`, `scoreAlineacion` devueltos como strings

**Uso en API routes:**
```typescript
import { serializePrismaData } from '@/lib/serializePrisma'

const proyecto = await prisma.proyectoEstrategico.findUnique({...})
return NextResponse.json({
  success: true,
  data: serializePrismaData(proyecto)
})
```

---

**Última actualización:** 2026-01-07
**Cambios:** Agregado serializePrisma helper
**Versión:** 1.1
