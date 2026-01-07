-- ============================================
-- Migration: Create items_estrategicos table
-- Description: Crea tabla de items estratégicos
--              vinculados a subtareas_estrategicas,
--              con deadline y proyecto denormalizado
-- Date: 2026-01-06
-- ============================================

BEGIN;

-- 1. Crear tabla items_estrategicos (idempotente)
CREATE TABLE IF NOT EXISTS items_estrategicos (
  id SERIAL PRIMARY KEY,
  subtarea_estrategica_id INTEGER NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  done BOOLEAN NOT NULL DEFAULT false,
  fecha_done TIMESTAMP,
  tiempo_estimado_minutos INTEGER,
  moscow "TipoMoscow",
  fecha_inicio DATE,
  fecha_fin DATE,
  dead_line DATE,
  proyecto_nombre VARCHAR(200),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Asegurar la FK a subtareas_estrategicas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    WHERE tc.table_name = 'items_estrategicos'
      AND tc.constraint_type = 'FOREIGN KEY'
      AND tc.constraint_name = 'items_estrategicos_subtarea_estrategica_id_fkey'
  ) THEN
    ALTER TABLE items_estrategicos
      ADD CONSTRAINT items_estrategicos_subtarea_estrategica_id_fkey
      FOREIGN KEY (subtarea_estrategica_id)
      REFERENCES subtareas_estrategicas(id)
      ON DELETE CASCADE;
  END IF;
END $$;

-- 3. Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_items_subtarea_id
  ON items_estrategicos(subtarea_estrategica_id);

CREATE INDEX IF NOT EXISTS idx_items_done
  ON items_estrategicos(done);

CREATE INDEX IF NOT EXISTS idx_items_dead_line
  ON items_estrategicos(dead_line);

CREATE INDEX IF NOT EXISTS idx_items_proyecto_nombre
  ON items_estrategicos(proyecto_nombre);

-- 4. Comentarios de documentación
COMMENT ON TABLE items_estrategicos IS 'Items (checklists) de subtareas estrategicas del plan Q1 2026 y futuros planes';
COMMENT ON COLUMN items_estrategicos.subtarea_estrategica_id IS 'FK a subtareas_estrategicas.id';
COMMENT ON COLUMN items_estrategicos.nombre IS 'Descripcion del item estrategico';
COMMENT ON COLUMN items_estrategicos.done IS 'Estado de completitud del item (checkbox)';
COMMENT ON COLUMN items_estrategicos.dead_line IS 'Fecha limite planificada para el item';
COMMENT ON COLUMN items_estrategicos.proyecto_nombre IS 'Nombre denormalizado del proyecto al que pertenece el item';

-- 5. Funcion para auto-poblar proyecto_nombre
CREATE OR REPLACE FUNCTION set_item_proyecto_nombre()
RETURNS TRIGGER AS $$
BEGIN
  SELECT pe.nombre INTO NEW.proyecto_nombre
  FROM subtareas_estrategicas se
  JOIN tareas_estrategicas te ON se.tarea_estrategica_id = te.id
  JOIN proyectos_estrategicos pe ON te.proyecto_id = pe.id
  WHERE se.id = NEW.subtarea_estrategica_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Trigger para proyecto_nombre en INSERT/UPDATE
DROP TRIGGER IF EXISTS trigger_set_item_proyecto_nombre ON items_estrategicos;
CREATE TRIGGER trigger_set_item_proyecto_nombre
  BEFORE INSERT OR UPDATE OF subtarea_estrategica_id
  ON items_estrategicos
  FOR EACH ROW
  EXECUTE FUNCTION set_item_proyecto_nombre();

-- 7. Trigger para mantener updated_at en updates
DROP TRIGGER IF EXISTS set_timestamp_items_estrategicos ON items_estrategicos;
CREATE TRIGGER set_timestamp_items_estrategicos
  BEFORE UPDATE ON items_estrategicos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMIT;
