# _CONTEXT.md - IA (Procesamiento con GPT)

## PROPÓSITO

Módulos de procesamiento de inteligencia artificial para generación de proyectos con GPT. Incluye prompts engineering, validación de responses, y persistencia de proyectos generados.

---

## STACK TÉCNICO ESPECÍFICO

- **OpenAI API:** GPT-5.1 (projectCreation), GPT-5.1-mini (extraction), GPT-5-mini (summaries)
- **Validación:** Zod 3.22.4
- **Prisma:** 6.18.0 (persistencia)
- **Configuración:** `models-config.json` (modelos por tipo de tarea)

---

## ARQUITECTURA Y PATRONES

### Flujo de Generación de Proyectos

```
Input (idea o descripción)
  → generador-proyectos.ts (GPT processing)
  → Validación (Zod schema)
  → guardar-proyecto.ts (Prisma write)
  → Return (proyecto creado)
```

### Prompts Engineering

**Ubicación:** `prompts-proyectos.ts` (6KB)

**Estructura de prompts:**
1. **System prompt:** Define rol y comportamiento del asistente
2. **User prompt:** Descripción del proyecto a generar
3. **Format instructions:** Estructura JSON esperada

**Versionado:**
- Prompts son strings en el código (NO archivos externos)
- Versionar cambios significativos en git
- Comentar razón de cambios importantes

---

## ARCHIVOS CLAVE

### generador-proyectos.ts

**Propósito:** Genera estructura de proyecto completo usando GPT-4.

**Input:**
```typescript
interface GenerateProjectInput {
  descripcion: string
  areaVidaId?: string
  contextoAdicional?: string
}
```

**Output:**
```typescript
interface ProyectoGenerado {
  titulo: string
  descripcion: string
  objetivo: string
  estado: EstadoKanban
  areaVidaId: string | null
  tareas: {
    titulo: string
    descripcion: string
    prioridad: 'ALTA' | 'MEDIA' | 'BAJA'
    estimacionHoras: number
  }[]
  cronograma: {
    fechaInicio: Date
    fechaFin: Date
    hitos: {
      nombre: string
      fecha: Date
      descripcion: string
    }[]
  }
}
```

**Validación con Zod:**
```typescript
const proyectoGeneradoSchema = z.object({
  titulo: z.string().min(3).max(200),
  descripcion: z.string().min(10).max(2000),
  objetivo: z.string().min(10).max(500),
  estado: z.enum(['BACKLOG', 'TODO', 'DOING', 'WAITING', 'DONE', 'FREEZER']),
  areaVidaId: z.string().uuid().nullable(),
  tareas: z.array(z.object({
    titulo: z.string().min(3).max(200),
    descripcion: z.string().max(1000),
    prioridad: z.enum(['ALTA', 'MEDIA', 'BAJA']),
    estimacionHoras: z.number().min(0.5).max(100),
  })),
  // ... resto del schema
})
```

**⚠️ Retry Logic:**
```typescript
const maxRetries = 3
let attempt = 0

while (attempt < maxRetries) {
  try {
    const completion = await openai.chat.completions.create({...})
    const parsed = proyectoGeneradoSchema.parse(JSON.parse(completion.choices[0].message.content))
    return parsed
  } catch (error) {
    attempt++
    if (attempt >= maxRetries) throw error
    await sleep(Math.pow(2, attempt) * 1000) // Backoff exponencial
  }
}
```

---

### prompts-proyectos.ts (6KB)

**Propósito:** Define prompts para generación de proyectos.

**Estructura:**

```typescript
export const SYSTEM_PROMPT = `
Eres un asistente especializado en planificación de proyectos para personas con TDAH.

PRINCIPIOS:
- Dividir proyectos en tareas pequeñas y manejables (máx 4 horas cada una)
- Priorizar claridad y especificidad
- Incluir estimaciones realistas
- Considerar dificultades de concentración y organización

FORMATO DE SALIDA:
Retorna un objeto JSON con la siguiente estructura:
{
  "titulo": "string (3-200 chars)",
  "descripcion": "string (10-2000 chars)",
  "objetivo": "string (10-500 chars)",
  "estado": "BACKLOG" | "TODO" | "DOING" | "WAITING" | "DONE" | "FREEZER",
  "areaVidaId": "uuid | null",
  "tareas": [
    {
      "titulo": "string",
      "descripcion": "string",
      "prioridad": "ALTA" | "MEDIA" | "BAJA",
      "estimacionHoras": number (0.5-100)
    }
  ],
  "cronograma": {
    "fechaInicio": "ISO date",
    "fechaFin": "ISO date",
    "hitos": [
      {
        "nombre": "string",
        "fecha": "ISO date",
        "descripcion": "string"
      }
    ]
  }
}
`

export const USER_PROMPT_TEMPLATE = (descripcion: string, contexto?: string) => `
Genera un plan de proyecto basado en esta descripción:

${descripcion}

${contexto ? `Contexto adicional:\n${contexto}` : ''}

INSTRUCCIONES:
- Divide el proyecto en tareas de máximo 4 horas
- Prioriza tareas por impacto y dificultad
- Estima duración total realista
- Incluye hitos intermedios para mantener motivación
- Estado inicial: BACKLOG (no iniciar automáticamente)
`
```

**Optimizaciones recientes:**
- Reducción de tokens: 1.2K → 800 tokens (33% menos costo)
- Uso de bullets en lugar de párrafos
- Ejemplos concisos y específicos

---

### guardar-proyecto.ts

**Propósito:** Persiste proyecto generado en base de datos con Prisma.

**Transacción atómica:**
```typescript
export async function guardarProyecto(proyecto: ProyectoGenerado): Promise<string> {
  return await prisma.$transaction(async (tx) => {
    // 1. Crear proyecto
    const proyectoCreado = await tx.proyecto.create({
      data: {
        titulo: proyecto.titulo,
        descripcion: proyecto.descripcion,
        objetivo: proyecto.objetivo,
        estado: proyecto.estado,
        areaVidaId: proyecto.areaVidaId,
        fechaInicio: proyecto.cronograma.fechaInicio,
        fechaFin: proyecto.cronograma.fechaFin,
      },
    })

    // 2. Crear tareas asociadas
    await tx.tarea.createMany({
      data: proyecto.tareas.map(tarea => ({
        ...tarea,
        proyectoId: proyectoCreado.id,
        estado: 'TODO',
      })),
    })

    // 3. Crear hitos
    await tx.hito.createMany({
      data: proyecto.cronograma.hitos.map(hito => ({
        ...hito,
        proyectoId: proyectoCreado.id,
      })),
    })

    return proyectoCreado.id
  })
}
```

**⚠️ Rollback automático:** Si cualquier paso falla, TODA la transacción se revierte.

---

## REGLAS Y RESTRICCIONES

### Prompts

#### ✅ SIEMPRE:
- Especificar formato JSON esperado en system prompt
- Incluir validaciones en el prompt (ej: "máximo 200 caracteres")
- Usar lenguaje imperativo ("Divide", "Prioriza", NO "Por favor divide")
- Incluir contexto de TDAH (tareas pequeñas, motivación, claridad)

#### ❌ NUNCA:
- Prompts vagos o ambiguos
- Asumir que GPT retorna formato correcto (SIEMPRE validar con Zod)
- Incluir información sensible en prompts

### Modelos GPT

**Configuración actual:** (desde `models-config.json`)
- **projectCreation:** `gpt-5.1` (temp: 0.8, maxTokens: 16000) - Generación creativa
- **extraction:** `gpt-5.1-mini` (temp: 0, maxTokens: 4000) - Extracción estructurada
- **dailySummary:** `gpt-5-mini` (temp: 0.3, maxTokens: 2000) - Resúmenes
- **transcription:** `whisper-v4` - Transcripción de audio

**⚠️ IMPORTANTE:**
- Los modelos `gpt-5.1`, `gpt-5.1-mini`, `whisper-v4` son específicos de OpenAI 2026
- NO reemplazar con modelos legacy sin confirmar disponibilidad
- Configuración centralizada en `getModelConfig()` de `model-config.ts`

### Validación

#### ✅ SIEMPRE:
- Validar response de GPT con Zod schema ANTES de guardar
- Retornar error 400 si validación falla
- Loggear response inválida para debugging

#### ❌ NUNCA:
- Guardar en DB sin validar
- Asumir que GPT retorna JSON válido (puede retornar texto o JSON malformado)

---

## CONFIGURACIÓN

### Modelo GPT

```typescript
// model-config.ts
export const GPT_CONFIG = {
  model: 'gpt-4-turbo-preview',
  temperature: 0.7,         // Creatividad moderada
  max_tokens: 4096,         // Suficiente para proyectos complejos
  top_p: 1,
  frequency_penalty: 0,
  presence_penalty: 0,
}
```

**Temperature:**
- `0.0`: Determinístico, respuestas consistentes
- `0.7`: Balance creatividad/consistencia (actual)
- `1.0`: Muy creativo, respuestas variadas

**Max Tokens:**
- Input + Output NO debe exceder límite del modelo (128K para GPT-4 Turbo)
- Output típico: 2-3K tokens (proyecto completo)

---

## NOTAS PARA IA

### ⚠️ GPT-4 Turbo NO soporta Function Calling Legacy
- Usar `tools` parameter (NO `functions`)
- Estructura:
```typescript
const completion = await openai.chat.completions.create({
  model: 'gpt-4-turbo-preview',
  messages: [...],
  tools: [{
    type: 'function',
    function: {
      name: 'guardar_proyecto',
      description: '...',
      parameters: {...},
    }
  }],
})
```

### ⚠️ Costos de GPT-4 Turbo
- Input: $0.01 / 1K tokens
- Output: $0.03 / 1K tokens
- Proyecto típico: ~1K input + 2.5K output = $0.085 por generación
- Monitorear uso en `logs/openai-usage.log`

### ⚠️ Rate Limits
- Tier 3: 500 req/min, 200K tokens/min
- Implementar queue si se generan múltiples proyectos en paralelo
- Backoff exponencial en retry

### ⚠️ JSON Parsing
```typescript
// GPT puede retornar JSON con texto adicional
const content = completion.choices[0].message.content

// Extraer JSON si está envuelto en markdown
const jsonMatch = content.match(/```json\n([\s\S]*?)\n```/)
const jsonString = jsonMatch ? jsonMatch[1] : content

const parsed = JSON.parse(jsonString)
```

---

## TESTING

### Estrategia
- Mock de OpenAI API (respuestas fijas)
- Tests de validación Zod (casos válidos e inválidos)
- Tests de transacción Prisma (rollback)

### Casos críticos:
- GPT retorna JSON válido → guardado exitoso
- GPT retorna JSON inválido → error 400, NO guardado
- Falla guardado de tareas → rollback proyecto
- Retry logic funciona tras error de OpenAI

---

## FLUJO DE GENERACIÓN CON MERGE DE DATOS

### Prioridad de Datos: Usuario > IA

**Problema original:** La IA generaba áreas y motivos, sobrescribiendo lo que el usuario seleccionó en el formulario.

**Solución implementada:**

1. **Frontend envía:**
   - `nombre`: Nombre del proyecto (usuario)
   - `descripcion`: Descripción (usuario)
   - `areasIds`: Áreas seleccionadas (usuario)
   - `motivosIds`: Motivos seleccionados (usuario)

2. **Backend (automatizaciones) hace merge:**
```typescript
const mergedEstructura = {
  ...estructuraGenerada,
  proyecto: {
    ...estructuraGenerada.proyecto,
    nombre: nombre || estructuraGenerada.proyecto.nombre || 'Proyecto sin nombre',
    descripcion: descripcion, // SIEMPRE del usuario
    areas_ids: areasIds?.length > 0 ? areasIds : estructuraGenerada.proyecto.areas_ids,
    motivos_ids: motivosIds?.length > 0 ? motivosIds : estructuraGenerada.proyecto.motivos_ids,
  }
}
```

3. **IA genera:**
   - Justificación estratégica
   - Objetivos SMART
   - Destrezas requeridas
   - Dificultades
   - Misiones de vida
   - Tareas y subtareas
   - Scores (motivacional, alineación, prioridad global)

### Estado Inicial de Proyectos

**Estado por defecto:** `'planificacion'` (NO `'idea'`)

**Razón:** Proyectos generados con IA ya están listos para planificarse, no son simples ideas.

### Campos Guardados

**Proyecto:**
- ✅ `nombre`, `descripcion` (usuario)
- ✅ `justificacionEstrategica`, `objetivosSmart` (IA)
- ✅ `areasIds`, `motivosIds` (usuario con fallback IA)
- ✅ `destrezasRequeridasIds`, `dificultadesIds`, `misionesIds` (IA)
- ✅ `prioridadGlobal`, `scoreMotivacional`, `scoreAlineacion` (IA)
- ✅ `estado: 'planificacion'`

**Tareas:**
- ✅ `nombre`, `descripcion` (IA)
- ✅ `orden`, `moscow`, `tiempoEstimadoHoras` (IA)
- ✅ `nivelRiesgo`, `impacto`, `urgencia` (IA)
- ✅ `prioridadVelocidadPerfeccion` (IA)

**Subtareas:**
- ✅ `nombre` (IA, campo llamado `titulo` en estructura)
- ✅ `tiempoEstimadoMinutos`, `moscow` (IA)

---

**Última actualización:** 2026-01-07
**Cambios:** Agregado merge de datos usuario/IA, estado inicial 'planificacion', campos completos en tareas/subtareas
**Versión:** 1.1
