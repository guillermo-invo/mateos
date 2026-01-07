-- Create missing database views for dashboard

-- Vista Matarife: Identifica tareas que deberían eliminarse o revisarse
CREATE OR REPLACE VIEW vista_matarife AS
SELECT
  t.id as tarea_id,
  t.nombre as tarea,
  p.nombre as proyecto,
  t.estado_kanban,
  t.moscow,
  t.nivel_riesgo,
  t.prioridad_velocidad_perfeccion,
  t.updated_at,
  CASE
    WHEN t.prioridad_velocidad_perfeccion = 'velocidad'
         AND t.moscow IN ('could', 'wont')
    THEN 'ELIMINAR'
    WHEN t.prioridad_velocidad_perfeccion = 'velocidad'
         AND t.nivel_riesgo IN ('alto', 'critico')
    THEN 'REVISAR_RIESGO'
    WHEN t.estado_kanban IN ('freezer', 'waiting')
         AND t.updated_at < NOW() - INTERVAL '7 days'
    THEN 'DESBLOQUEAR_O_ELIMINAR'
    ELSE 'OK'
  END as veredicto
FROM tareas_estrategicas t
JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
WHERE p.estado IN ('en_curso', 'planificacion');

-- Vista Proyectos Activos: Resumen de proyectos con métricas
CREATE OR REPLACE VIEW vista_proyectos_activos AS
SELECT
  p.id,
  p.nombre,
  p.estado,
  CAST(p.score_alineacion AS DOUBLE PRECISION) as score_alineacion,
  CAST(p.score_motivacional AS DOUBLE PRECISION) as score_motivacional,
  CAST(p.prioridad_global AS DOUBLE PRECISION) as prioridad_global,
  CAST(COUNT(DISTINCT t.id) FILTER (WHERE t.estado_kanban != 'done') AS INTEGER) as tareas_pendientes,
  CAST(COUNT(DISTINCT t.id) AS INTEGER) as total_tareas,
  CAST(COALESCE(
    ROUND(
      COUNT(DISTINCT s.id) FILTER (WHERE s.fecha_done IS NOT NULL) * 100.0 /
      NULLIF(COUNT(DISTINCT s.id), 0)
    , 1),
    0
  ) AS DOUBLE PRECISION) as porcentaje_completado,
  CAST(COALESCE(
    SUM(s.tiempo_estimado_minutos) FILTER (WHERE s.fecha_done IS NULL) / 60.0,
    0
  ) AS DOUBLE PRECISION) as horas_restantes
FROM proyectos_estrategicos p
LEFT JOIN tareas_estrategicas t ON t.proyecto_id = p.id
LEFT JOIN subtareas_estrategicas s ON s.tarea_estrategica_id = t.id
WHERE p.estado IN ('en_curso', 'planificacion')
GROUP BY p.id, p.nombre, p.estado, p.score_alineacion, p.score_motivacional, p.prioridad_global;
