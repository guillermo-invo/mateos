# _CONTEXT.md - Scripts DB

## PROPÓSITO

Scripts SQL y shell para gestión de base de datos: migraciones manuales, queries útiles, seed data, y sistema de tareas recurrentes.

---

## STACK TÉCNICO ESPECÍFICO

- **SQL:** PostgreSQL 15.5 (dialect específico)
- **Shell:** Bash 5.x
- **Convenciones:** snake_case (tablas, columnas, funciones)

---

## ARQUITECTURA Y ORGANIZACIÓN

### Estructura de Carpetas

```
scripts/db/
├── migrations/
│   ├── recurrentes/              [Sistema tareas recurrentes - Dic 2024]
│   │   ├── 01_alta_prioridad_tareas_recurrentes.sql
│   │   ├── 02_alta_prioridad_vistas.sql
│   │   ├── 03_media_prioridad_modificaciones.sql
│   │   ├── 04_baja_prioridad_configuracion.sql
│   │   ├── ejecutar_todas_migraciones.sh
│   │   ├── README.md
│   │   ├── EJEMPLOS_USO.md
│   │   ├── QUICK_REFERENCE.md
│   │   └── RESUMEN_IMPLEMENTACION.md
│   └── 20260130_personas_organizaciones_subproyectos.sql  [Sistema personas/orgs - Ene 2026]
├── queries_utiles.sql            [Queries, vistas, funciones - 15KB]
├── seed-data.sql                 [Datos iniciales - 18KB]
└── manual-migration.sql          [Migraciones manuales - 6KB]
```

---

## ARCHIVOS CLAVE

### queries_utiles.sql (15KB)

**Propósito:** Colección de queries frecuentes, vistas útiles, y funciones PostgreSQL.

**Contenido típico:**
- Queries de análisis (proyectos por estado, tareas por prioridad)
- Vistas materializadas (resúmenes, dashboards)
- Funciones PL/pgSQL (cálculos, validaciones)
- Triggers (auditoría, validaciones automáticas)

**Organización interna:**
```sql
-- ============================================
-- VISTAS
-- ============================================

CREATE OR REPLACE VIEW v_proyectos_activos AS ...

-- ============================================
-- FUNCIONES
-- ============================================

CREATE OR REPLACE FUNCTION calcular_progreso_proyecto(proyecto_id UUID)
RETURNS DECIMAL AS $$
...
$$ LANGUAGE plpgsql;

-- ============================================
-- QUERIES ÚTILES
-- ============================================

-- Proyectos con más de 3 en DOING
SELECT ...
```

---

### seed-data.sql (18KB)

**Propósito:** Datos iniciales para desarrollo y testing.

**Incluye:**
- Áreas de vida básicas (Salud, Trabajo, Familia, etc.)
- Proyectos de ejemplo
- Tareas de prueba
- Configuración inicial

**⚠️ NO ejecutar en producción:**
```sql
-- Guard: Solo en desarrollo
DO $$
BEGIN
  IF current_database() = 'mateos_prod' THEN
    RAISE EXCEPTION 'NO ejecutar seed data en producción';
  END IF;
END
$$;

-- Seed data...
```

**Ejecutar:**
```bash
psql $DATABASE_URL -f scripts/db/seed-data.sql
```

---

### manual-migration.sql (6KB)

**Propósito:** Migraciones SQL manuales (fuera de Prisma).

**Casos de uso:**
- Agregar columnas específicas de PostgreSQL (JSON, arrays)
- Crear índices complejos
- Modificar datos existentes (UPDATE masivo)
- Funciones y triggers que Prisma no soporta

**⚠️ Sincronizar con Prisma:**
```sql
-- 1. Ejecutar migración manual
-- 2. Actualizar schema.prisma para reflejar cambios
-- 3. Generar migración vacía en Prisma (tracking)
```

---

### migrations/recurrentes/

**Propósito:** Sistema completo de tareas recurrentes (implementado Dic 2024).

**Archivos:**

1. **`01_alta_prioridad_tareas_recurrentes.sql`**
   - Tablas: `tarea_recurrente_plantilla`, `tarea_recurrente_instancia`
   - Tipos: `tipo_recurrencia` (DIARIA, SEMANAL, MENSUAL, ANUAL)
   - Columnas core para generación de instancias

2. **`02_alta_prioridad_vistas.sql`**
   - Vistas: `v_estado_recurrentes`, `v_pendientes_futuro`
   - Análisis de tareas recurrentes

3. **`03_media_prioridad_modificaciones.sql`**
   - Funciones: `generar_instancia_recurrente()`, `aplicar_sobreescritura()`
   - Triggers: validaciones automáticas

4. **`04_baja_prioridad_configuracion.sql`**
   - Configuración del sistema
   - Seed data de plantillas ejemplo

**Ejecutar todo:**
```bash
cd /home/azureuser/mateos/scripts/db/migrations/recurrentes
./ejecutar_todas_migraciones.sh
```

**Documentación completa:** Ver `README.md` en esa carpeta (15KB de docs).

---

### migrations/20260130_personas_organizaciones_subproyectos.sql

**Propósito:** Sistema de gestión de personas, organizaciones y sub-proyectos (implementado Ene 2026).

**Tablas creadas (11 tablas):**

1. **`personas`**: Contactos personales y profesionales
   - Datos de contacto, redes sociales, tipo de relación
   - Gestión de contactos estrella, importancia, frecuencia de contacto
   - **Importado:** 2089 contactos desde Google Contacts

2. **`organizaciones`**: Organizaciones con las que se relaciona el usuario
   - Datos institucionales, tipo de organización, naturaleza de relación
   - Gestión de organizaciones estrella

3. **`personas_organizaciones`**: Relación N:M persona-organización
   - Cargos, tipo de vinculación, nivel de decisión

4. **`sub_proyectos`**: Proyectos emergentes (alianzas, colaboraciones)
   - Diferente de proyectos_estrategicos: surgen orgánicamente
   - Vinculación opcional a área_vida y proyecto_estrategico
   - Presupuesto y horas (estimadas, aprobadas, ejecutadas)

5. **`sub_proyectos_organizaciones`**: Organizaciones socias de cada sub-proyecto

6. **`contactos`**: Registro de interacciones (reuniones, llamadas, emails)
   - Tipo y canal de contacto, seguimiento
   - Acuerdos, tareas y compromisos generados (texto libre)

7. **Tablas intermedias** (relaciones N:M):
   - `contactos_personas`
   - `contactos_organizaciones`
   - `contactos_sub_proyectos`
   - `contactos_proyectos_estrategicos`

8. **`personas_proyectos`**: Participación de personas en proyectos

**Ejecutar:**
```bash
docker exec -i transcripcion-postgres psql -U asistente -d asistente_db < scripts/db/migrations/20260130_personas_organizaciones_subproyectos.sql
```

---

## CONVENCIONES SQL

### Naming

**Tablas:**
- Plural, snake_case: `proyectos`, `tareas_recurrentes`
- Prefijos NO usados (NO `tbl_proyectos`)

**Columnas:**
- snake_case: `fecha_inicio`, `area_vida_id`
- Timestamps: `created_at`, `updated_at`
- IDs: `id` (primary key), `[tabla]_id` (foreign key)

**Vistas:**
- Prefijo `v_`: `v_proyectos_activos`, `v_estado_recurrentes`

**Funciones:**
- snake_case, verbo al inicio: `calcular_progreso()`, `generar_instancia()`

**Triggers:**
- Prefijo `trg_`: `trg_validar_estado`, `trg_update_timestamp`

### Tipos de Datos

**IDs:**
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

**Timestamps:**
```sql
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

**Enums:**
```sql
CREATE TYPE estado_kanban AS ENUM (
  'FREEZER', 'BACKLOG', 'WAITING', 'TODO', 'DOING', 'DONE'
);
```

**JSON:**
```sql
patron_recurrencia JSONB NOT NULL
```

---

## REGLAS Y RESTRICCIONES

### Migraciones Manuales

#### ✅ SIEMPRE:
- Comentar propósito de cada migración
- Incluir fecha y autor
- Validar que puede ejecutarse múltiples veces (idempotente)
- Incluir rollback instructions en comentarios

```sql
-- ============================================
-- Migración: Agregar columna estimacion_horas
-- Fecha: 2025-12-26
-- Autor: Claude Code
-- Propósito: Trackear estimaciones de tiempo
-- ============================================

-- Agregar columna (idempotente)
ALTER TABLE tareas
ADD COLUMN IF NOT EXISTS estimacion_horas DECIMAL(5,2);

-- Rollback:
-- ALTER TABLE tareas DROP COLUMN IF EXISTS estimacion_horas;
```

#### ❌ NUNCA:
- Ejecutar sin backup
- Modificar datos sin WHERE clause (UPDATE masivo peligroso)
- Eliminar columnas sin confirmar que código no las usa

### Funciones PL/pgSQL

#### ✅ SIEMPRE:
- Declarar parámetros con tipos explícitos
- Incluir manejo de errores (EXCEPTION block)
- Retornar tipo explícito (RETURNS)
- Documentar con comentarios

```sql
CREATE OR REPLACE FUNCTION calcular_progreso_proyecto(
  p_proyecto_id UUID
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
  v_total INTEGER;
  v_completadas INTEGER;
BEGIN
  -- Contar tareas totales
  SELECT COUNT(*) INTO v_total
  FROM tareas
  WHERE proyecto_id = p_proyecto_id;

  -- Contar completadas
  SELECT COUNT(*) INTO v_completadas
  FROM tareas
  WHERE proyecto_id = p_proyecto_id
    AND estado = 'DONE';

  -- Calcular porcentaje
  IF v_total = 0 THEN
    RETURN 0;
  END IF;

  RETURN (v_completadas::DECIMAL / v_total) * 100;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error calculando progreso: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### Vistas

#### Preferir vistas materializadas para queries pesadas:
```sql
CREATE MATERIALIZED VIEW mv_dashboard_metricas AS
SELECT ...
-- Query compleja con múltiples JOINs

-- Crear índice en vista materializada
CREATE INDEX idx_mv_dashboard_fecha
ON mv_dashboard_metricas(fecha);

-- Refrescar vista (ejecutar diariamente via CRON)
REFRESH MATERIALIZED VIEW mv_dashboard_metricas;
```

---

## NOTAS PARA IA

### ⚠️ PostgreSQL Specific Features

**JSONB (NO JSON):**
```sql
-- ✅ BIEN (indexable, más eficiente)
patron_recurrencia JSONB

-- ❌ MAL (lento, no indexable)
patron_recurrencia JSON
```

**Operators útiles:**
```sql
-- Acceso a campo
patron->'frecuencia'          -- Retorna JSON
patron->>'frecuencia'         -- Retorna texto

-- Containment
patron @> '{"tipo": "SEMANAL"}'  -- TRUE si contiene

-- Exists
patron ? 'frecuencia'         -- TRUE si key existe
```

### ⚠️ Transactions

```sql
-- Todas las migraciones deben ser transaccionales
BEGIN;

-- Cambios...

-- Verificar antes de commit
SELECT COUNT(*) FROM tareas;

COMMIT;
-- o ROLLBACK; si algo falló
```

### ⚠️ Performance

**Indexes:**
```sql
-- Index simple
CREATE INDEX idx_tareas_estado ON tareas(estado);

-- Composite index (orden importa)
CREATE INDEX idx_tareas_proyecto_estado
ON tareas(proyecto_id, estado);

-- Partial index (solo rows que cumplen condición)
CREATE INDEX idx_tareas_activas
ON tareas(proyecto_id)
WHERE estado != 'DONE';

-- JSONB index
CREATE INDEX idx_patron_tipo
ON tarea_recurrente_plantilla
USING GIN (patron_recurrencia);
```

**EXPLAIN ANALYZE:**
```sql
-- Analizar performance de query
EXPLAIN ANALYZE
SELECT * FROM tareas WHERE proyecto_id = '...';
```

---

## TESTING

### Ejecutar Migraciones en Test DB

```bash
# Crear DB de prueba
createdb mateos_test

# Ejecutar migraciones
psql mateos_test -f scripts/db/migrations/recurrentes/01_*.sql
psql mateos_test -f scripts/db/migrations/recurrentes/02_*.sql
# ...

# Verificar
psql mateos_test -c "SELECT * FROM tarea_recurrente_plantilla;"

# Limpiar
dropdb mateos_test
```

---

## PRÓXIMOS PASOS (Planificados)

- [ ] Implementar soft delete (columna `deleted_at`)
- [ ] Agregar auditoría (quién modificó qué, cuándo)
- [ ] Crear funciones para reports automáticos
- [ ] Optimizar queries pesadas con índices
- [ ] Implementar archivado de datos antiguos

---

**Última actualización:** 2026-01-30
**Versión:** 1.1
