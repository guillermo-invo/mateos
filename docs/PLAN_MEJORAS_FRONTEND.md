# Plan de Mejoras Frontend - Sistema MATEOS

## 📋 Índice
1. [Configuración General](#1-configuración-general)
2. [Página: Crear Proyecto](#2-página-crear-proyecto)
3. [Página: Dashboard de Proyectos](#3-página-dashboard-de-proyectos)
4. [Página: Ideas de Proyecto](#4-página-ideas-de-proyecto)
5. [Página: Dashboard de Tareas (Sprint)](#5-página-dashboard-de-tareas-sprint)
6. [Orden de Implementación](#6-orden-de-implementación)

---

## 1. Configuración General

### 1.1 Sistema de Diseño Hero UI

**Objetivo**: Estandarizar todos los componentes usando Hero UI

**Paleta de Colores**:
```css
--primary: #4682b4      /* Azul Steel */
--success: #68bb7b      /* Verde */
--warning: #ffa500      /* Naranja */
--neutral: #696969      /* Gris */
--accent: #fceab0       /* Beige claro */
--white: #ffffff        /* Blanco */
--dark: #1e1f21         /* Negro carbón */
```

**Principios de Diseño**:
- ✅ Moderno, claro y sobrio
- ✅ Colores solo para destacar elementos importantes
- ✅ Enfoque en usabilidad y funcionalidad sobre estética
- ✅ Espacios blancos generosos
- ✅ Tipografía clara y legible

**Archivos a Modificar**:
- [ ] `/next-app/tailwind.config.js` - Agregar colores custom
- [ ] `/next-app/src/app/globals.css` - Configurar tema dark/light
- [ ] `/next-app/src/app/layout.tsx` - Configurar HeroUIProvider con tema

**Configuración Tailwind**:
```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'class',
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "./node_modules/@heroui/theme/dist/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        primary: '#4682b4',
        success: '#68bb7b',
        warning: '#ffa500',
        neutral: '#696969',
        accent: '#fceab0',
        dark: '#1e1f21',
      }
    }
  },
  plugins: [heroui({
    themes: {
      light: {
        colors: {
          primary: '#4682b4',
          success: '#68bb7b',
          warning: '#ffa500',
        }
      },
      dark: {
        colors: {
          primary: '#4682b4',
          success: '#68bb7b',
          warning: '#ffa500',
          background: '#1e1f21',
          foreground: '#ffffff',
        }
      }
    }
  })]
}
```

---

## 2. Página: Crear Proyecto

**URL Actual**: `/proyectos/crear`
**Estado**: Requiere mejoras

### 2.1 Cambios Requeridos

#### A. Selector de Ideas
**Problema**: No aparecen ideas de proyecto
**Solución**:
- [ ] Crear API: `GET /api/ideas/disponibles`
  - Filtrar ideas con `implementada = false`
  - Retornar: id, titulo, descripcion, categoria
- [ ] Componente: Dropdown/Select con Hero UI
  - Si se selecciona idea, prellenar descripción
  - Agregar opción "Nueva idea (sin plantilla)"

**Código API**:
```typescript
// /api/ideas/disponibles/route.ts
export async function GET() {
  const ideas = await prisma.ideaCapturada.findMany({
    where: { implementada: false },
    select: {
      id: true,
      titulo: true,
      descripcion: true,
      categoria: true,
    },
    orderBy: { createdAt: 'desc' }
  });
  return NextResponse.json({ success: true, data: ideas });
}
```

**Componente Hero UI**:
```tsx
<Select
  label="Seleccionar idea de proyecto"
  placeholder="Nueva idea (sin plantilla)"
  onChange={(e) => handleIdeaSelect(e.target.value)}
>
  {ideas.map(idea => (
    <SelectItem key={idea.id} value={idea.id}>
      {idea.titulo}
    </SelectItem>
  ))}
</Select>
```

#### B. Eliminar Checkbox "Generar con IA"
- [ ] Remover del formulario
- [ ] Siempre generar con IA automáticamente

#### C. Cambiar Estado del Proyecto
- [ ] Al crear, establecer `estado = 'planificacion'` (no 'idea')
- [ ] Modificar API POST para actualizar estado

#### D. Campos de Selección

**Áreas de Vida**:
- [ ] Cambiar de Checkbox múltiple → Radio buttons (elección única)
- [ ] Componente: `<RadioGroup>` de Hero UI

**Motivos Personales**:
- [ ] Mantener Checkbox múltiple
- [ ] Componente: `<CheckboxGroup>` de Hero UI

**Código Hero UI**:
```tsx
{/* Áreas de Vida - Elección ÚNICA */}
<RadioGroup
  label="Área de Vida"
  value={selectedArea}
  onValueChange={setSelectedArea}
>
  {areas.map(area => (
    <Radio key={area.id} value={area.id.toString()}>
      {area.nombre}
    </Radio>
  ))}
</RadioGroup>

{/* Motivos Personales - Múltiple */}
<CheckboxGroup
  label="Motivos Personales"
  value={selectedMotivos}
  onValueChange={setSelectedMotivos}
>
  {motivos.map(motivo => (
    <Checkbox key={motivo.id} value={motivo.id.toString()}>
      {motivo.nombre}
    </Checkbox>
  ))}
</CheckboxGroup>
```

### 2.2 Archivos a Crear/Modificar

- [ ] `GET /api/ideas/disponibles/route.ts` - Nuevo
- [ ] `POST /api/proyectos/route.ts` - Modificar para estado='planificacion'
- [ ] `/src/app/proyectos/crear/page.tsx` - Refactorizar completamente
- [ ] `/src/components/ProyectoForm.tsx` - Nuevo componente

---

## 3. Página: Dashboard de Proyectos

**URL Actual**: `/proyectos`
**URL Esperada**: `/proyectos` (dashboard principal)
**Estado**: Nueva funcionalidad

### 3.1 Diseño y Funcionalidad

**Layout**: Similar al dashboard de subtareas, pero con proyectos

**Estructura**:
```
Áreas de Vida (Acordeón)
  └─ Proyectos (Cards)
      ├─ Nombre del proyecto
      ├─ Estado: Badge (idea, planificacion, en_curso, etc)
      ├─ Progreso: Barra de progreso (%)
      ├─ Tiempo restante: "15.5h / 40h totales"
      └─ Acciones: Ver, Editar
```

### 3.2 Cálculo de Tiempos

**Fórmula**:
```typescript
// Total horas del proyecto
const totalHoras = proyecto.tareasEstrategicas
  .flatMap(t => t.subtareasEstrategicas)
  .reduce((sum, sub) => sum + (sub.tiempoEstimadoMinutos || 0), 0) / 60;

// Horas completadas
const horasCompletadas = proyecto.tareasEstrategicas
  .flatMap(t => t.subtareasEstrategicas)
  .filter(sub => sub.estadoKanban === 'done')
  .reduce((sum, sub) => sum + (sub.tiempoEstimadoMinutos || 0), 0) / 60;

// Horas restantes
const horasRestantes = totalHoras - horasCompletadas;

// Progreso
const progreso = totalHoras > 0 ? (horasCompletadas / totalHoras) * 100 : 0;
```

### 3.3 Filtros de Estado

- [ ] Mostrar TODOS los proyectos
- [ ] Indicar estado con Badge de color
  - `idea` → Gris neutral
  - `planificacion` → Azul primary
  - `en_curso` → Verde success
  - `pausado` → Naranja warning
  - `completado` → Verde con check
  - `cancelado` → Rojo
  - `archivado` → Gris claro

### 3.4 Botones de Acción

- [ ] Botón principal: "+ Crear Proyecto" → `/proyectos/crear`
- [ ] Botón secundario: "💡 Ideas" → `/proyectos/ideas`

**Hero UI Buttons**:
```tsx
<div className="flex gap-4 mb-6">
  <Button
    color="primary"
    size="lg"
    startContent={<PlusIcon />}
    as={Link}
    href="/proyectos/crear"
  >
    Crear Proyecto
  </Button>

  <Button
    color="default"
    variant="bordered"
    startContent={<LightbulbIcon />}
    as={Link}
    href="/proyectos/ideas"
  >
    Ideas
  </Button>
</div>
```

### 3.5 API Endpoint

- [ ] Crear: `GET /api/proyectos/dashboard/route.ts`

**Respuesta esperada**:
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "title": "Profesional",
      "projects": [
        {
          "id": "10",
          "title": "Mimochi 2026",
          "estado": "planificacion",
          "progress": 45,
          "horasCompletadas": 18,
          "horasTotal": 40,
          "horasRestantes": 22
        }
      ]
    }
  ]
}
```

### 3.6 Archivos a Crear

- [ ] `GET /api/proyectos/dashboard/route.ts` - Nuevo
- [ ] `/src/app/proyectos/page.tsx` - Refactorizar
- [ ] `/src/components/ProyectoDashboard.tsx` - Nuevo
- [ ] `/src/components/ProyectoCard.tsx` - Nuevo

---

## 4. Página: Ideas de Proyecto

**URL**: `/proyectos/ideas` (nueva página)
**Estado**: Nueva funcionalidad

### 4.1 Concepto

**Propósito**: Capturar y desarrollar ideas de proyectos antes de crearlos formalmente

**Workflow**:
1. Usuario tiene idea → La guarda aquí
2. Va agregando información conforme la idea madura
3. Cuando está lista → La convierte en Proyecto formal

### 4.2 Funcionalidad

#### A. Selector/Creador de Idea

**Componente Hero UI**:
```tsx
<div className="flex gap-4 items-end mb-6">
  {/* Desplegable para cargar idea existente */}
  <Select
    label="Cargar idea existente"
    placeholder="Seleccionar..."
    className="flex-1"
    onChange={handleLoadIdea}
  >
    {ideas.map(idea => (
      <SelectItem key={idea.id} value={idea.id}>
        {idea.titulo}
      </SelectItem>
    ))}
  </Select>

  {/* Botón crear nueva */}
  <Button
    color="primary"
    onPress={handleNuevaIdea}
  >
    + Nueva Idea
  </Button>
</div>
```

#### B. Formulario de Idea

**Campos**:
- [ ] Título (requerido)
- [ ] Descripción (textarea largo, multi-párrafo)
- [ ] Categoría (opcional)
- [ ] Área de Vida (Radio - elección única)
- [ ] Motivos Personales (Checkbox - múltiple)

**Diferencias con Crear Proyecto**:
- ❌ NO hay checkbox "Generar con IA"
- ❌ NO hay botón "Crear Proyecto"
- ✅ SÍ hay botón "Guardar Idea"
- ✅ Puede guardarse múltiples veces (va actualizando)

#### C. Botón de Acción

```tsx
<div className="flex gap-4 justify-end">
  <Button
    color="primary"
    size="lg"
    onPress={handleGuardarIdea}
  >
    Guardar Idea
  </Button>

  {/* Si hay idea cargada */}
  {ideaId && (
    <Button
      color="success"
      variant="bordered"
      as={Link}
      href={`/proyectos/crear?ideaId=${ideaId}`}
    >
      Convertir en Proyecto
    </Button>
  )}
</div>
```

### 4.3 API Endpoints

- [ ] `GET /api/ideas/route.ts` - Listar todas las ideas
- [ ] `POST /api/ideas/route.ts` - Crear nueva idea
- [ ] `PUT /api/ideas/[id]/route.ts` - Actualizar idea existente

### 4.4 Archivos a Crear

- [ ] `GET /api/ideas/route.ts` - Listar ideas
- [ ] `POST /api/ideas/route.ts` - Crear idea
- [ ] `PUT /api/ideas/[id]/route.ts` - Actualizar idea
- [ ] `/src/app/proyectos/ideas/page.tsx` - Nueva página
- [ ] `/src/components/IdeaForm.tsx` - Nuevo componente

---

## 5. Página: Dashboard de Tareas (Sprint)

**URL Actual**: `/dashboard`
**URL Nueva**: `/proyectos/dashboard`
**Estado**: Mejorar existente

### 5.1 Cambios Requeridos

#### A. Mover la Ruta
- [ ] Mover `/src/app/dashboard/page.tsx` → `/src/app/proyectos/dashboard/page.tsx`
- [ ] Actualizar links en navegación

#### B. Acordeones Abiertos por Defecto

**Cambio en KanbanTaskView.tsx**:
```tsx
<Accordion
  variant="splitted"
  defaultExpandedKeys="all"  // ← Todos abiertos
  selectionMode="multiple"    // ← Permite múltiples abiertos
>
```

#### C. Drag & Drop para Cambiar Estado

**Librería**: `@dnd-kit/core`

**Instalación**:
```bash
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
```

**Funcionalidad**:
- [ ] Arrastrar subtarea entre columnas (waiting → todo → doing → done)
- [ ] Al soltar, actualizar `estado_kanban` en BD
- [ ] Actualizar `fecha_done` si se mueve a 'done'

**API Endpoint**:
- [ ] `PATCH /api/subtareas/[id]/estado/route.ts`

**Código básico**:
```tsx
import { DndContext, DragEndEvent } from '@dnd-kit/core';

function KanbanTaskView({ data }: Props) {
  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;

    if (!over) return;

    const subtareaId = active.id;
    const nuevoEstado = over.id; // 'waiting', 'todo', 'doing', 'done'

    // Actualizar en BD
    await fetch(`/api/subtareas/${subtareaId}/estado`, {
      method: 'PATCH',
      body: JSON.stringify({ estado: nuevoEstado })
    });

    // Refrescar datos
    mutate();
  };

  return (
    <DndContext onDragEnd={handleDragEnd}>
      {/* Contenido del Kanban */}
    </DndContext>
  );
}
```

#### D. Mejorar Dark Mode

**Problema**: Texto claro sobre fondo claro

**Solución**:
```tsx
{/* Títulos de áreas y proyectos */}
<span className="font-bold text-lg text-gray-900 dark:text-white">
  {area.title}
</span>

<span className="font-semibold text-gray-700 dark:text-gray-200">
  {project.title}
</span>

{/* Cards de subtareas */}
<Card className="bg-white dark:bg-gray-800">
  <CardBody>
    <p className="text-gray-800 dark:text-gray-100">
      {subtask.title}
    </p>
  </CardBody>
</Card>

{/* Columnas Kanban */}
<div className="bg-gray-100 dark:bg-gray-700">
  {/* Contenido */}
</div>
```

### 5.2 Archivos a Modificar

- [ ] Mover `/src/app/dashboard/` → `/src/app/proyectos/dashboard/`
- [ ] `/src/components/KanbanTaskView.tsx` - Agregar DnD y dark mode
- [ ] `POST /api/subtareas/[id]/estado/route.ts` - Nuevo endpoint

---

## 6. Orden de Implementación

### Fase 1: Configuración Base (2-3 horas)
1. ✅ Configurar paleta de colores en Tailwind
2. ✅ Configurar tema dark/light en Hero UI
3. ✅ Crear componentes base reutilizables

### Fase 2: Proyectos (5-6 horas)
1. ✅ API: GET /api/ideas/disponibles
2. ✅ Página: /proyectos/crear (refactorizar)
3. ✅ API: GET /api/proyectos/dashboard
4. ✅ Página: /proyectos (dashboard principal)

### Fase 3: Ideas (3-4 horas)
1. ✅ API: CRUD de ideas
2. ✅ Página: /proyectos/ideas
3. ✅ Integración con /proyectos/crear

### Fase 4: Dashboard Sprint (4-5 horas)
1. ✅ Mover ruta a /proyectos/dashboard
2. ✅ Acordeones abiertos por defecto
3. ✅ Mejorar dark mode
4. ✅ Implementar drag & drop
5. ✅ API: PATCH estado de subtareas

### Fase 5: Testing y Pulido (2-3 horas)
1. ✅ Probar flujos completos
2. ✅ Ajustar responsive design
3. ✅ Optimizar rendimiento
4. ✅ Documentación de usuario

**Total Estimado**: 16-21 horas

---

## 7. Checklist de Implementación

### General
- [ ] Configurar colores custom en Tailwind
- [ ] Configurar tema Hero UI (dark/light)
- [ ] Crear componentes base reutilizables
- [ ] Actualizar navegación/menú

### /proyectos/crear
- [ ] API: GET /api/ideas/disponibles
- [ ] Dropdown de ideas con Hero UI Select
- [ ] Prellenar descripción si se selecciona idea
- [ ] Eliminar checkbox "Generar con IA"
- [ ] Cambiar estado a 'planificacion' al crear
- [ ] Radio buttons para Áreas de Vida
- [ ] Checkbox group para Motivos Personales

### /proyectos (Dashboard)
- [ ] API: GET /api/proyectos/dashboard
- [ ] Componente ProyectoDashboard
- [ ] Componente ProyectoCard
- [ ] Cálculo de tiempos (total, completado, restante)
- [ ] Badges de estado
- [ ] Botones: Crear Proyecto, Ideas
- [ ] Responsive design

### /proyectos/ideas
- [ ] API: GET /api/ideas
- [ ] API: POST /api/ideas
- [ ] API: PUT /api/ideas/[id]
- [ ] Página /proyectos/ideas
- [ ] Componente IdeaForm
- [ ] Selector cargar idea existente
- [ ] Botón crear nueva idea
- [ ] Botón guardar idea
- [ ] Botón convertir en proyecto

### /proyectos/dashboard (Sprint)
- [ ] Mover de /dashboard a /proyectos/dashboard
- [ ] Acordeones abiertos por defecto
- [ ] Selección múltiple de acordeones
- [ ] Mejorar dark mode (texto claro sobre claro)
- [ ] Instalar @dnd-kit
- [ ] Implementar drag & drop
- [ ] API: PATCH /api/subtareas/[id]/estado
- [ ] Actualizar fecha_done al mover a 'done'

---

## 8. Notas Técnicas

### Hero UI Components a Usar

```typescript
// Formularios
import { Input, Textarea, Select, SelectItem } from "@heroui/react";
import { Radio, RadioGroup } from "@heroui/react";
import { Checkbox, CheckboxGroup } from "@heroui/react";

// Layout
import { Card, CardBody, CardHeader } from "@heroui/react";
import { Accordion, AccordionItem } from "@heroui/react";

// Navegación
import { Button, Link } from "@heroui/react";
import { Chip } from "@heroui/react";

// Feedback
import { Progress } from "@heroui/react";
import { Spinner } from "@heroui/react";
```

### Paleta de Colores - Uso Recomendado

```typescript
// Colores por propósito
primary (#4682b4)   → Botones principales, links, progreso
success (#68bb7b)   → Estados completados, confirmaciones
warning (#ffa500)   → Alertas, estados pausados
neutral (#696969)   → Texto secundario, bordes
accent (#fceab0)    → Destacados sutiles, badges
dark (#1e1f21)      → Fondo modo oscuro
```

### Dark Mode - Clases Tailwind

```css
/* Fondos */
bg-white dark:bg-gray-800
bg-gray-50 dark:bg-gray-900
bg-gray-100 dark:bg-gray-700

/* Texto */
text-gray-900 dark:text-white
text-gray-700 dark:text-gray-200
text-gray-600 dark:text-gray-300

/* Bordes */
border-gray-200 dark:border-gray-700
```

---

## 9. Mockups de Referencia

### /proyectos/crear
```
┌────────────────────────────────────────────┐
│  Crear Proyecto                            │
├────────────────────────────────────────────┤
│  [Dropdown: Seleccionar idea ▼]  [Crear]  │
│                                            │
│  Nombre del Proyecto                       │
│  [________________________]                │
│                                            │
│  Descripción                               │
│  [________________________]                │
│  [________________________]                │
│  [________________________]                │
│                                            │
│  Área de Vida (selección única)           │
│  ○ Profesional                            │
│  ○ Personal                               │
│  ○ Salud                                  │
│                                            │
│  Motivos Personales (múltiple)            │
│  ☑ Impacto Social                         │
│  ☐ Crecimiento Personal                   │
│  ☑ Desafío Intelectual                    │
│                                            │
│            [Crear Proyecto]                │
└────────────────────────────────────────────┘
```

### /proyectos (Dashboard)
```
┌────────────────────────────────────────────┐
│  Proyectos        [+ Crear] [💡 Ideas]    │
├────────────────────────────────────────────┤
│  ▼ Profesional                             │
│  ┌──────────────────────────────────────┐ │
│  │ Mimochi 2026        [Planificación]  │ │
│  │ ████████░░ 45%                       │ │
│  │ 18h / 40h (22h restantes)            │ │
│  └──────────────────────────────────────┘ │
│  ┌──────────────────────────────────────┐ │
│  │ App Gestión         [En Curso]       │ │
│  │ ███████████ 70%                      │ │
│  │ 35h / 50h (15h restantes)            │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ▼ Personal                                │
│  ┌──────────────────────────────────────┐ │
│  │ Fitness 2025        [Idea]           │ │
│  │ ░░░░░░░░░░ 0%                        │ │
│  │ 0h / 30h (30h restantes)             │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

### /proyectos/ideas
```
┌────────────────────────────────────────────┐
│  Ideas de Proyecto                         │
├────────────────────────────────────────────┤
│  [Dropdown: Cargar idea ▼]  [+ Nueva]     │
│                                            │
│  Título                                    │
│  [________________________]                │
│                                            │
│  Descripción                               │
│  [________________________]                │
│  [________________________]                │
│  [________________________]                │
│  [________________________]                │
│                                            │
│  Categoría (opcional)                      │
│  [________________________]                │
│                                            │
│  Área de Vida                              │
│  ○ Profesional                            │
│  ○ Personal                               │
│                                            │
│  Motivos Personales                        │
│  ☑ Impacto Social                         │
│  ☐ Aprendizaje                            │
│                                            │
│  [Guardar Idea]  [Convertir en Proyecto]  │
└────────────────────────────────────────────┘
```

---

## 10. Comandos Útiles

```bash
# Instalar dependencias
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities

# Regenerar Prisma Client después de cambios
npx prisma generate

# Build y deploy
docker compose up -d --build next-app

# Ver logs
docker logs transcripcion-api --tail 50 -f

# Probar endpoints
curl https://mateos.involucrate.lat/api/ideas/disponibles
curl https://mateos.involucrate.lat/api/proyectos/dashboard
```

---

## 11. Referencias

- [Hero UI Docs](https://www.heroui.com/)
- [DnD Kit Docs](https://docs.dndkit.com/)
- [Tailwind Dark Mode](https://tailwindcss.com/docs/dark-mode)
- [Next.js Routing](https://nextjs.org/docs/app/building-your-application/routing)

---

**Fecha de Creación**: 4 de diciembre 2025
**Última Actualización**: 4 de diciembre 2025
**Estado**: Plan inicial - Pendiente de implementación
