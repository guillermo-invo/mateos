# Instrucciones para Mejoras de UI - MATEOS

Hola! Vas a trabajar en las mejoras visuales y de diseño del sistema MATEOS. Aquí están todas las instrucciones paso a paso.

---

## 🎯 Tu Rol

Tú te encargas de:
- ✅ Configuración visual (colores, tema)
- ✅ Componentes de UI
- ✅ Estilos y dark mode
- ✅ Reorganización de rutas

**NO toques**:
- ❌ Archivos en `/src/app/api/` (APIs)
- ❌ Lógica de fetching de datos
- ❌ Validaciones de formularios

---

## 📋 Tareas a Realizar

### ✅ Tarea 1: Configurar Paleta de Colores (30 min)

**Archivo**: `/next-app/tailwind.config.js`

**Reemplaza** el contenido completo con esto:

```javascript
const {heroui} = require('@heroui/theme');

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./node_modules/@heroui/theme/dist/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        'mateos-primary': '#4682b4',
        'mateos-success': '#68bb7b',
        'mateos-warning': '#ffa500',
        'mateos-neutral': '#696969',
        'mateos-accent': '#fceab0',
        'mateos-dark': '#1e1f21',
      }
    }
  },
  plugins: [
    heroui({
      themes: {
        light: {
          colors: {
            primary: {
              DEFAULT: '#4682b4',
              foreground: '#ffffff',
            },
            success: {
              DEFAULT: '#68bb7b',
              foreground: '#ffffff',
            },
            warning: {
              DEFAULT: '#ffa500',
              foreground: '#ffffff',
            },
          }
        },
        dark: {
          colors: {
            primary: {
              DEFAULT: '#4682b4',
              foreground: '#ffffff',
            },
            success: {
              DEFAULT: '#68bb7b',
              foreground: '#ffffff',
            },
            warning: {
              DEFAULT: '#ffa500',
              foreground: '#ffffff',
            },
            background: '#1e1f21',
            foreground: '#ffffff',
          }
        }
      }
    })
  ]
}
```

**Commit**: `[UI] Configure color palette and Hero UI theme`

---

### ✅ Tarea 2: Mover Dashboard a Nueva Ruta (15 min)

**Acción**: Mover carpeta

```bash
# Desde la raíz del proyecto
cd /home/azureuser/mateos/next-app

# Crear carpeta proyectos si no existe
mkdir -p src/app/proyectos

# Mover dashboard
mv src/app/dashboard src/app/proyectos/dashboard
```

**Commit**: `[UI] Move dashboard to /proyectos/dashboard route`

---

### ✅ Tarea 3: Mejorar Dark Mode en Dashboard Sprint (1-2h)

**Archivo**: `/next-app/src/components/KanbanTaskView.tsx`

**Cambios a hacer**:

1. **Títulos de áreas** (línea ~93):
```tsx
// ANTES:
<span className="font-bold text-lg">{area.title}</span>

// DESPUÉS:
<span className="font-bold text-lg text-gray-900 dark:text-white">
  {area.title}
</span>
```

2. **Títulos de proyectos** (línea ~105):
```tsx
// ANTES:
<span className="font-semibold text-gray-700 whitespace-nowrap">
  {project.title}
</span>

// DESPUÉS:
<span className="font-semibold text-gray-700 dark:text-gray-200 whitespace-nowrap">
  {project.title}
</span>
```

3. **Títulos de tareas** (línea ~125):
```tsx
// ANTES:
<span className="text-gray-600">{task.title}</span>

// DESPUÉS:
<span className="text-gray-600 dark:text-gray-300">{task.title}</span>
```

4. **Cards de subtareas** (línea ~44):
```tsx
// ANTES:
<Card shadow="sm" className="w-full mb-2 bg-white border border-gray-200">
  <CardBody className="p-3 text-small flex flex-col gap-1">
    <p className="font-semibold text-gray-800">{subtask.title}</p>
    <div className="text-gray-600 text-xs flex flex-col">

// DESPUÉS:
<Card shadow="sm" className="w-full mb-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
  <CardBody className="p-3 text-small flex flex-col gap-1">
    <p className="font-semibold text-gray-800 dark:text-gray-100">{subtask.title}</p>
    <div className="text-gray-600 dark:text-gray-400 text-xs flex flex-col">
```

5. **Columnas Kanban** (línea ~64):
```tsx
// ANTES:
<div className={`h-full p-2 rounded-lg ${colorClass} flex flex-col gap-2 min-h-[150px]`}>

// DESPUÉS:
<div className={`h-full p-2 rounded-lg ${colorClass} dark:bg-opacity-40 flex flex-col gap-2 min-h-[150px]`}>
```

6. **Header de columnas** (línea ~74):
```tsx
// ANTES:
<div className="grid grid-cols-[220px_1fr_1fr_1fr_1fr] gap-4 mb-2 px-4 font-bold text-center text-gray-700 uppercase text-sm sticky top-0 bg-white z-10 py-2">

// DESPUÉS:
<div className="grid grid-cols-[220px_1fr_1fr_1fr_1fr] gap-4 mb-2 px-4 font-bold text-center text-gray-700 dark:text-gray-300 uppercase text-sm sticky top-0 bg-white dark:bg-gray-900 z-10 py-2">
```

7. **Headers individuales** (líneas ~76-79):
```tsx
// ANTES:
<div className="bg-gray-200 rounded py-1">Waiting</div>
<div className="bg-blue-200 rounded py-1">Todo</div>
<div className="bg-amber-200 rounded py-1">Doing</div>
<div className="bg-green-200 rounded py-1">Done</div>

// DESPUÉS:
<div className="bg-gray-200 dark:bg-gray-700 rounded py-1">Waiting</div>
<div className="bg-blue-200 dark:bg-blue-900 rounded py-1">Todo</div>
<div className="bg-amber-200 dark:bg-amber-900 rounded py-1">Doing</div>
<div className="bg-green-200 dark:bg-green-900 rounded py-1">Done</div>
```

8. **Fondo principal** (línea ~85):
```tsx
// ANTES:
<div className="w-full max-w-7xl mx-auto p-4">

// DESPUÉS:
<div className="w-full max-w-7xl mx-auto p-4 bg-white dark:bg-gray-900">
```

**Commit**: `[UI] Improve dark mode contrast in KanbanTaskView`

---

### ✅ Tarea 4: Acordeones Abiertos por Defecto (15 min)

**Archivo**: `/next-app/src/components/KanbanTaskView.tsx`

**Cambios**:

1. **Acordeón de Áreas** (línea ~88):
```tsx
// ANTES:
<Accordion variant="splitted" className="px-0">

// DESPUÉS:
<Accordion
  variant="splitted"
  className="px-0"
  defaultExpandedKeys="all"
  selectionMode="multiple"
>
```

2. **Acordeón de Proyectos** (línea ~94):
```tsx
// ANTES:
<Accordion variant="light" className="pl-2">

// DESPUÉS:
<Accordion
  variant="light"
  className="pl-2"
  defaultExpandedKeys="all"
  selectionMode="multiple"
>
```

3. **Acordeón de Tareas** (línea ~118):
```tsx
// ANTES:
<Accordion variant="light">

// DESPUÉS:
<Accordion
  variant="light"
  defaultExpandedKeys="all"
  selectionMode="multiple"
>
```

**Commit**: `[UI] Set accordions to open by default with multiple selection`

---

### ✅ Tarea 5: Crear Componente Card de Proyecto (1-2h)

**Archivo nuevo**: `/next-app/src/components/ProyectoCard.tsx`

**Contenido**:

```tsx
'use client';

import { Card, CardBody, CardHeader, Progress, Chip } from "@heroui/react";
import Link from "next/link";

export type EstadoProyecto =
  | 'idea'
  | 'planificacion'
  | 'en_curso'
  | 'pausado'
  | 'completado'
  | 'cancelado'
  | 'archivado';

interface ProyectoCardProps {
  id: string;
  nombre: string;
  estado: EstadoProyecto;
  progreso: number;
  horasCompletadas: number;
  horasTotal: number;
  horasRestantes: number;
}

const estadoConfig: Record<EstadoProyecto, { color: any; label: string }> = {
  idea: { color: 'default', label: 'Idea' },
  planificacion: { color: 'primary', label: 'Planificación' },
  en_curso: { color: 'success', label: 'En Curso' },
  pausado: { color: 'warning', label: 'Pausado' },
  completado: { color: 'success', label: 'Completado' },
  cancelado: { color: 'danger', label: 'Cancelado' },
  archivado: { color: 'default', label: 'Archivado' },
};

export default function ProyectoCard({
  id,
  nombre,
  estado,
  progreso,
  horasCompletadas,
  horasTotal,
  horasRestantes,
}: ProyectoCardProps) {
  const estadoInfo = estadoConfig[estado];

  return (
    <Card
      className="w-full hover:shadow-lg transition-shadow cursor-pointer"
      isPressable
      as={Link}
      href={`/proyectos/${id}`}
    >
      <CardHeader className="flex justify-between items-center pb-0">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          {nombre}
        </h3>
        <Chip
          color={estadoInfo.color}
          variant="flat"
          size="sm"
        >
          {estadoInfo.label}
        </Chip>
      </CardHeader>

      <CardBody className="pt-2">
        {/* Barra de Progreso */}
        <Progress
          value={progreso}
          color={estadoInfo.color}
          showValueLabel
          className="mb-3"
        />

        {/* Información de Tiempo */}
        <div className="text-sm text-gray-600 dark:text-gray-400">
          <span className="font-medium">
            {horasCompletadas.toFixed(1)}h
          </span>
          {' / '}
          <span className="font-medium">
            {horasTotal.toFixed(1)}h
          </span>
          <span className="text-gray-500 dark:text-gray-500 ml-2">
            ({horasRestantes.toFixed(1)}h restantes)
          </span>
        </div>
      </CardBody>
    </Card>
  );
}
```

**Commit**: `[UI] Create ProyectoCard component with estado badges`

---

### ✅ Tarea 6: Actualizar Navegación (30 min)

**Archivo**: `/next-app/src/components/layout/Sidebar.tsx`

**Cambio**:

Busca el link que dice `/dashboard` y cámbialo a `/proyectos/dashboard`:

```tsx
// ANTES:
<Link href="/dashboard">
  Dashboard
</Link>

// DESPUÉS:
<Link href="/proyectos/dashboard">
  Sprint Actual
</Link>
```

Si hay más referencias a `/dashboard` en otros archivos de navegación, cámbialas también.

**Commit**: `[UI] Update navigation links to new dashboard route`

---

### ✅ Tarea 7: Mejorar Página de Dashboard Sprint (30 min)

**Archivo**: `/next-app/src/app/proyectos/dashboard/page.tsx`

**Cambios visuales**:

1. **Fondo de la página** (línea ~48):
```tsx
// ANTES:
<div className="min-h-screen bg-gray-50 py-8">

// DESPUÉS:
<div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8">
```

2. **Título** (línea ~51):
```tsx
// ANTES:
<h1 className="text-3xl font-bold text-gray-900 mb-2">

// DESPUÉS:
<h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
```

3. **Subtítulo** (línea ~54):
```tsx
// ANTES:
<p className="text-gray-600">

// DESPUÉS:
<p className="text-gray-600 dark:text-gray-400">
```

4. **Mensaje vacío** (línea ~62):
```tsx
// ANTES:
<p className="text-gray-500 text-lg">
  No hay tareas en el sprint actual.
</p>
<p className="text-gray-400 mt-2">

// DESPUÉS:
<p className="text-gray-500 dark:text-gray-400 text-lg">
  No hay tareas en el sprint actual.
</p>
<p className="text-gray-400 dark:text-gray-500 mt-2">
```

**Commit**: `[UI] Improve dark mode in dashboard page`

---

## 🧪 Testing

Después de cada tarea, verifica que:

1. **Light mode** se ve bien
2. **Dark mode** se ve bien (texto legible, contraste adecuado)
3. **No hay errores** en la consola del navegador
4. **La página carga** correctamente

Para probar dark mode:
- Abre DevTools (F12)
- En la pestaña Elements, busca el tag `<html>`
- Agrega manualmente la clase `dark` para ver el dark mode
- O usa el botón de tema si existe en la app

---

## 📦 Workflow de Git

```bash
# 1. Crear tu branch
git checkout -b feature/ui-improvements

# 2. Hacer cambios y commits frecuentes
git add .
git commit -m "[UI] Tu mensaje aquí"

# 3. Push al final del día
git push origin feature/ui-improvements

# 4. Comunicar que terminaste
```

---

## ❓ Si Tienes Dudas

**Pregunta ANTES de tocar**:
- Archivos en `/src/app/api/`
- Funciones que hacen `fetch()`
- Lógica de validación de formularios
- `useState`, `useEffect` con lógica compleja

**Puedes tocar libremente**:
- Clases de Tailwind
- Props de componentes Hero UI
- Estructura HTML/JSX (sin lógica)
- Estilos y colores

---

## ✅ Checklist Final

Antes de decir que terminaste, verifica:

- [ ] Paleta configurada en `tailwind.config.js`
- [ ] Dashboard movido a `/proyectos/dashboard`
- [ ] Dark mode mejorado en KanbanTaskView
- [ ] Acordeones abiertos por defecto
- [ ] ProyectoCard creado
- [ ] Navegación actualizada
- [ ] Todo hace commit con prefijo `[UI]`
- [ ] Todo pusheado a tu branch
- [ ] Probado en light y dark mode

---

## 🎉 ¡Eso es Todo!

Cuando termines todas las tareas:
1. Pushea tu branch
2. Avisa que terminaste
3. Se hará merge con lo que yo (Claude) estoy haciendo

**Tiempo estimado**: 6-9 horas

¡Éxito! 🚀
