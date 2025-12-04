# Changelog - Subtareas Estratégicas y Sistema Kanban

**Fecha**: 2025-12-03
**Versión**: 2.1.0

## 🎯 Cambios Implementados

### 1. **Renombrado de Tabla**

- ✅ `subtareas` → `subtareas_estrategicas`
  - Coherencia con nomenclatura del sistema
  - Mejor diferenciación con tareas simples del bot

### 2. **Tabla `tareas_estrategicas` - Nuevas Columnas**

| Columna | Tipo | Default | Descripción |
|---------|------|---------|-------------|
| `estado_kanban` | VARCHAR(20) | 'backlog' | Estado en tablero Kanban (freezer, backlog, waiting, todo, doing, done) |
| `fecha_done` | TIMESTAMP | null | Timestamp automático cuando pasa a estado 'done' |
| `impacto` | VARCHAR(20) | null | Nivel de impacto: alto, medio, bajo |
| `urgencia` | VARCHAR(20) | null | Nivel de urgencia: alta, media, baja |
| `eisenhower` | VARCHAR(30) | AUTO | Matriz de Eisenhower calculada automáticamente |

**Columnas eliminadas**:
- ❌ `estado` (TipoEstadoTarea) - Reemplazado por `estado_kanban`

### 3. **Tabla `subtareas_estrategicas` - Cambios**

| Cambio | Antes | Ahora |
|--------|-------|-------|
| Nombre de tabla | `subtareas` | `subtareas_estrategicas` |
| Columna nombre | `titulo` | `nombre` |
| Columna estado | `completada` (Boolean) | `estado_kanban` (VARCHAR) |
| Nueva columna | - | `fecha_done` (TIMESTAMP) |
| Ya existían | - | `fecha_inicio`, `fecha_fin` (DATE) |

### 4. **Nuevos Enums en Prisma**

```typescript
enum TipoEstadoKanban {
  freezer   // Congelado, no trabajar ahora
  backlog   // Backlog, por priorizar
  waiting   // Esperando dependencias
  todo      // Listo para hacer
  doing     // En progreso
  done      // Completado
}

enum TipoImpacto {
  alto
  medio
  bajo
}

enum TipoUrgencia {
  alta
  media
  baja
}

enum TipoEisenhower {
  cuadrante_1  // Urgente + Importante (Hacer YA)
  cuadrante_2  // No urgente + Importante (Planificar)
  cuadrante_3  // Urgente + No importante (Delegar)
  cuadrante_4  // No urgente + No importante (Eliminar)
}
```

### 5. **Cálculo Automático de Eisenhower** ⚡

Se creó un **trigger PostgreSQL** que calcula automáticamente el cuadrante de Eisenhower:

#### Reglas de Cálculo:

**Cuadrante 1 (urgente + importante)**:
- `moscow = 'must' AND urgencia = 'alta'`, O
- `nivel_riesgo IN ('alto', 'critico')`, O
- `impacto = 'alto' AND urgencia = 'alta'`

**Cuadrante 2 (no urgente + importante)**:
- `moscow IN ('must', 'should') AND urgencia IN ('media', 'baja')`, O
- `impacto = 'alto' AND nivel_riesgo IN ('bajo', 'medio')`

**Cuadrante 3 (urgente + no importante)**:
- `moscow = 'could' AND urgencia = 'alta'`, O
- `impacto = 'bajo' AND urgencia = 'alta'`

**Cuadrante 4 (no urgente + no importante)**:
- `moscow IN ('could', 'wont')`, O
- `impacto = 'bajo' AND urgencia = 'baja'`

**Default**: Cuadrante 2 (si no cumple ninguna regla)

#### El trigger se ejecuta automáticamente:
- Al crear una nueva tarea (`INSERT`)
- Al actualizar: `moscow`, `urgencia`, `impacto`, o `nivel_riesgo` (`UPDATE`)

### 6. **Nuevo Sistema de Prompt de IA**

**Archivo**: `automatizaciones/src/ia/prompts-proyectos.ts`

**Características**:
- Prompt estructurado con reglas claras
- Genera entre 5-15 tareas estratégicas
- Cada tarea con 3-8 subtareas
- Incluye campos de impacto y urgencia
- Formato JSON estricto
- Texto breve y asertivo

**Estructura de respuesta**:
```json
{
  "proyecto": {
    "justificacion_estrategica": {
      "impacto": "alto|medio|bajo",
      "urgencia": "alta|media|baja",
      "alineacion": "...",
      "oportunidad": "...",
      "recursos_clave": "...",
      "riesgos": "..."
    },
    "areas_ids": [],
    "motivos_ids": []
  },
  "tareas": [
    {
      "nombre": "3-4 palabras",
      "orden": 1,
      "moscow": "must",
      "tiempo_estimado_horas": 5,
      "nivel_riesgo": "medio",
      "estado_kanban": "backlog",
      "impacto": "alto",
      "urgencia": "media",
      "subtareas_estrategicas": ["- acción 1", "- acción 2"]
    }
  ],
  "subtareas_estrategicas_matriz": [
    {
      "tarea_orden": 1,
      "indice_subtarea": 1,
      "nombre": "acción 1",
      "comienzo": null,
      "fin": null
    }
  ]
}
```

## 📊 Uso en NocoDB

### Vista Kanban

Puedes crear una vista Kanban usando la columna `estado_kanban`:

**Columnas del tablero**:
1. **Freezer** - Proyectos/tareas congeladas
2. **Backlog** - Sin priorizar aún
3. **Waiting** - Bloqueadas por dependencias
4. **Todo** - Listas para trabajar
5. **Doing** - En progreso
6. **Done** - Completadas

### Vista Calendario

Usa las columnas:
- **`fecha_inicio`** - Cuándo comienza la tarea/subtarea
- **`fecha_fin`** - Cuándo termina

### Vista Eisenhower

Filtra por `eisenhower` para priorizar:
- **Hacer YA**: `cuadrante_1`
- **Planificar**: `cuadrante_2`
- **Delegar**: `cuadrante_3`
- **Eliminar**: `cuadrante_4`

## 🚀 Estado Actual

### ✅ Completado

1. Schema de base de datos actualizado
2. Migraciones SQL ejecutadas
3. Trigger de Eisenhower funcionando
4. Enums creados
5. Columnas de fechas agregadas
6. Nuevo prompt de IA creado
7. Contenedores reconstruidos

### ⚠️ Pendiente (Para Siguiente Iteración)

1. **Implementación completa en `project-creator.ts`**:
   - Generar subtareas automáticamente
   - Poblar `subtareas_estrategicas_matriz`
   - Guardar relaciones correctamente

2. **Frontend**:
   - Actualizar componentes para usar `estado_kanban`
   - Mostrar matriz de Eisenhower
   - UI para mover entre estados Kanban

3. **Testing**:
   - Probar generación de proyectos con subtareas
   - Verificar cálculo automático de Eisenhower
   - Test de migración de datos existentes

## 📝 Notas Técnicas

### Migración de Datos

Los datos existentes fueron migrados automáticamente:
- `completada = true` → `estado_kanban = 'done'`
- `completada = false` → `estado_kanban = 'backlog'`
- `titulo` → `nombre` (renombrado)

### Índices Creados

Para mejor performance:
```sql
CREATE INDEX idx_subtareas_estado_kanban ON subtareas_estrategicas(estado_kanban);
CREATE INDEX idx_tareas_estado_kanban ON tareas_estrategicas(estado_kanban);
CREATE INDEX idx_tareas_eisenhower ON tareas_estrategicas(eisenhower);
```

## 🔗 Archivos Modificados

1. `next-app/prisma/schema.prisma`
2. `automatizaciones/prisma/schema.prisma`
3. `automatizaciones/src/project-creator.ts`
4. `automatizaciones/src/ia/prompts-proyectos.ts` (nuevo)
5. `migrate_subtareas_estrategicas.sql` (migración)

## ⚙️ Comandos Útiles

```bash
# Ver tareas por estado Kanban
docker exec -i transcripcion-postgres psql -U asistente -d asistente_db -c \
  "SELECT nombre, estado_kanban, eisenhower FROM tareas_estrategicas ORDER BY orden;"

# Ver subtareas por tarea
docker exec -i transcripcion-postgres psql -U asistente -d asistente_db -c \
  "SELECT te.nombre as tarea, se.nombre as subtarea, se.estado_kanban
   FROM subtareas_estrategicas se
   JOIN tareas_estrategicas te ON se.tarea_estrategica_id = te.id
   ORDER BY te.orden, se.id;"

# Ver distribución de Eisenhower
docker exec -i transcripcion-postgres psql -U asistente -d asistente_db -c \
  "SELECT eisenhower, COUNT(*) FROM tareas_estrategicas
   WHERE eisenhower IS NOT NULL GROUP BY eisenhower;"
```

## 🎯 Próximos Pasos Recomendados

1. **Completar generación de subtareas** en `project-creator.ts`
2. **Crear endpoint** para mover tareas entre estados Kanban
3. **Agregar webhook** que actualice `fecha_done` automáticamente
4. **Crear vista** de matriz Eisenhower en el frontend
5. **Implementar drag & drop** para tablero Kanban

---

**Autor**: Claude Code Assistant
**Ticket**: MATEOS-V2-SUBTAREAS-KANBAN
