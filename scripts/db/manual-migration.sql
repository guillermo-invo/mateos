-- Manual Migration for MATEOS V2
-- Only creates elements that don't already exist

-- Create new ENUMs (skip Prioridad and Categoria as they exist)
DO $$ BEGIN
  CREATE TYPE "TipoMoscow" AS ENUM ('must', 'should', 'could', 'wont');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TipoEnfoque" AS ENUM ('velocidad', 'perfeccion', 'balanceado');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TipoLibertad" AS ENUM ('receta', 'resultado', 'mixto');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TipoRiesgo" AS ENUM ('bajo', 'medio', 'alto', 'critico');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TipoEnergia" AS ENUM ('relax', 'baja', 'media', 'alta', 'pico');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TipoEstadoProyecto" AS ENUM ('idea', 'planificacion', 'en_curso', 'pausado', 'completado', 'cancelado', 'archivado');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TipoEstadoTarea" AS ENUM ('por_hacer', 'en_progreso', 'bloqueada', 'en_revision', 'completada', 'cancelada');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Rename existing ideas table to ideas_capturadas if needed
ALTER TABLE IF EXISTS ideas RENAME TO ideas_capturadas;

-- Add FK column to ideas_capturadas if it doesn't exist
DO $$ BEGIN
  ALTER TABLE ideas_capturadas ADD COLUMN proyecto_estrategico_id INTEGER;
EXCEPTION
  WHEN duplicate_column THEN NULL;
END $$;

-- Add FK column to tareas if it doesn't exist
DO $$ BEGIN
  ALTER TABLE tareas ADD COLUMN proyecto_estrategico_id INTEGER;
EXCEPTION
  WHEN duplicate_column THEN NULL;
END $$;

-- Create new tables (taxative tables)
CREATE TABLE IF NOT EXISTS areas_vida (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  color_hex VARCHAR(7),
  orden_visualizacion INTEGER,
  activa BOOLEAN
);

CREATE TABLE IF NOT EXISTS motivos_personales (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  icono VARCHAR(20),
  peso_personal INTEGER
);

CREATE TABLE IF NOT EXISTS destrezas (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  categoria VARCHAR(50),
  nivel_actual INTEGER,
  descripcion TEXT,
  costo_energetico "TipoEnergia",
  mejor_momento_dia TEXT[],
  requiere_flow BOOLEAN,
  notas_contexto TEXT
);

CREATE TABLE IF NOT EXISTS dificultades (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  categoria VARCHAR(50),
  nivel_impacto INTEGER,
  descripcion TEXT,
  estrategia_mitigacion TEXT
);

CREATE TABLE IF NOT EXISTS misiones_vida (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  vision TEXT,
  prioridad INTEGER
);

-- Create new tables (generative tables)
CREATE TABLE IF NOT EXISTS proyectos_estrategicos (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  descripcion TEXT,
  areas_ids INTEGER[],
  motivos_ids INTEGER[],
  destrezas_requeridas_ids INTEGER[],
  dificultades_ids INTEGER[],
  misiones_ids INTEGER[],
  justificacion_estrategica JSONB,
  objetivos_smart JSONB,
  fecha_inicio DATE,
  fecha_fin_estimada DATE,
  estado "TipoEstadoProyecto" NOT NULL DEFAULT 'idea',
  prioridad_global DECIMAL(3,2),
  score_motivacional DECIMAL(3,2),
  score_alineacion DECIMAL(3,2),
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tareas_estrategicas (
  id SERIAL PRIMARY KEY,
  proyecto_id INTEGER NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  orden INTEGER,
  moscow "TipoMoscow",
  tiempo_estimado_horas INTEGER,
  nivel_riesgo "TipoRiesgo",
  prioridad_velocidad_perfeccion "TipoEnfoque",
  estado "TipoEstadoTarea" NOT NULL DEFAULT 'por_hacer',
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT tareas_estrategicas_proyecto_id_fkey
    FOREIGN KEY (proyecto_id) REFERENCES proyectos_estrategicos(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS subtareas (
  id SERIAL PRIMARY KEY,
  tarea_estrategica_id INTEGER NOT NULL,
  titulo VARCHAR(255) NOT NULL,
  completada BOOLEAN NOT NULL DEFAULT false,
  tiempo_estimado_minutos INTEGER,
  moscow "TipoMoscow",
  destreza_principal_id INTEGER,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT subtareas_tarea_estrategica_id_fkey
    FOREIGN KEY (tarea_estrategica_id) REFERENCES tareas_estrategicas(id) ON DELETE RESTRICT,
  CONSTRAINT subtareas_destreza_principal_id_fkey
    FOREIGN KEY (destreza_principal_id) REFERENCES destrezas(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS logs_generacion_ia (
  id SERIAL PRIMARY KEY,
  proyecto_id INTEGER,
  tipo_generacion VARCHAR(50),
  modelo_ia VARCHAR(100),
  tokens_usados INTEGER,
  prompt TEXT,
  respuesta TEXT,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT logs_generacion_ia_proyecto_id_fkey
    FOREIGN KEY (proyecto_id) REFERENCES proyectos_estrategicos(id) ON DELETE SET NULL
);

-- Add foreign keys if tables existed before
DO $$ BEGIN
  ALTER TABLE ideas_capturadas
    ADD CONSTRAINT ideas_capturadas_proyecto_estrategico_id_fkey
    FOREIGN KEY (proyecto_estrategico_id) REFERENCES proyectos_estrategicos(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE tareas
    ADD CONSTRAINT tareas_proyecto_estrategico_id_fkey
    FOREIGN KEY (proyecto_estrategico_id) REFERENCES proyectos_estrategicos(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS ideas_capturadas_notaAudioId_idx ON ideas_capturadas(notaAudioId);
CREATE INDEX IF NOT EXISTS ideas_capturadas_implementada_idx ON ideas_capturadas(implementada);
CREATE INDEX IF NOT EXISTS ideas_capturadas_categoria_idx ON ideas_capturadas(categoria);
