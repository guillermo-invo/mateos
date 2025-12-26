# _CONTEXT.md - Components

## PROPÓSITO

Componentes React reutilizables del frontend de Mateos. Incluye componentes de UI, layout, y lógica de presentación.

---

## STACK TÉCNICO ESPECÍFICO

- **React:** 19.2.1 (Server Components + Client Components)
- **UI Library:** HeroUI 2.8.5
- **Styling:** Tailwind CSS 3.3.6
- **Animaciones:** Framer Motion 12.23.25
- **Drag & Drop:** @dnd-kit (core, sortable, utilities)
- **TypeScript:** 5.7.0

---

## ARQUITECTURA Y PATRONES

### Organización de Componentes

```
src/components/
├── ProyectoCard.tsx          [Card de proyecto con badges]
├── KanbanTaskView.tsx        [Vista Kanban drag & drop - 14KB]
├── dashboard/                [Componentes específicos de dashboard]
│   └── (widgets de métricas)
└── layout/                   [Componentes de layout]
    └── (header, sidebar, etc.)
```

### Server Components vs Client Components

**Regla por defecto:** Componentes son Server Components (más rápidos, menos JS al cliente)

**Usar `'use client'` SOLO cuando necesitas:**
- Estado local (useState, useReducer)
- Effects (useEffect, useLayoutEffect)
- Event handlers (onClick, onChange, onSubmit)
- Hooks de navegación (useRouter, usePathname, useSearchParams)
- Context (useContext, Context.Provider)
- Browser APIs (localStorage, window, document)
- Drag & Drop (@dnd-kit hooks)

**Ejemplo:**
```tsx
// ✅ Server Component (por defecto, no necesita 'use client')
import { prisma } from '@/lib/prisma'

async function ProyectosList() {
  const proyectos = await prisma.proyecto.findMany()
  return (
    <div>
      {proyectos.map(p => <ProyectoCard key={p.id} proyecto={p} />)}
    </div>
  )
}

// ✅ Client Component (necesita estado)
'use client'

import { useState } from 'react'
import { Select } from '@heroui/react'

function ProyectoFilter() {
  const [filter, setFilter] = useState('DOING')
  return <Select value={filter} onChange={setFilter}>...</Select>
}
```

### Composition Pattern

Preferir composición sobre configuración:

```tsx
// ✅ BIEN (composición)
<Card>
  <CardHeader>
    <h2>{title}</h2>
  </CardHeader>
  <CardBody>
    {content}
  </CardBody>
</Card>

// ❌ MAL (configuración excesiva)
<Card
  title={title}
  content={content}
  headerClassName="..."
  bodyClassName="..."
  showBorder={true}
/>
```

---

## REGLAS Y RESTRICCIONES

### Props y TypeScript

#### ✅ SIEMPRE:
- Definir tipos de props explícitamente (NO usar `any`)
- Usar interfaces para props de componentes
- Exportar tipos si otros componentes los necesitan
- Marcar props opcionales con `?`

```typescript
interface ProyectoCardProps {
  proyecto: TProyecto
  onClick?: (id: string) => void
  showActions?: boolean
}

export function ProyectoCard({ proyecto, onClick, showActions = true }: ProyectoCardProps) {
  // ...
}
```

#### ❌ NUNCA:
- Usar `any` para props
- Pasar objetos enteros cuando solo necesitas 2-3 campos (destructura)
- Mutar props (son inmutables)

### HeroUI vs Custom Components

#### ✅ SIEMPRE usar HeroUI cuando existe el componente:
- `Button`, `Input`, `Select`, `Modal`, `Dropdown`, `Card`, `Badge`, `Chip`
- `Table`, `Pagination`, `Tabs`, `Accordion`
- Theme provider maneja dark mode automáticamente

#### ❌ SOLO crear custom component si:
- HeroUI no tiene equivalente
- Necesitas lógica de negocio específica
- HeroUI component no cubre el caso de uso

```tsx
// ✅ BIEN (usar HeroUI)
import { Button } from '@heroui/react'

function MyComponent() {
  return <Button color="primary">Click me</Button>
}

// ❌ MAL (reinventar la rueda)
function CustomButton({ children }: { children: React.ReactNode }) {
  return <button className="bg-blue-500 text-white px-4 py-2">{children}</button>
}
```

### Styling con Tailwind

#### ✅ SIEMPRE:
- Usar Tailwind utility classes
- Usar `dark:` prefix para dark mode
- Usar theme colors de Tailwind (no hardcodear hex)
- Responsive: `sm:`, `md:`, `lg:`, `xl:` prefixes

#### ❌ NUNCA:
- CSS modules (usar Tailwind)
- Inline styles (preferir Tailwind classes)
- Hardcodear colores (`#FF0000` → usar `text-red-500`)

```tsx
// ✅ BIEN
<div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow-md">
  <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
    {title}
  </h2>
</div>

// ❌ MAL
<div style={{ background: '#FFFFFF', padding: '16px' }}>
  <h2 style={{ fontSize: '24px', fontWeight: 'bold' }}>
    {title}
  </h2>
</div>
```

### Animaciones con Framer Motion

#### Usar para:
- Transiciones de entrada/salida
- Animaciones de lista (stagger)
- Gestos (drag, swipe)

```tsx
import { motion } from 'framer-motion'

<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: -20 }}
  transition={{ duration: 0.3 }}
>
  {content}
</motion.div>
```

#### ⚠️ NO abusar:
- Animaciones sutiles (evitar mareos)
- Duración corta (< 500ms)
- NO animar todo (solo lo que aporta UX)

---

## COMPONENTES CLAVE

### ProyectoCard.tsx

Card de proyecto con:
- Badge de estado (color según estado Kanban)
- Título y descripción
- Área de vida asociada
- Fecha de creación

**Props:**
```typescript
interface ProyectoCardProps {
  proyecto: TProyecto
  onClick?: (id: string) => void
}
```

**Estados con colores:**
- FREEZER: `bg-blue-100 text-blue-800` (dark: `bg-blue-900 text-blue-200`)
- BACKLOG: `bg-gray-100 text-gray-800`
- WAITING: `bg-yellow-100 text-yellow-800`
- TODO: `bg-purple-100 text-purple-800`
- DOING: `bg-green-100 text-green-800`
- DONE: `bg-gray-400 text-gray-900`

### KanbanTaskView.tsx (14KB)

Vista Kanban con drag & drop para tareas.

**Características:**
- 6 columnas (freezer, backlog, waiting, todo, doing, done)
- Drag & drop con @dnd-kit
- Actualización optimista (UI primero, API después)
- Indicador visual de límite de 3 proyectos en DOING

**Props:**
```typescript
interface KanbanTaskViewProps {
  tareas: TTarea[]
  onTaskMove: (tareaId: string, nuevoEstado: EstadoKanban) => Promise<void>
}
```

**⚠️ Gotcha:**
- Component DEBE ser client component (`'use client'`)
- Usar `closestCenter` collision detection
- Manejar error de límite de DOING (mostrar toast)

**Referencia completa:** Ver archivo para implementación de @dnd-kit

---

## NOTAS PARA IA

### ⚠️ Dark Mode
- HeroUI ThemeProvider configurado en `app/layout.tsx`
- Componentes HeroUI detectan tema automáticamente
- Para custom components: usar `useTheme()` de `next-themes`
- Tailwind: siempre agregar variante `dark:` para backgrounds y textos

```tsx
import { useTheme } from 'next-themes'

function CustomComponent() {
  const { theme } = useTheme() // 'light' | 'dark' | 'system'

  return (
    <div className="bg-white dark:bg-gray-900">
      {/* Content */}
    </div>
  )
}
```

### ⚠️ Client Components Boundary
- Server Components pueden renderizar Client Components
- Client Components NO pueden renderizar Server Components directamente
- Patrón: Pasar Server Component como children a Client Component

```tsx
// ✅ BIEN
// app/page.tsx (Server Component)
import ClientWrapper from '@/components/ClientWrapper'
import ServerChild from '@/components/ServerChild'

export default function Page() {
  return (
    <ClientWrapper>
      <ServerChild /> {/* Pasado como children */}
    </ClientWrapper>
  )
}

// components/ClientWrapper.tsx
'use client'
export default function ClientWrapper({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState(false)
  return <div>{children}</div>
}
```

### ⚠️ Drag & Drop Performance
- Limitar cantidad de items en Kanban (< 100 por columna)
- Usar `React.memo()` para cards si hay lag
- Virtualizar listas largas con `react-window` si necesario

---

## TESTING

### Estrategia
- Tests e2e con Playwright para flujos completos
- NO tests unitarios de componentes (preferir integración)
- Snapshots visuales (Playwright) para detectar regresiones UI

### Casos críticos:
- Drag & drop en Kanban funciona
- Filtros de proyectos actualizan correctamente
- Dark mode toggle funciona
- Responsive en mobile

---

**Última actualización:** 2025-12-26
**Versión:** 1.0
