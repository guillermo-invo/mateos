# 🏗️ MATEOS V2: Plan de Integración - Sistema de Gestión Estratégica

## 📋 Resumen Ejecutivo

**Objetivo**: Integrar un sistema de gestión estratégica de proyectos y tareas al sistema MATEOS existente (en producción), que actualmente captura notas de voz y extrae entidades básicas.

**Resultado esperado**: Un sistema unificado donde las notas de voz pueden convertirse en proyectos estratégicos completos con IA, y donde el usuario tiene dashboards inteligentes para decidir "qué hacer ahora".

---

## 1. ANÁLISIS DE SISTEMAS

### 1.1 Sistema Actual (MATEOS en Producción)

```
┌─────────────────────────────────────────────────────────────┐
│                   MATEOS V1 (PRODUCCIÓN)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  FLUJO ACTUAL:                                              │
│  Telegram → Bot → next-app → Whisper → automatizaciones    │
│                                    ↓                        │
│                            PostgreSQL (2 BDs)               │
│                                                              │
│  BASES DE DATOS:                                            │
│  • transcripciones_db → Transcripcion                       │
│  • asistente_db → NotaAudio, Tarea, Registro,              │
│                   Compromiso, IdeaCapturada                 │
│                                                              │
│  SERVICIOS DOCKER:                                          │
│  • postgres-db (puerto 1432)                                │
│  • next-app (puerto 1400)                                   │
│  • automatizaciones (puerto 1410)                           │
│  • telegram-bot                                             │
│                                                              │
│  TECNOLOGÍAS:                                               │
│  • Next.js 15.5, Express.js, Prisma 6.18                   │
│  • GPT-4o-mini, Whisper API, Cloudflare R2                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Sistema Nuevo (Gestión Estratégica)

```
┌─────────────────────────────────────────────────────────────┐
│                   MATEOS V2 (NUEVO)                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  TABLAS TAXATIVAS (datos personales, manual):               │
│  • areas (14 registros)                                     │
│  • motivos (12 registros)                                   │
│  • destrezas (79 registros + metadata energía/momento)     │
│  • dificultades (9 registros)                               │
│  • misiones (6 registros)                                   │
│                                                              │
│  TABLAS GENERATIVAS (IA + usuario):                         │
│  • proyectos (con justificacion_estrategica JSONB)         │
│  • tareas (con MoSCoW, dependencias, contexto)             │
│  • subtareas (con destreza/dificultad requerida)           │
│  • validaciones_pendientes                                  │
│  • logs_generacion_ia                                       │
│                                                              │
│  VISTAS DE DECISIÓN:                                        │
│  • vista_que_hacer_ahora                                    │
│  • vista_matarife (poda automática)                        │
│  • vista_proyectos_activos                                  │
│                                                              │
│  FUNCIONALIDADES:                                           │
│  • Generación de proyectos con IA desde descripción        │
│  • Dashboard "Qué Hacer Ahora" con contexto                │
│  • Sistema Matarife (poda de tareas ineficientes)          │
│  • Scoring de priorización (MoSCoW + riesgo + alineación)  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. ESTRATEGIA DE INTEGRACIÓN

### 2.1 Principio Fundamental: **Extensión, No Reemplazo**

El sistema nuevo se agrega **como una extensión** del sistema existente. No se modifican las tablas actuales de producción, solo se agregan nuevas.

```
┌─────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA INTEGRADA                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [CAPA EXISTENTE - NO TOCAR]                                │
│  transcripciones_db.Transcripcion (intacta)                │
│  asistente_db.NotaAudio (intacta)                          │
│  asistente_db.Tarea (existente) ←───┐                      │
│  asistente_db.Compromiso (intacta)  │                      │
│  asistente_db.IdeaCapturada (intacta)                      │
│                                      │                      │
│  [CAPA NUEVA - EXTENSIÓN]           │                      │
│  asistente_db.areas (nueva)          │                      │
│  asistente_db.motivos (nueva)        │                      │
│  asistente_db.destrezas (nueva)      │ FK opcional         │
│  asistente_db.dificultades (nueva)   │                      │
│  asistente_db.misiones (nueva)       │                      │
│  asistente_db.proyectos_estrategicos (nueva) ←──┘          │
│  asistente_db.tareas_estrategicas (nueva)                  │
│  asistente_db.subtareas (nueva)                            │
│                                                              │
│  [PUNTO DE CONEXIÓN]                                        │
│  IdeaCapturada.proyecto_id → proyectos_estrategicos.id     │
│  Tarea.proyecto_estrategico_id → proyectos_estrategicos.id │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Decisión Arquitectónica Clave: **Una Sola BD**

**Opción elegida**: Agregar todas las tablas nuevas a `asistente_db` (no crear una tercera BD).

**Justificación**:
- Simplicidad: Un solo Prisma schema para automatizaciones
- Relaciones directas: FKs entre NotaAudio/IdeaCapturada y proyectos
- Transacciones: Consistency en operaciones que cruzan tablas
- Ya existe la infraestructura (postgres-db ya sirve asistente_db)

### 2.3 Nombrado de Tablas Nuevas

Para evitar colisión con la tabla `Tarea` existente:

| Tabla Original (documento) | Nombre en BD | Razón |
|---------------------------|--------------|-------|
| proyectos | proyectos_estrategicos | Evitar confusión con futuros |
| tareas | tareas_estrategicas | Colisión con Tarea existente |
| subtareas | subtareas | No hay colisión |
| áreas | areas_vida | Claridad |
| motivos | motivos_personales | Claridad |
| destrezas | destrezas | OK |
| dificultades | dificultades | OK |
| misiones | misiones_vida | Claridad |

---

## 3. DIAGRAMA DE INTEGRACIÓN FINAL

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MATEOS V2 - ARQUITECTURA INTEGRADA               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ENTRADA (sin cambios)                                                  │
│  ┌──────────────┐                                                       │
│  │   Telegram   │ ──→ telegram-bot ──→ next-app ──→ Whisper            │
│  │  Nota de voz │                           ↓                           │
│  └──────────────┘                    transcripciones_db                 │
│                                             ↓                           │
│                                      automatizaciones                   │
│                                             ↓                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      asistente_db                                │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │ CAPA EXISTENTE (V1)                                      │   │   │
│  │  │                                                          │   │   │
│  │  │  NotaAudio ──→ Tarea (simple)                           │   │   │
│  │  │      ↓                                                   │   │   │
│  │  │  IdeaCapturada ────────────────────┐                    │   │   │
│  │  │      ↓                              │                    │   │   │
│  │  │  Compromiso                         │                    │   │   │
│  │  │      ↓                              │                    │   │   │
│  │  │  Registro                           │                    │   │   │
│  │  └─────────────────────────────────────│────────────────────┘   │   │
│  │                                        │                        │   │
│  │  ┌─────────────────────────────────────↓────────────────────┐   │   │
│  │  │ CAPA NUEVA (V2)                     │                    │   │   │
│  │  │                                     │                    │   │   │
│  │  │  ┌──────────────┐    ┌──────────────↓─────────┐         │   │   │
│  │  │  │ TAXATIVAS    │    │ GENERATIVAS            │         │   │   │
│  │  │  │              │    │                        │         │   │   │
│  │  │  │ areas_vida   │───→│ proyectos_estrategicos │←────────┤   │   │
│  │  │  │ motivos      │───→│         ↓              │         │   │   │
│  │  │  │ destrezas    │───→│ tareas_estrategicas    │         │   │   │
│  │  │  │ dificultades │───→│         ↓              │         │   │   │
│  │  │  │ misiones_vida│───→│     subtareas          │         │   │   │
│  │  │  └──────────────┘    └────────────────────────┘         │   │   │
│  │  │                                                          │   │   │
│  │  │  ┌─────────────────────────────────────────────┐        │   │   │
│  │  │  │ VISTAS PostgreSQL                            │        │   │   │
│  │  │  │ • vista_que_hacer_ahora                      │        │   │   │
│  │  │  │ • vista_matarife                             │        │   │   │
│  │  │  │ • vista_proyectos_activos                    │        │   │   │
│  │  │  └─────────────────────────────────────────────┘        │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  SALIDA (nuevo)                                                         │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │ FRONTEND WEB (Next.js)                                         │     │
│  │                                                                │     │
│  │  /dashboard          → Métricas + "Qué Hacer Ahora"           │     │
│  │  /proyectos          → Lista de proyectos estratégicos        │     │
│  │  /proyectos/crear    → Formulario + generación IA             │     │
│  │  /proyectos/[id]     → Detalle con tareas/subtareas           │     │
│  │  /matarife           → Poda de tareas                         │     │
│  │                                                                │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. PLAN DE DESARROLLO (6-8 semanas)

### FASE 0: Preparación (2-3 días)
**Objetivo**: Entorno de desarrollo listo sin afectar producción

| Tarea | Tiempo | Prioridad |
|-------|--------|-----------|
| Crear rama `feature/gestion-estrategica` | 1h | 🔴 |
| Hacer backup de BD de producción | 1h | 🔴 |
| Crear ambiente de desarrollo aislado | 4h | 🔴 |
| Documentar estado actual | 2h | 🟡 |

**Entregable**: Ambiente de desarrollo funcionando con copia de producción

---

### FASE 1: Modelo de Datos (4-5 días)
**Objetivo**: Tablas nuevas creadas y pobladas en desarrollo

#### 1.1 Crear ENUMs (2h)
```sql
-- En asistente_db
CREATE TYPE tipo_moscow AS ENUM ('must', 'should', 'could', 'wont');
CREATE TYPE tipo_enfoque AS ENUM ('velocidad', 'perfeccion', 'balanceado');
CREATE TYPE tipo_libertad AS ENUM ('receta', 'resultado', 'mixto');
CREATE TYPE tipo_riesgo AS ENUM ('bajo', 'medio', 'alto', 'critico');
CREATE TYPE tipo_energia AS ENUM ('relax', 'baja', 'media', 'alta', 'pico');
CREATE TYPE tipo_estado_proyecto AS ENUM ('idea', 'planificacion', 'en_curso', 'pausado', 'completado', 'cancelado', 'archivado');
CREATE TYPE tipo_estado_tarea AS ENUM ('por_hacer', 'en_progreso', 'bloqueada', 'en_revision', 'completada', 'cancelada');
```

#### 1.2 Crear Tablas Taxativas (4h)
```sql
CREATE TABLE areas_vida (...);
CREATE TABLE motivos_personales (...);
CREATE TABLE destrezas (...);  -- Con metadata de energía/momento
CREATE TABLE dificultades (...);
CREATE TABLE misiones_vida (...);
```

#### 1.3 Crear Tablas Generativas (4h)
```sql
CREATE TABLE proyectos_estrategicos (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  descripcion TEXT,
  areas_ids INTEGER[],
  motivos_ids INTEGER[],
  destrezas_requeridas_ids INTEGER[],
  dificultades_ids INTEGER[],
  misiones_ids INTEGER[],
  justificacion_estrategica JSONB,
  objetivos_smart JSONB,
  fecha_inicio DATE,
  fecha_fin_estimada DATE,
  estado tipo_estado_proyecto DEFAULT 'idea',
  prioridad_global DECIMAL(3,2),
  score_motivacional DECIMAL(3,2),
  score_alineacion DECIMAL(3,2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tareas_estrategicas (...);
CREATE TABLE subtareas (...);
CREATE TABLE logs_generacion_ia (...);
```

#### 1.4 Modificar Modelos Existentes (2h)
```sql
-- Agregar FK opcional a IdeaCapturada
ALTER TABLE ideas_capturadas 
ADD COLUMN proyecto_estrategico_id INTEGER 
REFERENCES proyectos_estrategicos(id);

-- Agregar FK opcional a Tarea existente
ALTER TABLE tareas
ADD COLUMN proyecto_estrategico_id INTEGER 
REFERENCES proyectos_estrategicos(id);
```

#### 1.5 Actualizar Prisma Schema (4h)
```prisma
// automatizaciones/prisma/schema.prisma

// Agregar todos los modelos nuevos
model AreasVida {
  id          Int      @id @default(autoincrement())
  nombre      String   @unique
  descripcion String?
  activa      Boolean  @default(true)
  createdAt   DateTime @default(now())
  
  proyectos   ProyectoEstrategico[]
}

model ProyectoEstrategico {
  id                        Int      @id @default(autoincrement())
  nombre                    String
  descripcion               String?
  areasIds                  Int[]
  motivosIds                Int[]
  destrezasRequeridasIds    Int[]
  dificultadesIds           Int[]
  misionesIds               Int[]
  justificacionEstrategica  Json?
  objetivosSmart            Json?
  fechaInicio               DateTime?
  fechaFinEstimada          DateTime?
  estado                    String   @default("idea")
  prioridadGlobal           Float?
  scoreMotivacional         Float?
  scoreAlineacion           Float?
  createdAt                 DateTime @default(now())
  updatedAt                 DateTime @updatedAt

  tareas                    TareaEstrategica[]
  ideasCapturadas           IdeaCapturada[]
  logsGeneracion            LogGeneracionIA[]
}

// ... resto de modelos
```

#### 1.6 Poblar Datos Taxativos (1-2 días)
- Ejecutar scripts SQL con los 14 áreas, 12 motivos, 79 destrezas, etc.
- Datos específicos de Guillermo (ya definidos en el documento)

**Entregable**: BD con todas las tablas nuevas y datos taxativos

---

### FASE 2: Vistas de Decisión (3-4 días)
**Objetivo**: Vistas PostgreSQL funcionando

#### 2.1 Vista "Qué Hacer Ahora" (1 día)
```sql
CREATE OR REPLACE VIEW vista_que_hacer_ahora AS
SELECT 
  s.id,
  s.titulo,
  t.nombre as tarea,
  p.nombre as proyecto,
  d.costo_energetico as nivel_energia_requerido,
  d.mejor_momento_dia as mejor_momento,
  s.tiempo_estimado_minutos,
  -- Cálculo de score
  CASE s.moscow WHEN 'must' THEN 40 WHEN 'should' THEN 30 WHEN 'could' THEN 15 ELSE 0 END
  + CASE t.nivel_riesgo WHEN 'critico' THEN 30 WHEN 'alto' THEN 22 WHEN 'medio' THEN 12 ELSE 5 END
  + CASE WHEN d.nivel_actual <= 4 THEN 20 WHEN d.nivel_actual <= 6 THEN 12 ELSE 5 END
  AS score_prioridad
FROM subtareas s
JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
LEFT JOIN destrezas d ON d.id = s.destreza_principal_id
WHERE s.completada = false
  AND t.estado NOT IN ('completada', 'cancelada')
  AND p.estado IN ('en_curso', 'planificacion');
```

#### 2.2 Vista "Matarife" (1 día)
```sql
CREATE OR REPLACE VIEW vista_matarife AS
SELECT 
  t.id as tarea_id,
  t.nombre as tarea,
  p.nombre as proyecto,
  CASE 
    WHEN t.prioridad_velocidad_perfeccion = 'velocidad' 
         AND t.moscow IN ('could', 'wont') 
    THEN 'ELIMINAR'
    WHEN t.prioridad_velocidad_perfeccion = 'velocidad' 
         AND t.nivel_riesgo IN ('alto', 'critico') 
    THEN 'REVISAR_RIESGO'
    WHEN t.estado = 'bloqueada' 
         AND t.updated_at < NOW() - INTERVAL '7 days'
    THEN 'DESBLOQUEAR_O_ELIMINAR'
    ELSE 'OK'
  END as veredicto,
  -- ... más campos
FROM tareas_estrategicas t
JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
WHERE p.estado IN ('en_curso', 'planificacion');
```

#### 2.3 Vista Proyectos Activos (4h)
```sql
CREATE OR REPLACE VIEW vista_proyectos_activos AS
SELECT 
  p.id,
  p.nombre,
  p.estado,
  p.score_alineacion,
  p.prioridad_global,
  COUNT(DISTINCT t.id) FILTER (WHERE t.estado != 'completada') as tareas_pendientes,
  ROUND(
    COUNT(DISTINCT s.id) FILTER (WHERE s.completada) * 100.0 / 
    NULLIF(COUNT(DISTINCT s.id), 0)
  , 1) as porcentaje_completado,
  SUM(s.tiempo_estimado_minutos) FILTER (WHERE NOT s.completada) / 60.0 as horas_restantes
FROM proyectos_estrategicos p
LEFT JOIN tareas_estrategicas t ON t.proyecto_id = p.id
LEFT JOIN subtareas s ON s.tarea_estrategica_id = t.id
WHERE p.estado IN ('en_curso', 'planificacion')
GROUP BY p.id;
```

#### 2.4 Funciones de Scoring (4h)
```sql
CREATE OR REPLACE FUNCTION calcular_score_motivos(motivos_ids INTEGER[])
RETURNS DECIMAL AS $$
  -- Lógica de cálculo
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calcular_score_alineacion(misiones_ids INTEGER[])
RETURNS DECIMAL AS $$
  -- Lógica de cálculo
$$ LANGUAGE plpgsql;
```

**Entregable**: Vistas funcionando con queries de prueba

---

### FASE 3: Sistema de IA (5-7 días)
**Objetivo**: Generación automática de estructura de proyectos

#### 3.1 Estructura de Prompts (1 día)
```typescript
// automatizaciones/src/ia/prompts-proyectos.ts

export const PROMPT_SISTEMA_PROYECTO = `
Eres un asistente estratégico de planificación de proyectos.

CONTEXTO DEL USUARIO:
{contexto_personal}

PROYECTOS ACTIVOS:
{proyectos_activos}

INSTRUCCIONES:
1. Analiza el proyecto propuesto en relación al contexto del usuario
2. Genera justificación estratégica estructurada
3. Descompón en 5-15 tareas con criterios MoSCoW
4. Para cada tarea, genera 3-8 subtareas
5. Asigna metadata: tiempo, energía, destreza, dificultad, riesgo

FORMATO DE RESPUESTA:
Responde ÚNICAMENTE con JSON válido con esta estructura:
{
  "proyecto": {
    "justificacion_estrategica": { ... },
    "areas_ids": [...],
    "motivos_ids": [...],
    "destrezas_requeridas_ids": [...],
    "dificultades_ids": [...],
    "misiones_ids": [...]
  },
  "tareas": [
    {
      "nombre": "...",
      "orden": 1,
      "moscow": "must|should|could|wont",
      "tiempo_estimado_horas": 5,
      "nivel_riesgo": "bajo|medio|alto|critico",
      "subtareas": [...]
    }
  ]
}
`;
```

#### 3.2 Generador de Proyectos (2 días)
```typescript
// automatizaciones/src/ia/generador-proyectos.ts

export async function generarEstructuraProyecto(
  descripcion: string,
  documentosUrls?: string[]
): Promise<EstructuraProyecto> {
  // 1. Obtener contexto personal
  const contexto = await obtenerContextoPersonal();
  
  // 2. Obtener proyectos activos
  const proyectosActivos = await obtenerProyectosActivos();
  
  // 3. Construir prompt
  const prompt = buildPrompt(descripcion, contexto, proyectosActivos);
  
  // 4. Llamar a Claude/GPT
  const response = await anthropic.messages.create({
    model: "claude-3-5-sonnet-20241022",
    temperature: 0.3,
    max_tokens: 8000,
    messages: [
      { role: "system", content: PROMPT_SISTEMA_PROYECTO },
      { role: "user", content: prompt }
    ]
  });
  
  // 5. Parsear y validar
  const estructura = JSON.parse(response.content[0].text);
  await validarEstructura(estructura);
  
  // 6. Enriquecer con cálculos
  estructura.proyecto.score_motivacional = calcularScoreMotivos(estructura.proyecto.motivos_ids);
  estructura.proyecto.score_alineacion = calcularScoreAlineacion(estructura.proyecto.misiones_ids);
  
  return estructura;
}
```

#### 3.3 Guardar Proyecto Generado (1 día)
```typescript
// automatizaciones/src/ia/guardar-proyecto.ts

export async function guardarProyectoGenerado(
  estructura: EstructuraProyecto
): Promise<number> {
  return await prisma.$transaction(async (tx) => {
    // 1. Crear proyecto
    const proyecto = await tx.proyectoEstrategico.create({
      data: {
        nombre: estructura.proyecto.nombre,
        descripcion: estructura.proyecto.descripcion,
        justificacionEstrategica: estructura.proyecto.justificacion_estrategica,
        areasIds: estructura.proyecto.areas_ids,
        // ... resto de campos
      }
    });
    
    // 2. Crear tareas
    for (const tareaData of estructura.tareas) {
      const tarea = await tx.tareaEstrategica.create({
        data: {
          proyectoId: proyecto.id,
          nombre: tareaData.nombre,
          orden: tareaData.orden,
          moscow: tareaData.moscow,
          // ...
        }
      });
      
      // 3. Crear subtareas
      for (const subtareaData of tareaData.subtareas) {
        await tx.subtarea.create({
          data: {
            tareaEstrategicaId: tarea.id,
            titulo: subtareaData.titulo,
            // ...
          }
        });
      }
    }
    
    // 4. Log de generación
    await tx.logGeneracionIA.create({
      data: {
        proyectoId: proyecto.id,
        tipoGeneracion: 'inicial',
        modeloIA: 'claude-3-5-sonnet',
        tokensUsados: response.usage.total_tokens,
        // ...
      }
    });
    
    return proyecto.id;
  });
}
```

#### 3.4 Integración con Flujo Existente (1-2 días)

Modificar `automatizaciones/src/processor.ts` para detectar ideas de proyectos:

```typescript
// Agregar nuevo case
case 'proyecto':
  // Cuando se detecta "Quiero hacer un proyecto de..."
  await crearIdeaProyecto(texto, notaAudioId);
  break;

async function crearIdeaProyecto(texto: string, notaAudioId: number) {
  // Guardar como idea pendiente de desarrollo
  await prisma.ideaCapturada.create({
    data: {
      notaAudioId,
      titulo: extraerTituloProyecto(texto),
      descripcion: texto,
      categoria: 'proyecto_potencial',
      // Estado especial para ideas de proyecto
    }
  });
  
  // Notificar al usuario que puede desarrollar el proyecto
  await enviarNotificacion(
    "💡 Idea de proyecto capturada. ¿Quieres desarrollarla en MATEOS?"
  );
}
```

**Entregable**: Sistema de IA generando proyectos completos

---

### FASE 4: Backend API (4-5 días)
**Objetivo**: Endpoints REST para el frontend

#### 4.1 Endpoints de Proyectos (1 día)
```typescript
// next-app/src/app/api/proyectos-estrategicos/route.ts
GET    /api/proyectos-estrategicos           → Lista proyectos
POST   /api/proyectos-estrategicos           → Crear proyecto manual
POST   /api/proyectos-estrategicos/generar   → Generar con IA

// next-app/src/app/api/proyectos-estrategicos/[id]/route.ts
GET    /api/proyectos-estrategicos/[id]      → Detalle proyecto
PUT    /api/proyectos-estrategicos/[id]      → Actualizar
DELETE /api/proyectos-estrategicos/[id]      → Eliminar
```

#### 4.2 Endpoints de Dashboard (1 día)
```typescript
GET /api/dashboard/que-hacer-ahora?energia=media&horas=2&momento=tarde
GET /api/dashboard/matarife
GET /api/dashboard/metricas
```

#### 4.3 Endpoints de Tareas (1 día)
```typescript
GET    /api/tareas-estrategicas?proyectoId=5
POST   /api/tareas-estrategicas
PUT    /api/tareas-estrategicas/[id]
DELETE /api/tareas-estrategicas/[id]
POST   /api/tareas-estrategicas/[id]/completar
```

#### 4.4 Endpoints de Subtareas (1 día)
```typescript
GET    /api/subtareas?tareaId=10
POST   /api/subtareas
PUT    /api/subtareas/[id]
DELETE /api/subtareas/[id]
POST   /api/subtareas/[id]/completar
```

#### 4.5 Endpoints Auxiliares (1 día)
```typescript
// Tablas taxativas (solo lectura)
GET /api/areas-vida
GET /api/motivos
GET /api/destrezas
GET /api/dificultades
GET /api/misiones
```

**Entregable**: API completa documentada

---

### FASE 5: Frontend Web (7-10 días)
**Objetivo**: Dashboard interactivo

#### 5.1 Layout Base (1 día)
- Sidebar con navegación
- Header con métricas rápidas
- Footer con estado del sistema
- Dark mode

#### 5.2 Dashboard Principal (2 días)
- Panel "Qué Hacer Ahora"
- Panel "Matarife" (si hay tareas para podar)
- Grid de proyectos activos con progreso

#### 5.3 Gestión de Proyectos (3 días)
- Lista de proyectos con filtros
- Formulario de creación (manual + IA)
- Vista de revisión de estructura generada
- Detalle de proyecto con tareas/subtareas

#### 5.4 Gestión de Tareas (2 días)
- Vista Kanban opcional
- Edición inline
- Drag & drop para reordenar

#### 5.5 Vista Matarife (1 día)
- Lista de tareas a podar
- Botones de acción (eliminar, postergar, revisar)
- Poda automática con confirmación

**Entregable**: Frontend funcional

---

### FASE 6: Integración y Testing (3-4 días)
**Objetivo**: Todo funcionando junto

#### 6.1 Integración con Flujo de Audio (1 día)
- Detectar ideas de proyectos en notas de voz
- Vincular ideas existentes a proyectos
- Crear subtareas ad-hoc desde audio

#### 6.2 Testing E2E (2 días)
- Flujo completo: audio → proyecto → tareas
- Pruebas de vistas de decisión
- Pruebas de generación IA

#### 6.3 Optimización (1 día)
- Índices faltantes
- Caching de queries frecuentes
- Performance de vistas

---

### FASE 7: Deployment (2-3 días)
**Objetivo**: Sistema en producción

#### 7.1 Migración de BD (4h)
```bash
# En producción
docker-compose exec automatizaciones npm run prisma:migrate
```

#### 7.2 Deploy de Servicios (4h)
```bash
docker-compose build
docker-compose up -d
```

#### 7.3 Smoke Testing (4h)
- Verificar endpoints
- Probar generación IA
- Validar vistas

#### 7.4 Monitoreo (4h)
- Logs estructurados
- Alertas básicas
- Backup strategy

---

## 5. RESUMEN DE ARCHIVOS A CREAR/MODIFICAR

### Archivos NUEVOS

```
automatizaciones/
├── prisma/
│   └── schema.prisma (agregar modelos)
├── src/
│   ├── ia/
│   │   ├── prompts-proyectos.ts (NUEVO)
│   │   ├── generador-proyectos.ts (NUEVO)
│   │   └── guardar-proyecto.ts (NUEVO)
│   ├── queries/
│   │   ├── proyectos.ts (NUEVO)
│   │   ├── tareas-estrategicas.ts (NUEVO)
│   │   └── dashboard.ts (NUEVO)
│   └── processor.ts (MODIFICAR - agregar case 'proyecto')

next-app/
├── src/app/
│   ├── api/
│   │   ├── proyectos-estrategicos/
│   │   │   ├── route.ts (NUEVO)
│   │   │   ├── generar/route.ts (NUEVO)
│   │   │   └── [id]/route.ts (NUEVO)
│   │   ├── tareas-estrategicas/
│   │   │   ├── route.ts (NUEVO)
│   │   │   └── [id]/route.ts (NUEVO)
│   │   ├── subtareas/
│   │   │   ├── route.ts (NUEVO)
│   │   │   └── [id]/route.ts (NUEVO)
│   │   └── dashboard/
│   │       ├── que-hacer-ahora/route.ts (NUEVO)
│   │       ├── matarife/route.ts (NUEVO)
│   │       └── metricas/route.ts (NUEVO)
│   ├── dashboard/
│   │   └── page.tsx (NUEVO)
│   ├── proyectos/
│   │   ├── page.tsx (NUEVO)
│   │   ├── crear/page.tsx (NUEVO)
│   │   └── [id]/page.tsx (NUEVO)
│   └── matarife/
│       └── page.tsx (NUEVO)
├── components/
│   ├── dashboard/
│   │   ├── QueHacerAhoraPanel.tsx (NUEVO)
│   │   ├── MatarifePanel.tsx (NUEVO)
│   │   └── ProyectosActivosGrid.tsx (NUEVO)
│   ├── proyectos/
│   │   ├── CrearProyectoForm.tsx (NUEVO)
│   │   ├── ProyectoCard.tsx (NUEVO)
│   │   └── RevisionEstructura.tsx (NUEVO)
│   └── tareas/
│       ├── TareaCard.tsx (NUEVO)
│       └── SubtareaItem.tsx (NUEVO)

sql/
├── 01_enums.sql (NUEVO)
├── 02_tablas_taxativas.sql (NUEVO)
├── 03_tablas_generativas.sql (NUEVO)
├── 04_indices.sql (NUEVO)
├── 05_vistas.sql (NUEVO)
├── 06_funciones.sql (NUEVO)
└── data/
    ├── areas.sql (NUEVO)
    ├── motivos.sql (NUEVO)
    ├── destrezas.sql (NUEVO)
    ├── dificultades.sql (NUEVO)
    └── misiones.sql (NUEVO)
```

### Archivos a MODIFICAR

```
automatizaciones/
├── prisma/schema.prisma (agregar 10+ modelos nuevos)
├── src/processor.ts (agregar case 'proyecto')
├── src/keyword-matcher.ts (agregar keywords de proyecto)
└── src/types.ts (agregar tipos nuevos)

next-app/
├── prisma/schema.prisma (agregar FK opcional)
└── src/app/layout.tsx (agregar navegación)

docker-compose.yml
└── (sin cambios significativos, mismo stack)

.env
└── (agregar ANTHROPIC_API_KEY si usas Claude)
```

---

## 6. ESTIMACIÓN TOTAL

| Fase | Días | Horas | Prioridad |
|------|------|-------|-----------|
| 0. Preparación | 2-3 | 16-24h | 🔴 Crítico |
| 1. Modelo de Datos | 4-5 | 32-40h | 🔴 Crítico |
| 2. Vistas de Decisión | 3-4 | 24-32h | 🔴 Crítico |
| 3. Sistema de IA | 5-7 | 40-56h | 🔴 Crítico |
| 4. Backend API | 4-5 | 32-40h | 🟡 Alto |
| 5. Frontend | 7-10 | 56-80h | 🟡 Alto |
| 6. Integración | 3-4 | 24-32h | 🟡 Alto |
| 7. Deployment | 2-3 | 16-24h | 🟢 Medio |
| **TOTAL** | **30-41 días** | **240-328h** | |

**Con 20h/semana**: 12-16 semanas (3-4 meses)
**Con 40h/semana**: 6-8 semanas

---

## 7. RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Prompts IA no generan buena estructura | Media | Alto | Iterar prompts, usar Claude en vez de GPT-mini |
| Conflicto con tablas existentes | Baja | Alto | Usar nombres distintos, FKs opcionales |
| Performance de vistas complejas | Media | Medio | Índices GIN, vistas materializadas |
| Scope creep | Alta | Medio | Priorizar MoSCoW, MVP primero |
| Migración de BD falla | Baja | Crítico | Backup antes, rollback plan |

---

## 8. SIGUIENTE PASO INMEDIATO

1. **Crear rama** `feature/gestion-estrategica`
2. **Hacer backup** de BD de producción
3. **Crear archivos SQL** con ENUMs y tablas (Fase 1.1-1.3)
4. **Actualizar Prisma schema** de automatizaciones
5. **Probar migración** en desarrollo

¿Empezamos por la Fase 1?
