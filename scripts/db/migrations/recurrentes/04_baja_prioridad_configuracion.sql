-- ============================================
-- BAJA PRIORIDAD: Configuración Personal
-- ============================================
-- Autor: Sistema Mateos
-- Fecha: 2025-12-24
-- Descripción: Tabla para guardar preferencias y parámetros del sistema
-- ============================================

BEGIN;

-- ============================================
-- 1. Tabla: configuracion_personal
-- ============================================
-- Tabla flexible para guardar configuraciones del sistema

CREATE TABLE IF NOT EXISTS configuracion_personal (
  clave VARCHAR(100) PRIMARY KEY,
  valor JSONB NOT NULL,
  descripcion TEXT,
  categoria VARCHAR(50), -- 'sistema', 'tiempo', 'notificaciones', 'integraciones', etc.
  tipo_dato VARCHAR(20), -- 'numero', 'texto', 'booleano', 'json', etc.
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_configuracion_categoria ON configuracion_personal(categoria);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_configuracion_personal_updated_at BEFORE UPDATE ON configuracion_personal
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comentarios
COMMENT ON TABLE configuracion_personal IS 'Configuraciones y preferencias del sistema Mateos';
COMMENT ON COLUMN configuracion_personal.valor IS 'Valor en formato JSONB para flexibilidad';
COMMENT ON COLUMN configuracion_personal.categoria IS 'Categoría de la configuración para organización';


-- ============================================
-- 2. Insertar valores iniciales
-- ============================================

INSERT INTO configuracion_personal (clave, valor, descripcion, categoria, tipo_dato) VALUES
  -- Tiempo y productividad
  ('horas_disponibles_promedio_dia', '5', 'Horas productivas promedio por día', 'tiempo', 'numero'),
  ('max_proyectos_paralelos', '3', 'Máximo de proyectos en DOING simultáneamente (ADHD)', 'tiempo', 'numero'),
  ('momento_mayor_energia', '"maniana"', 'Cuándo tengo más energía: maniana, tarde, noche', 'tiempo', 'texto'),
  ('tiempo_buffer_porcentaje', '20', 'Porcentaje de tiempo a dejar como buffer (imprevistos)', 'tiempo', 'numero'),
  ('duracion_sesion_foco_minutos', '90', 'Duración de sesión de trabajo profundo antes de break', 'tiempo', 'numero'),
  ('duracion_break_minutos', '15', 'Duración del descanso entre sesiones de foco', 'tiempo', 'numero'),

  -- Planificación
  ('semanas_adelante_generar_recurrentes', '2', 'Cuántas semanas adelante generar instancias recurrentes', 'planificacion', 'numero'),
  ('dia_planificacion_semanal', '0', 'Día de la semana para planificar (0=domingo, 6=sábado)', 'planificacion', 'numero'),
  ('hora_planificacion_semanal', '"20:00"', 'Hora para recordatorio de planificación semanal', 'planificacion', 'texto'),

  -- Priorización
  ('peso_eisenhower_cuadrante_1', '100', 'Peso para tareas cuadrante 1 (urgente e importante)', 'priorizacion', 'numero'),
  ('peso_eisenhower_cuadrante_2', '70', 'Peso para tareas cuadrante 2 (no urgente pero importante)', 'priorizacion', 'numero'),
  ('peso_eisenhower_cuadrante_3', '40', 'Peso para tareas cuadrante 3 (urgente pero no importante)', 'priorizacion', 'numero'),
  ('peso_eisenhower_cuadrante_4', '10', 'Peso para tareas cuadrante 4 (ni urgente ni importante)', 'priorizacion', 'numero'),
  ('peso_impacto_alto', '30', 'Puntos adicionales por impacto alto', 'priorizacion', 'numero'),
  ('peso_impacto_medio', '15', 'Puntos adicionales por impacto medio', 'priorizacion', 'numero'),
  ('peso_impacto_bajo', '5', 'Puntos adicionales por impacto bajo', 'priorizacion', 'numero'),
  ('peso_motivacional', '20', 'Multiplicador para score motivacional del proyecto', 'priorizacion', 'numero'),

  -- Integraciones
  ('google_calendar_id', 'null', 'ID del calendario de Google Calendar a usar', 'integraciones', 'texto'),
  ('google_calendar_color_trabajo', '"9"', 'Color ID para bloques de trabajo en Google Calendar', 'integraciones', 'texto'),
  ('google_calendar_color_personal', '"7"', 'Color ID para bloques personales en Google Calendar', 'integraciones', 'texto'),
  ('google_calendar_color_habitos', '"2"', 'Color ID para bloques de hábitos en Google Calendar', 'integraciones', 'texto'),
  ('sync_bloques_automatico', 'true', 'Sincronizar bloques automáticamente con Google Calendar', 'integraciones', 'booleano'),

  -- Notificaciones
  ('notificar_tareas_bloqueadas', 'true', 'Notificar cuando una tarea está bloqueada', 'notificaciones', 'booleano'),
  ('notificar_compromisos_proximos', 'true', 'Notificar compromisos próximos a vencer', 'notificaciones', 'booleano'),
  ('dias_anticipacion_compromisos', '3', 'Días de anticipación para notificar compromisos', 'notificaciones', 'numero'),

  -- Sistema
  ('zona_horaria', '"America/Argentina/Buenos_Aires"', 'Zona horaria del usuario', 'sistema', 'texto'),
  ('idioma', '"es"', 'Idioma preferido del sistema', 'sistema', 'texto'),
  ('formato_fecha', '"DD/MM/YYYY"', 'Formato de fecha preferido', 'sistema', 'texto'),
  ('formato_hora', '"HH:mm"', 'Formato de hora preferido (24h)', 'sistema', 'texto')

ON CONFLICT (clave) DO NOTHING;


-- ============================================
-- 3. Funciones auxiliares para configuración
-- ============================================

-- Función para obtener valor de configuración
CREATE OR REPLACE FUNCTION get_config(clave_param VARCHAR)
RETURNS JSONB AS $$
DECLARE
  resultado JSONB;
BEGIN
  SELECT valor INTO resultado
  FROM configuracion_personal
  WHERE clave = clave_param;

  IF resultado IS NULL THEN
    RAISE EXCEPTION 'Configuración no encontrada: %', clave_param;
  END IF;

  RETURN resultado;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_config IS 'Obtiene el valor de una configuración por clave';


-- Función para establecer valor de configuración
CREATE OR REPLACE FUNCTION set_config(clave_param VARCHAR, valor_param JSONB)
RETURNS VOID AS $$
BEGIN
  INSERT INTO configuracion_personal (clave, valor)
  VALUES (clave_param, valor_param)
  ON CONFLICT (clave)
  DO UPDATE SET valor = valor_param, updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_config IS 'Establece o actualiza el valor de una configuración';


-- Función para obtener valor como número
CREATE OR REPLACE FUNCTION get_config_numero(clave_param VARCHAR)
RETURNS NUMERIC AS $$
BEGIN
  RETURN (get_config(clave_param))::TEXT::NUMERIC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_config_numero IS 'Obtiene configuración y la convierte a número';


-- Función para obtener valor como texto
CREATE OR REPLACE FUNCTION get_config_texto(clave_param VARCHAR)
RETURNS TEXT AS $$
BEGIN
  RETURN (get_config(clave_param))::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_config_texto IS 'Obtiene configuración y la convierte a texto (sin comillas)';


-- Función para obtener valor como booleano
CREATE OR REPLACE FUNCTION get_config_bool(clave_param VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (get_config(clave_param))::TEXT::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_config_bool IS 'Obtiene configuración y la convierte a booleano';


-- ============================================
-- 4. Vista: configuracion_por_categoria
-- ============================================

CREATE OR REPLACE VIEW configuracion_por_categoria AS
SELECT
  categoria,
  COUNT(*) AS num_configuraciones,
  jsonb_object_agg(clave, valor) AS configuraciones
FROM configuracion_personal
WHERE categoria IS NOT NULL
GROUP BY categoria
ORDER BY categoria;

COMMENT ON VIEW configuracion_por_categoria IS 'Configuraciones agrupadas por categoría';


COMMIT;

-- ============================================
-- Verificación y Ejemplos de Uso
-- ============================================
--
-- -- Ver todas las configuraciones
-- SELECT * FROM configuracion_personal ORDER BY categoria, clave;
--
-- -- Ver configuraciones por categoría
-- SELECT * FROM configuracion_por_categoria;
--
-- -- Obtener valor de configuración
-- SELECT get_config('horas_disponibles_promedio_dia');
--
-- -- Obtener como número
-- SELECT get_config_numero('max_proyectos_paralelos');
--
-- -- Obtener como texto
-- SELECT get_config_texto('momento_mayor_energia');
--
-- -- Obtener como booleano
-- SELECT get_config_bool('notificar_tareas_bloqueadas');
--
-- -- Establecer nueva configuración
-- SELECT set_config('mi_configuracion', '{"valor": "personalizado"}');
--
-- -- Actualizar configuración existente
-- SELECT set_config('max_proyectos_paralelos', '5');
