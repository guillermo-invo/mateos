# Asistente Personal Inteligente - Documentación Maestra

**Versión**: 1.0.0 (MVP)
**Última actualización**: 3 de noviembre de 2025
**Estado**: En desarrollo - MVP funcional al 95%
**Autor**: Guillermo - Solopreneur Social, Montevideo, Uruguay

---

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Stack Tecnológico](#stack-tecnológico)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Base de Datos](#base-de-datos)
6. [Configuración y Despliegue](#configuración-y-despliegue)
7. [APIs y Endpoints](#apis-y-endpoints)
8. [Integraciones](#integraciones)
9. [Estado Actual y Pendientes](#estado-actual-y-pendientes)
10. [Guía de Desarrollo](#guía-de-desarrollo)

---

## 🎯 Visión General

### Descripción
Sistema de captura y procesamiento inteligente de notas de audio que transforma información no estructurada en datos organizados mediante IA. Permite capturar ideas, tareas, compromisos y métricas mediante notas de voz, procesándolas automáticamente para extraer entidades estructuradas.

### Objetivo Principal
Facilitar la gestión personal y profesional de un solopreneur social mediante la captura rápida de información por voz y su procesamiento automático con IA para generar tareas, compromisos, ideas y métricas estructuradas.

### Casos de Uso
1. **Captura de Notas de Audio**: Grabar notas de voz desde la web o Telegram
2. **Transcripción Automática**: Convertir audio a texto usando Whisper (local o API)
3. **Extracción de Entidades**: Identificar tareas, compromisos, personas, ideas y métricas mediante GPT-4o-mini
4. **Validación Humana**: Revisar y aprobar/rechazar extracciones de baja confianza
5. **Gestión de Tareas**: Ver y gestionar tareas pendientes
6. **Integración con n8n**: Automatizar workflows externos

---

## 🏗️ Arquitectura del Sistema

### Arquitectura General

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Frontend      │     │  Telegram Bot   │     │   n8n Webhook   │
│   Next.js 14    │     │   (Node.js)     │     │  (Automations)  │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                         │
         └───────────────────────┴─────────────────────────┘
                                 │
                    ┌────────────▼───────────┐
                    │   Next.js API Routes   │
                    │  /api/audio/upload     │
                    │  /api/tasks            │
                    │  /api/validations      │
                    └────────────┬───────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌────────▼────────┐   ┌──────────▼──────────┐  ┌───────▼────────┐
│  Cloudflare R2  │   │     PostgreSQL      │  │  Redis/BullMQ  │
│ (Audio Storage) │   │  (Prisma Client)    │  │   (Job Queue)  │
└─────────────────┘   └─────────────────────┘  └────────────────┘
                                                         │
                               ┌─────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Background Workers │
                    │  - transcription    │
                    │  - extraction       │
                    │  - validation       │
                    │  - notification     │
                    └─────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
            ┌───────▼────────┐   ┌───────▼────────┐
            │  Whisper API   │   │   OpenAI API   │
            │ (Transcription)│   │  (GPT-4o-mini) │
            └────────────────┘   └────────────────┘
```

### Flujo de Procesamiento de Audio

1. **Upload**: Usuario graba audio → `/api/audio/upload`
2. **Storage**: Audio se sube a Cloudflare R2
3. **DB Record**: Se crea registro en PostgreSQL (estado: SUBIDO)
4. **Queue**: Se agrega job a BullMQ (cola: transcribe-audio)
5. **Transcription Worker**:
   - Descarga audio de R2
   - Llama a Whisper API (o Whisper local)
   - Actualiza BD con transcripción (estado: TRANSCRITO)
   - Agrega job a cola extract-entities
6. **Extraction Worker**:
   - Toma transcripción
   - Llama a GPT-4o-mini para extraer entidades
   - Crea registros de ExtraccionNota
   - Si confianza < 85%, crea ValidacionPendiente
   - Actualiza BD (estado: PROCESADO)
7. **Validation**: Usuario revisa y aprueba/rechaza validaciones pendientes
8. **Storage**: Entidades validadas se convierten en tareas, compromisos, etc.

---

## 🛠️ Stack Tecnológico

### Frontend
- **Framework**: Next.js 14+ (App Router)
- **Lenguaje**: TypeScript 5.3+
- **UI**: Tailwind CSS 3.3+
- **Componentes**: React 18.2+
- **Iconos**: Lucide React
- **State Management**: Zustand (no implementado aún)
- **Data Fetching**: React Query (no implementado aún)
- **PWA**: next-pwa (configurado, deshabilitado en desarrollo)

### Backend
- **Runtime**: Node.js 20+
- **Framework**: Next.js API Routes
- **Lenguaje**: TypeScript (strict mode)
- **Validación**: Zod
- **ORM**: Prisma 5.7+
- **Queue**: BullMQ 4.15+
- **Cache**: ioredis 4.6+

### Base de Datos
- **Motor**: PostgreSQL 15
- **Cliente**: Prisma Client
- **Migraciones**: Prisma Migrate
- **Extensiones previstas**: pgvector (para embeddings)

### Almacenamiento
- **Archivos de Audio**: Cloudflare R2 (compatible S3)
- **Librería**: AWS SDK v3 (@aws-sdk/client-s3)

### Inteligencia Artificial
- **Transcripción**: OpenAI Whisper API (whisper-1)
- **Transcripción Local**: Whisper CLI (fallback en desarrollo)
- **Extracción de Entidades**: OpenAI GPT-4o-mini
- **SDK**: openai 4.20+

### Infraestructura
- **Contenedores**: Docker + Docker Compose
- **Servicios**:
  - PostgreSQL 15 (puerto 5433)
  - Redis 7 (puerto 6379)
  - n8n (puerto 5678)
  - NocoDB (puerto 8080)
  - Chatwoot (puerto 3001)
- **Reverse Proxy**: Ninguno (en desarrollo)
- **Monitoring**: Sin implementar

### Integraciones
- **Telegram Bot**: node-telegram-bot-api
- **Automation**: n8n (workflows)
- **Database UI**: NocoDB
- **Customer Support**: Chatwoot

### Herramientas de Desarrollo
- **Linter**: ESLint
- **Formatter**: Prettier
- **Testing**: Vitest + Playwright (configurado, no implementado)
- **Type Checking**: TypeScript compiler
- **Hot Reload**: Next.js Fast Refresh

---

## 📁 Estructura del Proyecto

### Estructura de Carpetas

```
AsistentePersonal/
├── app/                          # Next.js App Router
│   ├── api/                      # API Routes
│   │   ├── audio/
│   │   │   ├── upload/route.ts   # POST: Upload audio
│   │   │   └── process/route.ts  # POST: Process audio
│   │   ├── tasks/
│   │   │   ├── route.ts          # GET/POST: Lista de tareas
│   │   │   └── [id]/route.ts     # GET/PUT/DELETE: Tarea específica
│   │   ├── validations/
│   │   │   └── route.ts          # GET/POST: Validaciones pendientes
│   │   └── webhooks/
│   │       └── n8n/route.ts      # POST: Webhook para n8n
│   ├── layout.tsx                # Layout principal con navegación
│   ├── page.tsx                  # Dashboard (página principal)
│   ├── globals.css               # Estilos globales + componentes
│   ├── record/
│   │   └── page.tsx              # Página de grabación de audio
│   └── validations/
│       └── page.tsx              # Página de validaciones
│
├── components/                   # Componentes React
│   ├── audio/
│   │   └── AudioRecorder.tsx     # Grabador de audio con MediaRecorder API
│   ├── dashboard/
│   │   └── MetricsCard.tsx       # Tarjeta de métricas del dashboard
│   └── validation/
│       └── ValidationCard.tsx    # Tarjeta para validar extracciones
│
├── lib/                          # Librerías y utilidades
│   ├── db.ts                     # Prisma client singleton
│   ├── ai/
│   │   ├── whisper.ts            # Transcripción con Whisper
│   │   ├── claude.ts             # Extracción con OpenAI (nombre legacy)
│   │   └── prompts.ts            # Prompts para IA
│   ├── queue/
│   │   ├── queue.ts              # Setup de BullMQ
│   │   └── workers/
│   │       ├── transcription-worker.ts
│   │       └── extraction-worker.ts
│   └── storage/
│       └── r2.ts                 # Cliente para Cloudflare R2
│
├── prisma/
│   ├── schema.prisma             # Schema de base de datos (12 tablas)
│   └── seed.ts                   # Datos de prueba (no implementado)
│
├── telegram-bot/                 # Bot de Telegram (independiente)
│   ├── src/
│   │   ├── bot.ts                # Lógica principal del bot
│   │   ├── api-client.ts         # Cliente para llamar a la API
│   │   └── types.ts              # Tipos TypeScript
│   ├── package.json              # Dependencias del bot
│   ├── tsconfig.json             # Config TypeScript
│   ├── README.md                 # Documentación del bot
│   ├── INSTRUCCIONES.md          # Guía de uso
│   └── iniciar-bot.bat           # Script de inicio Windows
│
├── src/                          # Código NestJS (coexistente, pendiente integración)
│   └── prisma/
│       ├── prisma.service.ts     # Servicio Prisma para NestJS
│       └── prisma.module.ts      # Módulo Prisma para NestJS
│
├── scripts/
│   └── start-ngrok.ps1           # Script para iniciar ngrok (desarrollo)
│
├── public/                       # Archivos estáticos
│   └── (vacío)
│
├── .next/                        # Build de Next.js (ignorado)
├── node_modules/                 # Dependencias (ignorado)
│
├── next.config.js                # Configuración de Next.js
├── tailwind.config.js            # Configuración de Tailwind
├── postcss.config.js             # Configuración de PostCSS
├── tsconfig.json                 # Configuración de TypeScript
├── package.json                  # Dependencias del proyecto
├── docker-compose.yml            # Servicios Docker
├── env.example                   # Template de variables de entorno
├── .gitignore                    # Archivos ignorados por Git
│
├── README.md                     # Readme básico
├── CURSOR_INSTRUCTIONS.md        # Instrucciones originales de Cursor
├── PROGRESS.md                   # Registro de progreso del desarrollo
├── HANDOFF.md                    # Reporte de handoff
└── PROJECT_MASTER_DOC.md         # ESTE DOCUMENTO (fuente de verdad)
```

### Archivos Clave

| Archivo | Propósito | Estado |
|---------|-----------|--------|
| `package.json` | Dependencias y scripts | ✅ Completo |
| `next.config.js` | Configuración Next.js + PWA | ✅ Completo |
| `prisma/schema.prisma` | Schema de BD (12 tablas) | ✅ Completo |
| `docker-compose.yml` | Servicios Docker | ✅ Completo |
| `env.example` | Variables de entorno | ✅ Completo |
| `lib/db.ts` | Cliente Prisma singleton | ✅ Completo |
| `lib/queue/queue.ts` | Setup BullMQ | ✅ Completo |
| `app/layout.tsx` | Layout principal | ✅ Completo |
| `app/page.tsx` | Dashboard | ✅ Completo |

---

## 🗄️ Base de Datos

### Schema Prisma

El proyecto utiliza **12 tablas principales** en PostgreSQL:

#### 1. NotaAudio
Almacena las grabaciones de audio y su procesamiento.

```prisma
model NotaAudio {
  id                    Int                     @id @default(autoincrement())
  tituloAuto           String?
  duracionSegundos     Int?
  archivoAudioUrl      String?
  transcripcionCompleta String?                 @db.Text
  resumenEjecutivo     String?                  @db.Text
  estadoProcesamiento  EstadoProcesamiento      @default(SUBIDO)
  fechaGrabacion       DateTime                 @default(now())
  embeddingsVector     Float[]                  // pgvector

  extracciones         ExtraccionNota[]
  tareas              Tarea[]
  compromisos         Compromiso[]
  ideas               IdeaCapturada[]
  validaciones        ValidacionPendiente[]

  createdAt           DateTime                 @default(now())
  updatedAt           DateTime                 @updatedAt
  deletedAt           DateTime?
}
```

**Estados**: SUBIDO → TRANSCRIBIENDO → TRANSCRITO → EXTRAYENDO → PROCESADO / ERROR

#### 2. ExtraccionNota
Entidades extraídas de las transcripciones.

```prisma
model ExtraccionNota {
  id                          Int      @id @default(autoincrement())
  notaAudioId                 Int
  tipoEntidad                 String   // "tarea", "compromiso", "persona", "idea", "metrica"
  datosExtraidos              Json
  confianza                   Float    // 0-100
  procesadoAutomaticamente    Boolean  @default(false)

  notaAudio                   NotaAudio @relation(...)
  createdAt                   DateTime @default(now())
  updatedAt                   DateTime @updatedAt
}
```

#### 3. Tarea
Tareas identificadas o creadas manualmente.

```prisma
model Tarea {
  id                Int            @id @default(autoincrement())
  titulo            String
  descripcion       String?        @db.Text
  fechaVencimiento  DateTime?
  prioridad         PrioridadTarea @default(MEDIA)  // BAJA, MEDIA, ALTA, URGENTE
  estado            EstadoTarea    @default(PENDIENTE)  // PENDIENTE, EN_PROGRESO, COMPLETADA, CANCELADA
  completada        Boolean        @default(false)
  fechaCompletada   DateTime?

  notaAudioId       Int?
  proyectoId        Int?
  personaId         Int?

  notaAudio         NotaAudio?     @relation(...)
  proyecto          Proyecto?      @relation(...)
  persona           Persona?       @relation(...)

  createdAt         DateTime       @default(now())
  updatedAt         DateTime       @updatedAt
  deletedAt         DateTime?
}
```

#### 4. Compromiso
Compromisos con otras personas.

```prisma
model Compromiso {
  id                Int      @id @default(autoincrement())
  titulo            String
  descripcion       String?  @db.Text
  personaNombre     String
  fechaLimite       DateTime
  yoMeComprometi    Boolean  @default(false)
  cumplido          Boolean  @default(false)
  fechaCumplido     DateTime?

  notaAudioId       Int?
  personaId         Int?

  notaAudio         NotaAudio? @relation(...)
  persona           Persona?   @relation(...)

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
  deletedAt         DateTime?
}
```

#### 5. Persona
Personas mencionadas o agregadas.

```prisma
model Persona {
  id                Int      @id @default(autoincrement())
  nombre            String
  contexto          String?  @db.Text
  habilidades       String[] // Array de strings
  contacto          String?
  activa            Boolean  @default(true)

  tareas            Tarea[]
  compromisos       Compromiso[]

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
  deletedAt         DateTime?
}
```

#### 6. Proyecto
Proyectos para organizar tareas.

```prisma
model Proyecto {
  id                Int      @id @default(autoincrement())
  nombre            String
  descripcion       String?  @db.Text
  estado            String   @default("ACTIVO")  // ACTIVO, PAUSADO, COMPLETADO, CANCELADO
  fechaInicio       DateTime @default(now())
  fechaFin          DateTime?

  tareas            Tarea[]
  objetivos         Objetivo[]

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
  deletedAt         DateTime?
}
```

#### 7. Objetivo
Objetivos asociados a proyectos.

```prisma
model Objetivo {
  id                Int      @id @default(autoincrement())
  titulo            String
  descripcion       String?  @db.Text
  fechaObjetivo     DateTime
  completado        Boolean  @default(false)
  fechaCompletado   DateTime?

  proyectoId        Int?
  proyecto          Proyecto? @relation(...)

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
  deletedAt         DateTime?
}
```

#### 8. Metrica
Métricas a trackear.

```prisma
model Metrica {
  id                Int      @id @default(autoincrement())
  nombre            String
  descripcion       String?  @db.Text
  unidad            String   // "horas", "personas", "porcentaje"
  valorActual       Float
  valorObjetivo     Float?
  categoria         String?  // "productividad", "social", "personal"

  historial         HistorialMetrica[]

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
  deletedAt         DateTime?
}
```

#### 9. HistorialMetrica
Histórico de cambios en métricas.

```prisma
model HistorialMetrica {
  id                Int      @id @default(autoincrement())
  metricaId         Int
  valor             Float
  fecha             DateTime @default(now())
  notas             String?  @db.Text

  metrica           Metrica  @relation(...)
  createdAt         DateTime @default(now())
}
```

#### 10. IdeaCapturada
Ideas capturadas en las notas.

```prisma
model IdeaCapturada {
  id                  Int            @id @default(autoincrement())
  titulo              String
  descripcion         String?        @db.Text
  categoria           String?        // "innovacion", "mejora", "nuevo_proyecto"
  prioridad           PrioridadTarea @default(MEDIA)
  implementada        Boolean        @default(false)
  fechaImplementacion DateTime?

  notaAudioId         Int?
  notaAudio           NotaAudio? @relation(...)

  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
  deletedAt           DateTime?
}
```

#### 11. ValidacionPendiente
Validaciones de extracciones con baja confianza.

```prisma
model ValidacionPendiente {
  id                Int              @id @default(autoincrement())
  notaAudioId       Int
  tipoValidacion    TipoValidacion   // TAREA, COMPROMISO, PERSONA, IDEA, METRICA
  datosOriginales   Json
  datosSugeridos    Json?
  estado            EstadoValidacion @default(PENDIENTE)  // PENDIENTE, APROBADA, RECHAZADA, EXPIRADA
  confianzaOriginal Float
  fechaExpiracion   DateTime         // 7 días desde creación

  notaAudio         NotaAudio @relation(...)

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
}
```

#### 12. FeedbackIA
Feedback sobre el comportamiento de la IA.

```prisma
model FeedbackIA {
  id                Int          @id @default(autoincrement())
  tipoFeedback      TipoFeedback // POSITIVO, NEGATIVO, SUGERENCIA
  mensaje           String       @db.Text
  contexto          String?      @db.Text
  datosRelevantes   Json?
  procesado         Boolean      @default(false)

  createdAt         DateTime     @default(now())
  updatedAt         DateTime     @updatedAt
}
```

### Relaciones Principales

```
NotaAudio
  ├── 1:N → ExtraccionNota
  ├── 1:N → Tarea
  ├── 1:N → Compromiso
  ├── 1:N → IdeaCapturada
  └── 1:N → ValidacionPendiente

Proyecto
  ├── 1:N → Tarea
  └── 1:N → Objetivo

Persona
  ├── 1:N → Tarea
  └── 1:N → Compromiso

Metrica
  └── 1:N → HistorialMetrica
```

### Índices Definidos

Para optimizar consultas frecuentes:

- `NotaAudio`: estadoProcesamiento, fechaGrabacion, createdAt
- `ExtraccionNota`: notaAudioId, tipoEntidad, confianza
- `Tarea`: estado, prioridad, fechaVencimiento, completada
- `Compromiso`: fechaLimite, cumplido, yoMeComprometi
- `Persona`: nombre, activa
- `Proyecto`: estado, fechaInicio
- `ValidacionPendiente`: notaAudioId, tipoValidacion, estado, fechaExpiracion
- `FeedbackIA`: tipoFeedback, procesado

### Migraciones

**Estado**: Schema completo definido, migraciones NO ejecutadas todavía.

**Para ejecutar migraciones**:
```bash
npx prisma generate      # Genera el cliente Prisma
npx prisma db push       # Sincroniza schema con BD (desarrollo)
# o
npx prisma migrate dev   # Crea y aplica migración (producción)
```

---

## ⚙️ Configuración y Despliegue

### Variables de Entorno

Archivo: `env.example` (copiar a `.env.local` para desarrollo)

```env
# Database
DATABASE_URL="postgresql://asistente:n8npass@n8n-postgres:5432/asistente_db"

# Redis
REDIS_URL="redis://chatwoot-redis:6379/3"

# OpenAI
OPENAI_API_KEY="sk-proj-..."

# Whisper Local (en desarrollo, usar true para usar Whisper local)
WHISPER_USE_LOCAL=true
WHISPER_LOCAL_COMMAND="whisper"

# Cloudflare R2
R2_ACCOUNT_ID="374124541e5b062a236e893d30575708"
R2_ACCESS_KEY="09a70d544b3d57723c28518a2c5b4d75"
R2_SECRET_KEY="9398a1bb74ad9d7fb00ed447dd95e1c50440bc96012aeb7950305e94dcf387fb"
R2_BUCKET_NAME="asistente-personal"
R2_ENDPOINT_URL="https://374124541e5b062a236e893d30575708.r2.cloudflarestorage.com"

# NextAuth
NEXTAUTH_SECRET="your-secret-key-here"
NEXTAUTH_URL="https://asistente.involucrate.lat"

# n8n Integration
N8N_WEBHOOK_URL="http://n8n:5678/webhook/asistente"
N8N_AUTH_TOKEN="..."

# Environment
NODE_ENV="development"

# Audio Processing
MAX_AUDIO_SIZE_MB=50
SUPPORTED_AUDIO_FORMATS="audio/wav,audio/mp3,audio/m4a,audio/webm"

# AI Processing
CONFIDENCE_THRESHOLD=85
MAX_RETRIES=3
REQUEST_TIMEOUT_MS=300000

# Queue Configuration
QUEUE_CONCURRENCY=5
QUEUE_ATTEMPTS=3
QUEUE_BACKOFF_DELAY=2000
```

### Docker Compose

El proyecto incluye un `docker-compose.yml` con 5 servicios:

1. **PostgreSQL** (puerto 5433)
   - Base de datos principal
   - Usuario: `asistente`
   - Password: `n8npass`
   - Databases: `asistente_db`, `n8n`, `nocodb`, `chatwoot`

2. **Redis** (puerto 6379)
   - Queue backend para BullMQ
   - Persistencia con AOF

3. **n8n** (puerto 5678)
   - Workflow automation
   - Conectado a PostgreSQL
   - Auth: admin/admin

4. **NocoDB** (puerto 8080)
   - UI para base de datos
   - Conectado a PostgreSQL

5. **Chatwoot** (puerto 3001)
   - Customer support (no utilizado actualmente)

**Iniciar servicios**:
```bash
docker-compose up -d
```

**Detener servicios**:
```bash
docker-compose down
```

**Ver logs**:
```bash
docker-compose logs -f [servicio]
```

### Instalación Local

#### Requisitos
- Node.js 20+
- npm 10+
- Docker + Docker Compose
- PostgreSQL 15 (via Docker)
- Redis 7 (via Docker)

#### Pasos

1. **Clonar repositorio** (ya hecho)

2. **Instalar dependencias**:
```bash
npm install
```

3. **Configurar variables de entorno**:
```bash
cp env.example .env.local
# Editar .env.local con tus valores
```

4. **Iniciar servicios Docker**:
```bash
docker-compose up -d postgres redis
```

5. **Generar cliente Prisma**:
```bash
npm run db:generate
```

6. **Ejecutar migraciones**:
```bash
npm run db:push
```

7. **Iniciar aplicación**:
```bash
npm run dev
```

La aplicación estará disponible en `http://localhost:3000`

#### Iniciar Bot de Telegram (opcional)

1. **Configurar token**:
```bash
cd telegram-bot
cp .env.example .env
# Agregar TELEGRAM_BOT_TOKEN en .env
```

2. **Instalar dependencias**:
```bash
npm install
```

3. **Iniciar bot**:
```bash
npm run dev
```

O usar el script:
```bash
.\iniciar-bot.bat  # Windows
```

### Scripts Disponibles

#### Proyecto principal (Next.js)

```bash
npm run dev           # Iniciar desarrollo
npm run build         # Build de producción
npm start             # Iniciar producción
npm run lint          # Linter
npm run type-check    # Verificar tipos TypeScript

# Prisma
npm run db:generate   # Generar cliente Prisma
npm run db:push       # Sincronizar schema con BD
npm run db:migrate    # Crear migración
npm run db:seed       # Seed de datos
npm run db:studio     # Abrir Prisma Studio

# Workers
npm run queue:dev     # Iniciar workers de BullMQ
```

#### Bot de Telegram

```bash
npm run dev           # Desarrollo con hot reload
npm run build         # Compilar TypeScript
npm start             # Iniciar bot compilado
npm run typecheck     # Verificar tipos
```

---

## 🌐 APIs y Endpoints

### Base URL
- **Desarrollo**: `http://localhost:3000`
- **Producción**: `https://asistente.involucrate.lat` (configurar)

### Endpoints Implementados

#### 1. POST `/api/audio/upload`

Sube archivo de audio y crea nota en la base de datos.

**Request**:
```typescript
Content-Type: multipart/form-data

{
  audio: File,              // Archivo de audio (max 50MB)
  titulo?: string,          // Título opcional
  fechaGrabacion?: string   // ISO 8601 datetime
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "tituloAuto": "Nota de audio - 03/11/2025",
    "estadoProcesamiento": "SUBIDO",
    "archivoAudioUrl": "https://r2.../audio/123456-file.webm"
  }
}
```

**Errores**:
- 400: Validación fallida, tipo no soportado, archivo muy grande
- 500: Error interno

#### 2. POST `/api/audio/process`

Procesa un audio ya subido (no implementado completamente).

#### 3. GET `/api/tasks`

Lista tareas con paginación y filtros.

**Query params**:
- `page?: number` (default: 1)
- `limit?: number` (default: 20)
- `estado?: EstadoTarea`
- `prioridad?: PrioridadTarea`

**Response** (200):
```json
{
  "success": true,
  "data": {
    "tareas": [
      {
        "id": 1,
        "titulo": "Coordinar reunión",
        "descripcion": "...",
        "fechaVencimiento": "2025-11-10T00:00:00Z",
        "prioridad": "ALTA",
        "estado": "PENDIENTE",
        "completada": false
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "totalPages": 3
    }
  }
}
```

#### 4. POST `/api/tasks`

Crea una nueva tarea.

**Request**:
```json
{
  "titulo": "Nueva tarea",
  "descripcion": "Descripción opcional",
  "fechaVencimiento": "2025-11-15T00:00:00Z",
  "prioridad": "MEDIA",
  "notaAudioId": 1,
  "proyectoId": null,
  "personaId": null
}
```

**Response** (201):
```json
{
  "success": true,
  "data": {
    "id": 2,
    "titulo": "Nueva tarea",
    ...
  }
}
```

#### 5. GET `/api/tasks/[id]`

Obtiene una tarea específica.

#### 6. PUT `/api/tasks/[id]`

Actualiza una tarea.

#### 7. DELETE `/api/tasks/[id]`

Elimina (soft delete) una tarea.

#### 8. GET `/api/validations`

Lista validaciones pendientes.

**Response** (200):
```json
{
  "success": true,
  "data": {
    "validaciones": [
      {
        "id": 1,
        "notaAudioId": 3,
        "tipoValidacion": "TAREA",
        "datosOriginales": { ... },
        "confianzaOriginal": 72,
        "fechaExpiracion": "2025-11-10T00:00:00Z"
      }
    ]
  }
}
```

#### 9. POST `/api/validations`

Aprobar o rechazar una validación.

**Request**:
```json
{
  "validacionId": 1,
  "accion": "aprobar",  // o "rechazar"
  "datosCorregidos": { ... }  // opcional si accion = "aprobar"
}
```

#### 10. POST `/api/webhooks/n8n`

Webhook para recibir notificaciones de n8n.

**Request**:
```json
{
  "evento": "tarea_vencida",
  "datos": { ... }
}
```

### Endpoints Pendientes

- `GET /api/dashboard/metrics` - Métricas del dashboard
- `GET /api/notas` - Listar notas de audio
- `GET /api/notas/[id]` - Detalle de nota
- `GET /api/compromisos` - Listar compromisos
- `GET /api/ideas` - Listar ideas
- `GET /api/personas` - Listar personas
- `GET /api/proyectos` - Listar proyectos
- `POST /api/auth/login` - Autenticación (NextAuth)

---

## 🔌 Integraciones

### 1. Cloudflare R2 (Storage)

**Estado**: ✅ Implementado

**Configuración**:
- Account ID: `374124541e5b062a236e893d30575708`
- Bucket: `asistente-personal`
- Endpoint: `https://374124541e5b062a236e893d30575708.r2.cloudflarestorage.com`

**Funciones** (`lib/storage/r2.ts`):
- `uploadAudioToR2()` - Sube archivo
- `downloadAudioFromR2()` - Descarga archivo
- `deleteAudioFromR2()` - Elimina archivo
- `checkAudioExistsInR2()` - Verifica existencia
- `generateSignedUrl()` - URL temporal firmada
- `getAudioMetadata()` - Metadata del archivo

**Formato de keys**: `audio/{timestamp}-{sanitized-filename}`

### 2. OpenAI Whisper (Transcripción)

**Estado**: ⚠️ Implementado con fallback local

**Configuración**:
- API Key: `process.env.OPENAI_API_KEY`
- Modelo: `whisper-1`
- Idioma: Español (`es`)
- Formato: `verbose_json`

**Modos**:
1. **Whisper API** (producción): Llama a OpenAI API
2. **Whisper Local** (desarrollo): Usa CLI de Whisper instalado localmente
3. **Simulado** (fallback): Genera transcripción de prueba

**Función principal**: `transcribeAudio(audioUrl, audioType)`

**Comando local**: `whisper {file} --language es --output_format txt`

### 3. OpenAI GPT-4o-mini (Extracción)

**Estado**: ⚠️ Implementado con fallback simulado

**Configuración**:
- API Key: `process.env.OPENAI_API_KEY`
- Modelo: `gpt-4o-mini`
- Temperature: `0.1`
- Max tokens: `4000`
- Response format: `json_object`

**Función principal**: `extractEntities(transcription)`

**Entidades extraídas**:
```typescript
{
  tareas: [{
    titulo: string,
    descripcion?: string,
    fecha_vencimiento?: string,
    prioridad: 'alta' | 'media' | 'baja',
    confidence: number
  }],
  compromisos: [{
    titulo: string,
    persona: string,
    fecha_limite: string,
    yo_me_comprometi: boolean,
    confidence: number
  }],
  personas: [{
    nombre: string,
    contexto?: string,
    habilidades?: string[],
    confidence: number
  }],
  ideas: [{
    titulo: string,
    descripcion?: string,
    categoria?: string,
    confidence: number
  }],
  metricas: [{
    nombre: string,
    valor: number,
    unidad: string,
    confidence: number
  }]
}
```

**Umbral de confianza**: 85 (configurable via `CONFIDENCE_THRESHOLD`)

### 4. n8n (Automation)

**Estado**: ⚠️ Configurado, no utilizado activamente

**Configuración**:
- URL: `http://n8n:5678`
- Webhook: `http://n8n:5678/webhook/asistente`
- Auth: Basic (admin/admin)
- Database: PostgreSQL compartida

**Usos potenciales**:
- Notificaciones por email/Telegram
- Sincronización con calendarios
- Integraciones con servicios externos
- Recordatorios automáticos

**Endpoint de webhook**: `/api/webhooks/n8n`

### 5. Telegram Bot

**Estado**: ✅ Implementado y funcional

**Configuración**:
- Token: Configurado en `telegram-bot/.env`
- Modo: Polling (desarrollo), Webhook (producción)
- API Base URL: `http://localhost:3010` (NestJS) o `http://localhost:3000` (Next.js)

**Funcionalidades**:
- Recibe mensajes de texto → Crea ideas
- Recibe notas de voz/audio → Crea notas de audio
- Comandos: `/start`, `/help`, `/status`

**Arquitectura**:
```
Telegram → Bot (Node.js) → API (NestJS/Next.js) → PostgreSQL
```

**Archivos principales**:
- `telegram-bot/src/bot.ts` - Lógica del bot
- `telegram-bot/src/api-client.ts` - Cliente HTTP
- `telegram-bot/iniciar-bot.bat` - Script de inicio

### 6. BullMQ (Queue System)

**Estado**: ✅ Implementado

**Configuración**:
- Redis: `redis://localhost:6379/3`
- Colas: `transcribe-audio`, `extract-entities`, `process-validations`, `send-notifications`
- Concurrencia: 5 jobs simultáneos
- Reintentos: 3 (backoff exponencial de 2s)

**Workers**:
1. **transcription-worker**: Transcribe audio con Whisper
2. **extraction-worker**: Extrae entidades con GPT-4o-mini

**Funciones** (`lib/queue/queue.ts`):
- `addJob(queueName, data, options)` - Agregar job
- `getQueueStats()` - Estadísticas
- `cleanupQueues()` - Limpiar (solo desarrollo)

### 7. NocoDB (Database UI)

**Estado**: ⚠️ Configurado, no utilizado

**Configuración**:
- URL: `http://localhost:8080`
- Database: PostgreSQL compartida
- Uso: Interfaz visual para gestionar BD

### 8. Chatwoot (Customer Support)

**Estado**: ⚠️ Configurado, no utilizado

**Configuración**:
- URL: `http://localhost:3001`
- Database: PostgreSQL compartida
- Uso potencial: Soporte al usuario, gestión de conversaciones

---

## 📊 Estado Actual y Pendientes

### Estado General: MVP al 95%

#### ✅ Completado

##### Infraestructura
- [x] Setup de Next.js 14 con TypeScript
- [x] Configuración de Tailwind CSS
- [x] Configuración de Prisma
- [x] Docker Compose con todos los servicios
- [x] Variables de entorno configuradas

##### Base de Datos
- [x] Schema completo con 12 tablas
- [x] Relaciones entre tablas definidas
- [x] Índices para optimización
- [x] Cliente Prisma con funciones helper

##### Backend (API Routes)
- [x] `/api/audio/upload` - Upload de audio
- [x] `/api/tasks` - CRUD de tareas
- [x] `/api/tasks/[id]` - Operaciones individuales
- [x] `/api/validations` - Sistema de validaciones
- [x] `/api/webhooks/n8n` - Webhook para n8n

##### Queue System
- [x] Setup de BullMQ con 4 colas
- [x] Transcription worker (esqueleto)
- [x] Extraction worker (esqueleto)
- [x] Funciones de gestión de colas

##### AI Integration
- [x] Integración con Whisper API
- [x] Whisper local como fallback
- [x] Integración con GPT-4o-mini
- [x] Prompts de extracción completos
- [x] Validación de entidades

##### Storage
- [x] Integración con Cloudflare R2
- [x] Upload/download de archivos
- [x] Gestión de URLs firmadas

##### Frontend (React)
- [x] Layout principal con navegación
- [x] Dashboard con métricas y resúmenes
- [x] Página de grabación de audio
- [x] Componente AudioRecorder
- [x] Página de validaciones
- [x] Componente ValidationCard
- [x] Componente MetricsCard

##### Integraciones
- [x] Bot de Telegram funcional
- [x] Webhook de n8n configurado
- [x] Docker Compose con n8n, NocoDB, Chatwoot

#### ⚠️ Parcialmente Implementado

- [ ] **Workers de BullMQ**: Esqueleto hecho, lógica de procesamiento con placeholders
- [ ] **Transcripción**: Implementada con fallback a simulación si no hay API key
- [ ] **Extracción de entidades**: Implementada con fallback a simulación
- [ ] **Dashboard metrics**: Datos mock en frontend, falta endpoint real
- [ ] **Autenticación**: NextAuth configurado en dependencies, sin implementar

#### ❌ Pendiente

##### Funcionalidad Core
- [ ] Endpoint `/api/dashboard/metrics` real
- [ ] Procesamiento real end-to-end de audio
- [ ] Pruebas de integración completas
- [ ] Sistema de embeddings con pgvector
- [ ] Búsqueda semántica de notas

##### Páginas Faltantes
- [ ] `/app/tasks/page.tsx` - Lista completa de tareas
- [ ] `/app/settings/page.tsx` - Configuración de usuario
- [ ] `/app/projects/page.tsx` - Gestión de proyectos
- [ ] `/app/personas/page.tsx` - Gestión de personas
- [ ] `/app/ideas/page.tsx` - Gestión de ideas

##### Autenticación
- [ ] Implementar NextAuth
- [ ] Login/logout
- [ ] Protección de rutas
- [ ] Sesiones de usuario

##### Testing
- [ ] Unit tests (Vitest)
- [ ] E2E tests (Playwright)
- [ ] Integration tests
- [ ] Coverage reports

##### DevOps
- [ ] Dockerfile para Next.js app
- [ ] CI/CD pipeline
- [ ] Deployment a producción
- [ ] Monitoring y logging
- [ ] Backups automáticos

##### Optimizaciones
- [ ] Server-side rendering optimizado
- [ ] Caching con React Query
- [ ] Optimización de imágenes
- [ ] Lazy loading de componentes
- [ ] Service Worker para PWA

---

## 🚀 Guía de Desarrollo

### Flujo de Trabajo Recomendado

#### 1. Configurar Entorno Local

```bash
# 1. Instalar dependencias
npm install

# 2. Iniciar servicios Docker
docker-compose up -d postgres redis

# 3. Configurar variables de entorno
cp env.example .env.local
# Editar .env.local con tus valores

# 4. Generar cliente Prisma
npm run db:generate

# 5. Sincronizar schema con BD
npm run db:push

# 6. Iniciar aplicación
npm run dev
```

#### 2. Desarrollar Nueva Feature

**Ejemplo: Agregar endpoint de métricas**

1. **Definir tipos** (si es necesario):
```typescript
// types/metrics.ts
export interface DashboardMetrics {
  notasAudio: number;
  tareasPendientes: number;
  compromisosActivos: number;
  validacionesPendientes: number;
}
```

2. **Crear API route**:
```typescript
// app/api/dashboard/metrics/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';
import { z } from 'zod';

export async function GET() {
  try {
    const [notasAudio, tareasPendientes, compromisosActivos, validacionesPendientes] =
      await Promise.all([
        prisma.notaAudio.count({ where: { deletedAt: null } }),
        prisma.tarea.count({ where: { completada: false, deletedAt: null } }),
        prisma.compromiso.count({ where: { cumplido: false, deletedAt: null } }),
        prisma.validacionPendiente.count({ where: { estado: 'PENDIENTE' } }),
      ]);

    return NextResponse.json({
      success: true,
      data: {
        notasAudio,
        tareasPendientes,
        compromisosActivos,
        validacionesPendientes,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Error obteniendo métricas' },
      { status: 500 }
    );
  }
}
```

3. **Consumir en componente**:
```typescript
// components/dashboard/MetricsCard.tsx
'use client';
import { useEffect, useState } from 'react';

export default function MetricsCard() {
  const [metrics, setMetrics] = useState(null);

  useEffect(() => {
    fetch('/api/dashboard/metrics')
      .then(res => res.json())
      .then(data => setMetrics(data.data));
  }, []);

  // ... render
}
```

#### 3. Trabajar con Base de Datos

**Actualizar schema**:

1. Editar `prisma/schema.prisma`
2. Generar migración: `npm run db:migrate`
3. Aplicar cambios: `npm run db:push` (desarrollo)

**Consultas frecuentes**:

```typescript
// Obtener tareas pendientes con paginación
const tareas = await prisma.tarea.findMany({
  where: {
    completada: false,
    deletedAt: null,
  },
  orderBy: {
    fechaVencimiento: 'asc',
  },
  take: 20,
  skip: (page - 1) * 20,
});

// Crear nota de audio
const nota = await prisma.notaAudio.create({
  data: {
    tituloAuto: 'Nueva nota',
    archivoAudioUrl: 'https://...',
    estadoProcesamiento: 'SUBIDO',
  },
});

// Soft delete
await prisma.tarea.update({
  where: { id: 1 },
  data: { deletedAt: new Date() },
});
```

#### 4. Trabajar con Queue

**Agregar job**:

```typescript
import { addJob } from '@/lib/queue/queue';

await addJob('transcribe-audio', {
  notaAudioId: nota.id,
  archivoAudioUrl: nota.archivoAudioUrl,
  audioType: 'audio/webm',
  audioSize: 1024000,
});
```

**Crear worker**:

```typescript
// lib/queue/workers/mi-worker.ts
import { Worker, Job } from 'bullmq';
import { redis } from '../queue';

const worker = new Worker(
  'mi-cola',
  async (job: Job) => {
    console.log('Procesando job:', job.id);
    // ... lógica
    return { success: true };
  },
  { connection: redis }
);

worker.on('completed', (job) => {
  console.log('Job completado:', job.id);
});

worker.on('failed', (job, err) => {
  console.error('Job fallido:', job?.id, err);
});
```

#### 5. Testing

**Unit test (ejemplo)**:

```typescript
// lib/ai/whisper.test.ts
import { describe, it, expect } from 'vitest';
import { cleanTranscription, detectLanguage } from './whisper';

describe('Whisper Utils', () => {
  it('should clean transcription', () => {
    const dirty = '  Hello   world  ';
    const clean = cleanTranscription(dirty);
    expect(clean).toBe('Hello world');
  });

  it('should detect Spanish', () => {
    const text = 'Hola como estas el dia de hoy';
    const lang = detectLanguage(text);
    expect(lang).toBe('es');
  });
});
```

**E2E test (ejemplo)**:

```typescript
// e2e/upload.spec.ts
import { test, expect } from '@playwright/test';

test('should upload audio file', async ({ page }) => {
  await page.goto('http://localhost:3000/record');

  // Seleccionar archivo
  const fileInput = page.locator('input[type="file"]');
  await fileInput.setInputFiles('test-audio.webm');

  // Esperar respuesta
  await page.waitForSelector('text=Subido exitosamente');

  // Verificar redirección
  await expect(page).toHaveURL(/\/validations/);
});
```

### Convenciones de Código

#### Nombres de Archivos
- **Componentes React**: PascalCase (ej. `MetricsCard.tsx`)
- **Utils/libs**: kebab-case (ej. `audio-utils.ts`)
- **API routes**: `route.ts` (Next.js convención)
- **Páginas**: `page.tsx` (Next.js convención)

#### Nombres de Variables
- **camelCase**: variables, funciones
- **PascalCase**: componentes, tipos, interfaces, clases
- **UPPER_SNAKE_CASE**: constantes globales

#### Estructura de Funciones

```typescript
/**
 * Descripción clara de la función
 * @param param1 - Descripción del parámetro
 * @returns Descripción del valor de retorno
 */
export async function miFuncion(param1: string): Promise<Result> {
  try {
    console.log('🔧 Iniciando proceso:', param1);

    // Lógica principal
    const result = await doSomething();

    console.log('✅ Proceso completado');
    return result;
  } catch (error) {
    console.error('❌ Error en proceso:', error);
    throw error;
  }
}
```

#### Error Handling

```typescript
// API Routes
try {
  // ... lógica
} catch (error) {
  console.error('❌ Error:', error);
  return NextResponse.json(
    {
      success: false,
      error: error instanceof Error ? error.message : 'Error desconocido'
    },
    { status: 500 }
  );
}

// Componentes React
try {
  // ... lógica
} catch (err) {
  console.error('Error:', err);
  setError(err instanceof Error ? err.message : 'Error desconocido');
}
```

### Debugging

#### Logs
- Usar emojis para fácil identificación:
  - 🎵 Audio operations
  - 🔧 Processing
  - ✅ Success
  - ❌ Error
  - ⚠️ Warning
  - 📋 Queue
  - 💾 Database
  - 🧠 AI operations

#### Prisma Studio
```bash
npm run db:studio
# Abre http://localhost:5555
```

#### Redis Commander
```bash
npm install -g redis-commander
redis-commander --redis-host localhost --redis-port 6379
# Abre http://localhost:8081
```

#### n8n
Abrir `http://localhost:5678` (admin/admin)

---

## 🔐 Seguridad

### Consideraciones Actuales

#### ⚠️ Pendientes de Implementar
- [ ] Autenticación de usuarios
- [ ] Autorización por roles
- [ ] Rate limiting
- [ ] CSRF protection
- [ ] Input sanitization exhaustiva
- [ ] Encriptación de datos sensibles
- [ ] Auditoría de accesos

#### ✅ Implementado
- [x] Validación de inputs con Zod
- [x] CORS configurado
- [x] Variables de entorno para secrets
- [x] Soft deletes (no eliminar datos permanentemente)
- [x] Error handling sin exponer detalles internos

### Mejoras de Seguridad Recomendadas

1. **Implementar NextAuth**:
```bash
npm install next-auth
```

2. **Agregar rate limiting**:
```typescript
// middleware.ts
import { Ratelimit } from '@upstash/ratelimit';

export async function middleware(request: NextRequest) {
  // Implementar rate limiting
}
```

3. **Validar JWT en webhooks**:
```typescript
import { verifySignature } from '@/lib/auth';

if (!verifySignature(request.headers.get('x-signature'))) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
}
```

4. **Sanitizar HTML en inputs**:
```typescript
import DOMPurify from 'isomorphic-dompurify';

const clean = DOMPurify.sanitize(userInput);
```

---

## 📈 Roadmap

### Fase 1: MVP Completo (ACTUAL)
- [x] Setup base del proyecto
- [x] Schema de base de datos
- [x] APIs básicas
- [x] Frontend básico
- [ ] Testing completo
- [ ] Deployment inicial

### Fase 2: Producción Beta
- [ ] Autenticación completa
- [ ] Optimización de performance
- [ ] Monitoring y logging
- [ ] Backups automáticos
- [ ] CI/CD pipeline
- [ ] Documentación de usuario

### Fase 3: Features Avanzadas
- [ ] Búsqueda semántica con embeddings
- [ ] Integración con calendarios (Google, Outlook)
- [ ] App móvil nativa
- [ ] Compartir tareas/proyectos con otros usuarios
- [ ] Reportes y analytics avanzados
- [ ] Integraciones con más servicios (Slack, Notion, etc.)

### Fase 4: Escalabilidad
- [ ] Multi-tenancy
- [ ] Sharding de base de datos
- [ ] CDN para archivos estáticos
- [ ] Kubernetes deployment
- [ ] Auto-scaling
- [ ] Multi-región

---

## 🤝 Contribución

Este es un proyecto privado para uso personal de Guillermo. No se aceptan contribuciones externas en este momento.

---

## 📝 Notas Adicionales

### Diferencias con Documentación Original

Este documento **REEMPLAZA** los siguientes archivos:
- `README.md` - Información básica obsoleta
- `CURSOR_INSTRUCTIONS.md` - Instrucciones originales de desarrollo
- `PROGRESS.md` - Registro de progreso ya completado
- `HANDOFF.md` - Reporte de handoff obsoleto

### Información Verificada

Todo el contenido de este documento ha sido **verificado contra el código fuente real** del proyecto:
- ✅ Stack tecnológico coincide con `package.json`
- ✅ Schema de BD coincide con `prisma/schema.prisma`
- ✅ APIs coinciden con archivos en `app/api/`
- ✅ Componentes coinciden con archivos en `components/`
- ✅ Configuración coincide con archivos de config
- ✅ Docker Compose verificado contra `docker-compose.yml`
- ✅ Variables de entorno verificadas contra `env.example`

### Arquitectura Dual Detectada

El proyecto tiene **dos arquitecturas coexistentes**:

1. **Next.js (Principal)**:
   - Carpeta raíz
   - API Routes en `app/api/`
   - Frontend en `app/`
   - En uso activo

2. **NestJS (Legado/Coexistente)**:
   - Referenciado en `src/prisma/`
   - Mencionado en documentación del bot de Telegram
   - No completamente integrado

**Recomendación**: Consolidar en Next.js o migrar completamente a NestJS.

### Configuración Real vs. Placeholders

Algunos valores en `env.example` parecen ser **reales** (no placeholders):
- ⚠️ `OPENAI_API_KEY` - Parece ser una key real
- ⚠️ `R2_ACCESS_KEY`, `R2_SECRET_KEY` - Parecen ser credenciales reales
- ⚠️ Token de Telegram en `telegram-bot/.env` - Token real

**Recomendación URGENTE**:
1. Rotar todas las credenciales expuestas
2. Usar placeholders en archivos de ejemplo
3. Agregar `.env.local` a `.gitignore` (ya está)
4. Nunca commitear credenciales reales

---

## 📧 Contacto

**Guillermo**
Solopreneur Social
Montevideo, Uruguay

---

**Última actualización**: 3 de noviembre de 2025
**Versión del documento**: 1.0.0
**Estado del proyecto**: MVP 95% - En desarrollo activo
