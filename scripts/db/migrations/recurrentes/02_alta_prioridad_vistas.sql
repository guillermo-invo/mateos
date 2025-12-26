-- ============================================
-- ALTA PRIORIDAD: Vistas de Disponibilidad
-- ============================================
-- Autor: Sistema Mateos
-- Fecha: 2025-12-24
-- Descripción: Vistas para calcular carga de tareas recurrentes
--              y disponibilidad real para proyectos
-- ============================================

BEGIN;

-- ============================================
-- 1. Vista: carga_semanal_recurrentes
-- ============================================
-- Calcula cuántas horas por semana ocupan las tareas recurrentes
-- agrupadas por día de la semana

CREATE OR REPLACE VIEW carga_semanal_recurrentes AS
SELECT
  EXTRACT(DOW FROM i.fecha_programada) AS dia_semana_dow, -- 0=domingo, 1=lunes, ..., 6=sábado
  -- Convertir DOW (0-6, dom-sáb) a nuestro estándar (1-7, lun-dom)
  CASE
    WHEN EXTRACT(DOW FROM i.fecha_programada) = 0 THEN 7 -- domingo
    ELSE EXTRACT(DOW FROM i.fecha_programada)::INTEGER
  END AS dia_semana,
  COUNT(*) AS cantidad_tareas,
  SUM(t.duracion_estimada_minutos) / 60.0 AS horas_totales,
  SUM(CASE WHEN t.criticidad = 'must' THEN t.duracion_estimada_minutos ELSE 0 END) / 60.0 AS horas_must,
  SUM(CASE WHEN t.criticidad = 'should' THEN t.duracion_estimada_minutos ELSE 0 END) / 60.0 AS horas_should,
  SUM(CASE WHEN t.criticidad = 'could' THEN t.duracion_estimada_minutos ELSE 0 END) / 60.0 AS horas_could,
  SUM(CASE WHEN t.energia_requerida = 'alta' THEN t.duracion_estimada_minutos ELSE 0 END) / 60.0 AS horas_energia_alta
FROM instancias_tareas_recurrentes i
JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id
WHERE
  i.fecha_programada >= CURRENT_DATE
  AND i.fecha_programada < CURRENT_DATE + INTERVAL '7 days'
  AND i.saltada = false
  AND t.activa = true
GROUP BY dia_semana, dia_semana_dow
ORDER BY dia_semana;

COMMENT ON VIEW carga_semanal_recurrentes IS 'Carga horaria de tareas recurrentes por día de la semana (próximos 7 días)';


-- ============================================
-- 2. Vista: disponibilidad_real_semanal
-- ============================================
-- Combina disponibilidad teórica con tareas recurrentes
-- para calcular tiempo REAL disponible para proyectos

CREATE OR REPLACE VIEW disponibilidad_real_semanal AS
SELECT
  d.dia_semana,
  CASE d.dia_semana
    WHEN 1 THEN 'Lunes'
    WHEN 2 THEN 'Martes'
    WHEN 3 THEN 'Miércoles'
    WHEN 4 THEN 'Jueves'
    WHEN 5 THEN 'Viernes'
    WHEN 6 THEN 'Sábado'
    WHEN 7 THEN 'Domingo'
  END AS dia_nombre,
  d.horas_disponibles AS horas_teoricas,
  COALESCE(r.horas_totales, 0) AS horas_recurrentes,
  COALESCE(r.horas_must, 0) AS horas_recurrentes_must,
  COALESCE(r.horas_should, 0) AS horas_recurrentes_should,
  COALESCE(r.cantidad_tareas, 0) AS num_tareas_recurrentes,
  d.horas_disponibles - COALESCE(r.horas_totales, 0) AS horas_disponibles_proyectos,
  d.momento_optimo,
  d.notas,
  -- Indicador de salud del día
  CASE
    WHEN d.horas_disponibles - COALESCE(r.horas_totales, 0) < 0 THEN 'SOBRECARGA'
    WHEN d.horas_disponibles - COALESCE(r.horas_totales, 0) < 1 THEN 'SATURADO'
    WHEN d.horas_disponibles - COALESCE(r.horas_totales, 0) < 2 THEN 'JUSTO'
    ELSE 'HOLGADO'
  END AS estado_carga,
  -- Porcentaje de tiempo ocupado por recurrentes
  ROUND(
    (COALESCE(r.horas_totales, 0) / NULLIF(d.horas_disponibles, 0) * 100)::NUMERIC,
    1
  ) AS porcentaje_ocupado
FROM disponibilidad_semanal d
LEFT JOIN carga_semanal_recurrentes r ON d.dia_semana = r.dia_semana
ORDER BY d.dia_semana;

COMMENT ON VIEW disponibilidad_real_semanal IS 'Disponibilidad real por día (horas teóricas - horas recurrentes)';


-- ============================================
-- 3. Vista: resumen_disponibilidad_total
-- ============================================
-- Resumen total de la semana

CREATE OR REPLACE VIEW resumen_disponibilidad_total AS
SELECT
  SUM(horas_teoricas) AS total_horas_teoricas_semana,
  SUM(horas_recurrentes) AS total_horas_recurrentes_semana,
  SUM(horas_disponibles_proyectos) AS total_horas_disponibles_proyectos,
  ROUND(
    (SUM(horas_recurrentes) / NULLIF(SUM(horas_teoricas), 0) * 100)::NUMERIC,
    1
  ) AS porcentaje_tiempo_recurrentes,
  COUNT(*) AS dias_configurados,
  COUNT(CASE WHEN estado_carga IN ('SOBRECARGA', 'SATURADO') THEN 1 END) AS dias_problematicos
FROM disponibilidad_real_semanal;

COMMENT ON VIEW resumen_disponibilidad_total IS 'Resumen semanal total de disponibilidad de tiempo';


-- ============================================
-- 4. Vista: instancias_proxima_semana
-- ============================================
-- Todas las instancias de tareas recurrentes de la próxima semana

CREATE OR REPLACE VIEW instancias_proxima_semana AS
SELECT
  i.id,
  i.fecha_programada,
  EXTRACT(DOW FROM i.fecha_programada) AS dow,
  CASE
    WHEN EXTRACT(DOW FROM i.fecha_programada) = 0 THEN 7
    ELSE EXTRACT(DOW FROM i.fecha_programada)::INTEGER
  END AS dia_semana,
  t.nombre AS tarea_nombre,
  t.tipo,
  t.criticidad,
  t.duracion_estimada_minutos,
  t.energia_requerida,
  t.contexto_necesario,
  i.hora_inicio,
  i.hora_fin,
  i.completada,
  i.saltada,
  i.google_calendar_event_id,
  a.nombre AS area_nombre,
  p.nombre AS proyecto_nombre
FROM instancias_tareas_recurrentes i
JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id
LEFT JOIN areas_vida a ON t.area_id = a.id
LEFT JOIN proyectos_estrategicos p ON t.proyecto_estrategico_id = p.id
WHERE
  i.fecha_programada >= CURRENT_DATE
  AND i.fecha_programada < CURRENT_DATE + INTERVAL '7 days'
  AND t.activa = true
ORDER BY i.fecha_programada, i.hora_inicio NULLS LAST, t.criticidad DESC;

COMMENT ON VIEW instancias_proxima_semana IS 'Instancias de tareas recurrentes programadas para la próxima semana';


-- ============================================
-- 5. Vista: tareas_recurrentes_resumen
-- ============================================
-- Resumen de todas las tareas recurrentes activas

CREATE OR REPLACE VIEW tareas_recurrentes_resumen AS
SELECT
  t.id,
  t.nombre,
  t.tipo,
  t.criticidad,
  t.duracion_estimada_minutos,
  t.energia_requerida,
  t.contexto_necesario,
  t.patron_recurrencia->>'tipo' AS tipo_recurrencia,
  a.nombre AS area_nombre,
  p.nombre AS proyecto_nombre,
  -- Contar instancias generadas
  COUNT(i.id) AS instancias_generadas,
  COUNT(CASE WHEN i.completada THEN 1 END) AS instancias_completadas,
  COUNT(CASE WHEN i.saltada THEN 1 END) AS instancias_saltadas,
  -- Tasa de completitud
  ROUND(
    (COUNT(CASE WHEN i.completada THEN 1 END)::NUMERIC /
     NULLIF(COUNT(i.id), 0) * 100),
    1
  ) AS tasa_completitud
FROM tareas_recurrentes t
LEFT JOIN areas_vida a ON t.area_id = a.id
LEFT JOIN proyectos_estrategicos p ON t.proyecto_estrategico_id = p.id
LEFT JOIN instancias_tareas_recurrentes i ON i.tarea_recurrente_id = t.id
  AND i.fecha_programada >= CURRENT_DATE - INTERVAL '30 days'
WHERE t.activa = true
GROUP BY t.id, t.nombre, t.tipo, t.criticidad, t.duracion_estimada_minutos,
         t.energia_requerida, t.contexto_necesario, t.patron_recurrencia,
         a.nombre, p.nombre
ORDER BY t.criticidad DESC, t.nombre;

COMMENT ON VIEW tareas_recurrentes_resumen IS 'Resumen de tareas recurrentes con métricas de completitud (últimos 30 días)';

COMMIT;

-- ============================================
-- Verificación
-- ============================================
-- Para verificar que las vistas se crearon correctamente:
--
-- SELECT table_name FROM information_schema.views
-- WHERE table_schema = 'public'
-- AND table_name LIKE '%disponibilidad%' OR table_name LIKE '%recurrentes%';
--
-- -- Ver disponibilidad real
-- SELECT * FROM disponibilidad_real_semanal;
--
-- -- Ver resumen total
-- SELECT * FROM resumen_disponibilidad_total;
