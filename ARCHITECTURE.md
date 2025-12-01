# 🏗️ MATEOS - Arquitectura Completa del Proyecto

**Última actualización**: Diciembre 2025
**Estado**: Producción
**Versión**: 1.0.0 (MVP)

---

## 📋 Índice

1. [Visión General](#visión-general)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Arquitectura de Servicios](#arquitectura-de-servicios)
4. [Flujo de Datos End-to-End](#flujo-de-datos-end-to-end)
5. [Estructura de Bases de Datos](#estructura-de-bases-de-datos)
6. [Servicios en Detalle](#servicios-en-detalle)
7. [Decisiones Arquitectónicas](#decisiones-arquitectónicas)
8. [Deployment y Operaciones](#deployment-y-operaciones)
9. [Puntos Críticos y Lecciones Aprendidas](#puntos-críticos-y-lecciones-aprendidas)
10. [Próximas Fases](#próximas-fases)

---

## 🎯 Visión General

**MATEOS** es un asistente personal inteligente que:

1. **Captura** notas de voz por Telegram
2. **Transcribe** audio usando OpenAI Whisper
3. **Procesa** transcripciones con IA (GPT-4o-mini)
4. **Extrae** entidades (tareas, registros, compromisos, ideas)
5. **Almacena** de forma estructurada en PostgreSQL
6. **Visualiza** en NocoDB (opcional pero recomendado)

**Propósito**: Convertir notas rápidas de voz en información estructurada y procesable, permitiendo al usuario mantener un registro automático y enriquecido de sus actividades, compromisos e ideas.

---

## 🛠️ Stack Tecnológico

### Runtime & Languages
- **Node.js**: 20.11.0+ (LTS actual)
- **TypeScript**: 5.7.0 (todo el código está tipado)
- **Lenguaje**: Español (comentarios y variables)

### Frontend & API
- **Next.js**: 15.5.0 (App Router, no Pages)
  - Servicio full-stack (API + Frontend)
  - API Routes en `/src/app/api/*`
  - Server-side Rendering donde aplica
  - React 19.0.0 (última versión)

### Backend & Servicios
- **Express.js**: 4.18.2 (servicio automatizaciones)
- **Prisma**: 6.18.0 (ORM - 2 esquemas independientes)
- **Zod**: 3.22.4 (validación de esquemas)

### Base de Datos
- **PostgreSQL**: 15.5-alpine
  - 2 bases de datos independientes:
    - `transcripciones_db`: Fuente original
    - `asistente_db`: Datos procesados y enriquecidos

### APIs Externas
- **OpenAI API**:
  - Whisper (transcripción de audio)
  - GPT-4o-mini (extracción de entidades)
- **Cloudflare R2** (S3-compatible):
  - Almacenamiento de archivos de audio
  - Primeros 10GB gratis
- **Telegram Bot API**:
  - Polling (no webhooks, para simplicidad)
  - node-telegram-bot-api v0.66.0

### Almacenamiento & Storage
- **Docker Volumes**: `postgres-data` para persistencia
- **Cloudflare R2**: Archivos de audio (.ogg)
- **S3 SDK**: AWS SDK compatible con R2

### Logging & Monitoreo
- **Winston**: 3.11.0 (logging estructurado)
- **Docker Compose Healthchecks**: Verificación automática

### Containerización
- **Docker**: Multi-container orchestration
- **Docker Compose**: 3.9 (local + producción)
- **Imágenes base**:
  - `node:20-alpine` (aplicaciones Node)
  - `postgres:15.5-alpine` (base de datos)

### Utilitarios
- **fastest-levenshtein**: 1.0.16 (fuzzy matching para keywords)
- **cors**: 2.8.5 (cross-origin requests)
- **node-cron**: 3.0.3 (tareas programadas - resumen diario)
- **form-data**: 4.0.0 (multipart/form-data)
- **axios**: 1.6.7 (HTTP client)

---

## 🏛️ Arquitectura de Servicios

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                   USUARIO EN TELEGRAM                        │
└────────────────────┬────────────────────────────────────────┘
                     │ [Envía nota de voz]
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  TELEGRAM BOT SERVICE (telegram-bot:3000)                     │
│  • Recibe actualizaciones de Telegram via polling             │
│  • Descarga archivos de audio                                 │
│  • Envía respuestas al usuario                               │
└────────────────┬──────────────────────────────────────────────┘
                 │ POST /api/process-audio
                 ▼
┌──────────────────────────────────────────────────────────────┐
│  NEXT.JS API SERVICE (next-app:3000)                         │
│  • Router: POST /api/process-audio                            │
│  • 1️⃣ Valida entrada con Zod                                │
│  • 2️⃣ Sube audio a Cloudflare R2 (paralelo)                 │
│  • 3️⃣ Transcribe con OpenAI Whisper (paralelo)              │
│  • 4️⃣ Guarda en transcripciones_db                           │
│  • 5️⃣ Llama webhook a automatizaciones                       │
│  • 6️⃣ Retorna transcripción al bot                           │
└──────────────────────────────────────────────────────────────┘
                        │
           ┌────────────┴────────────────────┐
           │ Webhook (HTTP)                  │
           │ URL: http://automatizaciones:3100/webhook
           ▼                                  ▼
    [R2 STORAGE]              ┌──────────────────────────────┐
    .ogg files                │  AUTOMATIZACIONES SERVICE    │
                              │  (automatizaciones:3100)     │
                              │  • Express.js server         │
                              │  • 1️⃣ Detecta tipo (fuzzy)   │
                              │  • 2️⃣ Extrae entidades (IA) │
                              │  • 3️⃣ Guarda en asistente_db│
                              │  • 4️⃣ Envia resumen a TG     │
                              │  • 5️⃣ Tareas cron diarias    │
                              └──────────────────────────────┘
                                        │
                    ┌───────────────────┴────────────────┐
                    ▼                                     ▼
            [PostgreSQL DB]                      [NocoDB] (opcional)
            • transcripciones_db                • Visualización
            • asistente_db                      • Edición manual
```

### Servicios Docker

| Servicio | Imagen | Puerto | Propósito | Dependencia |
|----------|--------|--------|-----------|-------------|
| **postgres-db** | `postgres:15.5-alpine` | 1432:5432 | Base de datos | - |
| **next-app** | `node:20-alpine` (build custom) | 1400:3000 | API + Transcripción | postgres-db (healthy) |
| **automatizaciones** | `node:20-alpine` (build custom) | 1410:3100 | Procesamiento IA | postgres-db (healthy) |
| **telegram-bot** | `node:20-alpine` (build custom) | - (no expuesto) | Bot de Telegram | next-app (healthy) |

---

## 🔄 Flujo de Datos End-to-End

### Timeline Típico (Usuario envía: "Teo, llamar a María")

```
T+0s   → Usuario graba nota de voz en Telegram (5 segundos de audio)
         Mensaje: "Teo, llamar a María mañana a las 3pm"

T+1-2s → telegram-bot recibe actualización (polling cada 300ms)
         Descarga archivo de audio (Telegram servers)

T+2-3s → telegram-bot envía POST a next-app:3000/api/process-audio
         FormData:
         - audio: <binary>
         - metadata: { userId, messageId, telegramFileId, duration }

T+3-5s → next-app procesa en paralelo:
         1. Valida entrada con Zod
         2. uploadToR2() → Cloudflare R2
         3. transcribeAudioWithRetry() → OpenAI Whisper

T+5-8s → Whisper retorna: "Teo, llamar a María mañana a las 3pm"

T+8-9s → next-app:
         1. Crea registro en transcripciones_db
         2. Estado: PROCESANDO → COMPLETADO
         3. Guarda r2_url, r2_key

T+9s   → next-app notifyAutomatizaciones() via HTTP webhook
         POST http://automatizaciones:3100/webhook
         Body: {
           transcripcionId: 123,
           texto: "Teo, llamar a María...",
           archivoUrl: "https://r2.example.com/audio_123.ogg",
           fecha: "2025-12-01T10:30:00Z"
         }

T+9-10s → telegram-bot recibe respuesta
          Envía al usuario: "✅ Transcripción guardada"

T+10-15s → [BACKGROUND] automatizaciones procesa:
           1. detectTipoFromTranscription("Teo...") → tipo: "tarea"
           2. createNotaAudio(123, ..., detection)
           3. extractEntities("llamar a María...", "tarea")
           4. GPT-4o-mini extrae:
              - titulo: "Llamar a María"
              - fechaVencimiento: 2025-12-02 15:00
              - prioridad: MEDIA
           5. saveExtraction() → asistente_db.tareas

T+15s  → Resumen procesamiento guardado en logs
         Usuario ve en NocoDB nueva tarea (si está conectado)
```

### Variantes del Flujo

#### Caso: Sin Keyword Detectada ("Nota random")
```
T+10-15s → automatizaciones:
           1. detectTipoFromTranscription("Hoy fui al cine...") → sin_clasificar
           2. createNotaAudio() con tipo: null
           3. NO extrae entidades
           4. Guarda nota_audio pero sin datos en tareas/registros/etc
           5. Usuario puede editar manualmente en NocoDB
```

#### Caso: Error en Transcripción
```
T+5s → Whisper falla (audio corrupto, inaudible, etc)
        next-app:
        1. Retorna error al telegram-bot
        2. Guarda en transcripciones_db:
           - estado: ERROR
           - error_msg: "Audio file too short"
        3. NO llama webhook (no hay qué procesar)

T+6s → telegram-bot envía al usuario: "❌ Error procesando audio"
```

---

## 🗄️ Estructura de Bases de Datos

### PostgreSQL Setup

```
HOST: postgres-db (dentro de Docker)
      localhost:1432 (desde host local)
USER: asistente
PASS: n8npass (cambiar en producción)
```

#### Base de Datos 1: `transcripciones_db`

**Propósito**: Fuente de verdad de audios originales y transcripciones.

```sql
-- Tabla: transcripciones
CREATE TABLE transcripciones (
  id              SERIAL PRIMARY KEY,
  hora            TIMESTAMPTZ DEFAULT now(),
  texto           TEXT NOT NULL,              -- Transcripción

  -- R2 Storage
  r2_url          VARCHAR(512),               -- URL pública del audio
  r2_key          VARCHAR(256),               -- Key en R2

  -- Telegram Metadata
  telegram_file_id   VARCHAR(256),            -- Para deduplicación
  telegram_user_id   BIGINT,                  -- ID del usuario TG
  telegram_message_id BIGINT,                 -- ID del mensaje TG

  -- Audio Info
  duracion_segundos  INT,                     -- Duración en segundos
  tamano_bytes       BIGINT,                  -- Tamaño en bytes

  -- Audit
  created_at         TIMESTAMPTZ DEFAULT now(),
  updated_at         TIMESTAMPTZ DEFAULT now(),

  -- Status
  estado             ENUM('PROCESANDO', 'COMPLETADO', 'ERROR'),
  error_msg          TEXT,

  -- Índices
  INDEX (telegram_user_id),
  INDEX (created_at),
  INDEX (estado)
);
```

**Relaciones**: Uno a uno conceptual con `asistente_db.notas_audio` (via `transcripcionId`)

#### Base de Datos 2: `asistente_db`

**Propósito**: Datos enriquecidos y procesados por IA.

##### Tabla: `notas_audio`
```sql
-- Referencia enriquecida a transcripción original
CREATE TABLE notas_audio (
  id                    SERIAL PRIMARY KEY,
  transcripcionId       INT UNIQUE,            -- FK a transcripciones_db
  transcripcionCompleta TEXT,                  -- Copia de texto original
  archivoAudioUrl       VARCHAR(512),          -- Copia de r2_url
  resumenEjecutivo      TEXT,                  -- Generado por IA (futuro)
  fechaGrabacion        TIMESTAMPTZ,
  procesado             BOOLEAN DEFAULT false, -- ¿Fue procesado con IA?
  tipoDetectado         VARCHAR(50),           -- "tarea", "registro", "idea", "compromiso", "sin_clasificar"
  confianzaDeteccion    FLOAT,                 -- 0.0-1.0 (fuzzy matching score)

  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  INDEX (transcripcionId),
  INDEX (procesado),
  INDEX (tipoDetectado),
  INDEX (fechaGrabacion)
);
```

##### Tabla: `tareas`
```sql
-- Tareas extraídas de tipo "tarea"
CREATE TABLE tareas (
  id                  SERIAL PRIMARY KEY,
  titulo              VARCHAR(255) NOT NULL,
  descripcion         TEXT,
  fechaVencimiento    TIMESTAMPTZ,           -- Cuando debe hacerse
  prioridad           ENUM('BAJA', 'MEDIA', 'ALTA', 'URGENTE'),
  completada          BOOLEAN DEFAULT false,
  fechaCompletada     TIMESTAMPTZ,

  notaAudioId         INT NOT NULL,          -- FK a notas_audio (CASCADE delete)

  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now(),

  INDEX (notaAudioId),
  INDEX (completada),
  INDEX (fechaVencimiento),
  INDEX (prioridad)
);
```

##### Tabla: `registros`
```sql
-- Actividades YA REALIZADAS (pasado)
CREATE TABLE registros (
  id                    SERIAL PRIMARY KEY,
  descripcion           TEXT NOT NULL,
  duracionHoras         FLOAT,                 -- Cuántas horas tomó
  proyecto              VARCHAR(255),          -- En qué proyecto
  personasInvolucradas  TEXT[],                -- Array de nombres
  categoria             ENUM('TRABAJO', 'PERSONAL', 'SOCIAL', 'OTRO'),
  fechaActividad        TIMESTAMPTZ,

  notaAudioId           INT NOT NULL,          -- FK a notas_audio

  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  INDEX (notaAudioId),
  INDEX (fechaActividad),
  INDEX (categoria),
  INDEX (proyecto)
);
```

##### Tabla: `compromisos`
```sql
-- Compromisos/acuerdos con personas
CREATE TABLE compromisos (
  id                INT SERIAL PRIMARY KEY,
  titulo            VARCHAR(255) NOT NULL,
  descripcion       TEXT,
  personaNombre     VARCHAR(255) NOT NULL,   -- Con quién
  fechaLimite       TIMESTAMPTZ,             -- Cuándo debe cumplirse
  yoMeComprometi    BOOLEAN DEFAULT false,   -- true: yo prometí, false: otra persona prometió
  cumplido          BOOLEAN DEFAULT false,
  fechaCumplido     TIMESTAMPTZ,

  notaAudioId       INT NOT NULL,            -- FK a notas_audio

  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now(),

  INDEX (notaAudioId),
  INDEX (cumplido),
  INDEX (fechaLimite),
  INDEX (personaNombre)
);
```

##### Tabla: `ideas`
```sql
-- Ideas capturadas
CREATE TABLE ideas (
  id                    SERIAL PRIMARY KEY,
  titulo                VARCHAR(255) NOT NULL,
  descripcion           TEXT,
  categoria             VARCHAR(100),         -- "Producto", "Negocio", "Personal", etc
  implementada          BOOLEAN DEFAULT false,
  fechaImplementacion   TIMESTAMPTZ,

  notaAudioId           INT NOT NULL,         -- FK a notas_audio

  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  INDEX (notaAudioId),
  INDEX (implementada),
  INDEX (categoria)
);
```

### Estrategia de Datos

- **Single Source of Truth (SSOT)**: `transcripciones_db` es el original
- **Denormalización Intencional**: Copia de datos en `asistente_db` para independencia
- **Cascade Delete**: Borrar `nota_audio` borra todas sus entidades relacionadas
- **Índices Estratégicos**: En campos frecuentemente filtrados (usuario, fecha, estado)
- **Sin relaciones FK entre DBs**: Las 2 BD son independientes (escalabilidad futura)

---

## 🔧 Servicios en Detalle

### 1. Telegram Bot Service (`telegram-bot/`)

**Ubicación**: `/home/azureuser/mateos/telegram-bot`

**Estructura**:
```
telegram-bot/
├── src/
│   ├── index.ts           # Entry point, polling loop
│   ├── types.ts           # Tipos TypeScript
│   └── logger.ts          # Winston logger
├── Dockerfile             # Build multi-stage
├── package.json           # Dependencies
├── tsconfig.json          # Config TS
└── .dockerignore
```

**Tecnologías**:
- node-telegram-bot-api 0.66.0
- axios 1.6.7 (HTTP client)
- winston 3.11.0 (logging)
- TypeScript 5.7.0

**Responsabilidades**:
1. **Polling**: Cada 300ms pide updates a Telegram API
2. **Download**: Descarga archivos de audio de servidores Telegram
3. **Forward**: Envía POST a `next-app:3000/api/process-audio`
4. **Response**: Retorna transcripción al usuario
5. **Logging**: Registra todos los eventos

**Variables de Entorno**:
```bash
TELEGRAM_BOT_TOKEN=...              # Token del bot (@BotFather)
API_ENDPOINT=http://next-app:3000/api/process-audio
LOG_LEVEL=info
NODE_ENV=production
```

**Flujo Interno**:
```typescript
1. getUpdates() → Obtiene últimos mensajes
2. if (message.voice) → Es nota de voz
3. getFile() → Obtiene metadata del archivo
4. downloadFile() → Descarga audio a Buffer
5. POST /api/process-audio → Envía a next-app
6. sendMessage() → Retorna respuesta al usuario
7. Retry logic: 3 intentos si falla
```

**Healthcheck**: No tiene endpoint `/health` (sin estadísticas públicas)

---

### 2. Next.js API Service (`next-app/`)

**Ubicación**: `/home/azureuser/mateos/next-app`

**Estructura**:
```
next-app/
├── src/
│   ├── app/
│   │   └── api/
│   │       ├── process-audio/
│   │       │   └── route.ts           # POST /api/process-audio
│   │       ├── health/
│   │       │   └── route.ts           # GET /api/health
│   │       └── ...
│   ├── lib/
│   │   ├── prisma.ts                 # PrismaClient singleton
│   │   ├── r2-client.ts              # Cloudflare R2 uploader
│   │   ├── whisper-client.ts         # OpenAI Whisper API
│   │   ├── automatizaciones-webhook.ts # Webhook caller
│   │   └── logger.ts                 # Winston logger
│   ├── types/
│   │   └── index.ts                  # Tipos compartidos
│   └── middleware/
│       └── ...
├── prisma/
│   ├── schema.prisma                 # Schema ORM
│   └── migrations/                   # Historial de cambios
├── Dockerfile
├── next.config.js
├── package.json
├── tsconfig.json
└── .env.local
```

**Tecnologías**:
- Next.js 15.5.0 (App Router)
- React 19.0.0
- @prisma/client 6.18.0
- @aws-sdk/client-s3, lib-storage 3.515.0
- openai 6.1.0
- zod 3.22.4

**Endpoints Principales**:

#### POST `/api/process-audio`
```
REQUEST:
  Content-Type: multipart/form-data
  Body:
    - audio: <File>
    - metadata: JSON string { telegramFileId, userId, messageId, duration? }

RESPONSE (200):
  {
    "success": true,
    "transcriptionId": 123,
    "texto": "Transcripción completa..."
  }

RESPONSE (400):
  {
    "success": false,
    "error": "No audio file provided"
  }

RESPONSE (500):
  {
    "success": false,
    "error": "Whisper API failed"
  }
```

**Lógica Detallada**:
```typescript
POST /api/process-audio:
  1. Parsear FormData → audio File + metadata JSON
  2. Validar con Zod schema
  3. Convertir File → Buffer (en memoria)
  4. Check deduplicación (telegram_file_id)
  5. Crear/actualizar registro en transcripciones_db
     estado: PROCESANDO
  6. Ejecutar en PARALELO:
     - uploadToR2(buffer) → { url, key }
     - transcribeAudioWithRetry(buffer) → { text }
  7. Actualizar registro:
     estado: COMPLETADO
     texto: "..."
     r2_url, r2_key
  8. notifyAutomatizaciones(webhook) → fire-and-forget
     timeout: 10 segundos
     retry: 1 intento
  9. Retornar { success: true, transcriptionId, texto }
```

#### GET `/api/health`
```
RESPONSE (200):
  {
    "status": "ok",
    "service": "transcripcion-api",
    "db": "connected",
    "timestamp": "2025-12-01T10:30:00Z"
  }
```

**Variables de Entorno**:
```bash
# Base de datos
DATABASE_URL=postgresql://asistente:n8npass@postgres-db:5432/transcripciones_db

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_MODEL=whisper-1

# Cloudflare R2
R2_ACCOUNT_ID=...
R2_ACCESS_KEY=...
R2_SECRET_KEY=...
R2_BUCKET_NAME=transcripciones

# Automatizaciones
WEBHOOK_AUTOMATIZACIONES_URL=http://automatizaciones:3100/webhook

# Sistema
LOG_LEVEL=info
NODE_ENV=production
TELEGRAM_BOT_TOKEN=... (para logging)
```

---

### 3. Automatizaciones Service (`automatizaciones/`)

**Ubicación**: `/home/azureuser/mateos/automatizaciones`

**Estructura**:
```
automatizaciones/
├── src/
│   ├── index.ts                    # Entry point + Express setup
│   ├── processor.ts                # Orquestador de procesamiento
│   ├── keyword-matcher.ts          # Detección de tipo (fuzzy)
│   ├── ai-extractor.ts            # Extracción con GPT-4o-mini
│   ├── db-writer.ts               # Escritura en asistente_db
│   ├── scheduler.ts               # Tareas cron
│   ├── daily-summary.ts           # Resumen diario a TG
│   ├── historical-summary.ts      # Resumen histórico (futuro)
│   ├── telegram-client.ts         # Cliente Telegram (para enviar)
│   └── types.ts                   # Interfaces compartidas
├── prisma/
│   ├── schema.prisma              # Schema de asistente_db
│   └── migrations/
├── Dockerfile
├── package.json
├── tsconfig.json
└── .env.example
```

**Tecnologías**:
- Express.js 4.18.2
- @prisma/client 6.18.0
- openai 4.65.0
- fastest-levenshtein 1.0.16
- zod 3.22.4
- node-cron 3.0.3
- node-telegram-bot-api 0.64.0

#### 3.1 Keyword Matching (`keyword-matcher.ts`)

**Propósito**: Detectar qué tipo de nota es (tarea/registro/idea/compromiso)

**Algoritmo**:
```
Entrada: "Teo, llamar a María mañana"

1. Extraer primera palabra: "Teo"
2. Comparar con keywords usando Levenshtein distance:
   - "Teo" vs "teo" → distancia: 0 → MATCH (tipo: TAREA)
   - Confianza: 1.0 (100%)

3. Si Levenshtein ≥ umbral (0.6), es válido

Keywords mapeados:
┌──────────────────┬──────────────┬─────────┐
│ Entrada (fuzzy)  │ Detecta como │ Umbral  │
├──────────────────┼──────────────┼─────────┤
│ Teo/Theo/Deo     │ tarea        │ 60%     │
│ Juan/Cuando      │ registro     │ 60%     │
│ Ide/Idea         │ idea         │ 60%     │
│ Compa/Compra     │ compromiso   │ 60%     │
└──────────────────┴──────────────┴─────────┘

4. Retorna: {
     tipo: "tarea",
     confianza: 1.0,
     textoLimpio: "llamar a María mañana"  // Sin keyword
   }
```

**Funciones**:
```typescript
detectTipoFromTranscription(texto: string): DetectionResult
  - Input: transcripción completa
  - Output: { tipo, confianza, textoLimpio }
  - Edge cases:
    * Texto muy corto → sin_clasificar
    * Keyword incompleto → levenshtein distance
    * Sin keyword → sin_clasificar
```

#### 3.2 IA Extractor (`ai-extractor.ts`)

**Propósito**: Extraer estructuras semánticas de texto libre usando GPT-4o-mini

**Prompts Dinámicos**:

**Tipo: TAREA**
```
System: Eres un asistente experto en extraer tareas de texto libre.

User: "llamar a María mañana a las 3pm para revisar el proyecto"

Extrae JSON:
{
  "titulo": "Llamar a María",
  "descripcion": "Para revisar el proyecto",
  "fechaVencimiento": "2025-12-02T15:00:00Z",
  "prioridad": "MEDIA"
}
```

**Tipo: REGISTRO**
```
System: Eres un asistente experto en resumir actividades completadas.

User: "Estuve 2 horas con Juan y Pablo en reunión de proyecto X"

Extrae JSON:
{
  "descripcion": "Reunión de proyecto X",
  "duracionHoras": 2.0,
  "proyecto": "Proyecto X",
  "personasInvolucradas": ["Juan", "Pablo"],
  "categoria": "TRABAJO"
}
```

**Tipo: COMPROMISO**
```
System: Eres un asistente experto en identificar compromisos y promesas.

User: "Le prometí a Carlos que le enviaría el reporte el viernes"

Extrae JSON:
{
  "titulo": "Enviar reporte a Carlos",
  "personaNombre": "Carlos",
  "fechaLimite": "2025-12-05T23:59:59Z",
  "yoMeComprometi": true
}
```

**Tipo: IDEA**
```
System: Eres un asistente experto en capturar ideas creativas.

User: "Una app que gestione tareas usando IA"

Extrae JSON:
{
  "titulo": "App de gestión de tareas con IA",
  "descripcion": "Aplicación que use inteligencia artificial para gestionar tareas",
  "categoria": "PRODUCTO"
}
```

**Configuración OpenAI**:
```bash
OPENAI_MODEL=gpt-4o-mini        # Modelo más económico (~$0.00015 por request)
OPENAI_TEMPERATURE=1            # Máxima creatividad (puede variar)
OPENAI_MAX_TOKENS=4000          # Máximo output
```

**Validación**:
```typescript
validateExtraction(data: any): boolean
  - Verifica que campos requeridos no sean null
  - Verifica tipos de datos (fechas, enums, etc)
  - Retorna false si falló extracción
```

#### 3.3 DB Writer (`db-writer.ts`)

**Responsabilidades**:
```typescript
createNotaAudio(transcripcionId, texto, archivoUrl, detection)
  → Crea registro en notas_audio
  → Retorna NotaAudio creada

saveExtraction(notaAudio, extraction, tipo)
  → Según tipo, crea:
     * tipo === "tarea" → Tarea en tareas
     * tipo === "registro" → Registro en registros
     * tipo === "idea" → IdeaCapturada en ideas
     * tipo === "compromiso" → Compromiso en compromisos

isTranscripcionProcessed(transcripcionId): boolean
  → Verifica si ya existe NotaAudio con este transcripcionId
```

**Transacciones**: Usa Prisma transactions para garantizar consistencia

---

#### 3.4 Scheduler (`scheduler.ts`)

**Tareas Cron**:

```typescript
// Resumen diario a las 20:00 (hora configurada)
new CronJob(
  process.env.DAILY_SUMMARY_TIME || "0 20 * * *",
  () => generateDailySummary(),
  null,
  true,
  "America/Montevideo"
)

// Genera:
// 1. Conteo de tareas completadas hoy
// 2. Tareas pendientes para mañana
// 3. Compromisos a cumplir
// 4. Resumido con IA
// 5. Envía a Telegram
```

**Variables de Entorno**:
```bash
DAILY_SUMMARY_TIME=0 20 * * *       # Cron expression (20:00 diario)
TZ=America/Montevideo               # Zona horaria
USE_AI_SUMMARY=true                 # ¿Usar IA para resumir?
TELEGRAM_CHAT_ID=12345              # Chat privado del usuario
TELEGRAM_BOT_TOKEN=...
```

#### 3.5 Endpoints del Servicio

**POST `/webhook`** - Principal
```
REQUEST:
  {
    "transcripcionId": 123,
    "texto": "Teo, llamar a María...",
    "archivoUrl": "https://r2.example.com/audio_123.ogg",
    "fecha": "2025-12-01T10:30:00Z"
  }

RESPONSE (200):
  {
    "success": true,
    "notaAudioId": 45,
    "tipo": "tarea"
  }

RESPONSE (400):
  {
    "success": false,
    "error": "Invalid webhook payload"
  }
```

**GET `/health`** - Health check
```
RESPONSE (200):
  {
    "status": "ok",
    "service": "automatizaciones",
    "db": "connected"
  }
```

**GET `/test/keywords/:keyword`** - Test fuzzy matching (desarrollo)
```
GET /test/keywords/theo
RESPONSE:
  {
    "input": "theo",
    "detectedType": "tarea",
    "confidence": 1.0
  }
```

---

### 4. PostgreSQL Database

**Imagen**: `postgres:15.5-alpine`

**Configuración**:
```yaml
Container Name: transcripcion-postgres
Port: 1432:5432
User: asistente
Password: n8npass (CAMBIAR EN PRODUCCIÓN)
Init Script: scripts/init-db.sh
```

**Init Script** (`scripts/init-db.sh`):
```bash
#!/bin/bash
# Ejecutado automáticamente al iniciar PostgreSQL
set -e

# Crear BD asistente_db si no existe
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE asistente_db;
EOSQL

echo "Database asistente_db created successfully"
```

**Healthcheck**:
```yaml
test: ["CMD-SHELL", "pg_isready -U asistente -d transcripciones_db"]
interval: 10s
timeout: 5s
retries: 5
```

---

## 🎯 Decisiones Arquitectónicas

### 1. **Dos Bases de Datos Independientes**

**Decisión**: Separar `transcripciones_db` (original) de `asistente_db` (procesado)

**Razones**:
- ✅ **Independencia de servicios**: Cada servicio tiene su propia BD
- ✅ **Escalabilidad futura**: Pueden escalarse/replicarse por separado
- ✅ **Recuperación de fallos**: Si falla automatizaciones, transcripciones quedan intactas
- ✅ **Auditoría**: Versión original siempre disponible
- ✅ **Performance**: Queries en asistente_db no bloquean transcripciones_db

**Trade-off**:
- ❌ Mayor complejidad (dos conexiones Prisma)
- ❌ Overhead de sincronización (FK manual via transcripcionId)

### 2. **Polling en lugar de Webhooks para Telegram**

**Decisión**: Usar polling cada 300ms en lugar de webhooks

**Razones**:
- ✅ **Simplicidad**: No requiere dominio público en desarrollo
- ✅ **NAT-friendly**: Funciona detrás de firewalls/NAT
- ✅ **Desarrollo local**: Sin necesidad de ngrok o túneles
- ✅ **Testing**: Fácil de mock

**Trade-off**:
- ❌ Latencia: ~300ms-1s extra (vs ~0ms con webhook)
- ❌ Carga API Telegram: Polls cada 300ms
- ❌ Escalabilidad: No recomendado para >1M usuarios

**Migración futura**: Cambiar a webhooks en producción con dominio real

### 3. **Fire-and-Forget para Webhook a Automatizaciones**

**Decisión**: next-app no espera respuesta de automatizaciones, solo envía

**Razones**:
- ✅ **Latencia reducida**: Usuario ve transcripción al instante
- ✅ **Independencia**: Fallos en automatizaciones no afectan transcripción
- ✅ **Performance**: No bloquea loop de next-app
- ✅ **Idempotencia**: Si falla, simplemente se reintenta

**Implementación**:
```typescript
// next-app no espera:
await notifyAutomatizaciones(payload); // Fire-and-forget, timeout 10s
return NextResponse.json({ success: true, ... });

// Equivalente a:
notifyAutomatizaciones(payload).catch(err => {
  logger.error('Webhook failed', err); // Log pero no falla
});
```

### 4. **Fuzzy Matching con Levenshtein Distance**

**Decisión**: Usar `fastest-levenshtein` para detectar keywords con tolerancia

**Razones**:
- ✅ **Flexible**: Tolera errores de transcripción
- ✅ **User-friendly**: Usuario dice "Teo" o "Deo" o "Theo", mismo resultado
- ✅ **Simple**: Librería mínima, sin dependencias externas
- ✅ **Fast**: Algoritmo O(n*m) es rápido para strings cortos

**Trade-off**:
- ❌ No es lingüístico: "Teo" y "Deo" tienen distancia=1 (ambos válidos)
- ❌ No maneja sinónimos: Necesitaría lista manual

**Ejemplo**:
```
Input: "Teo, hacer informe"
Processing:
1. Extrae palabra 1: "Teo"
2. Compara distancia: levenshtein("Teo", "teo") = 0
3. 0/3 (distancia) < 0.4 (umbral) → MATCH
4. Confianza: 1.0
5. Tipo: tarea
```

### 5. **OpenAI GPT-4o-mini para Extracción**

**Decisión**: Usar GPT-4o-mini (no GPT-4, no davinci-003)

**Razones**:
- ✅ **Costo**: ~$0.00015 por request (100x más barato que GPT-4)
- ✅ **Velocidad**: Latencia <2 segundos típicamente
- ✅ **Accurary**: Suficiente para JSON estructurado
- ✅ **Context**: Puede manejar prompts de ~2000 tokens

**Trade-off**:
- ❌ Menos preciso que GPT-4 para casos edge
- ❌ Más alucinaciones posibles
- ❌ No recuerda contexto histórico (sin vector DB)

**Mitigation**: Validación manual de extracciones dudosas en NocoDB

### 6. **Cloudflare R2 para Storage de Audio**

**Decisión**: Usar R2 en lugar de AWS S3 o almacenamiento local

**Razones**:
- ✅ **Costo**: Primeros 10GB gratis, sin cargo de egreso (S3 cobra egreso)
- ✅ **Compatible**: API S3-compatible (@aws-sdk/client-s3 funciona)
- ✅ **Durabilidad**: Replicación automática
- ✅ **CDN**: Incluido en servicio (rápido desde cualquier lugar)

**Trade-off**:
- ❌ Proveedor menos conocido (pero buena reputación)
- ❌ Sin VPC endpoints (no importa aquí)

---

## 🚀 Deployment y Operaciones

### Local Development

```bash
# 1. Instalar dependencias
cd next-app && npm install && cd ..
cd automatizaciones && npm install && cd ..
cd telegram-bot && npm install && cd ..

# 2. Configurar .env
cp .env.example .env
# Editar con credenciales reales

# 3. Build Docker
docker-compose build

# 4. Iniciar servicios
docker-compose up -d

# 5. Migraciones
docker-compose exec next-app npx prisma migrate deploy
docker-compose exec automatizaciones npm run prisma:deploy
```

### Production Deployment

**Requisitos**:
- Docker Engine 24.0+
- Docker Compose 2.23+
- 2GB RAM mínimo
- 20GB storage (para BD y audios)
- Credenciales: OpenAI, Cloudflare R2, Telegram

**Pasos**:
```bash
# 1. Clone repo en servidor
git clone <repo> /opt/mateos
cd /opt/mateos

# 2. Configurar .env
nano .env
# Cambiar:
#   - DB_PASSWORD (contraseña fuerte)
#   - OPENAI_API_KEY
#   - R2_* credenciales
#   - TELEGRAM_BOT_TOKEN (bot separado en prod)

# 3. Build y start
docker-compose -f docker-compose.yml up -d --build

# 4. Migraciones
docker-compose exec next-app npx prisma migrate deploy
docker-compose exec automatizaciones npm run prisma:deploy

# 5. Verificar
docker-compose ps
curl http://localhost:1400/api/health
curl http://localhost:1410/health

# 6. Backup BD
docker-compose exec postgres-db pg_dump -U asistente transcripciones_db > backup_$(date +%Y%m%d).sql
```

### Monitoring & Maintenance

**Logs**:
```bash
# Ver todos los servicios
docker-compose logs -f

# Filtrar por servicio
docker-compose logs -f next-app
docker-compose logs -f automatizaciones
docker-compose logs -f postgres-db

# Buscar errores
docker-compose logs | grep -i error
```

**Health Checks**:
```bash
# Cada servicio tiene healthcheck automático
# Ver estado:
docker-compose ps

# Expected output:
# next-app     ... healthy
# postgres-db  ... healthy
# automatizaciones ... healthy
# telegram-bot ... Up
```

**Backups**:
```bash
# Backup automático diario
0 2 * * * docker-compose -f /opt/mateos/docker-compose.yml exec postgres-db pg_dump -U asistente transcripciones_db asistente_db > /backups/mateos_$(date +\%Y\%m\%d).sql

# Retención: 30 días
find /backups -name "mateos_*.sql" -mtime +30 -delete
```

---

## ⚠️ Puntos Críticos y Lecciones Aprendidas

### 1. **Estado y Deduplicación Crítica**

**Problema**: Mismo audio enviado 2 veces → 2 transcripciones duplicadas

**Solución**:
- ✅ Campo `telegram_file_id` UNIQUE
- ✅ Check en next-app antes de procesar
- ✅ Si existe y COMPLETADO → retornar existente
- ✅ Si existe y PROCESANDO → actualizar
- ✅ Nunca procesar dos veces

**Código**:
```typescript
const existing = await prisma.transcripcion.findFirst({
  where: { telegram_file_id: metadata.telegramFileId }
});

if (existing && existing.estado === 'COMPLETADO') {
  return NextResponse.json({
    success: true,
    transcriptionId: existing.id,
    texto: existing.texto,
  });
}
```

### 2. **Timeout y Retry en Llamadas Externas**

**Problema**: OpenAI API lenta, transcripción tarda >30s

**Solución**:
- ✅ `transcribeAudioWithRetry()`: 3 intentos
- ✅ Backoff exponencial: 1s, 2s, 4s
- ✅ Timeout: 60s máximo por intento
- ✅ Log detallado de fallos

```typescript
async function transcribeAudioWithRetry(
  buffer: Buffer,
  contentType: string,
  maxRetries = 3
): Promise<string> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await transcribeAudioWithOpenAI(buffer);
    } catch (error) {
      if (attempt === maxRetries) throw error;
      await sleep(Math.pow(2, attempt - 1) * 1000);
      logger.warn(`Whisper retry ${attempt}/${maxRetries}`);
    }
  }
}
```

### 3. **Paralelismo en Operaciones I/O**

**Problema**: Subir a R2 y transcribir secuencial → latencia 10-15s

**Solución**:
- ✅ `Promise.all([uploadToR2(), transcribeAudio()])`
- ✅ Ambas en paralelo → latencia 5-10s
- ✅ Ambas independientes → un fallo no afecta la otra

### 4. **Validación con Zod en Fronteras**

**Problema**: next-app recibe JSON malformado → crashes

**Solución**:
- ✅ Validar con Zod en entrada de cada endpoint
- ✅ Retornar 400 Bad Request si falla validación
- ✅ Log detallado del error

```typescript
const metadata = requestSchema.parse(JSON.parse(metadataStr));
// Si falla: ZodError → catch → 400 response
```

### 5. **Índices en Campos Frecuentemente Filtrados**

**Problema**: Queries lentas en tablas grandes (100k+ registros)

**Solución**:
- ✅ Índice en `telegram_user_id` (filtrar por usuario)
- ✅ Índice en `created_at` (filtrar por rango de fechas)
- ✅ Índice en `estado` (filtrar por status)
- ✅ Índice en `tipoDetectado` (filtrar por tipo de nota)

### 6. **Logging Estructurado con Winston**

**Problema**: Logs sin contexto → difícil debuggear

**Solución**:
```typescript
logger.info('Processing audio', {
  transcriptionId: 123,
  userId: 456,
  fileSize: 50000,
  duration: 5,
});

// Output:
// {"level":"info","message":"Processing audio","transcriptionId":123,...,"timestamp":"2025-12-01T10:30:00.000Z"}
```

### 7. **Gestión de Estado de Transcripción**

**Estados**:
- `PROCESANDO`: Iniciado, esperando Whisper
- `COMPLETADO`: Transcripción exitosa
- `ERROR`: Fallo (sin retry automático)

**Flujo**:
```
CREATE (estado=PROCESANDO)
  ↓
  ↓ [Whisper API]
  ↓
UPDATE (estado=COMPLETADO, texto=...)  OR  UPDATE (estado=ERROR, error_msg=...)
```

### 8. **Webhook Timeout y Retry Logic**

**Problema**: Automatizaciones tarda >10s → next-app timeout

**Solución**:
- ✅ Fire-and-forget: next-app NO espera respuesta
- ✅ Timeout: 10 segundos máximo
- ✅ Retry: 1 intento (si falla, log y continúa)
- ✅ Usuario ve transcripción ANTES de procesamiento IA

---

## 🔮 Próximas Fases

### Fase 2: Frontend Web (Trimestre Q1 2026)

- [ ] Dashboard de control
- [ ] Visualización de entidades (tareas, registros, etc)
- [ ] Edición manual de extracciones
- [ ] Búsqueda y filtros
- [ ] Exportación de datos

**Tech Stack**:
- React 19 (ya tenemos Next.js)
- TailwindCSS (estilos)
- Shadcn/ui (componentes)
- Next.js App Router

### Fase 3: Enriquecimiento con Embeddings (Q2 2026)

- [ ] Vector DB (Pinecone o pgvector)
- [ ] Embeddings de notas (OpenAI Embedding API)
- [ ] Búsqueda semántica
- [ ] Recomendaciones
- [ ] Detección de notas similares

**Tech Stack**:
- pgvector (extensión PostgreSQL)
- OpenAI Embedding API
- Semantic Search

### Fase 4: Integraciones (Q3 2026)

- [ ] Calendario (Google Calendar, Outlook)
- [ ] Email (enviar resumen diario)
- [ ] n8n (workflows custom)
- [ ] Slack (notificaciones)
- [ ] Zapier (automatizaciones externas)

### Fase 5: Machine Learning (Q4 2026)

- [ ] Fine-tuning de GPT con datos históricos
- [ ] Clasificación automática mejorada
- [ ] Predicción de prioridades
- [ ] Análisis de patrones
- [ ] Recomendaciones inteligentes

---

## 📊 Métricas de Producción

### Performance

| Métrica | Valor | Threshold |
|---------|-------|-----------|
| Latencia end-to-end | 10-25s | <30s |
| Transcripción (Whisper) | 5-15s | <20s |
| Extracción IA | 3-10s | <15s |
| Overhead BD | <500ms | <1s |
| Webhook call | <100ms | <200ms |

### Costos Mensuales (100 audios/día)

| Servicio | Costo | Notas |
|----------|-------|-------|
| OpenAI Whisper | $3-5 | ~30s promedio |
| GPT-4o-mini | $0.45 | ~50 tokens promedio |
| Cloudflare R2 | $0 | <10GB |
| PostgreSQL (self-hosted) | $0 | En Docker |
| Total | ~$4-6 | Muy accesible |

### Observabilidad Targets

- [ ] Sentry para error tracking
- [ ] Prometheus para métricas
- [ ] Grafana para dashboards
- [ ] LogRocket para session replay
- [ ] PagerDuty para alertas

---

## 🔐 Security Considerations

### En Desarrollo
- ✅ `.env` en `.gitignore`
- ✅ Credenciales de ejemplo en `.env.example`
- ✅ Logs sin datos sensibles

### En Producción (Checklist)

- [ ] Cambiar contraseña PostgreSQL
- [ ] Usar bot de Telegram separado
- [ ] Rotar OpenAI API key si fue comprometida
- [ ] Renovar R2 access keys cada 90 días
- [ ] HTTPS en frontend
- [ ] Rate limiting en `/api/*`
- [ ] CORS configurado restrictivamente
- [ ] Secrets en AWS Secrets Manager (si AWS)
- [ ] Backup encrypted
- [ ] Logs a ELK stack o similar
- [ ] VPN para acceso administrativo

---

## 📞 Contacto y Support

### Documentación Relacionada
- `README.md` - Descripción general
- `QUICKSTART.md` - Guía de inicio rápido
- `INTEGRATION_SUMMARY.md` - Resumen de integración
- `DEPLOYMENT.md` - Guía completa de despliegue
- `DAILY_SUMMARY.md` - Feature de resumen diario

### Debugging

**Problema**: Bot no responde
```bash
docker-compose logs telegram-bot | tail -50
# Buscar: "Error", "Failed", "timeout"
```

**Problema**: Transcripción lenta
```bash
docker-compose logs next-app | grep "Whisper"
# Verificar si OpenAI API responde
```

**Problema**: Entidades no se guardan
```bash
docker-compose logs automatizaciones | grep "DB"
# Verificar conexión a asistente_db
```

---

## 📈 Conclusión

**MATEOS** es una arquitectura moderna, escalable y costo-efectiva para capturar y procesar notas de voz personales.

**Fortalezas**:
- ✅ Stack moderno (Next.js, Prisma, TypeScript)
- ✅ Separación clara de responsabilidades
- ✅ Costo muy bajo (~$4-6/mes)
- ✅ Fácil de desplegar (Docker)
- ✅ Facilidad para agregar nuevas fases

**Áreas de mejora futuras**:
- 🔄 Webhooks en lugar de polling
- 🔄 Vector DB para búsqueda semántica
- 🔄 Frontend web completo
- 🔄 Fine-tuning de modelos
- 🔄 Integraciones con otros servicios

**Para desarrolladores nuevos**: Leer en orden:
1. Este archivo (`ARCHITECTURE.md`)
2. `README.md` (overview)
3. `QUICKSTART.md` (setup local)
4. Código fuente (comenzar por `next-app/src/app/api/process-audio/route.ts`)

---

**Documento creado**: Diciembre 2025
**Última actualización**: Diciembre 2025
**Versión**: 1.0.0
