# 🤖 Mateos Automatizaciones

Servicio de procesamiento inteligente de transcripciones con IA para el sistema Mateos.

## 🎯 Funcionalidad

Este servicio recibe transcripciones de audio desde `next-app` y:

1. **Detecta el tipo** de mensaje usando fuzzy matching de keywords
2. **Extrae entidades** estructuradas usando OpenAI GPT-4o-mini
3. **Guarda** en la base de datos extendida

## 🏷️ Keywords Detectadas

| Palabra | Tipo | Descripción |
|---------|------|-------------|
| `teo` | Tarea | TODO que debo hacer |
| `juan` | Registro | Actividad que YA hice |
| `ide` | Idea | Pensamiento o propuesta |
| `compa` | Compromiso | Acuerdo con otra persona |

**Fuzzy Matching**: Tolera errores de transcripción (ej: "theo" → "teo", "cuando" → "juan")

## 🗄️ Base de Datos

Usa PostgreSQL con base de datos `asistente_db` (separada de `transcripciones_db` de Mateos).

### Tablas:
- `notas_audio` - Copia enriquecida de transcripciones
- `tareas` - Tareas TODO extraídas
- `registros` - Actividades pasadas
- `compromisos` - Acuerdos con personas
- `ideas` - Pensamientos capturados

## 🚀 Uso

### Desarrollo Local

```bash
# Instalar dependencias
npm install

# Configurar .env (copiar de .env.example)
cp .env.example .env

# Generar cliente Prisma
npm run prisma:generate

# Crear BD (si no existe)
# Ejecutar en Postgres: CREATE DATABASE asistente_db;

# Push schema a BD
npm run prisma:migrate

# Iniciar servidor
npm run dev
```

El servidor estará en `http://localhost:3100`

### Con Docker (Producción)

Ya está configurado en `docker-compose.yml` del proyecto principal.

```bash
# Desde la raíz del proyecto
docker-compose up -d automatizaciones
```

## 📡 API

### `POST /webhook`

Recibe transcripción y la procesa.

**Request:**
```json
{
  "transcripcionId": 123,
  "texto": "Teo llamar a cliente mañana a las 3pm",
  "archivoUrl": "https://...",
  "fecha": "2025-11-06T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Procesamiento iniciado",
  "transcripcionId": 123
}
```

### `GET /health`

Health check.

**Response:**
```json
{
  "status": "ok",
  "service": "mateos-automatizaciones",
  "timestamp": "2025-11-06T10:30:00Z"
}
```

### `GET /test/keywords/:word`

Prueba fuzzy matching de una palabra.

**Ejemplo:** `GET /test/keywords/theo`

```
🧪 Testing: "theo"
  ✅ teo: 75%
  ❌ juan: 25%
  ❌ ide: 20%
  ❌ compa: 10%
```

## ⚙️ Variables de Entorno

Ver `.env.example` para todas las variables.

**Críticas:**
- `DATABASE_URL` - Conexión a `asistente_db`
- `OPENAI_API_KEY` - Key de OpenAI
- `CONFIDENCE_THRESHOLD` - Umbral de similitud (0.6 = 60%)

## 🧪 Testing

```bash
# Test de fuzzy matching
curl http://localhost:3100/test/keywords/theo
curl http://localhost:3100/test/keywords/cuando

# Test de webhook (simulado)
curl -X POST http://localhost:3100/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "transcripcionId": 999,
    "texto": "Teo llamar a cliente mañana",
    "fecha": "2025-11-06T10:30:00Z"
  }'
```

## 📊 Monitoreo

Ver logs del contenedor:
```bash
docker-compose logs -f automatizaciones
```

Logs incluyen emojis para fácil identificación:
- 🔍 Detección
- 🧠 IA
- 💾 Base de datos
- ✅ Éxito
- ❌ Error

## 🛠️ Desarrollo

### Estructura

```
src/
├── index.ts              # Express server
├── processor.ts          # Orquestador principal
├── keyword-matcher.ts    # Fuzzy matching
├── ai-extractor.ts       # OpenAI integration
├── db-writer.ts          # Prisma queries
└── types.ts              # TypeScript types

prisma/
└── schema.prisma         # DB schema
```

### Agregar Nueva Keyword

1. Editar `KEYWORDS` en `keyword-matcher.ts`
2. Agregar tipo en `types.ts`
3. Agregar prompt en `ai-extractor.ts`
4. Agregar case en `db-writer.ts`

## 🔄 Flujo Completo

```
Usuario graba audio en Telegram
    ↓
next-app transcribe con Whisper
    ↓
next-app llama webhook de automatizaciones
    ↓
keyword-matcher detecta tipo (ej: "teo" → tarea)
    ↓
ai-extractor usa GPT-4o-mini para extraer campos
    ↓
db-writer guarda en asistente_db
    ↓
Usuario ve en NocoDB
```

## 📝 Notas

- **Fuzzy matching** usa Levenshtein distance
- **Threshold**: 60% de similitud mínima (configurable)
- **Sin clasificar**: Si no match, se guarda pero no se procesa con IA
- **Idempotente**: No reprocesa transcripciones ya procesadas
