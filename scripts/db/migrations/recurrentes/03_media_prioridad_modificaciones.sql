-- ============================================
-- MEDIA PRIORIDAD: Modificaciones y Extensiones
-- ============================================
-- Autor: Sistema Mateos
-- Fecha: 2025-12-24
-- Descripción: Modificaciones a tareas_estrategicas y nueva tabla
--              bloques_tiempo_planificados para integración con Google Calendar
-- ============================================

BEGIN;

-- ============================================
-- 1. Modificar tabla: tareas_estrategicas
-- ============================================
-- Agregar campos para mejor priorización y planificación

-- Campo: energía requerida
ALTER TABLE tareas_estrategicas
  ADD COLUMN IF NOT EXISTS energia_requerida VARCHAR(20)
    CHECK (energia_requerida IN ('baja', 'media', 'alta'));

-- Campo: contexto necesario
ALTER TABLE tareas_estrategicas
  ADD COLUMN IF NOT EXISTS contexto_necesario VARCHAR(50)
    CHECK (contexto_necesario IN ('casa', 'oficina', 'anywhere', 'movil'));

-- Campo: duración real en horas (para aprender)
ALTER TABLE tareas_estrategicas
  ADD COLUMN IF NOT EXISTS duracion_real_horas DECIMAL(5,2)
    CHECK (duracion_real_horas >= 0);

-- Campo: bloqueada por (descripción de bloqueo)
ALTER TABLE tareas_estrategicas
  ADD COLUMN IF NOT EXISTS bloqueada_por TEXT;

-- Campo: fecha estimada de desbloqueo
ALTER TABLE tareas_estrategicas
  ADD COLUMN IF NOT EXISTS fecha_estimada_desbloqueo DATE;

-- Crear índices para los nuevos campos
CREATE INDEX IF NOT EXISTS idx_tareas_estrategicas_energia
  ON tareas_estrategicas(energia_requerida);

CREATE INDEX IF NOT EXISTS idx_tareas_estrategicas_contexto
  ON tareas_estrategicas(contexto_necesario);

CREATE INDEX IF NOT EXISTS idx_tareas_estrategicas_bloqueada
  ON tareas_estrategicas(estado_kanban) WHERE bloqueada_por IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tareas_estrategicas_fecha_desbloqueo
  ON tareas_estrategicas(fecha_estimada_desbloqueo) WHERE fecha_estimada_desbloqueo IS NOT NULL;

-- Comentarios
COMMENT ON COLUMN tareas_estrategicas.energia_requerida IS 'Nivel de energía mental/física necesaria';
COMMENT ON COLUMN tareas_estrategicas.contexto_necesario IS 'Dónde se puede realizar la tarea';
COMMENT ON COLUMN tareas_estrategicas.duracion_real_horas IS 'Tiempo real que tomó (para mejorar estimaciones)';
COMMENT ON COLUMN tareas_estrategicas.bloqueada_por IS 'Descripción de qué está bloqueando esta tarea';
COMMENT ON COLUMN tareas_estrategicas.fecha_estimada_desbloqueo IS 'Cuándo se espera que se desbloquee';


-- ============================================
-- 2. Nueva tabla: bloques_tiempo_planificados
-- ============================================
-- Para planificar la semana y bloquear tiempo en Google Calendar

CREATE TABLE IF NOT EXISTS bloques_tiempo_planificados (
  id SERIAL PRIMARY KEY,
  fecha DATE NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,

  -- Qué se va a hacer
  tipo_bloque VARCHAR(50) NOT NULL
    CHECK (tipo_bloque IN (
      'tarea_estrategica',
      'tarea_recurrente',
      'proyecto_foco',
      'buffer',
      'reunion',
      'compromiso',
      'otro'
    )),

  -- Referencias opcionales
  tarea_estrategica_id INTEGER REFERENCES tareas_estrategicas(id) ON DELETE SET NULL,
  tarea_recurrente_id INTEGER REFERENCES tareas_recurrentes(id) ON DELETE SET NULL,
  proyecto_estrategico_id INTEGER REFERENCES proyectos_estrategicos(id) ON DELETE SET NULL,
  area_vida_id INTEGER REFERENCES areas_vida(id) ON DELETE SET NULL,

  -- Descripción libre (si no está asociado a nada específico)
  descripcion_libre TEXT,
  notas TEXT,

  -- Sincronización con Google Calendar
  google_calendar_event_id VARCHAR(255),
  sincronizado_calendar BOOLEAN DEFAULT false,
  ultimo_sync TIMESTAMP,

  -- Estado
  completado BOOLEAN DEFAULT false,
  fecha_completado TIMESTAMP,

  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Validación: debe tener al menos una referencia o descripción
  CONSTRAINT check_tiene_contenido CHECK (
    tarea_estrategica_id IS NOT NULL OR
    tarea_recurrente_id IS NOT NULL OR
    proyecto_estrategico_id IS NOT NULL OR
    area_vida_id IS NOT NULL OR
    descripcion_libre IS NOT NULL
  ),

  -- Validación: hora de fin debe ser posterior a hora de inicio
  CONSTRAINT check_hora_valida CHECK (hora_fin > hora_inicio)
);

-- Índices para optimizar consultas
CREATE INDEX idx_bloques_fecha ON bloques_tiempo_planificados(fecha);
CREATE INDEX idx_bloques_tipo ON bloques_tiempo_planificados(tipo_bloque);
CREATE INDEX idx_bloques_tarea_estrategica ON bloques_tiempo_planificados(tarea_estrategica_id);
CREATE INDEX idx_bloques_proyecto ON bloques_tiempo_planificados(proyecto_estrategico_id);
CREATE INDEX idx_bloques_area ON bloques_tiempo_planificados(area_vida_id);
CREATE INDEX idx_bloques_google_calendar ON bloques_tiempo_planificados(google_calendar_event_id);
CREATE INDEX idx_bloques_sincronizado ON bloques_tiempo_planificados(sincronizado_calendar);
CREATE INDEX idx_bloques_completado ON bloques_tiempo_planificados(completado);

-- Índice compuesto para consultas de planificación semanal
CREATE INDEX idx_bloques_fecha_tipo ON bloques_tiempo_planificados(fecha, tipo_bloque);

-- Comentarios
COMMENT ON TABLE bloques_tiempo_planificados IS 'Bloques de tiempo planificados para la semana (chunks en Google Calendar)';
COMMENT ON COLUMN bloques_tiempo_planificados.tipo_bloque IS 'Tipo de actividad planificada en este bloque';
COMMENT ON COLUMN bloques_tiempo_planificados.descripcion_libre IS 'Descripción cuando no está vinculado a entidad específica';
COMMENT ON COLUMN bloques_tiempo_planificados.google_calendar_event_id IS 'ID del evento en Google Calendar';
COMMENT ON COLUMN bloques_tiempo_planificados.sincronizado_calendar IS 'Si el bloque está sincronizado con Google Calendar';


-- ============================================
-- 3. Trigger para actualizar updated_at
-- ============================================

CREATE TRIGGER update_bloques_tiempo_updated_at BEFORE UPDATE ON bloques_tiempo_planificados
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- 4. Vista: bloques_proxima_semana
-- ============================================
-- Ver todos los bloques planificados para la próxima semana

CREATE OR REPLACE VIEW bloques_proxima_semana AS
SELECT
  b.id,
  b.fecha,
  CASE
    WHEN EXTRACT(DOW FROM b.fecha) = 0 THEN 7
    ELSE EXTRACT(DOW FROM b.fecha)::INTEGER
  END AS dia_semana,
  b.hora_inicio,
  b.hora_fin,
  EXTRACT(EPOCH FROM (b.hora_fin - b.hora_inicio)) / 3600 AS duracion_horas,
  b.tipo_bloque,
  -- Descripción del bloque
  COALESCE(
    te.nombre,
    tr.nombre,
    p.nombre,
    a.nombre,
    b.descripcion_libre
  ) AS contenido,
  -- Referencias
  te.nombre AS tarea_estrategica,
  tr.nombre AS tarea_recurrente,
  p.nombre AS proyecto,
  a.nombre AS area,
  -- Estado
  b.completado,
  b.sincronizado_calendar,
  b.google_calendar_event_id,
  b.notas
FROM bloques_tiempo_planificados b
LEFT JOIN tareas_estrategicas te ON b.tarea_estrategica_id = te.id
LEFT JOIN tareas_recurrentes tr ON b.tarea_recurrente_id = tr.id
LEFT JOIN proyectos_estrategicos p ON b.proyecto_estrategico_id = p.id
LEFT JOIN areas_vida a ON b.area_vida_id = a.id
WHERE
  b.fecha >= CURRENT_DATE
  AND b.fecha < CURRENT_DATE + INTERVAL '7 days'
ORDER BY b.fecha, b.hora_inicio;

COMMENT ON VIEW bloques_proxima_semana IS 'Bloques de tiempo planificados para la próxima semana';


-- ============================================
-- 5. Vista: resumen_bloques_por_area
-- ============================================
-- Resumen de tiempo planificado por área de vida

CREATE OR REPLACE VIEW resumen_bloques_por_area AS
SELECT
  a.nombre AS area,
  COUNT(b.id) AS num_bloques,
  SUM(EXTRACT(EPOCH FROM (b.hora_fin - b.hora_inicio)) / 3600) AS horas_totales,
  SUM(CASE WHEN b.completado THEN EXTRACT(EPOCH FROM (b.hora_fin - b.hora_inicio)) / 3600 ELSE 0 END) AS horas_completadas,
  COUNT(CASE WHEN b.sincronizado_calendar THEN 1 END) AS bloques_sincronizados,
  MIN(b.fecha) AS primera_fecha,
  MAX(b.fecha) AS ultima_fecha
FROM bloques_tiempo_planificados b
JOIN areas_vida a ON b.area_vida_id = a.id
WHERE b.fecha >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY a.id, a.nombre
ORDER BY horas_totales DESC;

COMMENT ON VIEW resumen_bloques_por_area IS 'Resumen de tiempo planificado por área de vida (última semana)';


-- ============================================
-- 6. Función: calcular_tiempo_disponible_dia
-- ============================================
-- Calcula cuánto tiempo queda disponible en un día específico

CREATE OR REPLACE FUNCTION calcular_tiempo_disponible_dia(fecha_param DATE)
RETURNS TABLE (
  fecha DATE,
  dia_semana INTEGER,
  horas_disponibles NUMERIC,
  horas_recurrentes NUMERIC,
  horas_bloques_planificados NUMERIC,
  horas_libres NUMERIC,
  estado VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  WITH dia AS (
    SELECT CASE
      WHEN EXTRACT(DOW FROM fecha_param) = 0 THEN 7
      ELSE EXTRACT(DOW FROM fecha_param)::INTEGER
    END AS ds
  ),
  disponible AS (
    SELECT d.horas_disponibles
    FROM disponibilidad_semanal d, dia
    WHERE d.dia_semana = dia.ds
  ),
  recurrentes AS (
    SELECT COALESCE(SUM(t.duracion_estimada_minutos) / 60.0, 0) AS horas
    FROM instancias_tareas_recurrentes i
    JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id
    WHERE i.fecha_programada = fecha_param
      AND i.saltada = false
      AND t.activa = true
  ),
  bloques AS (
    SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (hora_fin - hora_inicio)) / 3600), 0) AS horas
    FROM bloques_tiempo_planificados
    WHERE fecha = fecha_param
  )
  SELECT
    fecha_param,
    dia.ds,
    disponible.horas_disponibles::NUMERIC,
    recurrentes.horas::NUMERIC,
    bloques.horas::NUMERIC,
    (disponible.horas_disponibles - recurrentes.horas - bloques.horas)::NUMERIC AS horas_libres,
    CASE
      WHEN (disponible.horas_disponibles - recurrentes.horas - bloques.horas) < 0 THEN 'SOBRECARGA'
      WHEN (disponible.horas_disponibles - recurrentes.horas - bloques.horas) < 1 THEN 'SATURADO'
      WHEN (disponible.horas_disponibles - recurrentes.horas - bloques.horas) < 2 THEN 'JUSTO'
      ELSE 'HOLGADO'
    END AS estado
  FROM dia, disponible, recurrentes, bloques;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calcular_tiempo_disponible_dia IS 'Calcula tiempo disponible en un día considerando recurrentes y bloques planificados';

COMMIT;

-- ============================================
-- Verificación
-- ============================================
-- Para verificar que todo se modificó correctamente:
--
-- -- Ver nuevas columnas en tareas_estrategicas
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'tareas_estrategicas'
-- AND column_name IN ('energia_requerida', 'contexto_necesario', 'duracion_real_horas', 'bloqueada_por', 'fecha_estimada_desbloqueo');
--
-- -- Ver tabla de bloques
-- SELECT * FROM bloques_tiempo_planificados LIMIT 5;
--
-- -- Probar función
-- SELECT * FROM calcular_tiempo_disponible_dia(CURRENT_DATE);
