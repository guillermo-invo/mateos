# _CONTEXT.md - API Routes

## PROPÓSITO

Endpoints REST del backend de Mateos. Implementa CRUD y lógica de negocio para todos los recursos del sistema (proyectos, tareas, ideas, dashboard, etc.).

---

## STACK TÉCNICO ESPECÍFICO

- **Framework:** Next.js 15 API Routes (App Router)
- **Runtime:** Node.js 20+ (Edge Runtime NO usado, necesitamos Prisma)
- **ORM:** Prisma 6.18.0
- **Validación:** Zod 3.22.4
- **Logger:** Winston 3.11.0

---

## ARQUITECTURA Y PATRONES

### Pattern Estándar

**Estructura de carpetas:**
```
api/[recurso]/
├── route.ts              # GET (lista), POST (crear)
└── [id]/
    └── route.ts          # GET, PATCH, DELETE (por ID)
```

**Flujo de request:**
```
HTTP Request
  → Validación (Zod schema)
  → Lógica de negocio
  → Prisma query
  → Response (formato estándar)
  → Error handling (catch + log)
```

### Formato de Respuesta Estándar

```typescript
// ✅ Success (200, 201)
return NextResponse.json({
  success: true,
  data: resultado
}, { status: 200 })

// ❌ Client Error (400, 404)
return NextResponse.json({
  success: false,
  error: "Mensaje descriptivo para el cliente"
}, { status: 400 })

// ❌ Server Error (500)
return NextResponse.json({
  success: false,
  error: "Error interno del servidor"
}, { status: 500 })
```

### Template de Endpoint

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import logger from '@/lib/logger'

// Schema de validación
const createSchema = z.object({
  campo1: z.string().min(1),
  campo2: z.number().optional()
})

// POST /api/recurso
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    // Validar
    const validated = createSchema.parse(body)

    // Lógica de negocio (si aplica)
    // ... validaciones adicionales ...

    // Prisma query
    const result = await prisma.recurso.create({
      data: validated
    })

    return NextResponse.json({
      success: true,
      data: result
    }, { status: 201 })

  } catch (error) {
    // Zod validation error
    if (error instanceof z.ZodError) {
      return NextResponse.json({
        success: false,
        error: error.errors[0].message
      }, { status: 400 })
    }

    // Server error
    logger.error('Error en POST /api/recurso:', error)
    return NextResponse.json({
      success: false,
      error: 'Error interno del servidor'
    }, { status: 500 })
  }
}

// GET /api/recurso
export async function GET(request: NextRequest) {
  try {
    // Query params (opcional)
    const { searchParams } = new URL(request.url)
    const filter = searchParams.get('filter')

    const results = await prisma.recurso.findMany({
      where: filter ? { campo: filter } : undefined,
      orderBy: { createdAt: 'desc' }
    })

    return NextResponse.json({
      success: true,
      data: results
    })

  } catch (error) {
    logger.error('Error en GET /api/recurso:', error)
    return NextResponse.json({
      success: false,
      error: 'Error interno del servidor'
    }, { status: 500 })
  }
}
```

---

## REGLAS Y RESTRICCIONES

### Validación

#### ✅ SIEMPRE:
- Validar TODOS los inputs con Zod schemas
- Definir schemas al inicio del archivo (antes de handlers)
- Retornar error 400 con mensaje claro en caso de validación fallida
- Validar tipos, longitudes, formatos (emails, UUIDs, etc.)

#### ❌ NUNCA:
- Confiar en inputs del cliente sin validar
- Usar validación manual (`if (typeof x === 'string')`) si Zod puede hacerlo
- Ignorar errores de Zod (siempre retornar 400)

### Status Codes

**Usar correctamente:**
- `200` OK: GET, PATCH, DELETE exitosos
- `201` Created: POST exitoso (recurso creado)
- `400` Bad Request: Input inválido, validación fallida
- `401` Unauthorized: Autenticación requerida (no implementado aún)
- `404` Not Found: Recurso no existe
- `500` Internal Server Error: Error del servidor

### Prisma

#### ✅ SIEMPRE:
- Importar desde `@/lib/prisma` (singleton)
- Usar transacciones para operaciones múltiples relacionadas
- Incluir `select` o `include` para optimizar queries
- Manejar errores `PrismaClientKnownRequestError` (ej: unique constraint)

#### ❌ NUNCA:
- Crear nueva instancia de `PrismaClient`
- Hacer queries sin try/catch
- Exponer errores raw de Prisma al cliente (traducir a mensajes amigables)

### Logging

#### ✅ SIEMPRE:
- Loggear errores 500 con `logger.error()`
- Incluir contexto útil (endpoint, userId si existe, input)
- Loggear operaciones críticas (ej: delete, cambios de estado importante)

#### ❌ NUNCA:
- Loggear datos sensibles (passwords, tokens)
- Loggear cada request 200 (crear ruido en logs)
- Usar `console.log` (usar Winston logger)

---

## ENDPOINTS ACTUALES

### Dashboard (7 endpoints)
- `GET /api/dashboard/proyectos-activos`: Resumen de proyectos por estado
- `GET /api/dashboard/estadisticas-generales`: Métricas globales
- `GET /api/dashboard/ideas-recientes`: Últimas ideas capturadas
- `GET /api/dashboard/tareas-prioritarias`: Tareas de alta prioridad
- `GET /api/dashboard/proximas-acciones`: Próximas acciones planificadas
- `GET /api/dashboard/progreso-semanal`: Progreso de la semana actual
- `GET /api/dashboard/areas-vida-balance`: Balance de áreas de vida

### Proyectos
- `GET /api/proyectos`: Lista todos los proyectos (filtros: estado, área)
- `POST /api/proyectos`: Crear proyecto simple (legacy)
- `GET /api/proyectos/[id]`: Detalle de proyecto
- `PATCH /api/proyectos/[id]`: Actualizar proyecto
- `DELETE /api/proyectos/[id]`: Eliminar proyecto

### Proyectos Estratégicos
- `GET /api/proyectos-estrategicos`: Lista proyectos V2 con planificación
- `POST /api/proyectos-estrategicos`: Crear proyecto V2 (legacy, sin IA)
- `POST /api/proyectos-estrategicos/generar`: Generar proyecto con IA (reenvía a automatizaciones)
- `GET /api/proyectos-estrategicos/[id]`: Detalle proyecto V2 (serializa Decimals a números)
- `PATCH /api/proyectos-estrategicos/[id]`: Actualizar proyecto V2
- `DELETE /api/proyectos-estrategicos/[id]`: Eliminar proyecto V2

### Tareas Estratégicas
- `GET /api/tareas-estrategicas`: Lista tareas (filtros: estado, proyecto)
- `POST /api/tareas-estrategicas`: Crear tarea
- `PATCH /api/tareas-estrategicas/[id]`: Actualizar tarea (incluye cambio de estado Kanban)
- `DELETE /api/tareas-estrategicas/[id]`: Eliminar tarea

### Subtareas
- `GET /api/subtareas`: Lista subtareas de un proyecto
- `POST /api/subtareas`: Crear subtarea
- `PATCH /api/subtareas/[id]`: Actualizar subtarea
- `DELETE /api/subtareas/[id]`: Eliminar subtarea

### Ideas
- `GET /api/ideas`: Lista ideas capturadas
- `POST /api/ideas`: Crear idea
- `PATCH /api/ideas/[id]`: Actualizar idea
- `DELETE /api/ideas/[id]`: Eliminar idea

### Áreas de Vida
- `GET /api/areas-vida`: Lista áreas de vida
- (CRUD completo similar)

### Misiones de Vida
- `GET /api/misiones-vida`: Lista misiones largo plazo
- (CRUD completo similar)

### Destrezas y Dificultades
- `GET /api/destrezas`: Lista habilidades/fortalezas
- `GET /api/dificultades`: Lista limitaciones/debilidades
- (CRUD completo similar)

### Procesamiento
- `POST /api/process-audio`: Procesar nota de voz (Whisper + IA)
- `POST /api/telegram-webhook`: Webhook Telegram bot

### Health
- `GET /api/health`: Health check endpoint

---

## REGLAS DE NEGOCIO ESPECÍFICAS

### Proyectos

#### Límite de Proyectos en DOING
```typescript
// ⚠️ CRÍTICO: Máximo 3 proyectos en estado DOING
const proyectosEnDoing = await prisma.proyecto.count({
  where: { estado: 'DOING' }
})

if (proyectosEnDoing >= 3 && nuevoEstado === 'DOING') {
  return NextResponse.json({
    success: false,
    error: 'Ya tienes 3 proyectos en curso. Completa o pausa uno antes de iniciar otro.'
  }, { status: 400 })
}
```

#### Estados Kanban (Proyectos)
- `FREEZER`: Congelado (no trabajar ahora)
- `BACKLOG`: En backlog (planificado)
- `WAITING`: Esperando dependencia externa
- `TODO`: Listo para empezar
- `DOING`: En progreso (máx 3)
- `DONE`: Completado

### Tareas

#### Estados Kanban (Tareas)
- Mismos 6 estados que proyectos
- NO hay límite de tareas en DOING (solo proyectos)

#### Relación Tarea-Proyecto
- Una tarea DEBE pertenecer a un proyecto (`proyectoId` required)
- Al eliminar proyecto: ¿eliminar tareas o dejarlas huérfanas? (definir)

---

## NOTAS PARA IA

### ⚠️ Prisma Schema es Source of Truth en automatizaciones/
- NO modificar `next-app/prisma/schema.prisma` directamente
- Modificar en `automatizaciones/prisma/schema.prisma`
- Ejecutar migrate en automatizaciones
- Copiar schema a next-app
- Ejecutar `npx prisma generate` en next-app

### ⚠️ Edge Runtime NO Soportado
- Next.js 15 permite `export const runtime = 'edge'`
- NO usarlo: Prisma requiere Node.js runtime
- Mantener runtime por defecto (Node.js)

### ⚠️ CORS
- Next.js API Routes tiene CORS deshabilitado por defecto (same-origin)
- Si se necesita CORS (ej: mobile app), agregar headers manualmente:
```typescript
return NextResponse.json(data, {
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE',
  }
})
```

### ⚠️ Body Parsing
- `request.json()` puede lanzar error si body no es JSON válido
- Wrap en try/catch o usar `request.text()` + JSON.parse con validación

---

## ARCHIVOS CLAVE

- Cada `route.ts` en subcarpetas de `api/`
- `src/lib/prisma.ts`: Cliente Prisma compartido
- `src/lib/logger.ts`: Logger Winston compartido

---

## PRÓXIMOS PASOS (Planificados)

- [ ] Implementar autenticación (JWT o sessions)
- [ ] Agregar rate limiting (express-rate-limit o similar)
- [ ] Implementar soft delete (marcar como eliminado sin borrar)
- [ ] Agregar auditoría (quién modificó qué, cuándo)
- [ ] Tests de integración (Playwright o Jest + Supertest)

---

## INTEGRACIÓN CON AUTOMATIZACIONES

### POST /api/proyectos-estrategicos/generar

**Propósito:** Endpoint que reenvía la creación de proyectos con IA al microservicio de automatizaciones.

**Flujo:**
```
Frontend (form)
  → POST /api/proyectos-estrategicos/generar
  → Reenvía a http://automatizaciones:1410/generar-proyecto
  → Automatizaciones procesa con IA
  → Retorna project ID
```

**Input (desde frontend):**
```typescript
{
  nombre: string,                    // Nombre del proyecto (usuario)
  descripcion: string,               // Descripción (usuario)
  areasIds: number[],                // Áreas seleccionadas (usuario)
  motivosIds: number[],              // Motivos seleccionados (usuario)
  nuevaAreaVida?: string,            // Nueva área si usuario escribió
  nuevoMotivoPersonal?: string,      // Nuevo motivo si usuario escribió
  ideaId?: number                    // ID de idea si se convierte
}
```

**⚠️ IMPORTANTE:**
- El endpoint REENVÍA todos los datos del formulario a automatizaciones
- NO procesa la IA en Next.js (delegado a automatizaciones)
- Los datos del usuario (nombre, áreas, motivos) tienen PRIORIDAD sobre IA
- Timeout: 60s (generación con IA puede tardar)

### Serialización de Decimals

**Problema:** Prisma devuelve campos `Decimal` como strings en JSON (`"8.5"` en lugar de `8.5`)

**Solución:** `serializeProyectoResponse()` en `[id]/route.ts`

**Campos afectados:**
- `prioridadGlobal`
- `scoreMotivacional`
- `scoreAlineacion`

**Implementación:**
```typescript
const serializeProyectoResponse = <T>(data: T): T => {
  const serialized = serializePrismaData(data)
  
  // Convertir strings a números
  decimalFields.forEach(field => {
    const value = serialized[field]
    if (value !== null && value !== undefined) {
      const numValue = parseFloat(String(value))
      serialized[field] = Number.isFinite(numValue) ? numValue : null
    }
  })
  
  return serialized
}
```

---

**Última actualización:** 2026-01-07
**Cambios:** Agregada generación con IA, serialización de Decimals, integración con automatizaciones
**Versión:** 1.1
