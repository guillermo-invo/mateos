-- Migración: Renombrar subtareas a subtareas_estrategicas y agregar nuevas columnas

-- 1. Renombrar tabla subtareas a subtareas_estrategicas
ALTER TABLE IF EXISTS subtareas RENAME TO subtareas_estrategicas;

-- 2. Renombrar columna titulo a nombre en subtareas_estrategicas
ALTER TABLE subtareas_estrategicas RENAME COLUMN IF EXISTS titulo TO nombre;

-- 3. Agregar columna estado_kanban (reemplaza completada)
DO $$
BEGIN
  -- Agregar nueva columna estado_kanban
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'subtareas_estrategicas'
                 AND column_name = 'estado_kanban') THEN
    ALTER TABLE subtareas_estrategicas ADD COLUMN estado_kanban VARCHAR(20) DEFAULT 'backlog';
  END IF;

  -- Migrar datos de completada a estado_kanban
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'subtareas_estrategicas'
             AND column_name = 'completada') THEN
    UPDATE subtareas_estrategicas
    SET estado_kanban = CASE
      WHEN completada = true THEN 'done'
      ELSE 'backlog'
    END;

    -- Eliminar columna completada
    ALTER TABLE subtareas_estrategicas DROP COLUMN completada;
  END IF;
END $$;

-- 4. Agregar columna fecha_done
ALTER TABLE subtareas_estrategicas
ADD COLUMN IF NOT EXISTS fecha_done TIMESTAMP;

-- 5. Modificar tareas_estrategicas: agregar nuevas columnas
ALTER TABLE tareas_estrategicas
ADD COLUMN IF NOT EXISTS estado_kanban VARCHAR(20) DEFAULT 'backlog',
ADD COLUMN IF NOT EXISTS fecha_done TIMESTAMP,
ADD COLUMN IF NOT EXISTS impacto VARCHAR(20),
ADD COLUMN IF NOT EXISTS urgencia VARCHAR(20),
ADD COLUMN IF NOT EXISTS eisenhower VARCHAR(30);

-- 6. Eliminar columna estado antigua si existe en tareas_estrategicas
ALTER TABLE tareas_estrategicas DROP COLUMN IF EXISTS estado;

-- 7. Crear índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_subtareas_estado_kanban ON subtareas_estrategicas(estado_kanban);
CREATE INDEX IF NOT EXISTS idx_tareas_estado_kanban ON tareas_estrategicas(estado_kanban);
CREATE INDEX IF NOT EXISTS idx_tareas_eisenhower ON tareas_estrategicas(eisenhower);

-- 8. Crear función para calcular Eisenhower automáticamente
CREATE OR REPLACE FUNCTION calcular_eisenhower()
RETURNS TRIGGER AS $$
BEGIN
  -- Cuadrante 1: urgente + importante
  IF (NEW.moscow = 'must' AND NEW.urgencia = 'alta') OR
     (NEW.nivel_riesgo IN ('alto', 'critico')) OR
     (NEW.impacto = 'alto' AND NEW.urgencia = 'alta') THEN
    NEW.eisenhower := 'cuadrante_1';

  -- Cuadrante 2: no urgente + importante
  ELSIF (NEW.moscow IN ('must', 'should') AND NEW.urgencia IN ('media', 'baja')) OR
        (NEW.impacto = 'alto' AND NEW.nivel_riesgo IN ('bajo', 'medio')) THEN
    NEW.eisenhower := 'cuadrante_2';

  -- Cuadrante 3: urgente + no importante
  ELSIF (NEW.moscow = 'could' AND NEW.urgencia = 'alta') OR
        (NEW.impacto = 'bajo' AND NEW.urgencia = 'alta') THEN
    NEW.eisenhower := 'cuadrante_3';

  -- Cuadrante 4: no urgente + no importante
  ELSIF (NEW.moscow IN ('could', 'wont')) OR
        (NEW.impacto = 'bajo' AND NEW.urgencia = 'baja') THEN
    NEW.eisenhower := 'cuadrante_4';

  ELSE
    -- Default: cuadrante 2 (importante pero no urgente)
    NEW.eisenhower := 'cuadrante_2';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Crear trigger para calcular eisenhower automáticamente
DROP TRIGGER IF EXISTS trigger_calcular_eisenhower ON tareas_estrategicas;
CREATE TRIGGER trigger_calcular_eisenhower
  BEFORE INSERT OR UPDATE OF moscow, urgencia, impacto, nivel_riesgo
  ON tareas_estrategicas
  FOR EACH ROW
  EXECUTE FUNCTION calcular_eisenhower();

-- 10. Actualizar eisenhower para tareas existentes
UPDATE tareas_estrategicas SET updated_at = NOW() WHERE id IS NOT NULL;

-- 11. Comentarios para documentación
COMMENT ON COLUMN tareas_estrategicas.estado_kanban IS 'Estado en el tablero Kanban: freezer, backlog, waiting, todo, doing, done';
COMMENT ON COLUMN tareas_estrategicas.eisenhower IS 'Matriz de Eisenhower calculada automáticamente: cuadrante_1 (urgente+importante), cuadrante_2 (importante), cuadrante_3 (urgente), cuadrante_4 (no urgente ni importante)';
COMMENT ON COLUMN tareas_estrategicas.fecha_done IS 'Timestamp cuando la tarea pasó a estado done';
COMMENT ON COLUMN subtareas_estrategicas.estado_kanban IS 'Estado en el tablero Kanban de la subtarea';
COMMENT ON COLUMN subtareas_estrategicas.fecha_done IS 'Timestamp cuando la subtarea pasó a estado done';
