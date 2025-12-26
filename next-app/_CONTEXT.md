# _CONTEXT.md - Next App (Frontend + API)

## PROPÓSITO

Aplicación web principal del sistema Mateos. Implementa el frontend (Next.js con App Router) y los endpoints de API (Next.js API Routes). Interfaz de usuario para gestión de proyectos, tareas, ideas, y dashboard de métricas.

---

## STACK TÉCNICO ESPECÍFICO

- **Framework:** Next.js 15.5.0 (App Router, React Server Components)
- **React:** 19.2.1
- **UI Library:** HeroUI 2.8.5 (componentes basados en Heroicons)
- **Styling:** Tailwind CSS 3.3.6
- **Animaciones:** Framer Motion 12.23.25
- **Drag & Drop:** @dnd-kit (core, sortable, utilities) para Kanban
- **ORM:** Prisma 6.18.0 (cliente, schema sincronizado desde `automatizaciones/`)
- **Validación:** Zod 3.22.4
- **Logger:** Winston 3.11.0
- **Testing:** Playwright 1.57.0 (e2e)
- **TypeScript:** 5.7.0

---

## ARQUITECTURA Y PATRONES

### Estructura App Router

```
src/app/
├── api/                  [API Routes - Backend REST]
│   ├── areas-vida/
│   ├── dashboard/        [7 endpoints de métricas]
│   ├── proyectos/
│   ├── tareas-estrategicas/
│   └── (15 endpoints totales)
├── proyectos/           [Páginas UI]
│   ├── crear/
│   ├── dashboard/
│   ├── [id]/
│   └── page.tsx
├── tareas/
├── matarife/            [Herramienta de priorización]
├── layout.tsx           [Layout global con HeroUI]
└── page.tsx             [Home]
```

### React Server Components vs Client Components

**Regla por defecto:** Usar React Server Components (RSC)

**SOLO usar `'use client'` cuando necesitas:**
- Estado local (useState, useReducer)
- Event handlers (onClick, onChange)
- Hooks de navegación (useRouter, useSearchParams)
- Context providers
- Browser APIs

**Ejemplo:**
```tsx
// ✅ Server Component (por defecto)
async function ProyectosList() {
  const proyectos = await prisma.proyecto.findMany()
  return <ProyectoCard proyectos={proyectos} />
}

// ✅ Client Component (cuando necesita interactividad)
'use client'
function ProyectoFilter() {
  const [filter, setFilter] = useState('DOING')
  return <Select value={filter} onChange={setFilter} />
}
```

### Pattern API Routes

**Estructura estándar:**
```
api/[recurso]/
├── route.ts              # GET (lista), POST (crear)
└── [id]/
    └── route.ts          # GET, PATCH, DELETE (operaciones específicas)
```

**Formato de respuesta:**
```typescript
// ✅ Success
return NextResponse.json({
  success: true,
  data: resultado
}, { status: 200 })

// ❌ Error
return NextResponse.json({
  success: false,
  error: "Mensaje de error"
}, { status: 400 })
```

---

## REGLAS Y RESTRICCIONES

### API Routes

#### ✅ SIEMPRE:
- Validar input con Zod schemas antes de lógica
- Usar status codes correctos: 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found), 500 (Server Error)
- Retornar formato `{success, data?, error?}`
- Usar Prisma client desde `lib/prisma.ts` (singleton)
- Loggear errores 500 con Winston

#### ❌ NUNCA:
- Exponer stack traces en producción (validar NODE_ENV)
- Hacer queries directas sin Prisma
- Retornar HTML desde API routes
- Hardcodear valores (usar .env)

### Frontend (Componentes)

#### ✅ SIEMPRE:
- Usar HeroUI components cuando sea posible (Button, Select, Modal, etc.)
- Validar props con TypeScript
- Usar Tailwind classes, NO CSS modules
- Componentes reutilizables en `src/components/`
- Dark mode support (HeroUI ThemeProvider maneja automáticamente)

#### ❌ NUNCA:
- Usar `any` en TypeScript (preferir `unknown` o tipos específicos)
- Fetch directo a API externa desde componente (usar `/api` routes como proxy)
- Hardcodear colores (usar Tailwind theme)

### Drag & Drop (Kanban)

- **Library:** @dnd-kit (NO react-beautiful-dnd, deprecado)
- **Pattern:** Ver `KanbanTaskView.tsx` (14KB, referencia completa)
- **Estados Kanban:** 6 estados (freezer, backlog, waiting, todo, doing, done)
- **Límite DOING:** Máximo 3 proyectos (validar en backend)

---

## CONVENCIONES DE CÓDIGO

### Naming
- **Componentes:** PascalCase (`ProyectoCard.tsx`)
- **API Routes:** kebab-case (`areas-vida/route.ts`)
- **Funciones:** camelCase (`getUserProjects()`)
- **Tipos:** PascalCase con prefijo `T` (`TProyecto`)

### Imports
```typescript
// Orden de imports:
// 1. React/Next
import { useState } from 'react'
import { NextResponse } from 'next/server'

// 2. Librerías externas
import { Button } from '@heroui/react'
import { z } from 'zod'

// 3. Internos (lib, types, components)
import { prisma } from '@/lib/prisma'
import { TProyecto } from '@/types'
import { ProyectoCard } from '@/components/ProyectoCard'
```

### Error Handling
```typescript
// API Routes
try {
  // lógica
} catch (error) {
  logger.error('Error en [endpoint]:', error)
  return NextResponse.json({
    success: false,
    error: 'Mensaje genérico para usuario'
  }, { status: 500 })
}
```

---

## INTEGRACIONES EXTERNAS

### Automatizaciones (Microservicio IA)
- **Endpoint:** `http://automatizaciones:3002/webhook` (Docker network)
- **Cliente:** `lib/automatizaciones-webhook.ts`
- **Uso:** Notificar eventos para procesamiento IA (nueva idea capturada, proyecto creado)

### Cloudflare R2 (S3-compatible storage)
- **Cliente:** `lib/r2-client.ts`
- **Uso:** Almacenar audios de notas de voz
- **Bucket:** Configurado en `.env` (`R2_BUCKET_NAME`)
- **Rate limit:** 100 req/min (Cloudflare free tier)

### OpenAI (Whisper)
- **Cliente:** `lib/whisper-client.ts`
- **Modelo:** whisper-1
- **Uso:** Transcripción de notas de voz
- **Max file size:** 25MB
- **⚠️ Gotcha:** Whisper retorna "undefined" si audio < 0.1s, validar duración ANTES

---

## CONFIGURACIÓN

### Variables de Entorno (.env)

```bash
# Base de datos (Prisma)
DATABASE_URL="postgresql://..."

# OpenAI
OPENAI_API_KEY="sk-..."

# Cloudflare R2
R2_ACCOUNT_ID="..."
R2_ACCESS_KEY_ID="..."
R2_SECRET_ACCESS_KEY="..."
R2_BUCKET_NAME="..."

# Automatizaciones
AUTOMATIZACIONES_WEBHOOK_URL="http://automatizaciones:3002/webhook"

# Next.js
NEXT_PUBLIC_API_URL="http://localhost:3000"  # Solo para client components
```

### Prisma Schema

- **⚠️ SOURCE OF TRUTH:** `automatizaciones/prisma/schema.prisma`
- **⚠️ Este schema es SINCRONIZADO**, NO modificar directamente
- **Proceso:** Modificar en `automatizaciones/`, ejecutar migrate, copiar a `next-app/`
- **Generate:** `npx prisma generate` (regenerar cliente tras cambios)

---

## NOTAS PARA IA

### ⚠️ Prisma Client
- SIEMPRE importar desde `lib/prisma.ts` (singleton)
- NO crear instancia nueva con `new PrismaClient()`
- Ejecutar `npx prisma generate` tras cambios en schema

### ⚠️ HeroUI Dark Mode
- ThemeProvider configurado en `layout.tsx`
- Componentes HeroUI detectan tema automáticamente
- Para custom components: usar `useTheme()` hook
- Tailwind: usar `dark:` prefix (ej: `dark:bg-gray-800`)

### ⚠️ App Router Caching
- Next.js 15 cachea agresivamente (ISR + Data Cache)
- Para datos dinámicos: usar `export const dynamic = 'force-dynamic'` en route
- Para revalidar: `revalidatePath('/path')` o `revalidateTag('tag')`

### ⚠️ Kanban Drag & Drop
- Ver `KanbanTaskView.tsx` como referencia completa
- @dnd-kit requiere `'use client'`
- Manejar colisiones con `closestCenter` strategy
- Actualizar estado local PRIMERO, luego API call (optimistic update)

### ⚠️ Límite de 3 Proyectos en DOING
- Validar en backend (API route) antes de mover proyecto
- Retornar error 400 con mensaje claro
- Frontend debe mostrar toast/alert
- Regla de negocio para optimización TDAH

---

## ARCHIVOS CLAVE

- `src/app/layout.tsx`: Layout global, HeroUI ThemeProvider, metadata
- `src/lib/prisma.ts`: Cliente Prisma singleton
- `src/lib/logger.ts`: Configuración Winston logger
- `src/components/KanbanTaskView.tsx`: Implementación completa de Kanban drag & drop
- `src/components/ProyectoCard.tsx`: Card de proyecto con badges de estado
- `prisma/schema.prisma`: Schema Prisma (sincronizado desde automatizaciones/)

---

## TESTING

### Playwright (e2e)
- **Ubicación:** `e2e/`
- **Ejecutar:** `npm run test:e2e`
- **Config:** `playwright.config.ts`
- **Browser:** Chromium (headless por defecto)

### Estrategia
- Tests e2e para flujos críticos (crear proyecto, mover tarea en Kanban)
- NO tests unitarios de componentes (preferir e2e)
- Mock de APIs externas (OpenAI, R2) en tests

---

## DEPENDENCIAS CRÍTICAS

### Depende de:
- **PostgreSQL:** Base de datos (Docker container)
- **Automatizaciones:** Procesamiento IA (opcional, el frontend funciona sin él)

### Debe ejecutarse después de:
- PostgreSQL (docker-compose depends_on)
- Prisma generate (build step)

---

**Última actualización:** 2025-12-26
**Versión:** 1.0
