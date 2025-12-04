# 🎯 MATEOS - Onboarding para Nueva Funcionalidad

**Para**: El desarrollador que va a agregar nueva funcionalidad a MATEOS
**Tiempo**: 3-4 horas para estar completamente onboardeado
**Objetivo**: Que entiendas el proyecto y puedas empezar a codificar

---

## 📍 Eres Aquí (5 minutos)

### ¿Qué es MATEOS?

Un asistente personal inteligente que:

```
Usuario graba nota de voz
    ↓ (Telegram)
Bot descarga audio
    ↓
API transcribe (Whisper)
    ↓
Automatizaciones procesa (GPT-4o-mini)
    ↓
BD guarda entidades estructuradas
    ↓
Usuario ve en NocoDB
```

### Resultado Final

Usuario dice: **"Teo, llamar a María mañana a las 3pm"**

Sistema guarda automáticamente:
```
Tabla: tareas
├─ titulo: "Llamar a María"
├─ fechaVencimiento: 2025-12-02 15:00
├─ prioridad: MEDIA
├─ descripcion: ""
└─ completada: false
```

---

## 🚀 Quickstart (30 minutos)

### 1. Verifica Prerequisites

```bash
node --version          # debe ser >= 20.11.0
npm --version           # debe ser >= 10.0.0
docker --version        # debe ser >= 24.0
docker-compose --version # debe ser >= 2.23
```

### 2. Clone el Repo

```bash
git clone <repo-url> mateos
cd mateos
```

### 3. Configura .env

```bash
# El .env ya debería estar configurado, pero verifica:
cat .env | grep OPENAI_API_KEY
# Si está vacío, pídele a alguien las credenciales
```

### 4. Inicia Servicios

```bash
# Build images
docker-compose build

# Iniciar todo
docker-compose up -d

# Esperar 15 segundos a PostgreSQL
sleep 15

# Migraciones
docker-compose exec next-app npx prisma migrate deploy
docker-compose exec automatizaciones npm run prisma:deploy

# Verificar status
docker-compose ps
# Deberías ver todos los servicios "Up" o "healthy"
```

### 5. Verifica que Funciona

```bash
# Health checks
curl http://localhost:1400/api/health
curl http://localhost:1410/health

# Ambos deberían retornar JSON con "status":"ok"
```

### 6. Explora la BD

```bash
# Ver transcripciones
docker-compose exec postgres-db psql -U asistente -d transcripciones_db -c \
  "SELECT id, LEFT(texto, 50) as texto FROM transcripciones LIMIT 5;"

# O mejor: interfaz gráfica
docker-compose exec next-app npx prisma studio
# Abre http://localhost:5555
```

---

## 📚 Lectura Recomendada (2 horas)

Lee EN ESTE ORDEN:

### 1. DOCUMENTACION.md (20 min)
**Ubicación**: `/mateos/DOCUMENTACION.md`

Lee la sección "🎯 Flujos de Lectura Recomendados" → elige tu flujo.

### 2. DEVELOPER_GUIDE.md (30 min)
**Ubicación**: `/mateos/DEVELOPER_GUIDE.md`

Lee estas secciones:
- "Lo Más Importante en 5 Minutos"
- "Conceptos Clave Explicados"
- "Flow: Rastreando un Request"
- "Dónde Agregar Nueva Funcionalidad"

### 3. ARCHITECTURE.md (60 min)
**Ubicación**: `/mateos/ARCHITECTURE.md`

Lee estas secciones (en orden):
1. "Visión General"
2. "Stack Tecnológico"
3. "Arquitectura de Servicios"
4. "Flujo de Datos End-to-End"
5. "Servicios en Detalle" → solo los servicios relevantes
6. "Decisiones Arquitectónicas" → para entender el por qué

---

## 🏗️ Estructura del Proyecto (10 minutos)

```
mateos/
├─ next-app/                  ← API REST + Frontend
│  ├─ src/app/api/
│  │  └─ process-audio/       ← 🌟 PUNTO DE ENTRADA
│  └─ src/lib/
│     ├─ prisma.ts
│     ├─ r2-client.ts
│     ├─ whisper-client.ts
│     └─ logger.ts
│
├─ automatizaciones/          ← Procesamiento IA (Express.js)
│  ├─ src/
│  │  ├─ index.ts
│  │  ├─ processor.ts         ← 🌟 ORQUESTADOR PRINCIPAL
│  │  ├─ keyword-matcher.ts   ← Detecta tipo
│  │  ├─ ai-extractor.ts      ← Extrae con GPT
│  │  └─ db-writer.ts
│  └─ prisma/schema.prisma
│
├─ telegram-bot/              ← Bot de Telegram
│  └─ src/index.ts            ← Polling loop
│
├─ docker-compose.yml         ← Orquestación
├─ ARCHITECTURE.md            ← 📘 LA BIBLIA
├─ DEVELOPER_GUIDE.md         ← 📗 PRÁCTICA
└─ DOCUMENTACION.md           ← 📑 ÍNDICE
```

---

## 💡 Los 5 Conceptos Más Importantes

### 1. **Prisma + 2 BDs**
```
next-app usa:        transcripciones_db    (transcripciones originales)
automatizaciones usa: asistente_db         (datos procesados)

NO son dos instancias de PostgreSQL:
es UNA ÚNICA instancia con DOS bases de datos
```

### 2. **Fire-and-Forget Webhook**
```
next-app no espera respuesta de automatizaciones
Retorna al usuario AL INSTANTE
Automatizaciones procesa EN BACKGROUND
```

### 3. **Fuzzy Matching**
```
Usuario dice "Deo" (por error de transcripción)
Sistema detecta como "Teo" (tolerancia de error)
Algoritmo: Levenshtein distance
```

### 4. **Promise.all para Paralelismo**
```
Upload a R2 + Transcripción en PARALELO
No secuencial (que sería más lento)
```

### 5. **Zod para Validación en Fronteras**
```
Todo input debe ser validado con Zod
Protege contra datos malformados
Retorna 400 Bad Request si falla
```

---

## 🔍 Código Clave para Leer

### Archivo 1: `next-app/src/app/api/process-audio/route.ts`
**Por qué**: Es el entry point de TODO

```typescript
// Flujo:
1. POST /api/process-audio
2. Parsear FormData
3. Validar con Zod
4. Convertir File → Buffer
5. Deduplicación (telegram_file_id)
6. Crear/actualizar Transcripcion
7. Promise.all([uploadToR2, transcribeAudio])
8. Guardar en BD
9. notifyAutomatizaciones (fire-and-forget)
10. Retornar respuesta
```

**Ubicación**: `/mateos/next-app/src/app/api/process-audio/route.ts`

**Tiempo de lectura**: 20 minutos

---

### Archivo 2: `automatizaciones/src/processor.ts`
**Por qué**: Es el orquestador de toda la lógica IA

```typescript
// Flujo:
1. Recibe webhook
2. Verifica si ya fue procesado
3. detectTipoFromTranscription() → fuzzy matching
4. createNotaAudio() → guarda referencia
5. extractEntities() → llama GPT-4o-mini
6. validateExtraction() → valida JSON
7. saveExtraction() → guarda entidades
8. Retorna resultado
```

**Ubicación**: `/mateos/automatizaciones/src/processor.ts`

**Tiempo de lectura**: 20 minutos

---

### Archivo 3: `automatizaciones/src/ai-extractor.ts`
**Por qué**: Aquí está la "magia" de extracción con IA

```typescript
// Funciones:
extractEntities() → Llamar GPT-4o-mini con prompt dinámico
validateExtraction() → Verificar que JSON sea válido

// Prompts para cada tipo:
- TAREA: "Extrae { titulo, descripcion, fechaVencimiento, prioridad }"
- REGISTRO: "Extrae { descripcion, duracionHoras, proyecto, personasInvolucradas }"
- IDEA: "Extrae { titulo, descripcion, categoria }"
- COMPROMISO: "Extrae { titulo, personaNombre, fechaLimite, yoMeComprometi }"
```

**Ubicación**: `/mateos/automatizaciones/src/ai-extractor.ts`

**Tiempo de lectura**: 15 minutos

---

### Archivo 4: `prisma/schema.prisma` (ambas BDs)
**Por qué**: Es el modelo de datos

**next-app/prisma/schema.prisma**:
```prisma
model Transcripcion {
  id: Int
  texto: String
  r2_url, r2_key: String       ← Audio en Cloudflare R2
  telegram_file_id: String     ← Deduplicación
  estado: enum(PROCESANDO|COMPLETADO|ERROR)
}
```

**automatizaciones/prisma/schema.prisma**:
```prisma
model NotaAudio {
  id: Int
  transcripcionId: Int @unique ← Referencia a otra BD
  tipoDetectado: String        ← "tarea", "registro", etc

  tareas: Tarea[]              ← Relación 1:N
  registros: Registro[]
  ideas: IdeaCapturada[]
  compromisos: Compromiso[]
}
```

**Ubicación**:
- `/mateos/next-app/prisma/schema.prisma`
- `/mateos/automatizaciones/prisma/schema.prisma`

**Tiempo de lectura**: 15 minutos

---

## 🧪 Tu Primer Test (10 minutos)

### Test 1: Health Checks
```bash
curl http://localhost:1400/api/health
curl http://localhost:1410/health

# Resultado esperado: {"status":"ok",...}
```

### Test 2: Keyword Matching
```bash
curl http://localhost:1410/test/keywords/theo
curl http://localhost:1410/test/keywords/cuando

# Resultado esperado: {"detectedType":"tarea","confidence":1.0}
```

### Test 3: Webhook Manual
```bash
curl -X POST http://localhost:1410/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "transcripcionId": 999,
    "texto": "Teo, hacer informe para mañana",
    "archivoUrl": "https://example.com/audio.ogg",
    "fecha": "2025-12-01T10:30:00Z"
  }'

# Resultado esperado: {"success":true,"tipo":"tarea",...}
```

### Test 4: Ver en BD
```bash
docker-compose exec postgres-db psql -U asistente -d asistente_db -c \
  "SELECT id, titulo FROM tareas WHERE id=999;"

# Deberías ver la tarea creada
```

---

## 🎯 Dónde Agregar Nueva Funcionalidad

### Caso 1: Nuevo Endpoint en API
**Archivo**: `next-app/src/app/api/<tu-feature>/route.ts`

Template:
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { logger } from '@/lib/logger';

const schema = z.object({ /* tu schema */ });

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validated = schema.parse(body);

    logger.info('Tu feature', { ...validated });

    // Tu lógica aquí

    return NextResponse.json({ success: true });
  } catch (error) {
    logger.error('Tu feature error', error);
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
```

### Caso 2: Nuevo Tipo de Entidad
**Archivos a cambiar** (en orden):

1. `automatizaciones/prisma/schema.prisma` → Nuevo modelo
2. `automatizaciones/src/types.ts` → Nuevo tipo
3. `automatizaciones/src/ai-extractor.ts` → Nuevo prompt
4. `automatizaciones/src/processor.ts` → Nuevo case
5. `automatizaciones/src/keyword-matcher.ts` → Nuevo keyword

Ver detalles completos en `DEVELOPER_GUIDE.md`.

### Caso 3: Nueva Tarea Cron
**Archivo**: `automatizaciones/src/scheduler.ts`

```typescript
new CronJob(
  "0 20 * * *",
  async () => {
    logger.info('Tu tarea cron');
    // Tu lógica
  },
  null,
  true,
  "America/Montevideo"
);
```

---

## 🐛 Debugging Rápido

### "No sé dónde está el error"
```bash
docker-compose logs -f
# Ver todos los logs en vivo
# Buscar "ERROR" o "error"
```

### "Quiero ver logs de un servicio específico"
```bash
docker-compose logs -f next-app          # Solo API
docker-compose logs -f automatizaciones  # Solo procesamiento
docker-compose logs -f telegram-bot      # Solo bot
```

### "Quiero ver la BD"
```bash
# Opción 1: Interfaz gráfica
docker-compose exec next-app npx prisma studio
# Abre http://localhost:5555

# Opción 2: Línea de comandos
docker-compose exec postgres-db psql -U asistente -d asistente_db
# psql> SELECT * FROM tareas;
```

### "Un servicio no inicia"
```bash
# Ver logs detallados
docker-compose logs <servicio>

# Intentar reiniciar
docker-compose restart <servicio>

# Rebuild
docker-compose up -d --build <servicio>
```

---

## 📋 Antes de Escribir Código

### Checklist

- [ ] Setup local funcionando
- [ ] Todos los servicios en "healthy"
- [ ] Leíste DEVELOPER_GUIDE.md
- [ ] Leíste ARCHITECTURE.md
- [ ] Entiendes el flujo end-to-end
- [ ] Hiciste los 4 tests anteriores
- [ ] Sabes dónde agregar tu feature
- [ ] Entiendes Prisma, Zod, async/await

### Si no cumples algo

**¿No funciona setup?**
→ Lee `QUICKSTART.md` → Troubleshooting

**¿No entiendes un concepto?**
→ Lee `DEVELOPER_GUIDE.md` → "Conceptos Clave Explicados"

**¿No sabes dónde agregar feature?**
→ Lee `DEVELOPER_GUIDE.md` → "Dónde Agregar Nueva Funcionalidad"

---

## 🚀 Primera Tarea Sugerida

Para practicar y familiarizarte:

### Tarea: Agregar Nuevo Tipo "EVENTO"

**Requiere**:
- Modificar schema Prisma
- Agregar keyword
- Escribir prompt de extracción
- Guardar en BD

**Tiempo estimado**: 1-2 horas

**Beneficio**: Entiendes todo el pipeline

**Pasos**:
1. Lee `DEVELOPER_GUIDE.md` → "Caso 2: Agregar Nuevo Tipo de Extracción"
2. Sigue pasos
3. Test manual
4. Ver en BD

---

## 📞 Necesitas Ayuda?

### Pregunta: "¿Dónde está..."
→ Busca en `DOCUMENTACION.md` → Índice

### Pregunta: "¿Cómo hago..."
→ Lee `DEVELOPER_GUIDE.md` → FAQ o sección específica

### Pregunta: "¿Por qué la arquitectura es así?"
→ Lee `ARCHITECTURE.md` → "Decisiones Arquitectónicas"

### Problema: "Algo no funciona"
→ Lee `QUICKSTART.md` → Troubleshooting

### Problema: Complejo/no sé resolver
→ Mira logs: `docker-compose logs -f`

---

## ✅ Eres Listo Cuando...

- [ ] Setup local funciona
- [ ] Entiendes qué hace MATEOS en 5 minutos
- [ ] Leíste DEVELOPER_GUIDE.md y ARCHITECTURE.md
- [ ] Hiciste los 4 tests correctamente
- [ ] Entiendes el flujo process-audio → automatizaciones → BD
- [ ] Sabes dónde agregar una nueva feature
- [ ] Puedes debuggear con logs
- [ ] Sabes navegar la BD

**Estimado**: 3-4 horas total

---

## 🎓 Próximos Pasos

1. **Hoy**: Sigue "Quickstart" + "Lectura Recomendada"
2. **Mañana**: Lee código fuente (process-audio → processor)
3. **Luego**: Haz tu primera tarea sugerida
4. **Finalmente**: Crea tu feature

---

## 📚 Documentación Rápida

| Necesitas | Lee esto |
|-----------|----------|
| Overview | README.md |
| Setup local | QUICKSTART.md |
| Dónde agregar feature | DEVELOPER_GUIDE.md |
| Entender arquitectura | ARCHITECTURE.md |
| Deploy | DEPLOYMENT.md |
| Ayuda general | DOCUMENTACION.md |

---

## 💪 ¡Estás Listo!

Tienes TODO lo que necesitas:
- ✅ Ambiente configurado
- ✅ Documentación completa
- ✅ Código para estudiar
- ✅ Tests para validar

**Ahora**: Elige tu primer feature y ¡empieza!

**Bienvenido al equipo MATEOS!** 🚀

---

**Creado**: Diciembre 2025
**Versión**: 1.0.0
**Para**: Nuevos desarrolladores de MATEOS
