-- ============================================
-- Migration: Add dead_line columns
-- Description: Agrega columna dead_line a
--              tareas_estrategicas y subtareas_estrategicas
-- Date: 2026-01-06
-- ============================================

BEGIN;

-- 1. Agregar columna dead_line a tareas_estrategicas
ALTER TABLE tareas_estrategicas
  ADD COLUMN IF NOT EXISTS dead_line DATE;

-- 2. Agregar columna dead_line a subtareas_estrategicas
ALTER TABLE subtareas_estrategicas
  ADD COLUMN IF NOT EXISTS dead_line DATE;

-- 3. Índices para facilitar queries por deadline
CREATE INDEX IF NOT EXISTS idx_tareas_estrategicas_dead_line
  ON tareas_estrategicas(dead_line);

CREATE INDEX IF NOT EXISTS idx_subtareas_estrategicas_dead_line
  ON subtareas_estrategicas(dead_line);

-- 4. Comentarios de documentación
COMMENT ON COLUMN tareas_estrategicas.dead_line IS
  'Fecha límite planificada (deadline) para la tarea estratégica';

COMMENT ON COLUMN subtareas_estrategicas.dead_line IS
  'Fecha límite planificada (deadline) para la subtarea estratégica';

COMMIT;
