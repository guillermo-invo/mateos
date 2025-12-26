-- ============================================
-- ALTA PRIORIDAD: Tareas Recurrentes
-- ============================================
-- Autor: Sistema Mateos
-- Fecha: 2025-12-24
-- Descripción: Creación de tablas para gestión de tareas recurrentes
--              y cálculo de disponibilidad de tiempo
-- ============================================

BEGIN;

-- ============================================
-- 1. Tabla: tareas_recurrentes
-- ============================================
-- Gestiona tareas que se repiten periódicamente
-- (trabajo, salud, hábitos, comunicación, marca personal)

CREATE TABLE IF NOT EXISTS tareas_recurrentes (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,

  -- Categorización
  area_id INTEGER REFERENCES areas_vida(id) ON DELETE SET NULL,
  proyecto_estrategico_id INTEGER REFERENCES proyectos_estrategicos(id) ON DELETE SET NULL,
  tipo VARCHAR(50) CHECK (tipo IN ('habito', 'mantenimiento', 'comunicacion', 'administrativo', 'otro')),

  -- Patrón de recurrencia
  -- Formato: {
  --   "tipo": "diaria|semanal|mensual|personalizada",
  --   "intervalo": 1,
  --   "diasSemana": [1,3,5], -- si es semanal: 1=lun, 7=dom
  --   "diaMes": 15, -- si es mensual
  --   "horaPreferida": "09:00", -- OPCIONAL
  --   "fechaInicio": "2025-01-01",
  --   "fechaFin": "2025-12-31" -- OPCIONAL, null = indefinido
  -- }
  patron_recurrencia JSONB NOT NULL,

  -- Tiempo y esfuerzo
  duracion_estimada_minutos INTEGER NOT NULL CHECK (duracion_estimada_minutos > 0),
  energia_requerida VARCHAR(20) CHECK (energia_requerida IN ('baja', 'media', 'alta')),
  contexto_necesario VARCHAR(50) CHECK (contexto_necesario IN ('casa', 'oficina', 'anywhere', 'movil')),

  -- Priorización
  criticidad VARCHAR(20) CHECK (criticidad IN ('must', 'should', 'could')),
  impacto VARCHAR(20) CHECK (impacto IN ('alto', 'medio', 'bajo')),

  -- Control
  activa BOOLEAN DEFAULT true,

  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para optimizar consultas
CREATE INDEX idx_tareas_recurrentes_area ON tareas_recurrentes(area_id);
CREATE INDEX idx_tareas_recurrentes_proyecto ON tareas_recurrentes(proyecto_estrategico_id);
CREATE INDEX idx_tareas_recurrentes_activa ON tareas_recurrentes(activa);
CREATE INDEX idx_tareas_recurrentes_tipo ON tareas_recurrentes(tipo);
CREATE INDEX idx_tareas_recurrentes_criticidad ON tareas_recurrentes(criticidad);

-- Índice GIN para búsquedas en JSONB
CREATE INDEX idx_tareas_recurrentes_patron ON tareas_recurrentes USING GIN (patron_recurrencia);

-- Comentarios para documentación
COMMENT ON TABLE tareas_recurrentes IS 'Tareas que se repiten periódicamente (hábitos, mantenimiento, comunicación)';
COMMENT ON COLUMN tareas_recurrentes.patron_recurrencia IS 'Configuración JSON del patrón de recurrencia (tipo, intervalo, días, etc.)';
COMMENT ON COLUMN tareas_recurrentes.criticidad IS 'must: crítica | should: importante | could: deseable';
COMMENT ON COLUMN tareas_recurrentes.energia_requerida IS 'Nivel de energía mental/física necesaria';
COMMENT ON COLUMN tareas_recurrentes.contexto_necesario IS 'Dónde se puede realizar la tarea';


-- ============================================
-- 2. Tabla: instancias_tareas_recurrentes
-- ============================================
-- Instancias específicas generadas a partir de tareas recurrentes

CREATE TABLE IF NOT EXISTS instancias_tareas_recurrentes (
  id SERIAL PRIMARY KEY,
  tarea_recurrente_id INTEGER NOT NULL REFERENCES tareas_recurrentes(id) ON DELETE CASCADE,
  fecha_programada DATE NOT NULL,
  hora_inicio TIME,
  hora_fin TIME,

  -- Estado
  completada BOOLEAN DEFAULT false,
  fecha_completada TIMESTAMP,
  saltada BOOLEAN DEFAULT false,
  razon_saltada TEXT,

  -- Tracking
  duracion_real_minutos INTEGER CHECK (duracion_real_minutos >= 0),

  -- Sincronización con calendario
  google_calendar_event_id VARCHAR(255),

  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Restricción: no duplicar instancias
  CONSTRAINT unique_instancia_por_fecha UNIQUE(tarea_recurrente_id, fecha_programada)
);

-- Índices para optimizar consultas
CREATE INDEX idx_instancias_tarea_recurrente ON instancias_tareas_recurrentes(tarea_recurrente_id);
CREATE INDEX idx_instancias_fecha_programada ON instancias_tareas_recurrentes(fecha_programada);
CREATE INDEX idx_instancias_completada ON instancias_tareas_recurrentes(completada);
CREATE INDEX idx_instancias_saltada ON instancias_tareas_recurrentes(saltada);
CREATE INDEX idx_instancias_google_calendar ON instancias_tareas_recurrentes(google_calendar_event_id);

-- Índice compuesto para consultas de planificación semanal
CREATE INDEX idx_instancias_fecha_estado ON instancias_tareas_recurrentes(fecha_programada, completada, saltada);

-- Comentarios para documentación
COMMENT ON TABLE instancias_tareas_recurrentes IS 'Instancias específicas generadas de tareas recurrentes para fechas concretas';
COMMENT ON COLUMN instancias_tareas_recurrentes.saltada IS 'true si se decidió conscientemente no hacer esta instancia';
COMMENT ON COLUMN instancias_tareas_recurrentes.duracion_real_minutos IS 'Tiempo real que tomó (para aprender y ajustar estimaciones)';


-- ============================================
-- 3. Tabla: disponibilidad_semanal
-- ============================================
-- Define cuántas horas productivas hay cada día de la semana

CREATE TABLE IF NOT EXISTS disponibilidad_semanal (
  id SERIAL PRIMARY KEY,
  dia_semana INTEGER NOT NULL CHECK (dia_semana >= 1 AND dia_semana <= 7), -- 1=lunes, 7=domingo
  horas_disponibles DECIMAL(4,2) NOT NULL CHECK (horas_disponibles >= 0 AND horas_disponibles <= 24),
  momento_optimo VARCHAR(20) CHECK (momento_optimo IN ('maniana', 'tarde', 'noche', 'todo_el_dia')),
  notas TEXT,

  -- Auditoría
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Solo un registro por día de la semana
  CONSTRAINT unique_dia_semana UNIQUE(dia_semana)
);

-- Índice en día de la semana
CREATE INDEX idx_disponibilidad_dia ON disponibilidad_semanal(dia_semana);

-- Comentarios para documentación
COMMENT ON TABLE disponibilidad_semanal IS 'Horas productivas disponibles por día de la semana (configuración base)';
COMMENT ON COLUMN disponibilidad_semanal.dia_semana IS '1=lunes, 2=martes, 3=miércoles, 4=jueves, 5=viernes, 6=sábado, 7=domingo';
COMMENT ON COLUMN disponibilidad_semanal.horas_disponibles IS 'Horas productivas teóricas disponibles';
COMMENT ON COLUMN disponibilidad_semanal.momento_optimo IS 'Momento del día con mayor energía/productividad';

-- Insertar valores por defecto (semana laboral estándar)
-- El usuario puede modificar estos valores según su realidad
INSERT INTO disponibilidad_semanal (dia_semana, horas_disponibles, momento_optimo, notas)
VALUES
  (1, 5.0, 'maniana', 'Lunes - semana estándar'),
  (2, 5.0, 'maniana', 'Martes - semana estándar'),
  (3, 5.0, 'maniana', 'Miércoles - semana estándar'),
  (4, 5.0, 'maniana', 'Jueves - semana estándar'),
  (5, 4.0, 'maniana', 'Viernes - reducir carga'),
  (6, 3.0, 'maniana', 'Sábado - tiempo personal/proyectos'),
  (7, 2.0, 'tarde', 'Domingo - planificación semanal')
ON CONFLICT (dia_semana) DO NOTHING;


-- ============================================
-- Trigger para actualizar updated_at automáticamente
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar triggers
CREATE TRIGGER update_tareas_recurrentes_updated_at BEFORE UPDATE ON tareas_recurrentes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instancias_recurrentes_updated_at BEFORE UPDATE ON instancias_tareas_recurrentes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_disponibilidad_semanal_updated_at BEFORE UPDATE ON disponibilidad_semanal
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- Función auxiliar: validar patrón de recurrencia
-- ============================================

CREATE OR REPLACE FUNCTION validar_patron_recurrencia(patron JSONB)
RETURNS BOOLEAN AS $$
BEGIN
  -- Validar que tenga el campo 'tipo'
  IF NOT (patron ? 'tipo') THEN
    RAISE EXCEPTION 'El patrón de recurrencia debe tener el campo "tipo"';
  END IF;

  -- Validar que el tipo sea válido
  IF NOT (patron->>'tipo' IN ('diaria', 'semanal', 'mensual', 'personalizada')) THEN
    RAISE EXCEPTION 'Tipo de recurrencia inválido: %', patron->>'tipo';
  END IF;

  -- Validar que tenga fechaInicio
  IF NOT (patron ? 'fechaInicio') THEN
    RAISE EXCEPTION 'El patrón de recurrencia debe tener "fechaInicio"';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Agregar constraint usando la función de validación
ALTER TABLE tareas_recurrentes
  ADD CONSTRAINT check_patron_valido CHECK (validar_patron_recurrencia(patron_recurrencia));

COMMIT;

-- ============================================
-- Verificación
-- ============================================
-- Para verificar que todo se creó correctamente:
--
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
-- AND table_name IN ('tareas_recurrentes', 'instancias_tareas_recurrentes', 'disponibilidad_semanal');
--
-- SELECT * FROM disponibilidad_semanal ORDER BY dia_semana;
