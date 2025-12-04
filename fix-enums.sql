-- Script para arreglar los enums faltantes en la base de datos
-- Fecha: 2025-12-04

-- 1. Crear los enums faltantes
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

-- 2. Convertir las columnas VARCHAR a ENUM en tareas_estrategicas
-- Primero verificar y limpiar datos inválidos si existen
UPDATE tareas_estrategicas
SET estado_kanban = 'backlog'
WHERE estado_kanban NOT IN ('freezer', 'backlog', 'waiting', 'todo', 'doing', 'done')
   OR estado_kanban IS NULL;

-- Convertir estado_kanban a enum
ALTER TABLE tareas_estrategicas
    ALTER COLUMN estado_kanban TYPE "TipoEstadoKanban"
    USING estado_kanban::"TipoEstadoKanban";

ALTER TABLE tareas_estrategicas
    ALTER COLUMN estado_kanban SET DEFAULT 'backlog'::"TipoEstadoKanban";

-- Convertir impacto a enum (puede ser NULL)
UPDATE tareas_estrategicas
SET impacto = NULL
WHERE impacto NOT IN ('alto', 'medio', 'bajo')
  AND impacto IS NOT NULL;

ALTER TABLE tareas_estrategicas
    ALTER COLUMN impacto TYPE "TipoImpacto"
    USING CASE WHEN impacto IS NULL THEN NULL ELSE impacto::"TipoImpacto" END;

-- Convertir urgencia a enum (puede ser NULL)
UPDATE tareas_estrategicas
SET urgencia = NULL
WHERE urgencia NOT IN ('alta', 'media', 'baja')
  AND urgencia IS NOT NULL;

ALTER TABLE tareas_estrategicas
    ALTER COLUMN urgencia TYPE "TipoUrgencia"
    USING CASE WHEN urgencia IS NULL THEN NULL ELSE urgencia::"TipoUrgencia" END;

-- Convertir eisenhower a enum (puede ser NULL)
UPDATE tareas_estrategicas
SET eisenhower = NULL
WHERE eisenhower NOT IN ('cuadrante_1', 'cuadrante_2', 'cuadrante_3', 'cuadrante_4')
  AND eisenhower IS NOT NULL;

ALTER TABLE tareas_estrategicas
    ALTER COLUMN eisenhower TYPE "TipoEisenhower"
    USING CASE WHEN eisenhower IS NULL THEN NULL ELSE eisenhower::"TipoEisenhower" END;

-- 3. Verificar subtareas_estrategicas
-- Convertir estado_kanban en subtareas_estrategicas
UPDATE subtareas_estrategicas
SET estado_kanban = 'backlog'
WHERE estado_kanban NOT IN ('freezer', 'backlog', 'waiting', 'todo', 'doing', 'done')
   OR estado_kanban IS NULL;

ALTER TABLE subtareas_estrategicas
    ALTER COLUMN estado_kanban TYPE "TipoEstadoKanban"
    USING estado_kanban::"TipoEstadoKanban";

ALTER TABLE subtareas_estrategicas
    ALTER COLUMN estado_kanban SET DEFAULT 'backlog'::"TipoEstadoKanban";

-- Mensaje de confirmación
SELECT 'Enums creados y columnas convertidas exitosamente' AS status;
