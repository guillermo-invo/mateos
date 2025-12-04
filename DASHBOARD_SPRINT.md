# Dashboard de Sprint Semanal

## 📋 Resumen

Sistema completo para visualizar las tareas del sprint actual (semana en curso) organizadas por Áreas de Vida, con vista Kanban.

---

## 🎯 Funcionalidad

### Reglas de Sprint
- **Inicio del sprint**: Lunes de la semana actual a las 00:00
- **Subtareas incluidas**:
  - Estado `waiting`, `todo`, `doing` → Siempre incluidas
  - Estado `done` → Solo si `fechaDone >= inicio del sprint`

### Organización de Datos
```
Áreas de Vida
  └─ Proyectos Estratégicos (con barra de progreso)
      └─ Tareas Estratégicas
          └─ Subtareas (en columnas Kanban)
```

---

## 📁 Archivos Creados

### 1. API Endpoint
**Ruta**: `/api/dashboard/current-sprint`

**Archivo**: `/next-app/src/app/api/dashboard/current-sprint/route.ts`

**Funcionalidad**:
- Calcula inicio del sprint (lunes 00:00)
- Filtra subtareas según reglas de sprint
- Organiza por áreas de vida
- Calcula progreso de proyectos
- Filtra solo proyectos activos (`planificacion`, `en_curso`)
- Filtra solo áreas activas

**Respuesta JSON**:
```json
{
  "success": true,
  "sprintStart": "2025-12-02T00:00:00.000Z",
  "data": [
    {
      "id": "1",
      "title": "Profesional",
      "projects": [
        {
          "id": "7",
          "title": "Mimochi 2026",
          "progress": 45,
          "tasks": [
            {
              "id": "23",
              "title": "Contactar empresas",
              "subtasks": [
                {
                  "id": "156",
                  "title": "Preparar pitch deck",
                  "status": "doing",
                  "estimate": "120min",
                  "moscow": "Must"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

---

### 2. Componente React
**Archivo**: `/next-app/src/components/KanbanTaskView.tsx`

**Props**:
```typescript
interface Props {
  data: AreaDeVida[];
}
```

**Características**:
- Acordeones anidados para jerarquía
- 4 columnas Kanban: Waiting, Todo, Doing, Done
- Barra de progreso por proyecto
- Chips de MoSCoW con colores:
  - Must → Rojo (danger)
  - Should → Amarillo (warning)
  - Could/Won't → Gris (default)
- Estimación de tiempo en cada subtarea

---

### 3. Página Dashboard
**Archivo**: `/next-app/src/app/dashboard/page.tsx`

**URL**: `http://localhost:3000/dashboard`

**Características**:
- Fetch automático de datos
- Loading spinner
- Manejo de errores
- Muestra fecha de inicio del sprint
- Mensaje cuando no hay tareas

---

## 🚀 Cómo Usar

### 1. Preparar Datos (Si no tienes)
Necesitas tener en la BD:
- Áreas de vida activas (`areas_vida.activa = true`)
- Proyectos en estado `planificacion` o `en_curso`
- Tareas estratégicas
- Subtareas con `estadoKanban` en: `waiting`, `todo`, `doing`, o `done`

### 2. Iniciar el Servidor
```bash
cd /home/azureuser/mateos/next-app
npm run dev
```

### 3. Abrir el Dashboard
Navega a: `http://localhost:3000/dashboard`

---

## 🧪 Probar el API Directamente

```bash
# Test endpoint
curl http://localhost:3000/api/dashboard/current-sprint | jq '.'

# Ver solo las áreas
curl http://localhost:3000/api/dashboard/current-sprint | jq '.data[].title'

# Ver cuántos proyectos hay
curl http://localhost:3000/api/dashboard/current-sprint | jq '.data[].projects | length'
```

---

## 📊 Cálculo de Progreso

El progreso de cada proyecto se calcula así:

```typescript
const totalSubtareas = // Número total de subtareas en el sprint
const subtareasDone = // Subtareas con estado 'done'
const progress = Math.round((subtareasDone / totalSubtareas) * 100)
```

**Ejemplo**:
- Proyecto tiene 20 subtareas en el sprint
- 9 están en `done`
- Progreso = (9 / 20) * 100 = **45%**

---

## 🎨 Personalización

### Cambiar Colores de Columnas
Edita en `KanbanTaskView.tsx`:

```typescript
const columnsConfig = [
  { status: 'waiting', color: 'bg-gray-100' },     // ← Cambia aquí
  { status: 'todo', color: 'bg-blue-100/80' },     // ← Cambia aquí
  { status: 'doing', color: 'bg-amber-100/80' },   // ← Cambia aquí
  { status: 'done', color: 'bg-green-100/80' },    // ← Cambia aquí
];
```

### Cambiar Inicio de Sprint
Si quieres que el sprint inicie otro día (ej: domingo), edita en `route.ts`:

```typescript
function getSprintStart(): Date {
  const now = new Date();
  const dayOfWeek = now.getDay();
  const daysToSubtract = dayOfWeek; // Para domingo como día 0

  const sprintStart = new Date(now);
  sprintStart.setDate(now.getDate() - daysToSubtract);
  sprintStart.setHours(0, 0, 0, 0);

  return sprintStart;
}
```

---

## 🐛 Troubleshooting

### No aparecen tareas
1. Verifica que haya subtareas con estado: `waiting`, `todo`, `doing`, o `done`
2. Si están en `done`, verifica que `fechaDone` sea de esta semana
3. Verifica que el proyecto esté en estado `planificacion` o `en_curso`
4. Verifica que las áreas de vida estén activas

### Error de compilación
Si ves errores de TypeScript, verifica que Hero UI esté instalado:
```bash
npm install @heroui/react
```

### El servidor no inicia
Verifica el puerto 3000:
```bash
lsof -ti:3000 | xargs kill -9
npm run dev
```

---

## 📈 Próximos Pasos (Opcional)

1. **Drag & Drop**: Agregar `@dnd-kit` para mover subtareas entre columnas
2. **Edición inline**: Click en subtarea para cambiar estado
3. **Filtros**: Filtrar por área, proyecto, o MoSCoW
4. **Vista semanal**: Agregar calendario con subtareas por día
5. **Estadísticas**: Agregar gráficos de velocidad del sprint

---

## ✅ Checklist de Verificación

- [ ] API endpoint responde correctamente
- [ ] Dashboard carga sin errores
- [ ] Se muestran las áreas de vida
- [ ] Se muestran los proyectos con barra de progreso
- [ ] Las subtareas aparecen en las columnas correctas
- [ ] Los chips de MoSCoW tienen los colores correctos
- [ ] La fecha de inicio del sprint es correcta
