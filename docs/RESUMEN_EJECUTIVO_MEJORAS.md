# Resumen Ejecutivo - Mejoras Frontend MATEOS

## 🎯 Objetivo General

Modernizar y mejorar la experiencia de usuario del sistema MATEOS usando Hero UI, con un diseño sobrio, claro y enfocado en funcionalidad.

---

## 📊 Resumen de Cambios

| Página | Cambios Principales | Esfuerzo |
|--------|---------------------|----------|
| **Config General** | Paleta colores, tema dark/light | 2-3h |
| **/proyectos/crear** | Selector ideas, Radio/Checkbox, estado auto | 3-4h |
| **/proyectos** | Dashboard completo, cálculo tiempos | 5-6h |
| **/proyectos/ideas** | Nueva página para ideas | 3-4h |
| **/proyectos/dashboard** | Drag & drop, dark mode, acordeones | 4-5h |

**Total**: 17-22 horas

---

## 🎨 Paleta de Colores

```css
#4682b4  →  Azul primario (botones, links)
#68bb7b  →  Verde éxito (completados)
#ffa500  →  Naranja advertencia (pausados)
#696969  →  Gris neutral (texto secundario)
#fceab0  →  Beige acento (destacados sutiles)
#ffffff  →  Blanco
#1e1f21  →  Negro carbón (fondo dark mode)
```

---

## 📝 Cambios por Página

### 1. /proyectos/crear

**Antes**:
- ❌ Selector de ideas vacío
- ❌ Checkbox "Generar con IA"
- ❌ Proyectos creados en estado "idea"
- ❌ Áreas de vida múltiple (incorrecto)

**Después**:
- ✅ Selector muestra ideas disponibles
- ✅ Pre-llena descripción desde idea
- ✅ Sin checkbox IA (siempre genera)
- ✅ Proyectos en estado "planificacion"
- ✅ Áreas: Radio (único) | Motivos: Checkbox (múltiple)

### 2. /proyectos (NUEVO Dashboard)

**Funcionalidad Nueva**:
- ✅ Vista por áreas de vida (acordeón)
- ✅ Cards de proyectos con:
  - Badge de estado (idea, planificacion, en_curso, etc)
  - Barra de progreso (%)
  - Tiempo: "18h / 40h (22h restantes)"
- ✅ Botones: "+ Crear Proyecto" y "💡 Ideas"
- ✅ Muestra TODOS los proyectos

### 3. /proyectos/ideas (NUEVO)

**Concepto**: Borrador de proyectos

**Funcionalidad**:
- ✅ Dropdown: Cargar idea existente
- ✅ Botón: Nueva idea
- ✅ Formulario: Título, descripción larga, categoría
- ✅ Campos: Área (radio), Motivos (checkbox)
- ✅ Botón: "Guardar Idea" (no crea proyecto)
- ✅ Botón: "Convertir en Proyecto" (si hay idea cargada)

### 4. /proyectos/dashboard (antes /dashboard)

**Mejoras**:
- ✅ Mover ruta: `/dashboard` → `/proyectos/dashboard`
- ✅ Acordeones abiertos por defecto
- ✅ Selección múltiple (varios abiertos a la vez)
- ✅ Dark mode mejorado (texto visible)
- ✅ **Drag & Drop**: Arrastrar subtareas entre columnas
- ✅ Actualización automática al soltar

---

## 🔧 Tecnologías

- **Hero UI**: Componentes React modernos
- **@dnd-kit**: Drag and drop
- **Tailwind CSS**: Dark mode y estilos
- **Next.js 15**: App Router

---

## 📋 APIs a Crear

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/ideas/disponibles` | GET | Ideas no implementadas |
| `/api/ideas` | GET | Listar todas las ideas |
| `/api/ideas` | POST | Crear nueva idea |
| `/api/ideas/[id]` | PUT | Actualizar idea |
| `/api/proyectos/dashboard` | GET | Dashboard de proyectos |
| `/api/subtareas/[id]/estado` | PATCH | Cambiar estado (DnD) |

---

## ✅ Checklist de Alto Nivel

### Sprint 1: Configuración (Día 1)
- [ ] Configurar paleta Tailwind
- [ ] Configurar Hero UI theme
- [ ] Crear componentes base

### Sprint 2: Proyectos (Día 2-3)
- [ ] API ideas disponibles
- [ ] Refactorizar /proyectos/crear
- [ ] Crear /proyectos dashboard

### Sprint 3: Ideas (Día 3-4)
- [ ] APIs CRUD ideas
- [ ] Crear /proyectos/ideas
- [ ] Integrar con crear proyecto

### Sprint 4: Dashboard Sprint (Día 4-5)
- [ ] Mover a /proyectos/dashboard
- [ ] Implementar drag & drop
- [ ] Mejorar dark mode

### Sprint 5: Testing (Día 5)
- [ ] Probar flujos completos
- [ ] Ajustar responsive
- [ ] Documentar

---

## 🎯 Prioridades

### Crítico (P0)
1. Configurar paleta y tema
2. Arreglar /proyectos/crear (selector ideas)
3. Mejorar dark mode dashboard

### Alto (P1)
4. Crear /proyectos dashboard
5. Crear /proyectos/ideas
6. Mover dashboard sprint

### Medio (P2)
7. Drag & drop en sprint
8. Acordeones abiertos por defecto

---

## 📐 Principios de Diseño

1. **Sobriedad**: Colores solo donde importa
2. **Claridad**: Jerarquía visual clara
3. **Funcionalidad**: UX sobre estética
4. **Consistencia**: Hero UI en todo
5. **Accesibilidad**: Dark mode legible

---

## 🚀 Próximos Pasos

1. **Revisar y aprobar** este plan
2. **Priorizar** funcionalidades (si hay restricciones de tiempo)
3. **Comenzar** con Sprint 1 (configuración)
4. **Iteraciones** semanales con feedback

---

**Documento Completo**: Ver `/docs/PLAN_MEJORAS_FRONTEND.md`

**Fecha**: 4 dic 2025
