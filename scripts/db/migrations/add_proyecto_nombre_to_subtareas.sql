-- Migration: Add proyecto_nombre to subtareas_estrategicas
-- Description: Adds denormalized project name column for faster queries
-- Date: 2025-12-27

-- 1. Add the new column
ALTER TABLE subtareas_estrategicas
  ADD COLUMN IF NOT EXISTS proyecto_nombre VARCHAR(200);

-- 2. Populate the column with existing data by joining through tareas_estrategicas
UPDATE subtareas_estrategicas se
SET proyecto_nombre = pe.nombre
FROM tareas_estrategicas te
JOIN proyectos_estrategicos pe ON te.proyecto_id = pe.id
WHERE se.tarea_estrategica_id = te.id;

-- 3. Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_subtareas_proyecto_nombre
  ON subtareas_estrategicas(proyecto_nombre);

-- 4. Add comment to document the column
COMMENT ON COLUMN subtareas_estrategicas.proyecto_nombre IS
  'Denormalized project name for easier querying. Updated via trigger when project name changes.';

-- 5. Create trigger function to auto-update proyecto_nombre when project name changes
CREATE OR REPLACE FUNCTION update_subtareas_proyecto_nombre()
RETURNS TRIGGER AS $$
BEGIN
  -- Update all subtareas when a project name changes
  UPDATE subtareas_estrategicas se
  SET proyecto_nombre = NEW.nombre
  FROM tareas_estrategicas te
  WHERE se.tarea_estrategica_id = te.id
    AND te.proyecto_id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger on proyectos_estrategicos to keep names in sync
DROP TRIGGER IF EXISTS trigger_update_subtareas_proyecto_nombre ON proyectos_estrategicos;
CREATE TRIGGER trigger_update_subtareas_proyecto_nombre
  AFTER UPDATE OF nombre
  ON proyectos_estrategicos
  FOR EACH ROW
  WHEN (OLD.nombre IS DISTINCT FROM NEW.nombre)
  EXECUTE FUNCTION update_subtareas_proyecto_nombre();

-- 7. Create trigger function to auto-populate proyecto_nombre on INSERT
CREATE OR REPLACE FUNCTION set_subtarea_proyecto_nombre()
RETURNS TRIGGER AS $$
BEGIN
  -- Set proyecto_nombre when creating new subtarea
  SELECT pe.nombre INTO NEW.proyecto_nombre
  FROM tareas_estrategicas te
  JOIN proyectos_estrategicos pe ON te.proyecto_id = pe.id
  WHERE te.id = NEW.tarea_estrategica_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger on subtareas_estrategicas to auto-populate on INSERT
DROP TRIGGER IF EXISTS trigger_set_subtarea_proyecto_nombre ON subtareas_estrategicas;
CREATE TRIGGER trigger_set_subtarea_proyecto_nombre
  BEFORE INSERT
  ON subtareas_estrategicas
  FOR EACH ROW
  EXECUTE FUNCTION set_subtarea_proyecto_nombre();
