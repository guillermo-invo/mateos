-- Script mejorado para arreglar los enums faltantes
-- Fecha: 2025-12-04

-- 1. Eliminar el trigger temporalmente
DROP TRIGGER IF EXISTS trigger_calcular_eisenhower ON tareas_estrategicas;

-- 2. Eliminar los defaults que causan problemas
ALTER TABLE tareas_estrategicas ALTER COLUMN estado_kanban DROP DEFAULT;
ALTER TABLE subtareas_estrategicas ALTER COLUMN estado_kanban DROP DEFAULT;

-- 3. Crear los enums faltantes
DO $$ BEGIN
    CREATE TYPE "TipoEstadoKanban" AS ENUM ('freezer', 'backlog', 'waiting', 'todo', 'doing', 'done');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "TipoImpacto" AS ENUM ('alto', 'medio', 'bajo');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "TipoUrgencia" AS ENUM ('alta', 'media', 'baja');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "TipoEisenhower" AS ENUM ('cuadrante_1', 'cuadrante_2', 'cuadrante_3', 'cuadrante_4');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "EstadoProcesamiento" AS ENUM ('PROCESANDO', 'COMPLETADO', 'ERROR');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 4. Limpiar datos inválidos en tareas_estrategicas
UPDATE tareas_estrategicas
SET estado_kanban = 'backlog'
WHERE estado_kanban NOT IN ('freezer', 'backlog', 'waiting', 'todo', 'doing', 'done')
   OR estado_kanban IS NULL;

UPDATE tareas_estrategicas
SET impacto = NULL
WHERE impacto NOT IN ('alto', 'medio', 'bajo')
  AND impacto IS NOT NULL;

UPDATE tareas_estrategicas
SET urgencia = NULL
WHERE urgencia NOT IN ('alta', 'media', 'baja')
  AND urgencia IS NOT NULL;

UPDATE tareas_estrategicas
SET eisenhower = NULL
WHERE eisenhower NOT IN ('cuadrante_1', 'cuadrante_2', 'cuadrante_3', 'cuadrante_4')
  AND eisenhower IS NOT NULL;

-- 5. Convertir columnas a ENUM en tareas_estrategicas
ALTER TABLE tareas_estrategicas
    ALTER COLUMN estado_kanban TYPE "TipoEstadoKanban"
    USING estado_kanban::"TipoEstadoKanban";

ALTER TABLE tareas_estrategicas
    ALTER COLUMN estado_kanban SET DEFAULT 'backlog'::"TipoEstadoKanban";

ALTER TABLE tareas_estrategicas
    ALTER COLUMN impacto TYPE "TipoImpacto"
    USING CASE WHEN impacto IS NULL THEN NULL ELSE impacto::"TipoImpacto" END;

ALTER TABLE tareas_estrategicas
    ALTER COLUMN urgencia TYPE "TipoUrgencia"
    USING CASE WHEN urgencia IS NULL THEN NULL ELSE urgencia::"TipoUrgencia" END;

ALTER TABLE tareas_estrategicas
    ALTER COLUMN eisenhower TYPE "TipoEisenhower"
    USING CASE WHEN eisenhower IS NULL THEN NULL ELSE eisenhower::"TipoEisenhower" END;

-- 6. Limpiar datos inválidos en subtareas_estrategicas
UPDATE subtareas_estrategicas
SET estado_kanban = 'backlog'
WHERE estado_kanban NOT IN ('freezer', 'backlog', 'waiting', 'todo', 'doing', 'done')
   OR estado_kanban IS NULL;

-- 7. Convertir columna en subtareas_estrategicas
ALTER TABLE subtareas_estrategicas
    ALTER COLUMN estado_kanban TYPE "TipoEstadoKanban"
    USING estado_kanban::"TipoEstadoKanban";

ALTER TABLE subtareas_estrategicas
    ALTER COLUMN estado_kanban SET DEFAULT 'backlog'::"TipoEstadoKanban";

-- 8. Recrear el trigger con los tipos correctos
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

CREATE TRIGGER trigger_calcular_eisenhower
  BEFORE INSERT OR UPDATE OF moscow, urgencia, impacto, nivel_riesgo
  ON tareas_estrategicas
  FOR EACH ROW
  EXECUTE FUNCTION calcular_eisenhower();

-- Mensaje de confirmación
SELECT 'Enums creados, columnas convertidas y trigger recreado exitosamente' AS status;
