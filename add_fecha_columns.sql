-- Add fecha_inicio and fecha_fin columns to tareas_estrategicas
ALTER TABLE tareas_estrategicas
ADD COLUMN IF NOT EXISTS fecha_inicio DATE,
ADD COLUMN IF NOT EXISTS fecha_fin DATE;

-- Add fecha_inicio and fecha_fin columns to subtareas
ALTER TABLE subtareas
ADD COLUMN IF NOT EXISTS fecha_inicio DATE,
ADD COLUMN IF NOT EXISTS fecha_fin DATE;
