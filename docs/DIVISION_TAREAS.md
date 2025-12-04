# División de Tareas - Frontend MATEOS

## 🎯 Estrategia de Trabajo Paralelo

**Claude**: APIs, lógica de negocio, integraciones complejas
**Amigo**: Configuración visual, componentes UI, estilos, rutas

---

## ✅ TAREAS SENCILLAS (Para el Amigo)

### 1. Configuración de Diseño (2-3h)

#### 1.1 Configurar Paleta en Tailwind
**Archivo**: `/next-app/tailwind.config.js`
**Dificultad**: ⭐ Muy Fácil
**Tiempo**: 30 min

#### 1.2 Configurar Tema Hero UI
**Archivo**: `/next-app/tailwind.config.js`
**Dificultad**: ⭐⭐ Fácil
**Tiempo**: 1h

#### 1.3 Mejorar Dark Mode en Componentes Existentes
**Archivos**:
- `/next-app/src/components/KanbanTaskView.tsx`
- Otros componentes visuales
**Dificultad**: ⭐⭐ Fácil
**Tiempo**: 1-2h

### 2. Reorganización de Rutas (1h)

#### 2.1 Mover Dashboard Sprint
**Acción**:
- Mover `/next-app/src/app/dashboard/` → `/next-app/src/app/proyectos/dashboard/`
**Dificultad**: ⭐ Muy Fácil
**Tiempo**: 15 min

#### 2.2 Actualizar Navegación
**Archivos**:
- `/next-app/src/components/layout/Sidebar.tsx`
- Otros links de navegación
**Dificultad**: ⭐ Muy Fácil
**Tiempo**: 30 min

### 3. Mejoras en Dashboard Sprint (1-2h)

#### 3.1 Acordeones Abiertos por Defecto
**Archivo**: `/next-app/src/components/KanbanTaskView.tsx`
**Dificultad**: ⭐ Muy Fácil
**Tiempo**: 15 min

#### 3.2 Selección Múltiple de Acordeones
**Archivo**: `/next-app/src/components/KanbanTaskView.tsx`
**Dificultad**: ⭐ Muy Fácil
**Tiempo**: 15 min

### 4. Componentes Base Reutilizables (2-3h)

#### 4.1 Wrapper de Formularios
**Archivo**: `/next-app/src/components/ui/FormWrapper.tsx` (nuevo)
**Dificultad**: ⭐⭐ Fácil
**Tiempo**: 1h

#### 4.2 Componente Card de Proyecto
**Archivo**: `/next-app/src/components/ProyectoCard.tsx` (nuevo)
**Dificultad**: ⭐⭐ Fácil
**Tiempo**: 1-2h

**TOTAL AMIGO**: 6-9 horas

---

## 🔥 TAREAS COMPLEJAS (Para Claude)

### 1. APIs Backend (5-6h)

#### 1.1 API Ideas Disponibles
**Endpoint**: `GET /api/ideas/disponibles`
**Dificultad**: ⭐⭐⭐ Media
**Razón**: Query Prisma, filtros
**Tiempo**: 45 min

#### 1.2 API CRUD de Ideas
**Endpoints**:
- `GET /api/ideas`
- `POST /api/ideas`
- `PUT /api/ideas/[id]`
**Dificultad**: ⭐⭐⭐ Media
**Razón**: Validación, relaciones
**Tiempo**: 2h

#### 1.3 API Dashboard Proyectos
**Endpoint**: `GET /api/proyectos/dashboard`
**Dificultad**: ⭐⭐⭐⭐ Alta
**Razón**: Cálculos complejos, agregaciones
**Tiempo**: 2-3h

#### 1.4 API Cambiar Estado Subtarea
**Endpoint**: `PATCH /api/subtareas/[id]/estado`
**Dificultad**: ⭐⭐⭐ Media
**Razón**: Actualización condicional, fecha_done
**Tiempo**: 1h

### 2. Páginas con Lógica (6-8h)

#### 2.1 Refactorizar /proyectos/crear
**Archivo**: `/next-app/src/app/proyectos/crear/page.tsx`
**Dificultad**: ⭐⭐⭐⭐ Alta
**Razón**: Integración API ideas, estado, validación
**Tiempo**: 3-4h

#### 2.2 Crear /proyectos/ideas
**Archivo**: `/next-app/src/app/proyectos/ideas/page.tsx` (nuevo)
**Dificultad**: ⭐⭐⭐ Media
**Razón**: CRUD completo, estado local
**Tiempo**: 2-3h

#### 2.3 Crear /proyectos Dashboard
**Archivo**: `/next-app/src/app/proyectos/page.tsx`
**Dificultad**: ⭐⭐⭐⭐ Alta
**Razón**: Cálculos, visualización compleja
**Tiempo**: 2-3h

### 3. Features Avanzadas (3-4h)

#### 3.1 Drag & Drop en Sprint
**Archivo**: `/next-app/src/components/KanbanTaskView.tsx`
**Dificultad**: ⭐⭐⭐⭐⭐ Muy Alta
**Razón**: Librería @dnd-kit, estado optimista, API calls
**Tiempo**: 3-4h

**TOTAL CLAUDE**: 14-18 horas

---

## 🚫 REGLAS PARA EVITAR CONFLICTOS

### Amigo NO debe tocar:
- ❌ Carpeta `/next-app/src/app/api/**/*` (todas las APIs)
- ❌ Lógica de fetching de datos (fetch, SWR, etc.)
- ❌ Validaciones de formularios
- ❌ State management complejo
- ❌ Integraciones entre páginas

### Amigo SÍ puede tocar:
- ✅ `/next-app/tailwind.config.js`
- ✅ `/next-app/src/app/globals.css`
- ✅ Componentes en `/next-app/src/components/` (solo visuales)
- ✅ Rutas y carpetas (mover, renombrar)
- ✅ Props de componentes Hero UI (colors, variants, etc.)

### Claude NO debe tocar:
- ❌ `/next-app/tailwind.config.js`
- ❌ Clases Tailwind en componentes que el amigo está trabajando
- ❌ Estructura visual de componentes base

### Claude SÍ puede tocar:
- ✅ Toda la carpeta `/next-app/src/app/api/`
- ✅ Lógica de páginas (fetching, validación, estado)
- ✅ Integraciones complejas

---

## 📅 Orden Sugerido

### Día 1 - Fundación
**Amigo**:
1. Configurar Tailwind (30min)
2. Tema Hero UI (1h)
3. Mover rutas (30min)

**Claude**:
1. APIs de ideas (3h)

### Día 2 - Componentes y Dashboard
**Amigo**:
1. Componentes base (3h)
2. Mejorar dark mode (2h)

**Claude**:
1. API Dashboard proyectos (3h)
2. Página /proyectos dashboard (3h)

### Día 3 - Páginas y Features
**Amigo**:
1. Acordeones mejorados (30min)
2. ProyectoCard (2h)

**Claude**:
1. Refactorizar /proyectos/crear (4h)
2. Crear /proyectos/ideas (3h)

### Día 4 - Drag & Drop
**Amigo**:
1. Testing visual
2. Ajustes de diseño

**Claude**:
1. API estado subtarea (1h)
2. Drag & Drop completo (4h)

---

## ✅ Checklist de Coordinación

### Antes de Empezar
- [ ] Amigo clona/pull del repo
- [ ] Amigo crea branch: `feature/ui-improvements`
- [ ] Claude crea branch: `feature/api-and-logic`
- [ ] Acordar horario de merge diario

### Durante el Trabajo
- [ ] Amigo hace commits frecuentes con prefijo `[UI]`
- [ ] Claude hace commits frecuentes con prefijo `[API]` o `[LOGIC]`
- [ ] Comunicación si hay duda sobre "quién toca qué"

### Al Finalizar Cada Día
- [ ] Amigo pushea su branch
- [ ] Claude pushea su branch
- [ ] Merge a main (o branch de desarrollo)
- [ ] Rebuild y test en staging

---

## 🎯 Criterios de Éxito

### Amigo
- ✅ Paleta de colores aplicada en toda la app
- ✅ Dark mode legible en todos los componentes
- ✅ Dashboard en ruta `/proyectos/dashboard`
- ✅ Acordeones funcionan correctamente
- ✅ Componentes base reutilizables creados

### Claude
- ✅ Todas las APIs funcionando
- ✅ /proyectos/crear con selector de ideas
- ✅ /proyectos dashboard con cálculos correctos
- ✅ /proyectos/ideas funcionando
- ✅ Drag & drop operativo

---

**Ver archivo**: `PROMPT_PARA_AMIGO.md` para instrucciones detalladas
