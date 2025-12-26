-- ============================================
-- QUERIES ÚTILES: Sistema de Gestión de Tiempo
-- ============================================
-- Autor: Sistema Mateos
-- Fecha: 2025-12-24
-- Descripción: Colección de queries útiles para análisis,
--              planificación y monitoreo del sistema
-- ============================================

-- ============================================
-- PARTE 1: Detección de Sobrecarga y Salud Semanal
-- ============================================

-- 1.1 Detectar sobrecarga semanal día por día
CREATE OR REPLACE VIEW vista_sobrecarga_semanal AS
SELECT
  fecha,
  dia_semana,
  dia_nombre,
  horas_disponibles_proyectos AS horas_disponibles,
  estado_carga,
  porcentaje_ocupado,
  CASE
    WHEN estado_carga = 'SOBRECARGA' THEN '🔴 CRÍTICO'
    WHEN estado_carga = 'SATURADO' THEN '🟡 ALERTA'
    WHEN estado_carga = 'JUSTO' THEN '🟢 OK'
    ELSE '✅ BIEN'
  END AS indicador
FROM (
  SELECT
    CURRENT_DATE + (dia_semana - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER) AS fecha,
    d.*
  FROM disponibilidad_real_semanal d
) AS subquery
ORDER BY fecha;

COMMENT ON VIEW vista_sobrecarga_semanal IS 'Vista semanal con indicadores de sobrecarga por día';


-- 1.2 Resumen de salud de la semana actual
CREATE OR REPLACE VIEW resumen_salud_semana_actual AS
SELECT
  COUNT(*) AS total_dias,
  COUNT(CASE WHEN estado_carga = 'SOBRECARGA' THEN 1 END) AS dias_sobrecarga,
  COUNT(CASE WHEN estado_carga = 'SATURADO' THEN 1 END) AS dias_saturados,
  COUNT(CASE WHEN estado_carga IN ('JUSTO', 'HOLGADO') THEN 1 END) AS dias_saludables,
  SUM(horas_disponibles_proyectos) AS total_horas_proyectos,
  AVG(porcentaje_ocupado) AS porcentaje_ocupado_promedio,
  CASE
    WHEN COUNT(CASE WHEN estado_carga = 'SOBRECARGA' THEN 1 END) > 0 THEN '🔴 Semana sobrecargada'
    WHEN COUNT(CASE WHEN estado_carga = 'SATURADO' THEN 1 END) > 2 THEN '🟡 Semana ajustada'
    ELSE '✅ Semana saludable'
  END AS estado_general
FROM disponibilidad_real_semanal;

COMMENT ON VIEW resumen_salud_semana_actual IS 'Resumen general de la salud de la semana';


-- ============================================
-- PARTE 2: Sugerencia de Priorización Diaria
-- ============================================

-- 2.1 Vista de tareas priorizadas para hoy
CREATE OR REPLACE VIEW tareas_sugeridas_hoy AS
SELECT
  t.id,
  t.nombre,
  p.nombre AS proyecto,
  t.tiempo_estimado_horas,
  t.eisenhower,
  t.impacto,
  t.urgencia,
  t.energia_requerida,
  t.contexto_necesario,
  t.estado_kanban,
  p.score_motivacional,
  -- Cálculo de score compuesto
  (
    CASE t.eisenhower
      WHEN 'cuadrante_1' THEN get_config_numero('peso_eisenhower_cuadrante_1')
      WHEN 'cuadrante_2' THEN get_config_numero('peso_eisenhower_cuadrante_2')
      WHEN 'cuadrante_3' THEN get_config_numero('peso_eisenhower_cuadrante_3')
      WHEN 'cuadrante_4' THEN get_config_numero('peso_eisenhower_cuadrante_4')
      ELSE 0
    END +
    CASE t.impacto
      WHEN 'alto' THEN get_config_numero('peso_impacto_alto')
      WHEN 'medio' THEN get_config_numero('peso_impacto_medio')
      WHEN 'bajo' THEN get_config_numero('peso_impacto_bajo')
      ELSE 0
    END +
    (COALESCE(p.score_motivacional, 0) * get_config_numero('peso_motivacional'))
  )::NUMERIC AS score_prioridad
FROM tareas_estrategicas t
JOIN proyectos_estrategicos p ON t.proyecto_id = p.id
WHERE t.estado_kanban IN ('todo', 'doing')
  AND (t.fecha_inicio IS NULL OR t.fecha_inicio <= CURRENT_DATE)
  AND t.bloqueada_por IS NULL
  AND p.estado IN ('en_curso', 'planificacion')
ORDER BY score_prioridad DESC, t.urgencia DESC;

COMMENT ON VIEW tareas_sugeridas_hoy IS 'Tareas priorizadas por score compuesto para trabajar hoy';


-- 2.2 Tareas bloqueadas que requieren atención
CREATE OR REPLACE VIEW tareas_bloqueadas_atencion AS
SELECT
  t.id,
  t.nombre,
  p.nombre AS proyecto,
  t.bloqueada_por,
  t.fecha_estimada_desbloqueo,
  t.estado_kanban,
  CASE
    WHEN t.fecha_estimada_desbloqueo IS NULL THEN 'Sin fecha de desbloqueo'
    WHEN t.fecha_estimada_desbloqueo <= CURRENT_DATE THEN '🔴 Ya debería estar desbloqueada'
    WHEN t.fecha_estimada_desbloqueo <= CURRENT_DATE + INTERVAL '3 days' THEN '🟡 Próxima a desbloquearse'
    ELSE '⏳ Bloqueada largo plazo'
  END AS estado_bloqueo
FROM tareas_estrategicas t
JOIN proyectos_estrategicos p ON t.proyecto_id = p.id
WHERE t.bloqueada_por IS NOT NULL
ORDER BY
  CASE
    WHEN t.fecha_estimada_desbloqueo <= CURRENT_DATE THEN 1
    WHEN t.fecha_estimada_desbloqueo <= CURRENT_DATE + INTERVAL '3 days' THEN 2
    ELSE 3
  END,
  t.fecha_estimada_desbloqueo NULLS LAST;

COMMENT ON VIEW tareas_bloqueadas_atencion IS 'Tareas bloqueadas que requieren seguimiento';


-- ============================================
-- PARTE 3: Reporte de Tiempo por Área de Vida
-- ============================================

-- 3.1 Vista de tiempo por área (semana actual)
CREATE OR REPLACE VIEW tiempo_por_area_semana AS
SELECT
  a.nombre AS area,
  a.color_hex,
  -- Tiempo de tareas recurrentes
  COALESCE(SUM(
    CASE WHEN i.fecha_programada >= CURRENT_DATE
         AND i.fecha_programada < CURRENT_DATE + INTERVAL '7 days'
    THEN t.duracion_estimada_minutos / 60.0
    ELSE 0 END
  ), 0) AS horas_recurrentes_semana,
  -- Proyectos activos en esta área
  COUNT(DISTINCT CASE WHEN p.estado = 'en_curso' THEN p.id END) AS proyectos_activos,
  -- Horas estimadas de tareas estratégicas pendientes
  COALESCE(SUM(
    CASE WHEN te.estado_kanban IN ('todo', 'doing')
    THEN te.tiempo_estimado_horas
    ELSE 0 END
  ), 0) AS horas_tareas_estrategicas_pendientes,
  -- Total
  COALESCE(SUM(
    CASE WHEN i.fecha_programada >= CURRENT_DATE
         AND i.fecha_programada < CURRENT_DATE + INTERVAL '7 days'
    THEN t.duracion_estimada_minutos / 60.0
    ELSE 0 END
  ), 0) +
  COALESCE(SUM(
    CASE WHEN te.estado_kanban IN ('todo', 'doing')
    THEN te.tiempo_estimado_horas
    ELSE 0 END
  ), 0) AS horas_totales
FROM areas_vida a
LEFT JOIN tareas_recurrentes t ON t.area_id = a.id AND t.activa = true
LEFT JOIN instancias_tareas_recurrentes i ON i.tarea_recurrente_id = t.id
LEFT JOIN proyectos_estrategicos p ON a.id = ANY(p.areas_ids)
LEFT JOIN tareas_estrategicas te ON te.proyecto_id = p.id
WHERE a.activa IS NOT FALSE
GROUP BY a.id, a.nombre, a.color_hex
ORDER BY horas_totales DESC;

COMMENT ON VIEW tiempo_por_area_semana IS 'Distribución de tiempo por área de vida (semana actual)';


-- 3.2 Porcentaje de tiempo por área
CREATE OR REPLACE VIEW distribucion_porcentual_areas AS
SELECT
  area,
  horas_totales,
  ROUND(
    (horas_totales / NULLIF(SUM(horas_totales) OVER (), 0) * 100)::NUMERIC,
    1
  ) AS porcentaje
FROM tiempo_por_area_semana
WHERE horas_totales > 0
ORDER BY horas_totales DESC;

COMMENT ON VIEW distribucion_porcentual_areas IS 'Distribución porcentual de tiempo por área';


-- ============================================
-- PARTE 4: Análisis de Compromisos
-- ============================================

-- 4.1 Compromisos próximos a vencer (crítico para marca personal)
CREATE OR REPLACE VIEW compromisos_proximos AS
SELECT
  c.id,
  c.titulo,
  c.persona_nombre,
  c.fecha_limite,
  c.yo_me_comprometi,
  CURRENT_DATE AS hoy,
  c.fecha_limite - CURRENT_DATE AS dias_restantes,
  CASE
    WHEN c.fecha_limite < CURRENT_DATE THEN '🔴 VENCIDO'
    WHEN c.fecha_limite = CURRENT_DATE THEN '🔴 HOY'
    WHEN c.fecha_limite <= CURRENT_DATE + INTERVAL '1 day' THEN '🟠 MAÑANA'
    WHEN c.fecha_limite <= CURRENT_DATE + get_config_numero('dias_anticipacion_compromisos') * INTERVAL '1 day' THEN '🟡 PRÓXIMO'
    ELSE '✅ A TIEMPO'
  END AS urgencia,
  CASE
    WHEN c.yo_me_comprometi THEN '👤 YO prometí'
    ELSE '👥 Otros prometieron'
  END AS tipo_compromiso
FROM compromisos c
WHERE c.cumplido = false
  AND c.fecha_limite IS NOT NULL
ORDER BY
  CASE
    WHEN c.fecha_limite < CURRENT_DATE THEN 1
    WHEN c.fecha_limite <= CURRENT_DATE + INTERVAL '1 day' THEN 2
    WHEN c.fecha_limite <= CURRENT_DATE + get_config_numero('dias_anticipacion_compromisos') * INTERVAL '1 day' THEN 3
    ELSE 4
  END,
  c.fecha_limite;

COMMENT ON VIEW compromisos_proximos IS 'Compromisos ordenados por urgencia (crítico para marca personal)';


-- ============================================
-- PARTE 5: Métricas de Productividad
-- ============================================

-- 5.1 Tasa de completitud de tareas recurrentes (últimos 30 días)
CREATE OR REPLACE VIEW metricas_tareas_recurrentes AS
SELECT
  t.nombre AS tarea,
  t.tipo,
  t.criticidad,
  COUNT(i.id) AS instancias_programadas,
  COUNT(CASE WHEN i.completada THEN 1 END) AS instancias_completadas,
  COUNT(CASE WHEN i.saltada THEN 1 END) AS instancias_saltadas,
  ROUND(
    (COUNT(CASE WHEN i.completada THEN 1 END)::NUMERIC /
     NULLIF(COUNT(i.id), 0) * 100),
    1
  ) AS tasa_completitud,
  AVG(i.duracion_real_minutos) AS duracion_promedio_real
FROM tareas_recurrentes t
LEFT JOIN instancias_tareas_recurrentes i ON i.tarea_recurrente_id = t.id
  AND i.fecha_programada >= CURRENT_DATE - INTERVAL '30 days'
  AND i.fecha_programada <= CURRENT_DATE
WHERE t.activa = true
GROUP BY t.id, t.nombre, t.tipo, t.criticidad
ORDER BY t.criticidad DESC, tasa_completitud ASC;

COMMENT ON VIEW metricas_tareas_recurrentes IS 'Métricas de completitud de tareas recurrentes (últimos 30 días)';


-- 5.2 Comparación estimado vs real en tareas estratégicas
CREATE OR REPLACE VIEW precision_estimaciones AS
SELECT
  t.nombre AS tarea,
  p.nombre AS proyecto,
  t.tiempo_estimado_horas,
  t.duracion_real_horas,
  CASE
    WHEN t.duracion_real_horas IS NULL THEN 'Pendiente'
    WHEN t.duracion_real_horas <= t.tiempo_estimado_horas THEN '✅ Dentro de estimación'
    WHEN t.duracion_real_horas <= t.tiempo_estimado_horas * 1.2 THEN '🟡 +20% sobre estimado'
    ELSE '🔴 Muy por encima'
  END AS precision,
  CASE
    WHEN t.duracion_real_horas IS NOT NULL
    THEN ROUND(((t.duracion_real_horas - t.tiempo_estimado_horas) / NULLIF(t.tiempo_estimado_horas, 0) * 100)::NUMERIC, 1)
  END AS desviacion_porcentaje
FROM tareas_estrategicas t
JOIN proyectos_estrategicos p ON t.proyecto_id = p.id
WHERE t.estado_kanban = 'done'
  AND t.tiempo_estimado_horas IS NOT NULL
ORDER BY t.fecha_done DESC
LIMIT 50;

COMMENT ON VIEW precision_estimaciones IS 'Análisis de precisión de estimaciones (últimas 50 tareas completadas)';


-- ============================================
-- PARTE 6: Planificación de la Semana
-- ============================================

-- 6.1 Vista consolidada para planificación semanal
CREATE OR REPLACE VIEW planificacion_semana_completa AS
SELECT
  fecha,
  dia_nombre,
  tipo,
  hora_inicio,
  hora_fin,
  duracion_horas,
  titulo,
  area,
  completado
FROM (
  -- Instancias de tareas recurrentes
  SELECT
    i.fecha_programada AS fecha,
    CASE
      WHEN EXTRACT(DOW FROM i.fecha_programada) = 0 THEN 'Domingo'
      WHEN EXTRACT(DOW FROM i.fecha_programada) = 1 THEN 'Lunes'
      WHEN EXTRACT(DOW FROM i.fecha_programada) = 2 THEN 'Martes'
      WHEN EXTRACT(DOW FROM i.fecha_programada) = 3 THEN 'Miércoles'
      WHEN EXTRACT(DOW FROM i.fecha_programada) = 4 THEN 'Jueves'
      WHEN EXTRACT(DOW FROM i.fecha_programada) = 5 THEN 'Viernes'
      ELSE 'Sábado'
    END AS dia_nombre,
    'Recurrente' AS tipo,
    i.hora_inicio,
    i.hora_fin,
    t.duracion_estimada_minutos / 60.0 AS duracion_horas,
    t.nombre AS titulo,
    a.nombre AS area,
    i.completada AS completado
  FROM instancias_tareas_recurrentes i
  JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id
  LEFT JOIN areas_vida a ON t.area_id = a.id
  WHERE i.fecha_programada >= CURRENT_DATE
    AND i.fecha_programada < CURRENT_DATE + INTERVAL '7 days'
    AND i.saltada = false

  UNION ALL

  -- Bloques planificados
  SELECT
    b.fecha,
    CASE
      WHEN EXTRACT(DOW FROM b.fecha) = 0 THEN 'Domingo'
      WHEN EXTRACT(DOW FROM b.fecha) = 1 THEN 'Lunes'
      WHEN EXTRACT(DOW FROM b.fecha) = 2 THEN 'Martes'
      WHEN EXTRACT(DOW FROM b.fecha) = 3 THEN 'Miércoles'
      WHEN EXTRACT(DOW FROM b.fecha) = 4 THEN 'Jueves'
      WHEN EXTRACT(DOW FROM b.fecha) = 5 THEN 'Viernes'
      ELSE 'Sábado'
    END AS dia_nombre,
    b.tipo_bloque AS tipo,
    b.hora_inicio,
    b.hora_fin,
    EXTRACT(EPOCH FROM (b.hora_fin - b.hora_inicio)) / 3600 AS duracion_horas,
    COALESCE(te.nombre, tr.nombre, p.nombre, b.descripcion_libre) AS titulo,
    a.nombre AS area,
    b.completado
  FROM bloques_tiempo_planificados b
  LEFT JOIN tareas_estrategicas te ON b.tarea_estrategica_id = te.id
  LEFT JOIN tareas_recurrentes tr ON b.tarea_recurrente_id = tr.id
  LEFT JOIN proyectos_estrategicos p ON b.proyecto_estrategico_id = p.id
  LEFT JOIN areas_vida a ON b.area_vida_id = a.id
  WHERE b.fecha >= CURRENT_DATE
    AND b.fecha < CURRENT_DATE + INTERVAL '7 days'
) AS eventos
ORDER BY fecha, hora_inicio NULLS LAST;

COMMENT ON VIEW planificacion_semana_completa IS 'Vista consolidada de toda la planificación semanal';


-- ============================================
-- PARTE 7: Funciones de Utilidad
-- ============================================

-- 7.1 Función para obtener tiempo disponible en un rango de fechas
CREATE OR REPLACE FUNCTION obtener_disponibilidad_rango(
  fecha_inicio DATE,
  fecha_fin DATE
)
RETURNS TABLE (
  total_dias INTEGER,
  total_horas_teoricas NUMERIC,
  total_horas_recurrentes NUMERIC,
  total_horas_disponibles NUMERIC,
  porcentaje_ocupado NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH dias AS (
    SELECT generate_series(fecha_inicio, fecha_fin, '1 day'::INTERVAL)::DATE AS fecha
  ),
  disponibilidad AS (
    SELECT
      d.fecha,
      ds.horas_disponibles,
      COALESCE(SUM(t.duracion_estimada_minutos) / 60.0, 0) AS horas_recurrentes
    FROM dias d
    LEFT JOIN disponibilidad_semanal ds ON
      CASE
        WHEN EXTRACT(DOW FROM d.fecha) = 0 THEN 7
        ELSE EXTRACT(DOW FROM d.fecha)::INTEGER
      END = ds.dia_semana
    LEFT JOIN instancias_tareas_recurrentes i ON i.fecha_programada = d.fecha AND i.saltada = false
    LEFT JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id AND t.activa = true
    GROUP BY d.fecha, ds.horas_disponibles
  )
  SELECT
    COUNT(*)::INTEGER,
    SUM(horas_disponibles)::NUMERIC,
    SUM(horas_recurrentes)::NUMERIC,
    SUM(horas_disponibles - horas_recurrentes)::NUMERIC,
    ROUND((SUM(horas_recurrentes) / NULLIF(SUM(horas_disponibles), 0) * 100)::NUMERIC, 1)
  FROM disponibilidad;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_disponibilidad_rango IS 'Calcula disponibilidad total en un rango de fechas';


-- ============================================
-- Ejemplos de Uso
-- ============================================

-- Ver sobrecarga semanal
-- SELECT * FROM vista_sobrecarga_semanal;

-- Ver resumen de salud
-- SELECT * FROM resumen_salud_semana_actual;

-- Ver tareas priorizadas para hoy
-- SELECT * FROM tareas_sugeridas_hoy LIMIT 10;

-- Ver compromisos próximos
-- SELECT * FROM compromisos_proximos;

-- Ver tiempo por área
-- SELECT * FROM tiempo_por_area_semana;

-- Ver planificación completa de la semana
-- SELECT * FROM planificacion_semana_completa;

-- Obtener disponibilidad del próximo mes
-- SELECT * FROM obtener_disponibilidad_rango(CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
