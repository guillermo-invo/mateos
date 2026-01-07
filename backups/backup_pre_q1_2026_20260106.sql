--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 15.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: Categoria; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."Categoria" AS ENUM (
    'TRABAJO',
    'PERSONAL',
    'SOCIAL',
    'OTRO'
);


ALTER TYPE public."Categoria" OWNER TO asistente;

--
-- Name: EstadoProcesamiento; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."EstadoProcesamiento" AS ENUM (
    'PROCESANDO',
    'COMPLETADO',
    'ERROR'
);


ALTER TYPE public."EstadoProcesamiento" OWNER TO asistente;

--
-- Name: Prioridad; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."Prioridad" AS ENUM (
    'BAJA',
    'MEDIA',
    'ALTA',
    'URGENTE'
);


ALTER TYPE public."Prioridad" OWNER TO asistente;

--
-- Name: TipoEisenhower; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoEisenhower" AS ENUM (
    'cuadrante_1',
    'cuadrante_2',
    'cuadrante_3',
    'cuadrante_4'
);


ALTER TYPE public."TipoEisenhower" OWNER TO asistente;

--
-- Name: TipoEnergia; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoEnergia" AS ENUM (
    'relax',
    'baja',
    'media',
    'alta',
    'pico'
);


ALTER TYPE public."TipoEnergia" OWNER TO asistente;

--
-- Name: TipoEnfoque; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoEnfoque" AS ENUM (
    'velocidad',
    'perfeccion',
    'balanceado'
);


ALTER TYPE public."TipoEnfoque" OWNER TO asistente;

--
-- Name: TipoEstadoKanban; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoEstadoKanban" AS ENUM (
    'freezer',
    'backlog',
    'waiting',
    'todo',
    'doing',
    'done'
);


ALTER TYPE public."TipoEstadoKanban" OWNER TO asistente;

--
-- Name: TipoEstadoProyecto; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoEstadoProyecto" AS ENUM (
    'idea',
    'planificacion',
    'en_curso',
    'pausado',
    'completado',
    'cancelado',
    'archivado'
);


ALTER TYPE public."TipoEstadoProyecto" OWNER TO asistente;

--
-- Name: TipoEstadoTarea; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoEstadoTarea" AS ENUM (
    'por_hacer',
    'en_progreso',
    'bloqueada',
    'en_revision',
    'completada',
    'cancelada'
);


ALTER TYPE public."TipoEstadoTarea" OWNER TO asistente;

--
-- Name: TipoImpacto; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoImpacto" AS ENUM (
    'alto',
    'medio',
    'bajo'
);


ALTER TYPE public."TipoImpacto" OWNER TO asistente;

--
-- Name: TipoLibertad; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoLibertad" AS ENUM (
    'receta',
    'resultado',
    'mixto'
);


ALTER TYPE public."TipoLibertad" OWNER TO asistente;

--
-- Name: TipoMoscow; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoMoscow" AS ENUM (
    'must',
    'should',
    'could',
    'wont'
);


ALTER TYPE public."TipoMoscow" OWNER TO asistente;

--
-- Name: TipoRiesgo; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoRiesgo" AS ENUM (
    'bajo',
    'medio',
    'alto',
    'critico'
);


ALTER TYPE public."TipoRiesgo" OWNER TO asistente;

--
-- Name: TipoUrgencia; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."TipoUrgencia" AS ENUM (
    'alta',
    'media',
    'baja'
);


ALTER TYPE public."TipoUrgencia" OWNER TO asistente;

--
-- Name: calcular_eisenhower(); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.calcular_eisenhower() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Cuadrante 1: urgente + importante
  IF (NEW.moscow = 'must' AND NEW.urgencia = 'alta') OR
     (NEW.nivel_riesgo IN ('alto', 'critico')) OR
     (NEW.impacto = 'alto' AND NEW.urgencia = 'alta') THEN
    NEW.eisenhower := 'cuadrante_1';

  -- Cuadrante 2: no urgente + importante
  ELSIF (NEW.moscow IN ('must', 'should') AND NEW.urgencia IN ('media', 'baja')) OR
        (NEW.impacto = 'alto' AND NEW.nivel_riesgo IN ('bajo', 'medio')) THEN
    NEW.eisenhower := 'cuadrante_2';

  -- Cuadrante 3: urgente + no importante
  ELSIF (NEW.moscow = 'could' AND NEW.urgencia = 'alta') OR
        (NEW.impacto = 'bajo' AND NEW.urgencia = 'alta') THEN
    NEW.eisenhower := 'cuadrante_3';

  -- Cuadrante 4: no urgente + no importante
  ELSIF (NEW.moscow IN ('could', 'wont')) OR
        (NEW.impacto = 'bajo' AND NEW.urgencia = 'baja') THEN
    NEW.eisenhower := 'cuadrante_4';

  ELSE
    -- Default: cuadrante 2 (importante pero no urgente)
    NEW.eisenhower := 'cuadrante_2';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.calcular_eisenhower() OWNER TO asistente;

--
-- Name: calcular_tiempo_disponible_dia(date); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.calcular_tiempo_disponible_dia(fecha_param date) RETURNS TABLE(fecha date, dia_semana integer, horas_disponibles numeric, horas_recurrentes numeric, horas_bloques_planificados numeric, horas_libres numeric, estado character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.calcular_tiempo_disponible_dia(fecha_param date) OWNER TO asistente;

--
-- Name: FUNCTION calcular_tiempo_disponible_dia(fecha_param date); Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON FUNCTION public.calcular_tiempo_disponible_dia(fecha_param date) IS 'Calcula tiempo disponible en un día considerando recurrentes y bloques planificados';


--
-- Name: get_config(character varying); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.get_config(clave_param character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_config(clave_param character varying) OWNER TO asistente;

--
-- Name: get_config_bool(character varying); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.get_config_bool(clave_param character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (get_config(clave_param))::TEXT::BOOLEAN;
END;
$$;


ALTER FUNCTION public.get_config_bool(clave_param character varying) OWNER TO asistente;

--
-- Name: get_config_numero(character varying); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.get_config_numero(clave_param character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (get_config(clave_param))::TEXT::NUMERIC;
END;
$$;


ALTER FUNCTION public.get_config_numero(clave_param character varying) OWNER TO asistente;

--
-- Name: get_config_texto(character varying); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.get_config_texto(clave_param character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN (get_config(clave_param))::TEXT;
END;
$$;


ALTER FUNCTION public.get_config_texto(clave_param character varying) OWNER TO asistente;

--
-- Name: mateos_set_config(character varying, jsonb); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.mateos_set_config(clave_param character varying, valor_param jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO configuracion_personal (clave, valor)
  VALUES (clave_param, valor_param)
  ON CONFLICT (clave)
  DO UPDATE SET valor = valor_param, updated_at = NOW();
END;
$$;


ALTER FUNCTION public.mateos_set_config(clave_param character varying, valor_param jsonb) OWNER TO asistente;

--
-- Name: obtener_disponibilidad_rango(date, date); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.obtener_disponibilidad_rango(fecha_inicio date, fecha_fin date) RETURNS TABLE(total_dias integer, total_horas_teoricas numeric, total_horas_recurrentes numeric, total_horas_disponibles numeric, porcentaje_ocupado numeric)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.obtener_disponibilidad_rango(fecha_inicio date, fecha_fin date) OWNER TO asistente;

--
-- Name: FUNCTION obtener_disponibilidad_rango(fecha_inicio date, fecha_fin date); Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON FUNCTION public.obtener_disponibilidad_rango(fecha_inicio date, fecha_fin date) IS 'Calcula disponibilidad total en un rango de fechas';


--
-- Name: set_subtarea_proyecto_nombre(); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.set_subtarea_proyecto_nombre() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Set proyecto_nombre when creating new subtarea
  SELECT pe.nombre INTO NEW.proyecto_nombre
  FROM tareas_estrategicas te
  JOIN proyectos_estrategicos pe ON te.proyecto_id = pe.id
  WHERE te.id = NEW.tarea_estrategica_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_subtarea_proyecto_nombre() OWNER TO asistente;

--
-- Name: update_subtareas_proyecto_nombre(); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.update_subtareas_proyecto_nombre() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Update all subtareas when a project name changes
  UPDATE subtareas_estrategicas se
  SET proyecto_nombre = NEW.nombre
  FROM tareas_estrategicas te
  WHERE se.tarea_estrategica_id = te.id
    AND te.proyecto_id = NEW.id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_subtareas_proyecto_nombre() OWNER TO asistente;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO asistente;

--
-- Name: validar_patron_recurrencia(jsonb); Type: FUNCTION; Schema: public; Owner: asistente
--

CREATE FUNCTION public.validar_patron_recurrencia(patron jsonb) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.validar_patron_recurrencia(patron jsonb) OWNER TO asistente;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO asistente;

--
-- Name: areas_vida; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.areas_vida (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    color_hex character varying(7),
    orden_visualizacion integer,
    activa boolean
);


ALTER TABLE public.areas_vida OWNER TO asistente;

--
-- Name: TABLE areas_vida; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.areas_vida IS 'Campos de vida donde Guillermo desarrolla proyectos';


--
-- Name: areas_vida_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.areas_vida_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.areas_vida_id_seq OWNER TO asistente;

--
-- Name: areas_vida_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.areas_vida_id_seq OWNED BY public.areas_vida.id;


--
-- Name: bloques_tiempo_planificados; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.bloques_tiempo_planificados (
    id integer NOT NULL,
    fecha date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    tipo_bloque character varying(50) NOT NULL,
    tarea_estrategica_id integer,
    tarea_recurrente_id integer,
    proyecto_estrategico_id integer,
    area_vida_id integer,
    descripcion_libre text,
    notas text,
    google_calendar_event_id character varying(255),
    sincronizado_calendar boolean DEFAULT false,
    ultimo_sync timestamp without time zone,
    completado boolean DEFAULT false,
    fecha_completado timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT bloques_tiempo_planificados_tipo_bloque_check CHECK (((tipo_bloque)::text = ANY ((ARRAY['tarea_estrategica'::character varying, 'tarea_recurrente'::character varying, 'proyecto_foco'::character varying, 'buffer'::character varying, 'reunion'::character varying, 'compromiso'::character varying, 'otro'::character varying])::text[]))),
    CONSTRAINT check_hora_valida CHECK ((hora_fin > hora_inicio)),
    CONSTRAINT check_tiene_contenido CHECK (((tarea_estrategica_id IS NOT NULL) OR (tarea_recurrente_id IS NOT NULL) OR (proyecto_estrategico_id IS NOT NULL) OR (area_vida_id IS NOT NULL) OR (descripcion_libre IS NOT NULL)))
);


ALTER TABLE public.bloques_tiempo_planificados OWNER TO asistente;

--
-- Name: TABLE bloques_tiempo_planificados; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.bloques_tiempo_planificados IS 'Bloques de tiempo planificados para la semana (chunks en Google Calendar)';


--
-- Name: COLUMN bloques_tiempo_planificados.tipo_bloque; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.bloques_tiempo_planificados.tipo_bloque IS 'Tipo de actividad planificada en este bloque';


--
-- Name: COLUMN bloques_tiempo_planificados.descripcion_libre; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.bloques_tiempo_planificados.descripcion_libre IS 'Descripción cuando no está vinculado a entidad específica';


--
-- Name: COLUMN bloques_tiempo_planificados.google_calendar_event_id; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.bloques_tiempo_planificados.google_calendar_event_id IS 'ID del evento en Google Calendar';


--
-- Name: COLUMN bloques_tiempo_planificados.sincronizado_calendar; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.bloques_tiempo_planificados.sincronizado_calendar IS 'Si el bloque está sincronizado con Google Calendar';


--
-- Name: proyectos_estrategicos; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.proyectos_estrategicos (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    descripcion text,
    areas_ids integer[],
    motivos_ids integer[],
    destrezas_requeridas_ids integer[],
    dificultades_ids integer[],
    misiones_ids integer[],
    justificacion_estrategica jsonb,
    objetivos_smart jsonb,
    fecha_inicio date,
    fecha_fin_estimada date,
    estado public."TipoEstadoProyecto" DEFAULT 'idea'::public."TipoEstadoProyecto" NOT NULL,
    prioridad_global numeric(3,2),
    score_motivacional numeric(3,2),
    score_alineacion numeric(3,2),
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.proyectos_estrategicos OWNER TO asistente;

--
-- Name: tareas_estrategicas; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.tareas_estrategicas (
    id integer NOT NULL,
    proyecto_id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    descripcion text,
    orden integer,
    moscow public."TipoMoscow",
    tiempo_estimado_horas integer,
    nivel_riesgo public."TipoRiesgo",
    prioridad_velocidad_perfeccion public."TipoEnfoque",
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    estado_kanban public."TipoEstadoKanban" DEFAULT 'backlog'::public."TipoEstadoKanban",
    fecha_done timestamp without time zone,
    impacto public."TipoImpacto",
    urgencia public."TipoUrgencia",
    eisenhower public."TipoEisenhower",
    energia_requerida character varying(20),
    contexto_necesario character varying(50),
    duracion_real_horas numeric(5,2),
    bloqueada_por text,
    fecha_estimada_desbloqueo date,
    CONSTRAINT tareas_estrategicas_contexto_necesario_check CHECK (((contexto_necesario)::text = ANY ((ARRAY['casa'::character varying, 'oficina'::character varying, 'anywhere'::character varying, 'movil'::character varying])::text[]))),
    CONSTRAINT tareas_estrategicas_duracion_real_horas_check CHECK ((duracion_real_horas >= (0)::numeric)),
    CONSTRAINT tareas_estrategicas_energia_requerida_check CHECK (((energia_requerida)::text = ANY ((ARRAY['baja'::character varying, 'media'::character varying, 'alta'::character varying])::text[])))
);


ALTER TABLE public.tareas_estrategicas OWNER TO asistente;

--
-- Name: COLUMN tareas_estrategicas.estado_kanban; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.estado_kanban IS 'Estado en el tablero Kanban: freezer, backlog, waiting, todo, doing, done';


--
-- Name: COLUMN tareas_estrategicas.fecha_done; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.fecha_done IS 'Timestamp cuando la tarea pasó a estado done';


--
-- Name: COLUMN tareas_estrategicas.eisenhower; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.eisenhower IS 'Matriz de Eisenhower calculada automáticamente: cuadrante_1 (urgente+importante), cuadrante_2 (importante), cuadrante_3 (urgente), cuadrante_4 (no urgente ni importante)';


--
-- Name: COLUMN tareas_estrategicas.energia_requerida; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.energia_requerida IS 'Nivel de energía mental/física necesaria';


--
-- Name: COLUMN tareas_estrategicas.contexto_necesario; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.contexto_necesario IS 'Dónde se puede realizar la tarea';


--
-- Name: COLUMN tareas_estrategicas.duracion_real_horas; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.duracion_real_horas IS 'Tiempo real que tomó (para mejorar estimaciones)';


--
-- Name: COLUMN tareas_estrategicas.bloqueada_por; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.bloqueada_por IS 'Descripción de qué está bloqueando esta tarea';


--
-- Name: COLUMN tareas_estrategicas.fecha_estimada_desbloqueo; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_estrategicas.fecha_estimada_desbloqueo IS 'Cuándo se espera que se desbloquee';


--
-- Name: tareas_recurrentes; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.tareas_recurrentes (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    descripcion text,
    area_id integer,
    proyecto_estrategico_id integer,
    tipo character varying(50),
    patron_recurrencia jsonb NOT NULL,
    duracion_estimada_minutos integer NOT NULL,
    energia_requerida character varying(20),
    contexto_necesario character varying(50),
    criticidad character varying(20),
    impacto character varying(20),
    activa boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT check_patron_valido CHECK (public.validar_patron_recurrencia(patron_recurrencia)),
    CONSTRAINT tareas_recurrentes_contexto_necesario_check CHECK (((contexto_necesario)::text = ANY ((ARRAY['casa'::character varying, 'oficina'::character varying, 'anywhere'::character varying, 'movil'::character varying])::text[]))),
    CONSTRAINT tareas_recurrentes_criticidad_check CHECK (((criticidad)::text = ANY ((ARRAY['must'::character varying, 'should'::character varying, 'could'::character varying])::text[]))),
    CONSTRAINT tareas_recurrentes_duracion_estimada_minutos_check CHECK ((duracion_estimada_minutos > 0)),
    CONSTRAINT tareas_recurrentes_energia_requerida_check CHECK (((energia_requerida)::text = ANY ((ARRAY['baja'::character varying, 'media'::character varying, 'alta'::character varying])::text[]))),
    CONSTRAINT tareas_recurrentes_impacto_check CHECK (((impacto)::text = ANY ((ARRAY['alto'::character varying, 'medio'::character varying, 'bajo'::character varying])::text[]))),
    CONSTRAINT tareas_recurrentes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['habito'::character varying, 'mantenimiento'::character varying, 'comunicacion'::character varying, 'administrativo'::character varying, 'otro'::character varying])::text[])))
);


ALTER TABLE public.tareas_recurrentes OWNER TO asistente;

--
-- Name: TABLE tareas_recurrentes; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.tareas_recurrentes IS 'Tareas que se repiten periódicamente (hábitos, mantenimiento, comunicación)';


--
-- Name: COLUMN tareas_recurrentes.patron_recurrencia; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_recurrentes.patron_recurrencia IS 'Configuración JSON del patrón de recurrencia (tipo, intervalo, días, etc.)';


--
-- Name: COLUMN tareas_recurrentes.energia_requerida; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_recurrentes.energia_requerida IS 'Nivel de energía mental/física necesaria';


--
-- Name: COLUMN tareas_recurrentes.contexto_necesario; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_recurrentes.contexto_necesario IS 'Dónde se puede realizar la tarea';


--
-- Name: COLUMN tareas_recurrentes.criticidad; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.tareas_recurrentes.criticidad IS 'must: crítica | should: importante | could: deseable';


--
-- Name: bloques_proxima_semana; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.bloques_proxima_semana AS
 SELECT b.id,
    b.fecha,
        CASE
            WHEN (EXTRACT(dow FROM b.fecha) = (0)::numeric) THEN 7
            ELSE (EXTRACT(dow FROM b.fecha))::integer
        END AS dia_semana,
    b.hora_inicio,
    b.hora_fin,
    (EXTRACT(epoch FROM (b.hora_fin - b.hora_inicio)) / (3600)::numeric) AS duracion_horas,
    b.tipo_bloque,
    COALESCE(te.nombre, tr.nombre, p.nombre, a.nombre, (b.descripcion_libre)::character varying) AS contenido,
    te.nombre AS tarea_estrategica,
    tr.nombre AS tarea_recurrente,
    p.nombre AS proyecto,
    a.nombre AS area,
    b.completado,
    b.sincronizado_calendar,
    b.google_calendar_event_id,
    b.notas
   FROM ((((public.bloques_tiempo_planificados b
     LEFT JOIN public.tareas_estrategicas te ON ((b.tarea_estrategica_id = te.id)))
     LEFT JOIN public.tareas_recurrentes tr ON ((b.tarea_recurrente_id = tr.id)))
     LEFT JOIN public.proyectos_estrategicos p ON ((b.proyecto_estrategico_id = p.id)))
     LEFT JOIN public.areas_vida a ON ((b.area_vida_id = a.id)))
  WHERE ((b.fecha >= CURRENT_DATE) AND (b.fecha < (CURRENT_DATE + '7 days'::interval)))
  ORDER BY b.fecha, b.hora_inicio;


ALTER TABLE public.bloques_proxima_semana OWNER TO asistente;

--
-- Name: VIEW bloques_proxima_semana; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.bloques_proxima_semana IS 'Bloques de tiempo planificados para la próxima semana';


--
-- Name: bloques_tiempo_planificados_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.bloques_tiempo_planificados_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bloques_tiempo_planificados_id_seq OWNER TO asistente;

--
-- Name: bloques_tiempo_planificados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.bloques_tiempo_planificados_id_seq OWNED BY public.bloques_tiempo_planificados.id;


--
-- Name: instancias_tareas_recurrentes; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.instancias_tareas_recurrentes (
    id integer NOT NULL,
    tarea_recurrente_id integer NOT NULL,
    fecha_programada date NOT NULL,
    hora_inicio time without time zone,
    hora_fin time without time zone,
    completada boolean DEFAULT false,
    fecha_completada timestamp without time zone,
    saltada boolean DEFAULT false,
    razon_saltada text,
    duracion_real_minutos integer,
    google_calendar_event_id character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT instancias_tareas_recurrentes_duracion_real_minutos_check CHECK ((duracion_real_minutos >= 0))
);


ALTER TABLE public.instancias_tareas_recurrentes OWNER TO asistente;

--
-- Name: TABLE instancias_tareas_recurrentes; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.instancias_tareas_recurrentes IS 'Instancias específicas generadas de tareas recurrentes para fechas concretas';


--
-- Name: COLUMN instancias_tareas_recurrentes.saltada; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.instancias_tareas_recurrentes.saltada IS 'true si se decidió conscientemente no hacer esta instancia';


--
-- Name: COLUMN instancias_tareas_recurrentes.duracion_real_minutos; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.instancias_tareas_recurrentes.duracion_real_minutos IS 'Tiempo real que tomó (para aprender y ajustar estimaciones)';


--
-- Name: carga_semanal_recurrentes; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.carga_semanal_recurrentes AS
 SELECT EXTRACT(dow FROM i.fecha_programada) AS dia_semana_dow,
        CASE
            WHEN (EXTRACT(dow FROM i.fecha_programada) = (0)::numeric) THEN 7
            ELSE (EXTRACT(dow FROM i.fecha_programada))::integer
        END AS dia_semana,
    count(*) AS cantidad_tareas,
    ((sum(t.duracion_estimada_minutos))::numeric / 60.0) AS horas_totales,
    ((sum(
        CASE
            WHEN ((t.criticidad)::text = 'must'::text) THEN t.duracion_estimada_minutos
            ELSE 0
        END))::numeric / 60.0) AS horas_must,
    ((sum(
        CASE
            WHEN ((t.criticidad)::text = 'should'::text) THEN t.duracion_estimada_minutos
            ELSE 0
        END))::numeric / 60.0) AS horas_should,
    ((sum(
        CASE
            WHEN ((t.criticidad)::text = 'could'::text) THEN t.duracion_estimada_minutos
            ELSE 0
        END))::numeric / 60.0) AS horas_could,
    ((sum(
        CASE
            WHEN ((t.energia_requerida)::text = 'alta'::text) THEN t.duracion_estimada_minutos
            ELSE 0
        END))::numeric / 60.0) AS horas_energia_alta
   FROM (public.instancias_tareas_recurrentes i
     JOIN public.tareas_recurrentes t ON ((i.tarea_recurrente_id = t.id)))
  WHERE ((i.fecha_programada >= CURRENT_DATE) AND (i.fecha_programada < (CURRENT_DATE + '7 days'::interval)) AND (i.saltada = false) AND (t.activa = true))
  GROUP BY
        CASE
            WHEN (EXTRACT(dow FROM i.fecha_programada) = (0)::numeric) THEN 7
            ELSE (EXTRACT(dow FROM i.fecha_programada))::integer
        END, (EXTRACT(dow FROM i.fecha_programada))
  ORDER BY
        CASE
            WHEN (EXTRACT(dow FROM i.fecha_programada) = (0)::numeric) THEN 7
            ELSE (EXTRACT(dow FROM i.fecha_programada))::integer
        END;


ALTER TABLE public.carga_semanal_recurrentes OWNER TO asistente;

--
-- Name: VIEW carga_semanal_recurrentes; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.carga_semanal_recurrentes IS 'Carga horaria de tareas recurrentes por día de la semana (próximos 7 días)';


--
-- Name: compromisos; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.compromisos (
    id integer NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    "personaNombre" text NOT NULL,
    "fechaLimite" timestamp(3) without time zone,
    "yoMeComprometi" boolean DEFAULT false NOT NULL,
    cumplido boolean DEFAULT false NOT NULL,
    "fechaCumplido" timestamp(3) without time zone,
    "notaAudioId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.compromisos OWNER TO asistente;

--
-- Name: compromisos_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.compromisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.compromisos_id_seq OWNER TO asistente;

--
-- Name: compromisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.compromisos_id_seq OWNED BY public.compromisos.id;


--
-- Name: compromisos_proximos; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.compromisos_proximos AS
 SELECT c.id,
    c.titulo,
    c."personaNombre" AS persona_nombre,
    c."fechaLimite" AS fecha_limite,
    c."yoMeComprometi" AS yo_me_comprometi,
    CURRENT_DATE AS hoy,
    (c."fechaLimite" - (CURRENT_DATE)::timestamp without time zone) AS dias_restantes,
        CASE
            WHEN (c."fechaLimite" < CURRENT_DATE) THEN '🔴 VENCIDO'::text
            WHEN (c."fechaLimite" = CURRENT_DATE) THEN '🔴 HOY'::text
            WHEN (c."fechaLimite" <= (CURRENT_DATE + '1 day'::interval)) THEN '🟠 MAÑANA'::text
            WHEN (c."fechaLimite" <= (CURRENT_DATE + ((public.get_config_numero('dias_anticipacion_compromisos'::character varying))::double precision * '1 day'::interval))) THEN '🟡 PRÓXIMO'::text
            ELSE '✅ A TIEMPO'::text
        END AS urgencia,
        CASE
            WHEN c."yoMeComprometi" THEN '👤 YO prometí'::text
            ELSE '👥 Otros prometieron'::text
        END AS tipo_compromiso
   FROM public.compromisos c
  WHERE ((c.cumplido = false) AND (c."fechaLimite" IS NOT NULL))
  ORDER BY
        CASE
            WHEN (c."fechaLimite" < CURRENT_DATE) THEN 1
            WHEN (c."fechaLimite" <= (CURRENT_DATE + '1 day'::interval)) THEN 2
            WHEN (c."fechaLimite" <= (CURRENT_DATE + ((public.get_config_numero('dias_anticipacion_compromisos'::character varying))::double precision * '1 day'::interval))) THEN 3
            ELSE 4
        END, c."fechaLimite";


ALTER TABLE public.compromisos_proximos OWNER TO asistente;

--
-- Name: VIEW compromisos_proximos; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.compromisos_proximos IS 'Compromisos ordenados por urgencia (crítico para marca personal)';


--
-- Name: configuracion_personal; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.configuracion_personal (
    clave character varying(100) NOT NULL,
    valor jsonb NOT NULL,
    descripcion text,
    categoria character varying(50),
    tipo_dato character varying(20),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.configuracion_personal OWNER TO asistente;

--
-- Name: TABLE configuracion_personal; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.configuracion_personal IS 'Configuraciones y preferencias del sistema Mateos';


--
-- Name: COLUMN configuracion_personal.valor; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.configuracion_personal.valor IS 'Valor en formato JSONB para flexibilidad';


--
-- Name: COLUMN configuracion_personal.categoria; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.configuracion_personal.categoria IS 'Categoría de la configuración para organización';


--
-- Name: configuracion_por_categoria; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.configuracion_por_categoria AS
 SELECT configuracion_personal.categoria,
    count(*) AS num_configuraciones,
    jsonb_object_agg(configuracion_personal.clave, configuracion_personal.valor) AS configuraciones
   FROM public.configuracion_personal
  WHERE (configuracion_personal.categoria IS NOT NULL)
  GROUP BY configuracion_personal.categoria
  ORDER BY configuracion_personal.categoria;


ALTER TABLE public.configuracion_por_categoria OWNER TO asistente;

--
-- Name: destrezas; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.destrezas (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    categoria character varying(50),
    nivel_actual integer,
    descripcion text,
    costo_energetico public."TipoEnergia",
    mejor_momento_dia text[],
    requiere_flow boolean,
    notas_contexto text
);


ALTER TABLE public.destrezas OWNER TO asistente;

--
-- Name: TABLE destrezas; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.destrezas IS 'Habilidades y capacidades de Guillermo con metadata de contexto de ejecución';


--
-- Name: destrezas_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.destrezas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.destrezas_id_seq OWNER TO asistente;

--
-- Name: destrezas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.destrezas_id_seq OWNED BY public.destrezas.id;


--
-- Name: dificultades; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.dificultades (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    categoria character varying(50),
    nivel_impacto integer,
    descripcion text,
    estrategia_mitigacion text
);


ALTER TABLE public.dificultades OWNER TO asistente;

--
-- Name: TABLE dificultades; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.dificultades IS 'Desafíos personales de Guillermo con estrategias de mitigación';


--
-- Name: dificultades_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.dificultades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dificultades_id_seq OWNER TO asistente;

--
-- Name: dificultades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.dificultades_id_seq OWNED BY public.dificultades.id;


--
-- Name: disponibilidad_semanal; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.disponibilidad_semanal (
    id integer NOT NULL,
    dia_semana integer NOT NULL,
    horas_disponibles numeric(4,2) NOT NULL,
    momento_optimo character varying(20),
    notas text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT disponibilidad_semanal_dia_semana_check CHECK (((dia_semana >= 1) AND (dia_semana <= 7))),
    CONSTRAINT disponibilidad_semanal_horas_disponibles_check CHECK (((horas_disponibles >= (0)::numeric) AND (horas_disponibles <= (24)::numeric))),
    CONSTRAINT disponibilidad_semanal_momento_optimo_check CHECK (((momento_optimo)::text = ANY ((ARRAY['maniana'::character varying, 'tarde'::character varying, 'noche'::character varying, 'todo_el_dia'::character varying])::text[])))
);


ALTER TABLE public.disponibilidad_semanal OWNER TO asistente;

--
-- Name: TABLE disponibilidad_semanal; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.disponibilidad_semanal IS 'Horas productivas disponibles por día de la semana (configuración base)';


--
-- Name: COLUMN disponibilidad_semanal.dia_semana; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.disponibilidad_semanal.dia_semana IS '1=lunes, 2=martes, 3=miércoles, 4=jueves, 5=viernes, 6=sábado, 7=domingo';


--
-- Name: COLUMN disponibilidad_semanal.horas_disponibles; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.disponibilidad_semanal.horas_disponibles IS 'Horas productivas teóricas disponibles';


--
-- Name: COLUMN disponibilidad_semanal.momento_optimo; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.disponibilidad_semanal.momento_optimo IS 'Momento del día con mayor energía/productividad';


--
-- Name: disponibilidad_real_semanal; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.disponibilidad_real_semanal AS
 SELECT d.dia_semana,
        CASE d.dia_semana
            WHEN 1 THEN 'Lunes'::text
            WHEN 2 THEN 'Martes'::text
            WHEN 3 THEN 'Miércoles'::text
            WHEN 4 THEN 'Jueves'::text
            WHEN 5 THEN 'Viernes'::text
            WHEN 6 THEN 'Sábado'::text
            WHEN 7 THEN 'Domingo'::text
            ELSE NULL::text
        END AS dia_nombre,
    d.horas_disponibles AS horas_teoricas,
    COALESCE(r.horas_totales, (0)::numeric) AS horas_recurrentes,
    COALESCE(r.horas_must, (0)::numeric) AS horas_recurrentes_must,
    COALESCE(r.horas_should, (0)::numeric) AS horas_recurrentes_should,
    COALESCE(r.cantidad_tareas, (0)::bigint) AS num_tareas_recurrentes,
    (d.horas_disponibles - COALESCE(r.horas_totales, (0)::numeric)) AS horas_disponibles_proyectos,
    d.momento_optimo,
    d.notas,
        CASE
            WHEN ((d.horas_disponibles - COALESCE(r.horas_totales, (0)::numeric)) < (0)::numeric) THEN 'SOBRECARGA'::text
            WHEN ((d.horas_disponibles - COALESCE(r.horas_totales, (0)::numeric)) < (1)::numeric) THEN 'SATURADO'::text
            WHEN ((d.horas_disponibles - COALESCE(r.horas_totales, (0)::numeric)) < (2)::numeric) THEN 'JUSTO'::text
            ELSE 'HOLGADO'::text
        END AS estado_carga,
    round(((COALESCE(r.horas_totales, (0)::numeric) / NULLIF(d.horas_disponibles, (0)::numeric)) * (100)::numeric), 1) AS porcentaje_ocupado
   FROM (public.disponibilidad_semanal d
     LEFT JOIN public.carga_semanal_recurrentes r ON ((d.dia_semana = r.dia_semana)))
  ORDER BY d.dia_semana;


ALTER TABLE public.disponibilidad_real_semanal OWNER TO asistente;

--
-- Name: VIEW disponibilidad_real_semanal; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.disponibilidad_real_semanal IS 'Disponibilidad real por día (horas teóricas - horas recurrentes)';


--
-- Name: disponibilidad_semanal_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.disponibilidad_semanal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.disponibilidad_semanal_id_seq OWNER TO asistente;

--
-- Name: disponibilidad_semanal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.disponibilidad_semanal_id_seq OWNED BY public.disponibilidad_semanal.id;


--
-- Name: tiempo_por_area_semana; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.tiempo_por_area_semana AS
 SELECT a.nombre AS area,
    a.color_hex,
    COALESCE(sum(
        CASE
            WHEN ((i.fecha_programada >= CURRENT_DATE) AND (i.fecha_programada < (CURRENT_DATE + '7 days'::interval))) THEN ((t.duracion_estimada_minutos)::numeric / 60.0)
            ELSE (0)::numeric
        END), (0)::numeric) AS horas_recurrentes_semana,
    count(DISTINCT
        CASE
            WHEN (p.estado = 'en_curso'::public."TipoEstadoProyecto") THEN p.id
            ELSE NULL::integer
        END) AS proyectos_activos,
    COALESCE(sum(
        CASE
            WHEN (te.estado_kanban = ANY (ARRAY['todo'::public."TipoEstadoKanban", 'doing'::public."TipoEstadoKanban"])) THEN te.tiempo_estimado_horas
            ELSE 0
        END), (0)::bigint) AS horas_tareas_estrategicas_pendientes,
    (COALESCE(sum(
        CASE
            WHEN ((i.fecha_programada >= CURRENT_DATE) AND (i.fecha_programada < (CURRENT_DATE + '7 days'::interval))) THEN ((t.duracion_estimada_minutos)::numeric / 60.0)
            ELSE (0)::numeric
        END), (0)::numeric) + (COALESCE(sum(
        CASE
            WHEN (te.estado_kanban = ANY (ARRAY['todo'::public."TipoEstadoKanban", 'doing'::public."TipoEstadoKanban"])) THEN te.tiempo_estimado_horas
            ELSE 0
        END), (0)::bigint))::numeric) AS horas_totales
   FROM ((((public.areas_vida a
     LEFT JOIN public.tareas_recurrentes t ON (((t.area_id = a.id) AND (t.activa = true))))
     LEFT JOIN public.instancias_tareas_recurrentes i ON ((i.tarea_recurrente_id = t.id)))
     LEFT JOIN public.proyectos_estrategicos p ON ((a.id = ANY (p.areas_ids))))
     LEFT JOIN public.tareas_estrategicas te ON ((te.proyecto_id = p.id)))
  WHERE (a.activa IS NOT FALSE)
  GROUP BY a.id, a.nombre, a.color_hex
  ORDER BY (COALESCE(sum(
        CASE
            WHEN ((i.fecha_programada >= CURRENT_DATE) AND (i.fecha_programada < (CURRENT_DATE + '7 days'::interval))) THEN ((t.duracion_estimada_minutos)::numeric / 60.0)
            ELSE (0)::numeric
        END), (0)::numeric) + (COALESCE(sum(
        CASE
            WHEN (te.estado_kanban = ANY (ARRAY['todo'::public."TipoEstadoKanban", 'doing'::public."TipoEstadoKanban"])) THEN te.tiempo_estimado_horas
            ELSE 0
        END), (0)::bigint))::numeric) DESC;


ALTER TABLE public.tiempo_por_area_semana OWNER TO asistente;

--
-- Name: VIEW tiempo_por_area_semana; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.tiempo_por_area_semana IS 'Distribución de tiempo por área de vida (semana actual)';


--
-- Name: distribucion_porcentual_areas; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.distribucion_porcentual_areas AS
 SELECT tiempo_por_area_semana.area,
    tiempo_por_area_semana.horas_totales,
    round(((tiempo_por_area_semana.horas_totales / NULLIF(sum(tiempo_por_area_semana.horas_totales) OVER (), (0)::numeric)) * (100)::numeric), 1) AS porcentaje
   FROM public.tiempo_por_area_semana
  WHERE (tiempo_por_area_semana.horas_totales > (0)::numeric)
  ORDER BY tiempo_por_area_semana.horas_totales DESC;


ALTER TABLE public.distribucion_porcentual_areas OWNER TO asistente;

--
-- Name: VIEW distribucion_porcentual_areas; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.distribucion_porcentual_areas IS 'Distribución porcentual de tiempo por área';


--
-- Name: ideas_capturadas; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.ideas_capturadas (
    id integer NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    categoria text,
    implementada boolean DEFAULT false NOT NULL,
    "fechaImplementacion" timestamp(3) without time zone,
    "notaAudioId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    proyecto_estrategico_id integer
);


ALTER TABLE public.ideas_capturadas OWNER TO asistente;

--
-- Name: ideas_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.ideas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ideas_id_seq OWNER TO asistente;

--
-- Name: ideas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.ideas_id_seq OWNED BY public.ideas_capturadas.id;


--
-- Name: instancias_proxima_semana; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.instancias_proxima_semana AS
 SELECT i.id,
    i.fecha_programada,
    EXTRACT(dow FROM i.fecha_programada) AS dow,
        CASE
            WHEN (EXTRACT(dow FROM i.fecha_programada) = (0)::numeric) THEN 7
            ELSE (EXTRACT(dow FROM i.fecha_programada))::integer
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
   FROM (((public.instancias_tareas_recurrentes i
     JOIN public.tareas_recurrentes t ON ((i.tarea_recurrente_id = t.id)))
     LEFT JOIN public.areas_vida a ON ((t.area_id = a.id)))
     LEFT JOIN public.proyectos_estrategicos p ON ((t.proyecto_estrategico_id = p.id)))
  WHERE ((i.fecha_programada >= CURRENT_DATE) AND (i.fecha_programada < (CURRENT_DATE + '7 days'::interval)) AND (t.activa = true))
  ORDER BY i.fecha_programada, i.hora_inicio, t.criticidad DESC;


ALTER TABLE public.instancias_proxima_semana OWNER TO asistente;

--
-- Name: VIEW instancias_proxima_semana; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.instancias_proxima_semana IS 'Instancias de tareas recurrentes programadas para la próxima semana';


--
-- Name: instancias_tareas_recurrentes_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.instancias_tareas_recurrentes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.instancias_tareas_recurrentes_id_seq OWNER TO asistente;

--
-- Name: instancias_tareas_recurrentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.instancias_tareas_recurrentes_id_seq OWNED BY public.instancias_tareas_recurrentes.id;


--
-- Name: logs_generacion_ia; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.logs_generacion_ia (
    id integer NOT NULL,
    proyecto_id integer,
    tipo_generacion character varying(50),
    modelo_ia character varying(100),
    tokens_usados integer,
    prompt text,
    respuesta text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.logs_generacion_ia OWNER TO asistente;

--
-- Name: logs_generacion_ia_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.logs_generacion_ia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.logs_generacion_ia_id_seq OWNER TO asistente;

--
-- Name: logs_generacion_ia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.logs_generacion_ia_id_seq OWNED BY public.logs_generacion_ia.id;


--
-- Name: metricas_tareas_recurrentes; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.metricas_tareas_recurrentes AS
 SELECT t.nombre AS tarea,
    t.tipo,
    t.criticidad,
    count(i.id) AS instancias_programadas,
    count(
        CASE
            WHEN i.completada THEN 1
            ELSE NULL::integer
        END) AS instancias_completadas,
    count(
        CASE
            WHEN i.saltada THEN 1
            ELSE NULL::integer
        END) AS instancias_saltadas,
    round((((count(
        CASE
            WHEN i.completada THEN 1
            ELSE NULL::integer
        END))::numeric / (NULLIF(count(i.id), 0))::numeric) * (100)::numeric), 1) AS tasa_completitud,
    avg(i.duracion_real_minutos) AS duracion_promedio_real
   FROM (public.tareas_recurrentes t
     LEFT JOIN public.instancias_tareas_recurrentes i ON (((i.tarea_recurrente_id = t.id) AND (i.fecha_programada >= (CURRENT_DATE - '30 days'::interval)) AND (i.fecha_programada <= CURRENT_DATE))))
  WHERE (t.activa = true)
  GROUP BY t.id, t.nombre, t.tipo, t.criticidad
  ORDER BY t.criticidad DESC, (round((((count(
        CASE
            WHEN i.completada THEN 1
            ELSE NULL::integer
        END))::numeric / (NULLIF(count(i.id), 0))::numeric) * (100)::numeric), 1));


ALTER TABLE public.metricas_tareas_recurrentes OWNER TO asistente;

--
-- Name: VIEW metricas_tareas_recurrentes; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.metricas_tareas_recurrentes IS 'Métricas de completitud de tareas recurrentes (últimos 30 días)';


--
-- Name: misiones_vida; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.misiones_vida (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    vision text,
    prioridad integer
);


ALTER TABLE public.misiones_vida OWNER TO asistente;

--
-- Name: TABLE misiones_vida; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.misiones_vida IS 'Roles de vida y propósitos de Guillermo a largo plazo';


--
-- Name: misiones_vida_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.misiones_vida_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.misiones_vida_id_seq OWNER TO asistente;

--
-- Name: misiones_vida_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.misiones_vida_id_seq OWNED BY public.misiones_vida.id;


--
-- Name: motivos_personales; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.motivos_personales (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    icono character varying(20),
    peso_personal integer
);


ALTER TABLE public.motivos_personales OWNER TO asistente;

--
-- Name: TABLE motivos_personales; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON TABLE public.motivos_personales IS 'Motivaciones que impulsan a Guillermo a llevar adelante proyectos';


--
-- Name: motivos_personales_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.motivos_personales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.motivos_personales_id_seq OWNER TO asistente;

--
-- Name: motivos_personales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.motivos_personales_id_seq OWNED BY public.motivos_personales.id;


--
-- Name: notas_audio; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.notas_audio (
    id integer NOT NULL,
    "transcripcionId" integer NOT NULL,
    "transcripcionCompleta" text NOT NULL,
    "archivoAudioUrl" text,
    "resumenEjecutivo" text,
    "fechaGrabacion" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    procesado boolean DEFAULT false NOT NULL,
    "tipoDetectado" text,
    "confianzaDeteccion" double precision,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.notas_audio OWNER TO asistente;

--
-- Name: notas_audio_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.notas_audio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notas_audio_id_seq OWNER TO asistente;

--
-- Name: notas_audio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.notas_audio_id_seq OWNED BY public.notas_audio.id;


--
-- Name: planificacion_semana_completa; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.planificacion_semana_completa AS
 SELECT eventos.fecha,
    eventos.dia_nombre,
    eventos.tipo,
    eventos.hora_inicio,
    eventos.hora_fin,
    eventos.duracion_horas,
    eventos.titulo,
    eventos.area,
    eventos.completado
   FROM ( SELECT i.fecha_programada AS fecha,
                CASE
                    WHEN (EXTRACT(dow FROM i.fecha_programada) = (0)::numeric) THEN 'Domingo'::text
                    WHEN (EXTRACT(dow FROM i.fecha_programada) = (1)::numeric) THEN 'Lunes'::text
                    WHEN (EXTRACT(dow FROM i.fecha_programada) = (2)::numeric) THEN 'Martes'::text
                    WHEN (EXTRACT(dow FROM i.fecha_programada) = (3)::numeric) THEN 'Miércoles'::text
                    WHEN (EXTRACT(dow FROM i.fecha_programada) = (4)::numeric) THEN 'Jueves'::text
                    WHEN (EXTRACT(dow FROM i.fecha_programada) = (5)::numeric) THEN 'Viernes'::text
                    ELSE 'Sábado'::text
                END AS dia_nombre,
            'Recurrente'::character varying AS tipo,
            i.hora_inicio,
            i.hora_fin,
            ((t.duracion_estimada_minutos)::numeric / 60.0) AS duracion_horas,
            t.nombre AS titulo,
            a.nombre AS area,
            i.completada AS completado
           FROM ((public.instancias_tareas_recurrentes i
             JOIN public.tareas_recurrentes t ON ((i.tarea_recurrente_id = t.id)))
             LEFT JOIN public.areas_vida a ON ((t.area_id = a.id)))
          WHERE ((i.fecha_programada >= CURRENT_DATE) AND (i.fecha_programada < (CURRENT_DATE + '7 days'::interval)) AND (i.saltada = false))
        UNION ALL
         SELECT b.fecha,
                CASE
                    WHEN (EXTRACT(dow FROM b.fecha) = (0)::numeric) THEN 'Domingo'::text
                    WHEN (EXTRACT(dow FROM b.fecha) = (1)::numeric) THEN 'Lunes'::text
                    WHEN (EXTRACT(dow FROM b.fecha) = (2)::numeric) THEN 'Martes'::text
                    WHEN (EXTRACT(dow FROM b.fecha) = (3)::numeric) THEN 'Miércoles'::text
                    WHEN (EXTRACT(dow FROM b.fecha) = (4)::numeric) THEN 'Jueves'::text
                    WHEN (EXTRACT(dow FROM b.fecha) = (5)::numeric) THEN 'Viernes'::text
                    ELSE 'Sábado'::text
                END AS dia_nombre,
            b.tipo_bloque AS tipo,
            b.hora_inicio,
            b.hora_fin,
            (EXTRACT(epoch FROM (b.hora_fin - b.hora_inicio)) / (3600)::numeric) AS duracion_horas,
            COALESCE(te.nombre, tr.nombre, p.nombre, (b.descripcion_libre)::character varying) AS titulo,
            a.nombre AS area,
            b.completado
           FROM ((((public.bloques_tiempo_planificados b
             LEFT JOIN public.tareas_estrategicas te ON ((b.tarea_estrategica_id = te.id)))
             LEFT JOIN public.tareas_recurrentes tr ON ((b.tarea_recurrente_id = tr.id)))
             LEFT JOIN public.proyectos_estrategicos p ON ((b.proyecto_estrategico_id = p.id)))
             LEFT JOIN public.areas_vida a ON ((b.area_vida_id = a.id)))
          WHERE ((b.fecha >= CURRENT_DATE) AND (b.fecha < (CURRENT_DATE + '7 days'::interval)))) eventos
  ORDER BY eventos.fecha, eventos.hora_inicio;


ALTER TABLE public.planificacion_semana_completa OWNER TO asistente;

--
-- Name: VIEW planificacion_semana_completa; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.planificacion_semana_completa IS 'Vista consolidada de toda la planificación semanal';


--
-- Name: precision_estimaciones; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.precision_estimaciones AS
 SELECT t.nombre AS tarea,
    p.nombre AS proyecto,
    t.tiempo_estimado_horas,
    t.duracion_real_horas,
        CASE
            WHEN (t.duracion_real_horas IS NULL) THEN 'Pendiente'::text
            WHEN (t.duracion_real_horas <= (t.tiempo_estimado_horas)::numeric) THEN '✅ Dentro de estimación'::text
            WHEN (t.duracion_real_horas <= ((t.tiempo_estimado_horas)::numeric * 1.2)) THEN '🟡 +20% sobre estimado'::text
            ELSE '🔴 Muy por encima'::text
        END AS "precision",
        CASE
            WHEN (t.duracion_real_horas IS NOT NULL) THEN round((((t.duracion_real_horas - (t.tiempo_estimado_horas)::numeric) / (NULLIF(t.tiempo_estimado_horas, 0))::numeric) * (100)::numeric), 1)
            ELSE NULL::numeric
        END AS desviacion_porcentaje
   FROM (public.tareas_estrategicas t
     JOIN public.proyectos_estrategicos p ON ((t.proyecto_id = p.id)))
  WHERE ((t.estado_kanban = 'done'::public."TipoEstadoKanban") AND (t.tiempo_estimado_horas IS NOT NULL))
  ORDER BY t.fecha_done DESC
 LIMIT 50;


ALTER TABLE public.precision_estimaciones OWNER TO asistente;

--
-- Name: VIEW precision_estimaciones; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.precision_estimaciones IS 'Análisis de precisión de estimaciones (últimas 50 tareas completadas)';


--
-- Name: proyectos_estrategicos_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.proyectos_estrategicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.proyectos_estrategicos_id_seq OWNER TO asistente;

--
-- Name: proyectos_estrategicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.proyectos_estrategicos_id_seq OWNED BY public.proyectos_estrategicos.id;


--
-- Name: registros; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.registros (
    id integer NOT NULL,
    descripcion text NOT NULL,
    "duracionHoras" double precision,
    proyecto text,
    "personasInvolucradas" text[],
    categoria public."Categoria" DEFAULT 'TRABAJO'::public."Categoria" NOT NULL,
    "fechaActividad" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "notaAudioId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.registros OWNER TO asistente;

--
-- Name: registros_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.registros_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.registros_id_seq OWNER TO asistente;

--
-- Name: registros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.registros_id_seq OWNED BY public.registros.id;


--
-- Name: resumen_bloques_por_area; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.resumen_bloques_por_area AS
 SELECT a.nombre AS area,
    count(b.id) AS num_bloques,
    sum((EXTRACT(epoch FROM (b.hora_fin - b.hora_inicio)) / (3600)::numeric)) AS horas_totales,
    sum(
        CASE
            WHEN b.completado THEN (EXTRACT(epoch FROM (b.hora_fin - b.hora_inicio)) / (3600)::numeric)
            ELSE (0)::numeric
        END) AS horas_completadas,
    count(
        CASE
            WHEN b.sincronizado_calendar THEN 1
            ELSE NULL::integer
        END) AS bloques_sincronizados,
    min(b.fecha) AS primera_fecha,
    max(b.fecha) AS ultima_fecha
   FROM (public.bloques_tiempo_planificados b
     JOIN public.areas_vida a ON ((b.area_vida_id = a.id)))
  WHERE (b.fecha >= (CURRENT_DATE - '7 days'::interval))
  GROUP BY a.id, a.nombre
  ORDER BY (sum((EXTRACT(epoch FROM (b.hora_fin - b.hora_inicio)) / (3600)::numeric))) DESC;


ALTER TABLE public.resumen_bloques_por_area OWNER TO asistente;

--
-- Name: VIEW resumen_bloques_por_area; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.resumen_bloques_por_area IS 'Resumen de tiempo planificado por área de vida (última semana)';


--
-- Name: resumen_disponibilidad_total; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.resumen_disponibilidad_total AS
 SELECT sum(disponibilidad_real_semanal.horas_teoricas) AS total_horas_teoricas_semana,
    sum(disponibilidad_real_semanal.horas_recurrentes) AS total_horas_recurrentes_semana,
    sum(disponibilidad_real_semanal.horas_disponibles_proyectos) AS total_horas_disponibles_proyectos,
    round(((sum(disponibilidad_real_semanal.horas_recurrentes) / NULLIF(sum(disponibilidad_real_semanal.horas_teoricas), (0)::numeric)) * (100)::numeric), 1) AS porcentaje_tiempo_recurrentes,
    count(*) AS dias_configurados,
    count(
        CASE
            WHEN (disponibilidad_real_semanal.estado_carga = ANY (ARRAY['SOBRECARGA'::text, 'SATURADO'::text])) THEN 1
            ELSE NULL::integer
        END) AS dias_problematicos
   FROM public.disponibilidad_real_semanal;


ALTER TABLE public.resumen_disponibilidad_total OWNER TO asistente;

--
-- Name: VIEW resumen_disponibilidad_total; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.resumen_disponibilidad_total IS 'Resumen semanal total de disponibilidad de tiempo';


--
-- Name: resumen_salud_semana_actual; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.resumen_salud_semana_actual AS
 SELECT count(*) AS total_dias,
    count(
        CASE
            WHEN (disponibilidad_real_semanal.estado_carga = 'SOBRECARGA'::text) THEN 1
            ELSE NULL::integer
        END) AS dias_sobrecarga,
    count(
        CASE
            WHEN (disponibilidad_real_semanal.estado_carga = 'SATURADO'::text) THEN 1
            ELSE NULL::integer
        END) AS dias_saturados,
    count(
        CASE
            WHEN (disponibilidad_real_semanal.estado_carga = ANY (ARRAY['JUSTO'::text, 'HOLGADO'::text])) THEN 1
            ELSE NULL::integer
        END) AS dias_saludables,
    sum(disponibilidad_real_semanal.horas_disponibles_proyectos) AS total_horas_proyectos,
    avg(disponibilidad_real_semanal.porcentaje_ocupado) AS porcentaje_ocupado_promedio,
        CASE
            WHEN (count(
            CASE
                WHEN (disponibilidad_real_semanal.estado_carga = 'SOBRECARGA'::text) THEN 1
                ELSE NULL::integer
            END) > 0) THEN '🔴 Semana sobrecargada'::text
            WHEN (count(
            CASE
                WHEN (disponibilidad_real_semanal.estado_carga = 'SATURADO'::text) THEN 1
                ELSE NULL::integer
            END) > 2) THEN '🟡 Semana ajustada'::text
            ELSE '✅ Semana saludable'::text
        END AS estado_general
   FROM public.disponibilidad_real_semanal;


ALTER TABLE public.resumen_salud_semana_actual OWNER TO asistente;

--
-- Name: VIEW resumen_salud_semana_actual; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.resumen_salud_semana_actual IS 'Resumen general de la salud de la semana';


--
-- Name: subtareas_estrategicas; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.subtareas_estrategicas (
    id integer NOT NULL,
    tarea_estrategica_id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    tiempo_estimado_minutos integer,
    moscow public."TipoMoscow",
    destreza_principal_id integer,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    estado_kanban public."TipoEstadoKanban" DEFAULT 'backlog'::public."TipoEstadoKanban",
    fecha_done timestamp without time zone,
    proyecto_nombre character varying(200)
);


ALTER TABLE public.subtareas_estrategicas OWNER TO asistente;

--
-- Name: COLUMN subtareas_estrategicas.estado_kanban; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.subtareas_estrategicas.estado_kanban IS 'Estado en el tablero Kanban de la subtarea';


--
-- Name: COLUMN subtareas_estrategicas.fecha_done; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.subtareas_estrategicas.fecha_done IS 'Timestamp cuando la subtarea pasó a estado done';


--
-- Name: COLUMN subtareas_estrategicas.proyecto_nombre; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON COLUMN public.subtareas_estrategicas.proyecto_nombre IS 'Denormalized project name for easier querying. Updated via trigger when project name changes.';


--
-- Name: subtareas_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.subtareas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subtareas_id_seq OWNER TO asistente;

--
-- Name: subtareas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.subtareas_id_seq OWNED BY public.subtareas_estrategicas.id;


--
-- Name: tareas; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.tareas (
    id integer NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    "fechaVencimiento" timestamp(3) without time zone,
    prioridad public."Prioridad" DEFAULT 'MEDIA'::public."Prioridad" NOT NULL,
    completada boolean DEFAULT false NOT NULL,
    "fechaCompletada" timestamp(3) without time zone,
    "notaAudioId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    proyecto_estrategico_id integer
);


ALTER TABLE public.tareas OWNER TO asistente;

--
-- Name: tareas_bloqueadas_atencion; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.tareas_bloqueadas_atencion AS
 SELECT t.id,
    t.nombre,
    p.nombre AS proyecto,
    t.bloqueada_por,
    t.fecha_estimada_desbloqueo,
    t.estado_kanban,
        CASE
            WHEN (t.fecha_estimada_desbloqueo IS NULL) THEN 'Sin fecha de desbloqueo'::text
            WHEN (t.fecha_estimada_desbloqueo <= CURRENT_DATE) THEN '🔴 Ya debería estar desbloqueada'::text
            WHEN (t.fecha_estimada_desbloqueo <= (CURRENT_DATE + '3 days'::interval)) THEN '🟡 Próxima a desbloquearse'::text
            ELSE '⏳ Bloqueada largo plazo'::text
        END AS estado_bloqueo
   FROM (public.tareas_estrategicas t
     JOIN public.proyectos_estrategicos p ON ((t.proyecto_id = p.id)))
  WHERE (t.bloqueada_por IS NOT NULL)
  ORDER BY
        CASE
            WHEN (t.fecha_estimada_desbloqueo <= CURRENT_DATE) THEN 1
            WHEN (t.fecha_estimada_desbloqueo <= (CURRENT_DATE + '3 days'::interval)) THEN 2
            ELSE 3
        END, t.fecha_estimada_desbloqueo;


ALTER TABLE public.tareas_bloqueadas_atencion OWNER TO asistente;

--
-- Name: VIEW tareas_bloqueadas_atencion; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.tareas_bloqueadas_atencion IS 'Tareas bloqueadas que requieren seguimiento';


--
-- Name: tareas_estrategicas_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.tareas_estrategicas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tareas_estrategicas_id_seq OWNER TO asistente;

--
-- Name: tareas_estrategicas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.tareas_estrategicas_id_seq OWNED BY public.tareas_estrategicas.id;


--
-- Name: tareas_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.tareas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tareas_id_seq OWNER TO asistente;

--
-- Name: tareas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.tareas_id_seq OWNED BY public.tareas.id;


--
-- Name: tareas_recurrentes_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.tareas_recurrentes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tareas_recurrentes_id_seq OWNER TO asistente;

--
-- Name: tareas_recurrentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.tareas_recurrentes_id_seq OWNED BY public.tareas_recurrentes.id;


--
-- Name: tareas_recurrentes_resumen; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.tareas_recurrentes_resumen AS
 SELECT t.id,
    t.nombre,
    t.tipo,
    t.criticidad,
    t.duracion_estimada_minutos,
    t.energia_requerida,
    t.contexto_necesario,
    (t.patron_recurrencia ->> 'tipo'::text) AS tipo_recurrencia,
    a.nombre AS area_nombre,
    p.nombre AS proyecto_nombre,
    count(i.id) AS instancias_generadas,
    count(
        CASE
            WHEN i.completada THEN 1
            ELSE NULL::integer
        END) AS instancias_completadas,
    count(
        CASE
            WHEN i.saltada THEN 1
            ELSE NULL::integer
        END) AS instancias_saltadas,
    round((((count(
        CASE
            WHEN i.completada THEN 1
            ELSE NULL::integer
        END))::numeric / (NULLIF(count(i.id), 0))::numeric) * (100)::numeric), 1) AS tasa_completitud
   FROM (((public.tareas_recurrentes t
     LEFT JOIN public.areas_vida a ON ((t.area_id = a.id)))
     LEFT JOIN public.proyectos_estrategicos p ON ((t.proyecto_estrategico_id = p.id)))
     LEFT JOIN public.instancias_tareas_recurrentes i ON (((i.tarea_recurrente_id = t.id) AND (i.fecha_programada >= (CURRENT_DATE - '30 days'::interval)))))
  WHERE (t.activa = true)
  GROUP BY t.id, t.nombre, t.tipo, t.criticidad, t.duracion_estimada_minutos, t.energia_requerida, t.contexto_necesario, t.patron_recurrencia, a.nombre, p.nombre
  ORDER BY t.criticidad DESC, t.nombre;


ALTER TABLE public.tareas_recurrentes_resumen OWNER TO asistente;

--
-- Name: VIEW tareas_recurrentes_resumen; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.tareas_recurrentes_resumen IS 'Resumen de tareas recurrentes con métricas de completitud (últimos 30 días)';


--
-- Name: tareas_sugeridas_hoy; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.tareas_sugeridas_hoy AS
 SELECT t.id,
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
    ((
        CASE t.eisenhower
            WHEN 'cuadrante_1'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_1'::character varying)
            WHEN 'cuadrante_2'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_2'::character varying)
            WHEN 'cuadrante_3'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_3'::character varying)
            WHEN 'cuadrante_4'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_4'::character varying)
            ELSE (0)::numeric
        END +
        CASE t.impacto
            WHEN 'alto'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_alto'::character varying)
            WHEN 'medio'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_medio'::character varying)
            WHEN 'bajo'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_bajo'::character varying)
            ELSE (0)::numeric
        END) + (COALESCE(p.score_motivacional, (0)::numeric) * public.get_config_numero('peso_motivacional'::character varying))) AS score_prioridad
   FROM (public.tareas_estrategicas t
     JOIN public.proyectos_estrategicos p ON ((t.proyecto_id = p.id)))
  WHERE ((t.estado_kanban = ANY (ARRAY['todo'::public."TipoEstadoKanban", 'doing'::public."TipoEstadoKanban"])) AND ((t.fecha_inicio IS NULL) OR (t.fecha_inicio <= CURRENT_DATE)) AND (t.bloqueada_por IS NULL) AND (p.estado = ANY (ARRAY['en_curso'::public."TipoEstadoProyecto", 'planificacion'::public."TipoEstadoProyecto"])))
  ORDER BY ((
        CASE t.eisenhower
            WHEN 'cuadrante_1'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_1'::character varying)
            WHEN 'cuadrante_2'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_2'::character varying)
            WHEN 'cuadrante_3'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_3'::character varying)
            WHEN 'cuadrante_4'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_4'::character varying)
            ELSE (0)::numeric
        END +
        CASE t.impacto
            WHEN 'alto'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_alto'::character varying)
            WHEN 'medio'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_medio'::character varying)
            WHEN 'bajo'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_bajo'::character varying)
            ELSE (0)::numeric
        END) + (COALESCE(p.score_motivacional, (0)::numeric) * public.get_config_numero('peso_motivacional'::character varying))) DESC, t.urgencia DESC;


ALTER TABLE public.tareas_sugeridas_hoy OWNER TO asistente;

--
-- Name: VIEW tareas_sugeridas_hoy; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.tareas_sugeridas_hoy IS 'Tareas priorizadas por score compuesto para trabajar hoy';


--
-- Name: transcripciones; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.transcripciones (
    id integer NOT NULL,
    hora timestamp(6) with time zone DEFAULT now(),
    texto text NOT NULL,
    r2_url character varying(512),
    r2_key character varying(256),
    telegram_file_id character varying(256),
    telegram_user_id bigint,
    telegram_message_id bigint,
    duracion_segundos integer,
    tamano_bytes bigint,
    created_at timestamp(6) with time zone DEFAULT now(),
    updated_at timestamp(6) with time zone DEFAULT now(),
    estado character varying(20) DEFAULT 'PROCESANDO'::character varying,
    error_msg text
);


ALTER TABLE public.transcripciones OWNER TO asistente;

--
-- Name: transcripciones_id_seq; Type: SEQUENCE; Schema: public; Owner: asistente
--

CREATE SEQUENCE public.transcripciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transcripciones_id_seq OWNER TO asistente;

--
-- Name: transcripciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asistente
--

ALTER SEQUENCE public.transcripciones_id_seq OWNED BY public.transcripciones.id;


--
-- Name: vista_que_hacer_ahora; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.vista_que_hacer_ahora AS
 SELECT s.id,
    s.nombre AS titulo,
    t.nombre AS tarea,
    p.nombre AS proyecto,
    COALESCE((t.energia_requerida)::text, 'media'::text) AS nivel_energia_requerido,
    ARRAY[
        CASE
            WHEN (d.mejor_momento_dia IS NOT NULL) THEN (d.mejor_momento_dia)::text
            ELSE 'cualquier_momento'::text
        END] AS mejor_momento,
    COALESCE(s.tiempo_estimado_minutos, 30) AS tiempo_estimado_minutos,
    ((
        CASE t.eisenhower
            WHEN 'cuadrante_1'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_1'::character varying)
            WHEN 'cuadrante_2'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_2'::character varying)
            WHEN 'cuadrante_3'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_3'::character varying)
            WHEN 'cuadrante_4'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_4'::character varying)
            ELSE (0)::numeric
        END +
        CASE t.impacto
            WHEN 'alto'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_alto'::character varying)
            WHEN 'medio'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_medio'::character varying)
            WHEN 'bajo'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_bajo'::character varying)
            ELSE (0)::numeric
        END) + (COALESCE(p.score_motivacional, (0)::numeric) * public.get_config_numero('peso_motivacional'::character varying))) AS score_prioridad
   FROM (((public.subtareas_estrategicas s
     JOIN public.tareas_estrategicas t ON ((s.tarea_estrategica_id = t.id)))
     JOIN public.proyectos_estrategicos p ON ((t.proyecto_id = p.id)))
     LEFT JOIN public.destrezas d ON ((s.destreza_principal_id = d.id)))
  WHERE ((s.estado_kanban = ANY (ARRAY['todo'::public."TipoEstadoKanban", 'doing'::public."TipoEstadoKanban"])) AND (t.estado_kanban = ANY (ARRAY['todo'::public."TipoEstadoKanban", 'doing'::public."TipoEstadoKanban"])) AND ((t.fecha_inicio IS NULL) OR (t.fecha_inicio <= CURRENT_DATE)) AND (t.bloqueada_por IS NULL) AND (p.estado = ANY (ARRAY['en_curso'::public."TipoEstadoProyecto", 'planificacion'::public."TipoEstadoProyecto"])))
  ORDER BY ((
        CASE t.eisenhower
            WHEN 'cuadrante_1'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_1'::character varying)
            WHEN 'cuadrante_2'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_2'::character varying)
            WHEN 'cuadrante_3'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_3'::character varying)
            WHEN 'cuadrante_4'::public."TipoEisenhower" THEN public.get_config_numero('peso_eisenhower_cuadrante_4'::character varying)
            ELSE (0)::numeric
        END +
        CASE t.impacto
            WHEN 'alto'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_alto'::character varying)
            WHEN 'medio'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_medio'::character varying)
            WHEN 'bajo'::public."TipoImpacto" THEN public.get_config_numero('peso_impacto_bajo'::character varying)
            ELSE (0)::numeric
        END) + (COALESCE(p.score_motivacional, (0)::numeric) * public.get_config_numero('peso_motivacional'::character varying))) DESC
 LIMIT 10;


ALTER TABLE public.vista_que_hacer_ahora OWNER TO asistente;

--
-- Name: VIEW vista_que_hacer_ahora; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.vista_que_hacer_ahora IS 'Top 10 subtareas priorizadas para trabajar ahora';


--
-- Name: vista_sobrecarga_semanal; Type: VIEW; Schema: public; Owner: asistente
--

CREATE VIEW public.vista_sobrecarga_semanal AS
 SELECT subquery.fecha,
    subquery.dia_semana,
    subquery.dia_nombre,
    subquery.horas_disponibles_proyectos AS horas_disponibles,
    subquery.estado_carga,
    subquery.porcentaje_ocupado,
        CASE
            WHEN (subquery.estado_carga = 'SOBRECARGA'::text) THEN '🔴 CRÍTICO'::text
            WHEN (subquery.estado_carga = 'SATURADO'::text) THEN '🟡 ALERTA'::text
            WHEN (subquery.estado_carga = 'JUSTO'::text) THEN '🟢 OK'::text
            ELSE '✅ BIEN'::text
        END AS indicador
   FROM ( SELECT (CURRENT_DATE + (d.dia_semana - (EXTRACT(dow FROM CURRENT_DATE))::integer)) AS fecha,
            d.dia_semana,
            d.dia_nombre,
            d.horas_teoricas,
            d.horas_recurrentes,
            d.horas_recurrentes_must,
            d.horas_recurrentes_should,
            d.num_tareas_recurrentes,
            d.horas_disponibles_proyectos,
            d.momento_optimo,
            d.notas,
            d.estado_carga,
            d.porcentaje_ocupado
           FROM public.disponibilidad_real_semanal d) subquery
  ORDER BY subquery.fecha;


ALTER TABLE public.vista_sobrecarga_semanal OWNER TO asistente;

--
-- Name: VIEW vista_sobrecarga_semanal; Type: COMMENT; Schema: public; Owner: asistente
--

COMMENT ON VIEW public.vista_sobrecarga_semanal IS 'Vista semanal con indicadores de sobrecarga por día';


--
-- Name: areas_vida id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.areas_vida ALTER COLUMN id SET DEFAULT nextval('public.areas_vida_id_seq'::regclass);


--
-- Name: bloques_tiempo_planificados id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.bloques_tiempo_planificados ALTER COLUMN id SET DEFAULT nextval('public.bloques_tiempo_planificados_id_seq'::regclass);


--
-- Name: compromisos id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.compromisos ALTER COLUMN id SET DEFAULT nextval('public.compromisos_id_seq'::regclass);


--
-- Name: destrezas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.destrezas ALTER COLUMN id SET DEFAULT nextval('public.destrezas_id_seq'::regclass);


--
-- Name: dificultades id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.dificultades ALTER COLUMN id SET DEFAULT nextval('public.dificultades_id_seq'::regclass);


--
-- Name: disponibilidad_semanal id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.disponibilidad_semanal ALTER COLUMN id SET DEFAULT nextval('public.disponibilidad_semanal_id_seq'::regclass);


--
-- Name: ideas_capturadas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas_capturadas ALTER COLUMN id SET DEFAULT nextval('public.ideas_id_seq'::regclass);


--
-- Name: instancias_tareas_recurrentes id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.instancias_tareas_recurrentes ALTER COLUMN id SET DEFAULT nextval('public.instancias_tareas_recurrentes_id_seq'::regclass);


--
-- Name: logs_generacion_ia id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.logs_generacion_ia ALTER COLUMN id SET DEFAULT nextval('public.logs_generacion_ia_id_seq'::regclass);


--
-- Name: misiones_vida id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.misiones_vida ALTER COLUMN id SET DEFAULT nextval('public.misiones_vida_id_seq'::regclass);


--
-- Name: motivos_personales id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.motivos_personales ALTER COLUMN id SET DEFAULT nextval('public.motivos_personales_id_seq'::regclass);


--
-- Name: notas_audio id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.notas_audio ALTER COLUMN id SET DEFAULT nextval('public.notas_audio_id_seq'::regclass);


--
-- Name: proyectos_estrategicos id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.proyectos_estrategicos ALTER COLUMN id SET DEFAULT nextval('public.proyectos_estrategicos_id_seq'::regclass);


--
-- Name: registros id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.registros ALTER COLUMN id SET DEFAULT nextval('public.registros_id_seq'::regclass);


--
-- Name: subtareas_estrategicas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.subtareas_estrategicas ALTER COLUMN id SET DEFAULT nextval('public.subtareas_id_seq'::regclass);


--
-- Name: tareas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas ALTER COLUMN id SET DEFAULT nextval('public.tareas_id_seq'::regclass);


--
-- Name: tareas_estrategicas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_estrategicas ALTER COLUMN id SET DEFAULT nextval('public.tareas_estrategicas_id_seq'::regclass);


--
-- Name: tareas_recurrentes id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_recurrentes ALTER COLUMN id SET DEFAULT nextval('public.tareas_recurrentes_id_seq'::regclass);


--
-- Name: transcripciones id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.transcripciones ALTER COLUMN id SET DEFAULT nextval('public.transcripciones_id_seq'::regclass);


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
809daaec-2540-41ad-92e8-31ff1155e570	f0336f4d1ecbadb406d7d195464ba49cddd69eb1104d5507905e8817f1dac5d2	\N	20251201231235_init_mateos_v2_schema	A migration failed to apply. New migrations cannot be applied before the error is recovered from. Read more about how to resolve migration issues in a production database: https://pris.ly/d/migrate-resolve\n\nMigration name: 20251201231235_init_mateos_v2_schema\n\nDatabase error code: 42710\n\nDatabase error:\nERROR: type "Prioridad" already exists\n\nDbError { severity: "ERROR", parsed_severity: Some(Error), code: SqlState(E42710), message: "type \\"Prioridad\\" already exists", detail: None, hint: None, position: None, where_: None, schema: None, table: None, column: None, datatype: None, constraint: None, file: Some("typecmds.c"), line: Some(1167), routine: Some("DefineEnum") }\n\n   0: sql_schema_connector::apply_migration::apply_script\n           with migration_name="20251201231235_init_mateos_v2_schema"\n             at schema-engine/connectors/sql-schema-connector/src/apply_migration.rs:113\n   1: schema_commands::commands::apply_migrations::Applying migration\n           with migration_name="20251201231235_init_mateos_v2_schema"\n             at schema-engine/commands/src/commands/apply_migrations.rs:95\n   2: schema_core::state::ApplyMigrations\n             at schema-engine/core/src/state.rs:260	2025-12-02 03:00:33.504248+00	2025-12-02 03:00:16.441466+00	0
d2f93546-2c73-4dbd-a37a-563d36364c0b	f0336f4d1ecbadb406d7d195464ba49cddd69eb1104d5507905e8817f1dac5d2	2025-12-02 03:00:33.510618+00	20251201231235_init_mateos_v2_schema		\N	2025-12-02 03:00:33.510618+00	0
\.


--
-- Data for Name: areas_vida; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.areas_vida (id, nombre, descripcion, color_hex, orden_visualizacion, activa) FROM stdin;
1	involucrate	Plataforma de voluntariado corporativo y gestión de impacto social	#FF6B6B	1	t
2	involucrarse	Proyectos sociales directos y coordinación de iniciativas comunitarias	#4ECDC4	2	t
5	tdahAACC	Exploración y gestión de TDAH y Altas Capacidades	#AA96DA	5	t
15	CanalYoutubeTdahAacc	Canal de youtube que difunde Realidades de TDAH y AACC en adultos en español	#2D5FF5	15	t
16	ForkAI	Proyectos de venta de agentes y sistematizaciones para las empresas. 	#FF8C00	16	t
19	AdminInvolucra	Tareas requeridas por la administración de la empresa. 	#FFD700	19	t
18	SistemaEmprendedorSolitario	Servicio personal para maximizar rentabilidad a emprendedores latinoméricanos.	#546E7A	18	t
4	MarcaPersonal	Construcción de marca, contenido, redes sociales y posicionamiento	#F38181	4	t
14	Familia	Tiempo familiar, paternidad y relaciones	#FF9AA2	14	t
13	Finanzas	Gestión financiera personal, inversiones y economía	#F7DC6F	13	t
3	Mateos	Metodología de gestión personal y sistema de decisiones (este proyecto)	#95E1D3	3	t
12	Salud	Salud física, ejercicio, alimentación y bienestar	#98D8C8	12	t
9	olectivoPlacita	Proyectos barriales, espacio público y comunidad local	#A8E6CF	9	t
10	EscuelaComisionFomento	Proyectos en escuela de los hijos	#FFB6C1	10	t
11	JardinComisionFomento	Proyectos en jardín de infantes	#DDA0DD	11	t
6	Fibras	Salud mental, bienestar emocional y terapia	#FCBAD3	6	t
7	GyermekClubHungaro	Proyectos con niños, educación y desarrollo infantil	#FFFFD2	7	t
8	Murga	Expresión artística, murga, música y performance	#FFD3B6	8	t
17	LibroProductosPadres	Libro qué con herramientas para maximizar rentabilidad a emprendedores latinoméricanos.	#D72638	17	t
20	involucrados	Proyecto de desarrollo y enseñanza de la gestión de ONGs especialmente en voluntariado	#1B5E20	20	t
\.


--
-- Data for Name: bloques_tiempo_planificados; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.bloques_tiempo_planificados (id, fecha, hora_inicio, hora_fin, tipo_bloque, tarea_estrategica_id, tarea_recurrente_id, proyecto_estrategico_id, area_vida_id, descripcion_libre, notas, google_calendar_event_id, sincronizado_calendar, ultimo_sync, completado, fecha_completado, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: compromisos; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.compromisos (id, titulo, descripcion, "personaNombre", "fechaLimite", "yoMeComprometi", cumplido, "fechaCumplido", "notaAudioId", "createdAt", "updatedAt") FROM stdin;
1	Reunión con UQ Business School	Tengo una reunión con UQ Business School el viernes 7 a las 11 de la mañana, les envié un link de Google Meets.	UQ Business School	2025-11-07 11:00:00	t	t	\N	3	2025-11-07 02:39:40.643	2025-11-07 02:39:40.643
2	Participar en el grupito de Fe y Alegría	Le dije que sí a Pablo de Fiberas para participar en el grupito de Fe y Alegría para la puesta en marcha de eso.	Pablo de Fiberas	2025-11-06 00:00:00	t	f	\N	20	2025-11-07 21:31:12.265	2025-11-07 21:31:12.265
3	Hablar con el arquitecto	Mañana tengo que ir al municipio a hablar con el arquitecto para preguntarle y poder pedirle cuáles son los planos y las instrucciones que le pasó a la empresa constructora.	arquitecto	2025-11-18 00:00:00	t	f	\N	38	2025-11-17 17:15:15.98	2025-11-17 17:15:15.98
\.


--
-- Data for Name: configuracion_personal; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.configuracion_personal (clave, valor, descripcion, categoria, tipo_dato, created_at, updated_at) FROM stdin;
horas_disponibles_promedio_dia	5	Horas productivas promedio por día	tiempo	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
max_proyectos_paralelos	3	Máximo de proyectos en DOING simultáneamente (ADHD)	tiempo	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
momento_mayor_energia	"maniana"	Cuándo tengo más energía: maniana, tarde, noche	tiempo	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
tiempo_buffer_porcentaje	20	Porcentaje de tiempo a dejar como buffer (imprevistos)	tiempo	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
duracion_sesion_foco_minutos	90	Duración de sesión de trabajo profundo antes de break	tiempo	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
duracion_break_minutos	15	Duración del descanso entre sesiones de foco	tiempo	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
semanas_adelante_generar_recurrentes	2	Cuántas semanas adelante generar instancias recurrentes	planificacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
dia_planificacion_semanal	0	Día de la semana para planificar (0=domingo, 6=sábado)	planificacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
hora_planificacion_semanal	"20:00"	Hora para recordatorio de planificación semanal	planificacion	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_eisenhower_cuadrante_1	100	Peso para tareas cuadrante 1 (urgente e importante)	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_eisenhower_cuadrante_2	70	Peso para tareas cuadrante 2 (no urgente pero importante)	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_eisenhower_cuadrante_3	40	Peso para tareas cuadrante 3 (urgente pero no importante)	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_eisenhower_cuadrante_4	10	Peso para tareas cuadrante 4 (ni urgente ni importante)	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_impacto_alto	30	Puntos adicionales por impacto alto	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_impacto_medio	15	Puntos adicionales por impacto medio	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_impacto_bajo	5	Puntos adicionales por impacto bajo	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
peso_motivacional	20	Multiplicador para score motivacional del proyecto	priorizacion	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
google_calendar_color_trabajo	"9"	Color ID para bloques de trabajo en Google Calendar	integraciones	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
google_calendar_color_personal	"7"	Color ID para bloques personales en Google Calendar	integraciones	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
google_calendar_color_habitos	"2"	Color ID para bloques de hábitos en Google Calendar	integraciones	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
sync_bloques_automatico	true	Sincronizar bloques automáticamente con Google Calendar	integraciones	booleano	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
notificar_tareas_bloqueadas	true	Notificar cuando una tarea está bloqueada	notificaciones	booleano	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
notificar_compromisos_proximos	true	Notificar compromisos próximos a vencer	notificaciones	booleano	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
dias_anticipacion_compromisos	3	Días de anticipación para notificar compromisos	notificaciones	numero	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
zona_horaria	"America/Argentina/Buenos_Aires"	Zona horaria del usuario	sistema	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
idioma	"es"	Idioma preferido del sistema	sistema	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
formato_fecha	"DD/MM/YYYY"	Formato de fecha preferido	sistema	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
formato_hora	"HH:mm"	Formato de hora preferido (24h)	sistema	texto	2026-01-03 10:13:24.635026	2026-01-03 10:13:24.635026
google_calendar_id	"c_0c44e02391421207de4f23659eab7603fd098368b04ef8d6d3aaf9ea361d2660@group.calendar.google.com"	ID del calendario de Google Calendar a usar	integraciones	texto	2026-01-03 10:13:24.635026	2026-01-03 10:35:23.54375
google_calendar_nombre	"trunches"	\N	\N	\N	2026-01-03 10:35:23.54375	2026-01-03 10:35:23.54375
google_calendar_trunches_id	"c_0c44e02391421207de4f23659eab7603fd098368b04ef8d6d3aaf9ea361d2660@group.calendar.google.com"	\N	\N	\N	2026-01-03 11:11:02.682344	2026-01-03 11:11:02.682344
google_calendar_personal_id	"guillermo@involucrate.uy"	\N	\N	\N	2026-01-03 11:11:02.682344	2026-01-03 11:11:02.682344
google_calendar_descripcion_trunches	"Bloques de tiempo por área de vida (capacidad)"	\N	\N	\N	2026-01-03 11:11:02.682344	2026-01-03 11:11:02.682344
google_calendar_descripcion_personal	"Citas, reuniones, tareas reales (eventos confirmados)"	\N	\N	\N	2026-01-03 11:11:02.682344	2026-01-03 11:11:02.682344
\.


--
-- Data for Name: destrezas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.destrezas (id, nombre, categoria, nivel_actual, descripcion, costo_energetico, mejor_momento_dia, requiere_flow, notas_contexto) FROM stdin;
1	empatía	Social	9	Capacidad de conectar emocionalmente con otros	media	{cualquier_momento}	f	Natural, no me cansa
2	asertivo	Social	7	Expresar opiniones y límites con claridad	media	{mañana,tarde}	f	Requiere estar descansado para no caer en agresividad
3	confianza	Social	8	Generar confianza en otros, ser confiable	baja	{cualquier_momento}	f	Se construye con consistencia
4	buenMediador	Social	8	Facilitar acuerdos y resolver conflictos	alta	{mañana}	f	Requiere paciencia y energía emocional
5	oratoria	Social	7	Hablar en público con claridad y persuasión	alta	{mañana,tarde}	f	Mejor con preparación previa
6	comunicación	Social	8	Transmitir ideas claramente, escuchar activamente	media	{cualquier_momento}	f	Core skill, uso constante
7	manejoDeGrupos	Social	8	Coordinar y facilitar dinámicas grupales	alta	{mañana,tarde}	f	Requiere energía social alta
8	liderazgo	Gestión	8	Inspirar y guiar equipos hacia objetivos	alta	{mañana}	f	Mejor en días con alta energía
9	buenLíderPersonal	Gestión	8	Gestionar mi propia vida y proyectos	media	{mañana}	t	Requiere claridad mental
10	hacerPlanes	Gestión	9	Diseñar estrategias y roadmaps	media	{mañana,noche}	t	Me gusta y me sale natural
11	ordenDeIdeas	Gestión	8	Estructurar pensamientos complejos	media	{mañana}	t	Necesito tranquilidad
12	voluntariadoGestion	Gestión	9	Coordinar voluntarios y proyectos sociales	alta	{mañana,tarde}	f	Expertise profesional
13	inteligenciaArtificial	Técnica	8	Crear automatizaciones y usar APIs de IA	pico	{mañana_temprano,noche}	t	Requiere máxima concentración
14	desarrolloCodigo	Técnica	7	Programar en Python, JavaScript, TypeScript	pico	{mañana_temprano}	t	Necesito flow completo, 2+ horas
15	diseñoFuncional	Técnica	7	Diseñar arquitecturas de sistemas	alta	{mañana}	t	Requiere pensamiento profundo
16	tecnologia	Técnica	8	Entender y usar nuevas tecnologías	media	{cualquier_momento}	f	Aprendizaje continuo
17	teoríaDeComputadoras	Técnica	6	Fundamentos de ciencias de la computación	alta	{mañana}	t	Requiere estudio concentrado
18	webDesign	Técnica	6	Diseñar interfaces web	media	{tarde,noche}	f	Creativo, no muy técnico
19	UX	Técnica	7	Diseño de experiencia de usuario	media	{tarde}	f	Combina empatía y diseño
20	designThinking	Técnica	8	Metodología de innovación centrada en usuario	media	{mañana,tarde}	f	Framework que uso mucho
21	producción	Creativa	7	Producir eventos, proyectos, contenido	alta	{cualquier_momento}	f	Coordinar múltiples elementos
22	ediciónDeVideo	Creativa	6	Editar videos	alta	{tarde,noche}	t	Requiere bloques largos
23	ediciónDeAudio	Creativa	7	Editar audio y podcasts	media	{tarde,noche}	t	Me relaja más que video
24	fotografía	Creativa	6	Capturar fotos de calidad	baja	{cualquier_momento}	f	Tarea ligera
25	iluminación	Creativa	5	Diseñar iluminación para eventos/video	media	{tarde}	f	Técnico pero creativo
26	copyEscritura	Creativa	7	Escribir textos persuasivos	media	{mañana,noche}	t	Requiere concentración
27	danza	Artística	6	Bailar, coreografías	alta	{tarde,noche}	f	Energético, me recarga
28	musica	Artística	6	Tocar instrumentos, componer	media	{tarde,noche}	f	Expresión personal
29	canto	Artística	6	Cantar	media	{cualquier_momento}	f	Liberador
30	guitarra	Artística	5	Tocar guitarra	media	{tarde,noche}	f	Requiere práctica
31	ukelele	Artística	6	Tocar ukelele	baja	{cualquier_momento}	f	Instrumento ligero
32	rítmo	Artística	7	Sentido del ritmo	baja	{cualquier_momento}	f	Natural
33	coreografías	Artística	6	Crear coreografías de danza/murga	alta	{tarde}	f	Requiere creatividad e imaginación
34	actuarTeatro	Artística	6	Actuar, performance teatral	alta	{tarde,noche}	f	Requiere desinhibición
35	chistes	Artística	7	Hacer reír, humor	baja	{cualquier_momento}	f	Natural, me sale espontáneo
36	solucionesDriven	Cognitiva	9	Enfoque en soluciones, no problemas	media	{cualquier_momento}	f	Mindset natural
37	ingenio	Cognitiva	9	Encontrar soluciones creativas con recursos limitados	media	{mañana,tarde}	f	Fortaleza clave
38	pensamientoPropio	Cognitiva	9	Pensar críticamente, cuestionar status quo	media	{mañana,noche}	t	Requiere soledad y silencio
39	analisisCriticoDetallado	Cognitiva	8	Analizar en profundidad	alta	{mañana}	t	Requiere concentración máxima
40	pensamientoRamificado	Cognitiva	9	Ver múltiples caminos y conexiones	media	{mañana}	f	TDAH advantage
41	comprensionDeSystemas	Cognitiva	9	Ver el todo, entender interdependencias	alta	{mañana}	t	Pensamiento sistémico natural
42	pensamientoEnSistemas	Cognitiva	9	Modelar sistemas complejos	alta	{mañana}	t	Core skill para proyectos
43	esquemas	Cognitiva	8	Crear diagramas y modelos visuales	media	{mañana,tarde}	f	Ayuda a pensar mejor
44	conocimientoFilosofía	Conocimiento	7	Filosofía, historia del pensamiento	media	{noche}	f	Lectura y reflexión
45	existencialismo	Conocimiento	8	Filosofía existencialista	media	{noche}	f	Resonancia personal
46	conocimientoPsicología	Conocimiento	8	Psicología, comportamiento humano	media	{cualquier_momento}	f	Estudio continuo
47	eneagrama	Conocimiento	7	Sistema de personalidad Eneagrama	baja	{cualquier_momento}	f	Herramienta de autoconocimiento
48	conocimientoEconomía	Conocimiento	6	Economía y macroeconomía	alta	{mañana}	t	Requiere concentración
49	conocimientoFinanzas	Conocimiento	6	Finanzas personales y empresariales	media	{mañana,tarde}	f	Aprendizaje en progreso
50	conocimientoNegocios	Conocimiento	7	Estrategia de negocios, emprendimiento	media	{mañana,tarde}	f	Experiencia práctica
51	matematicas	Conocimiento	7	Matemáticas, lógica	alta	{mañana}	t	Requiere mente fresca
52	carpintería	Práctica	5	Trabajar con madera	alta	{mañana,tarde}	f	Físico, requiere energía
53	bioconstrucción	Práctica	5	Construcción sustentable	alta	{mañana,tarde}	f	Físico y técnico
54	cocinero	Práctica	6	Cocinar	media	{tarde,noche}	f	Tarea cotidiana
55	atleta	Práctica	6	Deportes, actividad física	alta	{mañana,tarde}	f	Me recarga energéticamente
56	facilidadDeportes	Práctica	7	Aprender deportes rápidamente	media	{cualquier_momento}	f	Natural
57	facilidadParaCiencias	Práctica	8	Entender conceptos científicos	alta	{mañana}	t	Requiere concentración
58	pedagogía	Educativa	7	Enseñar, facilitar aprendizaje	media	{mañana,tarde}	f	Disfruto enseñar
59	enseñanza	Educativa	7	Transmitir conocimiento efectivamente	media	{mañana,tarde}	f	Paciencia y claridad
60	recreacion	Educativa	8	Diseñar actividades recreativas	media	{tarde}	f	Creativo y energético
61	campamentero	Educativa	7	Organizar campamentos, actividades outdoor	alta	{cualquier_momento}	f	Requiere energía y coordinación
62	esfuerzo	Personal	8	Capacidad de trabajar duro cuando es necesario	alta	{mañana}	f	Intensidad cuando hace falta
63	podcast	Media	6	Crear y producir podcasts	media	{tarde,noche}	f	Conversacional
64	redesSociales	Media	6	Gestionar redes sociales	baja	{tarde,noche}	f	Tarea ligera
65	buenPadre	Personal	8	Ser presente y buen padre	alta	{tarde,noche}	f	Requiere energía emocional
66	impactoSocialAmbiental	Social	9	Diseñar proyectos con impacto positivo	media	{mañana,tarde}	f	Propósito de vida
67	causasSociales	Social	9	Trabajo en causas sociales	media	{cualquier_momento}	f	Motivación intrínseca
68	meditar	Personal	6	Meditar, mindfulness	relax	{mañana_temprano,noche}	f	Me recarga
69	titulosAcademicos	Conocimiento	7	Formación académica formal	media	{cualquier_momento}	f	Base de conocimiento
\.


--
-- Data for Name: dificultades; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.dificultades (id, nombre, categoria, nivel_impacto, descripcion, estrategia_mitigacion) FROM stdin;
1	revisarMails	Temporal	8	Procrastinación en revisar y responder emails. Se acumulan.	Bloquear 30 min diarios específicos (15:00-15:30). Usar templates de respuesta. Regla 2 minutos: si toma menos, responder ya.
2	constancia	Emocional	9	Dificultad para mantener constancia en hábitos y tareas repetitivas. TDAH.	Sistemas de accountability (check-ins con alguien). Vincular hábito a recompensa inmediata. Usar Habit Tracker visual. No confiar solo en motivación, crear fricción para NO hacer.
3	exponerme	Emocional	7	Miedo a exponerme públicamente, mostrar vulnerabilidad o imperfección.	Empezar con audiencias pequeñas y seguras. Recordar que la perfección paraliza. Compartir proceso, no solo resultados. Terapia para trabajar miedo al juicio.
4	responderRedes	Social	7	Procrastinación en responder mensajes de redes sociales. Inbox de WhatsApp, LinkedIn, Instagram con mensajes sin leer.	Igualar estrategia que emails: bloque de 20 min diarios. Usar respuestas rápidas. Comunicar "respondo lento" en bio. Delegar si es posible.
5	mantenerPromesas	Social	8	Sobre-comprometerme y luego no cumplir promesas. Decir "sí" cuando debería decir "no".	Regla: ante propuesta nueva, decir "Déjame revisarlo y te confirmo". Calcular tiempo real × 1.5. Aprender a decir no con gracia. Recordar costo de oportunidad.
6	darPasoAdelante	Emocional	8	Paralización ante incertidumbre. Perfeccionismo que impide empezar.	Mantra: "Done is better than perfect". Prototipar rápido. Timebox de decisiones (máximo X tiempo para decidir, luego ejecutar). Recordar que se aprende haciendo.
7	ordenar	Práctica	7	Dificultad para mantener espacios físicos ordenados. TDAH.	Sistema de "un lugar para cada cosa". Reducir cantidad de objetos (minimalismo). Ordenar al final del día 10 minutos. No acumular, tirar/donar rápido.
8	limpiar	Práctica	6	Procrastinación en tareas de limpieza.	Música alegre mientras limpio. Técnica Pomodoro (25 min limpieza). Recompensa post-limpieza (café, serie). Si es posible, delegar o contratar.
9	recoger	Práctica	7	Dejar cosas fuera de lugar. No recoger en el momento.	Regla "one-touch": si toco algo, lo guardo ya. Baskets/cajas por área para "tirar" cosas temporalmente. Recordar que recoger ahora = 10 segundos, después = 5 minutos de buscar.
\.


--
-- Data for Name: disponibilidad_semanal; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.disponibilidad_semanal (id, dia_semana, horas_disponibles, momento_optimo, notas, created_at, updated_at) FROM stdin;
1	1	5.00	maniana	Lunes - semana estándar	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
2	2	5.00	maniana	Martes - semana estándar	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
3	3	5.00	maniana	Miércoles - semana estándar	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
4	4	5.00	maniana	Jueves - semana estándar	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
5	5	4.00	maniana	Viernes - reducir carga	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
6	6	3.00	maniana	Sábado - tiempo personal/proyectos	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
7	7	2.00	tarde	Domingo - planificación semanal	2026-01-03 10:06:58.410555	2026-01-03 10:06:58.410555
\.


--
-- Data for Name: ideas_capturadas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.ideas_capturadas (id, titulo, descripcion, categoria, implementada, "fechaImplementacion", "notaAudioId", "createdAt", "updatedAt", proyecto_estrategico_id) FROM stdin;
1	Mejora en la gestión de proyectos	Necesidad de tener una tabla accesible desde nocodb para cambiar nombres de proyectos y gestionar personas involucradas, incluyendo la identificación de cada persona por su ID en relación a los proyectos.	mejora	f	\N	10	2025-11-07 04:54:27.038	2025-11-07 04:54:27.038	\N
2	Compra de máquina de sublimación	Pensé en comprar una máquina de sublimación y agregarlo en el ande, como, no sé.	producto	f	\N	11	2025-11-07 04:55:09.283	2025-11-07 04:55:09.283	\N
3	Implementar tabla de comunicación para proyectos	Proponer la creación de una tabla que defina el tipo de contenido y la línea de comunicación permitida para los proyectos, especificando qué información se puede compartir y qué no.	estrategia	f	\N	133	2025-12-01 18:57:33.659	2025-12-01 18:57:33.659	\N
\.


--
-- Data for Name: instancias_tareas_recurrentes; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.instancias_tareas_recurrentes (id, tarea_recurrente_id, fecha_programada, hora_inicio, hora_fin, completada, fecha_completada, saltada, razon_saltada, duracion_real_minutos, google_calendar_event_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logs_generacion_ia; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.logs_generacion_ia (id, proyecto_id, tipo_generacion, modelo_ia, tokens_usados, prompt, respuesta, created_at) FROM stdin;
1	\N	inicial	claude-3-5-sonnet-20241022	1000	Crear un sistema para gestionar voluntarios en Involucrate. Necesito inscripciones, asignación de proyectos y reportes de impacto.	{"proyecto":{"justificacion_estrategica":"Justificación estratégica de prueba","areas_ids":[1],"motivos_ids":[1],"destrezas_requeridas_ids":[1],"dificultades_ids":[1],"misiones_ids":[1],"score_motivacional":8.5,"score_alineacion":9.2},"tareas":[{"nombre":"Tarea de prueba","orden":1,"moscow":"must","tiempo_estimado_horas":1,"nivel_riesgo":"bajo","subtareas":[{"titulo":"Subtarea de prueba"}]}]}	2025-12-02 03:27:47.262
\.


--
-- Data for Name: misiones_vida; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.misiones_vida (id, nombre, descripcion, vision, prioridad) FROM stdin;
1	facilitador_bondad	Facilitador de la ejecución de la bondad de los demás	Ser el puente que conecta la intención de ayudar con la acción concreta. Que cuando alguien piense "quiero hacer algo bueno", yo sea quien lo hace posible. Multiplicar el impacto social facilitando que miles de personas ejecuten su bondad.	10
2	momentador_herramientas	Momentador y creador de herramientas para una sociedad más comunicada	Crear sistemas y herramientas (digitales, metodológicas, conceptuales) que ayuden a las personas a comunicarse mejor, entenderse mejor, y coordinarse mejor. Que mis herramientas sean usadas por miles para mejorar su comunicación.	9
3	creador_plataformas	Creador de plataformas y proyectos para que las personas desarrollen su potencial	Diseñar espacios (físicos, digitales, conceptuales) donde las personas puedan crecer, aprender, y convertirse en su mejor versión. Que al menos 10,000 personas hayan desarrollado su potencial gracias a mis plataformas.	9
4	creador_modelos_mentales	Creador de modelos mentales	Crear frameworks, sistemas de pensamiento, y modelos mentales que ayuden a otros a pensar mejor, decidir mejor, y vivir mejor. Que mis modelos sean enseñados y replicados por otros.	8
5	money_maker	Money Maker - Generador de valor económico sostenible	Crear ingresos suficientes para vivir bien, sostener a mi familia, y reinvertir en proyectos de impacto. Llegar a $10k USD/mes recurrentes con proyectos que amo. Libertad financiera sin sacrificar propósito.	8
6	creador_contenido	Creador de contenido que inspira y educa	Crear contenido (escrito, audio, video) que inspire a otros a actuar, a pensar diferente, a crear impacto. Tener una audiencia de 10,000+ personas que esperan mi contenido y se transforman con él.	7
\.


--
-- Data for Name: motivos_personales; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.motivos_personales (id, nombre, descripcion, icono, peso_personal) FROM stdin;
1	impacto_social	Generar cambio positivo medible en la sociedad	🌍	10
2	desarrollo_personal	Aprender, crecer y expandir capacidades	📚	9
3	status_reconocimiento	Ganar autoridad y reconocimiento en el sector	⭐	7
4	desafio_intelectual	Resolver problemas complejos y salir de zona de confort	🧠	9
5	ingresos_sostenibilidad	Generar ingresos para sostenibilidad económica	💰	8
6	conexiones_red	Ampliar red de contactos valiosos	🤝	7
7	creatividad_expresion	Expresar creatividad y crear algo único	🎨	8
8	legado_trascendencia	Dejar algo que trascienda en el tiempo	🏛️	8
9	comunidad_pertenencia	Fortalecer lazos comunitarios y sentido de pertenencia	👥	9
10	experimentacion	Probar cosas nuevas, iterar, aprender haciendo	🔬	9
11	libertad_autonomia	Trabajar con libertad de decisión y creatividad	🦅	9
12	diversion_disfrute	Disfrutar el proceso, pasarla bien	😄	8
\.


--
-- Data for Name: notas_audio; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.notas_audio (id, "transcripcionId", "transcripcionCompleta", "archivoAudioUrl", "resumenEjecutivo", "fechaGrabacion", procesado, "tipoDetectado", "confianzaDeteccion", "createdAt", "updatedAt") FROM stdin;
1	999	Teo llamar a María mañana a las 3pm para revisar el proyecto	https://example.com/audio.mp3	\N	2025-11-07 01:36:29.868	t	tarea	1	2025-11-07 01:36:29.868	2025-11-07 01:36:32.208
122	68	Juan, después fui a Valdivia a comprar TNT para la escuela.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_68_1763420230700.ogg	\N	2025-11-17 22:57:12.691	t	registro	0.8	2025-11-17 22:57:12.691	2025-11-17 22:57:14.916
2	9	Teo, hay que armar y escribir la sección 1 del formulario de capital Semilla de Andes.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_9_1762483130770.ogg	\N	2025-11-07 02:38:53.212	t	tarea	0.75	2025-11-07 02:38:53.212	2025-11-07 02:38:56.192
3	10	Compa, tengo una reunión con UQ Business School el viernes 7 a las 11 de la mañana, les envié un link de Google Meets	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_10_1762483175413.ogg	\N	2025-11-07 02:39:37.64	t	compromiso	0.8333333333333334	2025-11-07 02:39:37.64	2025-11-07 02:39:40.65
123	69	Juan, de tarde, antes de ir a buscar a Feli, hice un escrito para enviar a los padres desde la Comisión Fomento como fin de año.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_69_1763420256289.ogg	\N	2025-11-17 22:57:38.656	t	registro	0.8	2025-11-17 22:57:38.656	2025-11-17 22:57:40.835
4	11	Teo, tengo que escribirle a Diego Sastre mañana al mediodía para revisar a ver si me van a apoyar desde Fibras o si no.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_11_1762483226266.ogg	\N	2025-11-07 02:40:27.869	t	tarea	0.75	2025-11-07 02:40:27.869	2025-11-07 02:40:29.86
5	12	Juan, estuve las últimas tres horas armando dos cosas a la vez, la primera es Mateos que ahora estoy usando y la otra es llenado de un formulario postulación para ANDE	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_12_1762483312119.ogg	\N	2025-11-07 02:41:55.28	t	registro	0.8	2025-11-07 02:41:55.28	2025-11-07 02:41:57.691
124	70	Juan, fui a la ortodoncista a ver cómo le estaba yendo a Feli y a cambiar mi ortodoncia.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_70_1763420272013.ogg	\N	2025-11-17 22:57:54.497	t	registro	0.8	2025-11-17 22:57:54.497	2025-11-17 22:57:57.181
6	13	Juan, llevo Gaby con los niños y los tuve que bajar y ahí empecé a... me enganché con el celular y creo que perdí una hora entera mirando videítos	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_13_1762483346511.ogg	\N	2025-11-07 02:42:28.239	t	registro	0.8	2025-11-07 02:42:28.239	2025-11-07 02:42:29.694
7	14	Juan, hice mucha fuerza y escuché el mensaje que mandó Diego, ya se lo respondí, ya le dije que estoy haciendo el formulario este.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_14_1762483369011.ogg	\N	2025-11-07 02:42:52.284	t	registro	0.8	2025-11-07 02:42:52.284	2025-11-07 02:42:53.834
125	71	Juan, en el medio me sumé a la reunión de fe y alegría con el chatbot y pedí para poder generar un nuevo prompt.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_71_1763420294277.ogg	\N	2025-11-17 22:58:15.865	t	registro	0.8	2025-11-17 22:58:15.865	2025-11-17 22:58:17.854
8	15	Juan, hice toda la automatización, le agregué a Mateos la automatización de el resumen del día así que el viernes a las 8 estaría llegando la primera automatización con todo lo que se hizo en el día	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_15_1762489551172.ogg	\N	2025-11-07 04:25:54.908	t	registro	0.8	2025-11-07 04:25:54.908	2025-11-07 04:25:59.85
9	16	Teo, el viernes 7 de noviembre lo que tengo que hacer es agarrar la planilla de estrategias de social media que me mandó Metricool y tratar de llenarla como para poder empezar a generar acciones y contenido	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_16_1762489639280.ogg	\N	2025-11-07 04:27:23.76	t	tarea	0.75	2025-11-07 04:27:23.76	2025-11-07 04:27:26.596
126	72	Juan, cuando venía para acá también pasé a buscar medicamentos y a comprar una garrafa.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_72_1763420322937.ogg	\N	2025-11-17 22:58:44.795	t	registro	0.8	2025-11-17 22:58:44.795	2025-11-17 22:58:46.297
10	17	Idea, tengo que tener una tabla que pueda acceder desde acá desde nocodb para poder cambiar los nombres de los proyectos por ejemplo y poder cambiar también la parte de las personas etcétera, es decir que en verdad sería como una forma de que pueda hacer esos cambios y cuando dice personas involucradas por ejemplo en la tabla de registros ahí vamos a tener poner un id de persona que es z Diego capaz que se puede después arreglar un poco eso dependiendo del proyecto que Diego hay en ese proyecto y tratar de descubrir cuál es el id digamos de esa persona	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_17_1762491258485.ogg	\N	2025-11-07 04:54:25.376	t	idea	0.6	2025-11-07 04:54:25.376	2025-11-07 04:54:27.043
127	73	Juan, mientras tanto también escribí un escrito para Whatsapp para la rifa de mañana de la escuela.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_73_1763420341765.ogg	\N	2025-11-17 22:59:03.381	t	registro	0.8	2025-11-17 22:59:03.381	2025-11-17 22:59:05.075
128	74	Juan le contesté a Valentina para poder tener una reunión el miércoles a las de tarde.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_74_1763420365809.ogg	\N	2025-11-17 22:59:31.568	t	registro	1	2025-11-17 22:59:31.568	2025-11-17 22:59:33.209
129	75	Juan, estuve revisando la información del presupuesto participativo y aportando y hice un deep research para ver si realmente nos pueden o nos tienen que entregar los pliegos.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_75_1763420386157.ogg	\N	2025-11-17 22:59:47.98	t	registro	0.8	2025-11-17 22:59:47.98	2025-11-17 22:59:52.482
138	84	Idea? Tengo que hacer como un template de todos los proyectos clásicos, como un día para involucrarte, unidos para bregar, solo involucrate, mimochi, etc. Y eso dejarlo en los templates o en los prompts o en un lugar quizás que sea tipo de proyectos, donde cada vez que vayas a hacer un proyecto de esos, se lea dentro del contexto y ese contexto sea clásico.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2026/01/audio_84_1767566098233.ogg	\N	2026-01-04 22:35:03.728	f	idea	0.6	2026-01-04 22:35:03.728	2026-01-04 22:35:03.728
130	76	Bueno, hoy estuve mirando el supercampeonato de la revista y ya abrí a mí toda la parte de... de... de la historia y de por del final de la revista y así que yo al final no la voy a contar ahora porque voy a tener que accountar desde el principio	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_76_1763757480231.ogg	\N	2025-11-21 20:38:05.708	f	sin_clasificar	0	2025-11-21 20:38:05.708	2025-11-21 20:38:05.708
11	18	Idea, pensé en comprar una maquina de sublimación y agregarlo en el ande, como, no sé.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_18_1762491303751.ogg	\N	2025-11-07 04:55:07.117	t	idea	0.6	2025-11-07 04:55:07.117	2025-11-07 04:55:09.291
131	77	¡SUSCRÍBETE!	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_77_1763757495871.ogg	\N	2025-11-21 20:38:17.313	f	sin_clasificar	0	2025-11-21 20:38:17.313	2025-11-21 20:38:17.313
12	19	Tengo que escribirle a Adri mañana sí o sí	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_19_1762491336098.ogg	\N	2025-11-07 04:55:37.986	t	tarea	0.6	2025-11-07 04:55:37.986	2025-11-07 04:55:40.014
132	78	Debo cambiar de ruido.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_78_1763757507660.ogg	\N	2025-11-21 20:38:32.778	f	sin_clasificar	0	2025-11-21 20:38:32.778	2025-11-21 20:38:32.778
13	20	Tengo que hacer una automatización para cuando se envíe o llegue un mensaje de conexión enviar Whatsapp a la persona, a la ONG primero que nada.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_20_1762491427005.ogg	\N	2025-11-07 04:57:09.561	t	tarea	0.6	2025-11-07 04:57:09.561	2025-11-07 04:57:10.943
14	21	Juan, estuve trabajando de 9 a 11 en mejorar la postulación de ANDE con CLOUD y ahora me quedé sin tokens en CLOUD, pero tengo que seguir.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_21_1762530101480.ogg	\N	2025-11-07 15:41:44.614	t	registro	0.8	2025-11-07 15:41:44.614	2025-11-07 15:41:46.874
15	22	Juan, tuve reunión con la energía, al final se puede llevar adelante la postulación de fibras, tengo que, bueno, y nada, eso, hablamos un poco de todo y me contó que creo que lo final es que lo que tengo que presentar tiene que tener sentido para mi proyecto.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_22_1762530136130.ogg	\N	2025-11-07 15:42:18.753	t	registro	0.8	2025-11-07 15:42:18.753	2025-11-07 15:42:21.409
16	23	Teo, tengo que enviar las respuestas del proyecto de Andes al mail de Anaria y de Rochi y de Leo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_23_1762530168027.ogg	\N	2025-11-07 15:42:50.622	t	tarea	0.75	2025-11-07 15:42:50.622	2025-11-07 15:42:53.25
17	24	Juan, tuve una reunión con Enzo y Germán de UCUBS donde me dijeron que estaban ayudando adelante del proyecto Re-Vincularse y me invitaron a participar en un Ateneo el 10 de Diciembre para que presente algo sobre el voluntariado y las personas mayores.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_24_1762530229215.ogg	\N	2025-11-07 15:43:53.081	t	registro	0.8	2025-11-07 15:43:53.081	2025-11-07 15:43:55.431
18	25	Teo, tengo que armar como un esquema de lo que voy a decir en Ateneo y estudiar un poco más sobre los proyectos que vienen.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_25_1762530285261.ogg	\N	2025-11-07 15:44:47.904	t	tarea	0.75	2025-11-07 15:44:47.904	2025-11-07 15:44:49.925
19	26	Teo, envié el mail a Rochi, Leo, Diego y Analia para avisar que estaba con este proyecto y dar el ok en este sentido y a ver si Rochi y Leo están dispuestos a hacer el esfuerzo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_26_1762536991711.ogg	\N	2025-11-07 17:36:34.533	t	tarea	0.75	2025-11-07 17:36:34.533	2025-11-07 17:36:37.37
20	27	Compa, le dije que sí a Pablo de Fiberas para participar en el grupito de Fe y Alegría para la puesta en marcha de eso, así que bueno, voy a... el lunes tenemos una reunión a la hora que teníamos antes la reunión de alianzas	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_27_1762551064916.ogg	\N	2025-11-07 21:31:09.015	t	compromiso	0.8333333333333334	2025-11-07 21:31:09.015	2025-11-07 21:31:12.279
34	41	Teo, en proyecto involucrate, el paso que sigue es armar como la base de datos de POSGRES, llenar las tablas	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_41_1762639695658.ogg	\N	2025-11-08 22:08:19.181	t	tarea	0.75	2025-11-08 22:08:19.181	2025-11-17 17:15:05.995
21	28	Bueno, hoy estuve trabajando en la presentación para Andes y bajando un poco más a tierra todo y me da que... al final me dijeron de fibras que no me podían ayudar y me quedo ahí en la espera de si voy a hacer este... no sé todavía cómo voy a definir si voy a presentarme con otra IP o simplemente la dejo pasar	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_28_1762551134123.ogg	\N	2025-11-07 21:32:18.219	f	sin_clasificar	0	2025-11-07 21:32:18.219	2025-11-07 21:32:18.219
22	29	Juan, pasé también, fui a llevar a Feli a la práctica de fútbol de Mario, después pasé para casa. Pasé por casa, antes fui a comprar frutas y verduras en Los Patos. Y tenía que ir al dentista pero no llegué.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_29_1762551257709.ogg	\N	2025-11-07 21:34:20.611	t	registro	0.8	2025-11-07 21:34:20.611	2025-11-07 21:34:22.859
133	79	Idea, una de las cosas que podemos hacer también es poner una tabla de comunicación o de contenido para los proyectos, qué es lo que se puede decir y qué no, y qué es lo que, por dónde puede ir la información.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_79_1764615447032.ogg	\N	2025-12-01 18:57:30.805	t	idea	0.6	2025-12-01 18:57:30.805	2025-12-01 18:57:33.667
23	30	Juan, mandé un mail bastante complejo a Analia, Rochi, y lo que fuere, toda la gente, para limpiar un poco mi... limpiar un poco, no sé, como que había recibido un mail de Analia, como que yo estaba apurando en las cosas y que... no sé, no se siente cómoda con lo que yo que sé, como si yo lo sentí un poco, como que me estaba diciendo que yo estaba apurando y en verdad lo único que quería era una confirmación sí, estaba apurando en la confirmación, pero era un tema de tiempos y que cualquier persona con empatía lo podría entender bueno, está	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_30_1762551311970.ogg	\N	2025-11-07 21:35:16.375	t	registro	0.8	2025-11-07 21:35:16.375	2025-11-07 21:35:19.361
24	31	Juan, un poco gasté, ahora estoy bastante enojado y perturbado digamos, así que no sé bien qué voy a hacer todavía para llevar adelante esto y no sabría decirte. Tengo que definir si tengo que ir a otra IP o si lo dejo pasar y sumarme en alguna otra oportunidad.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_31_1762551379566.ogg	\N	2025-11-07 21:36:23.113	t	registro	0.8	2025-11-07 21:36:23.113	2025-11-07 21:36:27.681
25	32	Bueno, me mandó un mensaje Álvaro y me dijo que me pasó el contacto de Karina, que es de Ruta de Impacto, que es una IP chiquitita, pero que capaz que le puede llegar a servir, y hablé con Nota y después le dije que la iba a contactar y también después fui a escribirle a Santi para contarle a ver que onda, como es el tema del aborto, como lo maneja todo eso, así que bueno, veremos.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_32_1762559778474.ogg	\N	2025-11-07 23:56:22.135	f	sin_clasificar	0	2025-11-07 23:56:22.135	2025-11-07 23:56:22.135
26	33	Juan, hoy de mañana estuve mirando los avances que venía y decidí al final posponer un poco la postulación para el anda y hacerlo después, capaz que también con fibras, así que bueno, ya mandé mail para avisar, conciliador y bueno, dije que tenía ganas de verlo como para la próxima instancia.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_33_1762621866656.ogg	\N	2025-11-08 17:11:10.078	t	registro	0.8	2025-11-08 17:11:10.078	2025-11-17 17:14:38.006
30	37	Juan, hoy, mañana, arreglé el puff y también puse cintas en el vidrio que estaba rajado.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_37_1762638096522.ogg	\N	2025-11-08 21:41:38.901	t	registro	0.8	2025-11-08 21:41:38.901	2025-11-17 17:14:52.634
32	39	Tengo que revisar la postulación de Álvaro y armarle ahí algo para que queden lindas las cosas de ella.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_39_1762638256886.ogg	\N	2025-11-08 21:44:18.936	t	tarea	0.6	2025-11-08 21:44:18.936	2025-11-17 17:14:59.869
33	40	Teo, hay que revisar de vuelta lo de idas y vueltas y lo del plato lleno y las cosas que tengo que hacer en realidad es...	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_40_1762639658800.ogg	\N	2025-11-08 22:07:40.956	t	tarea	0.75	2025-11-08 22:07:40.956	2025-11-17 17:15:03.144
28	35	Tengo que copiar la información que tengo en las otras bases de datos y pegarlas a la nueva base de datos de involucrajado	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_35_1762621929737.ogg	\N	2025-11-08 17:12:11.889	t	tarea	0.6	2025-11-08 17:12:11.889	2025-11-17 17:14:46.796
31	38	Juan, después enviamos, no, colgué el ropa y vinimos a tomar un helado con los niños y ahora estamos en una placita jugando, que hay una suerte de... pero hay cosas de inmigrantes, me encontré con llanices y bueno, estamos por acá.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_38_1762638131614.ogg	\N	2025-11-08 21:42:14.607	t	registro	0.8	2025-11-08 21:42:14.607	2025-11-17 17:14:56.591
27	34	Juan, estuve, vamos pues, estuve lavando platos y tratando de, bueno, lavando platos mientras que ponía, trataba de hacer el test de Involucra Hub de la base de datos y no pude. No quedó pronto ese test y lo que me quedé pensando es que ya lo digo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_34_1762621913443.ogg	\N	2025-11-08 17:11:58.04	t	registro	0.8	2025-11-08 17:11:58.04	2025-11-17 17:14:41.647
29	36	Juan, cociné unos fideos para todos con huevo y tomate y también hice unos pepinos al vinagre y también lavé las frutas para que queden prontas para comer.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_36_1762621963259.ogg	\N	2025-11-08 17:12:45.482	t	registro	0.8	2025-11-08 17:12:45.482	2025-11-17 17:14:49.514
134	80	Juan, hoy fui a sacar fotos a los de la escuela y a los del jardín y llegué como a las diez y media, perdón, llegué como a las diez y media a casa.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_80_1764699178049.ogg	\N	2025-12-02 18:13:01.792	t	registro	0.8	2025-12-02 18:13:01.792	2025-12-02 18:13:05.608
45	52	y de álvaro de verde urbano está fascinado por el trabajo que hice que en verdad me llevó tiempo sí que de hecho le dediqué mucho tiempo pero al mismo tiempo me dejó muy contento de que él estimara también el trabajo como así que bueno nada como quiero destacar también esa cualidad que tengo de poder presentar proyectos fuertes buenos por lo menos ahora	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_52_1762806555092.ogg	\N	2025-11-10 20:29:18.136	f	sin_clasificar	0	2025-11-10 20:29:18.136	2025-11-17 17:15:36.074
37	44	Juan, hoy estuve en la mañana en la unión de información fomento de la escuela y después fui con Yanela a la placita a hablar con las personas que estaban en la obra de la placita	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_44_1762804780125.ogg	\N	2025-11-10 19:59:46.066	t	registro	0.8	2025-11-10 19:59:46.066	2025-11-17 17:15:12.309
38	45	Compa, mañana tengo que ir al municipio a hablar con el arquitecto para preguntarle y poder pedirle cuáles son los planos y las instrucciones que le pasó a la empresa constructora.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_45_1762804798992.ogg	\N	2025-11-10 20:00:01.869	t	compromiso	0.8333333333333334	2025-11-10 20:00:01.869	2025-11-17 17:15:15.987
40	47	Juan, estuve revisando la parte de la contabilidad de fibras, que Leo había dicho que había algo mal, pero ya veo que Fabián ya lo resolvió, así que seguimos adelante.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_47_1762804869683.ogg	\N	2025-11-10 20:01:14.261	t	registro	0.8	2025-11-10 20:01:14.261	2025-11-17 17:15:22.633
41	48	Teo, me voy para Pixis ahora, cinco y media, a tener la reunión del proyecto Fe y Alegría con Diego y con Pablo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_48_1762804897698.ogg	\N	2025-11-10 20:01:39.252	t	tarea	0.75	2025-11-10 20:01:39.252	2025-11-17 17:15:25.914
42	49	Teo, voy a enviar la presentación que armé para la ANDE de involucrarse a Analia y las personas que están en proyecto de impacto para poder empezar a trabajar desde ahí.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_49_1762804945779.ogg	\N	2025-11-10 20:02:27.99	t	tarea	0.75	2025-11-10 20:02:27.99	2025-11-17 17:15:29.142
43	50	Teo, se comunicaron una voluntaria que se había contactado con Hecho y que no le han contestado. Tengo que arreglar eso y contactarme con ellos a ver si recibieron el contacto.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_50_1762804966134.ogg	\N	2025-11-10 20:02:48.254	t	tarea	0.75	2025-11-10 20:02:48.254	2025-11-17 17:15:31.702
44	51	Teo, hoy de noche tengo murga también. De ocho y media a nueve a once.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_51_1762805011906.ogg	\N	2025-11-10 20:03:34.078	t	tarea	0.75	2025-11-10 20:03:34.078	2025-11-17 17:15:35.071
47	54	Bueno, solo para contar que el jueves estuve contactando con el municipio todo el tiempo para ver que me pase el proyecto bueno, el miércoles que fue 12 estuve de noche también armando la carta para hablar sobre y exponer en redes la parte de que no se están tomando en cuenta y que se está metiendo a la placita del barrio	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_54_1763236839984.ogg	\N	2025-11-15 20:00:43.958	f	sin_clasificar	0	2025-11-15 20:00:43.958	2025-11-17 17:15:40.121
46	53	Juan, fui al comunal a hablar con el arquitecto que no estaba, me dijeron que me iban a llamar cuando llegó cuando llegó volví a ir para allá y cuando se iba ya no estaba, estaba hablando con el alcalde y ahora hablé con la directora, llamé de vuelta a la directora, la directora me dice que cuando la llamé de vuelta que estaba en una reunión con el alcalde con Álvaro, el otro arquitecto, pero bueno seguimos en la búsqueda de contactar para, en la búsqueda de poder generar como, no, tener el pliego de eso, de lo que le pidieron a la empresa	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_53_1762885886487.ogg	\N	2025-11-11 18:31:30.875	t	registro	0.8	2025-11-11 18:31:30.875	2025-11-17 17:15:39.118
48	55	Después, el viernes, estuve ayudando en la parte del viaje por la 190, y estuve todo el día ahí, con poca gente.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_55_1763236861552.ogg	\N	2025-11-15 20:01:04.321	f	sin_clasificar	0	2025-11-15 20:01:04.321	2025-11-17 17:15:41.127
49	56	Juan, el viernes estuve en consulta con Sara y ahí le estuve comentando también sobre el tema de la frustración y cómo me impacta.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_56_1763236893506.ogg	\N	2025-11-15 20:01:35.297	t	registro	0.8	2025-11-15 20:01:35.297	2025-11-17 17:15:43.877
50	57	Juan, el viernes también estuve haciendo. Llevé a los niños al fútbol. Primero a lo de Mario, después al Palá y estuve jugando un poco al básquetbol en la cancha nueva.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_57_1763236917906.ogg	\N	2025-11-15 20:02:00.741	t	registro	0.8	2025-11-15 20:02:00.741	2025-11-17 17:15:47.413
51	58	Juan, después no tuve murga, así que volví a casa y dormí hasta tarde.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_58_1763236926477.ogg	\N	2025-11-15 20:02:08.622	t	registro	0.8	2025-11-15 20:02:08.622	2025-11-17 17:15:50.43
52	59	Juan, hoy fui a comprar el tarmo que me quedaba por comprar con el mate y estuve durmiendo, me dormí hasta muy tarde también.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_59_1763236948492.ogg	\N	2025-11-15 20:02:30.239	t	registro	0.8	2025-11-15 20:02:30.239	2025-11-17 17:15:53.58
53	60	Juan, lave un poco los platos, cocine el almuerzo para Gaby y para mi y me baño.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_60_1763236964167.ogg	\N	2025-11-15 20:02:45.554	t	registro	0.8	2025-11-15 20:02:45.554	2025-11-17 17:15:56.758
36	43	Y hay que revisar si será posible cambiar el sistema de whatsapp para el actual aplicación.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_43_1762639800879.ogg	\N	2025-11-08 22:10:04.224	f	sin_clasificar	0	2025-11-08 22:10:04.224	2025-11-17 17:15:08.003
135	81	Juan, después me entretuve con las redes sociales, creo que recién a las 2 y media, recién pude encarar algo, perdón, o antes, como a las 2 y media.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_81_1764699208086.ogg	\N	2025-12-02 18:13:29.941	t	registro	0.8	2025-12-02 18:13:29.941	2025-12-02 18:13:32.29
136	82	Juan, estuve también revisando el tema de los test que hacen de EQ, los de Mensa y viendo a ver qué tal era el EQ y qué tan complejo eran los test.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_82_1764699236977.ogg	\N	2025-12-02 18:13:58.89	t	registro	0.8	2025-12-02 18:13:58.89	2025-12-02 18:14:01.885
137	83	Juan, hice un test de Dinamarca creo que era, de Mensa, porque no había más cupos en el test de este año y encontré que estoy por encima, así con 133%, 133% de IQ, perdón IQ, de IQ.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_83_1764699278640.ogg	\N	2025-12-02 18:14:42.285	t	registro	0.8	2025-12-02 18:14:42.285	2025-12-02 18:14:44.401
58	62	Juan, hoy de mañana revisé mis objetivos generales y ahora después te los voy a pasar.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_62_1763398931128.ogg	\N	2025-11-17 17:02:13.426	t	registro	0.8	2025-11-17 17:02:13.426	2025-11-17 17:02:16.634
121	67	Juan, después fui a buscar a Feli a la escuela.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_67_1763420217946.ogg	\N	2025-11-17 22:57:00.493	t	registro	0.8	2025-11-17 22:57:00.493	2025-11-17 22:57:02.527
35	42	pero después es también importante poder armar el sistema de whatsapps	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_42_1762639707654.ogg	\N	2025-11-08 22:08:30.319	f	sin_clasificar	0	2025-11-08 22:08:30.319	2025-11-17 17:15:06.999
39	46	Juan, hoy estuve revisando bien a fondo la postulación de Verde Urbano a Ande y estuve cambiando cosas y estuve hablando mucho con el emprendedor Álvaro y tengo como un buen caso de éxito en cuanto a presentación de proyectos al menos así quedó el emprendedor pese a que la presentación será ahora	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_46_1762804841790.ogg	\N	2025-11-10 20:00:46.384	t	registro	0.8	2025-11-10 20:00:46.384	2025-11-17 17:15:19.435
54	61	Juan, ahora fuimos, venimos a buscar a los pequeños a la casa de mi madre para ir al cumpleaños de Ximena	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_61_1763236980657.ogg	\N	2025-11-15 20:03:02.658	t	registro	0.8	2025-11-15 20:03:02.658	2025-11-17 17:16:00.168
117	63	Bueno, hoy fui con Facu al paseo en Punta Espinilla.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_63_1763420118480.ogg	\N	2025-11-17 22:55:20.979	f	sin_clasificar	0	2025-11-17 22:55:20.979	2025-11-17 22:55:20.979
118	64	Juan, hoy fui con Facu al paseo de punta a espinillo durante toda la mañana de 8 a 1.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_64_1763420145908.ogg	\N	2025-11-17 22:55:47.336	t	registro	0.8	2025-11-17 22:55:47.336	2025-11-17 22:55:51.267
119	65	Juan, después volví con Facu también y traté de trabajar haciendo, revisando la parte de la automatización del día de este chatbot	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_65_1763420166612.ogg	\N	2025-11-17 22:56:09.318	t	registro	0.8	2025-11-17 22:56:09.318	2025-11-17 22:56:11.749
120	66	Juan, mientras tanto también estaba viendo el diseño de la revista de Involucrarse Transforma.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_66_1763420194764.ogg	\N	2025-11-17 22:56:36.569	t	registro	0.8	2025-11-17 22:56:36.569	2025-11-17 22:56:38.835
\.


--
-- Data for Name: proyectos_estrategicos; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.proyectos_estrategicos (id, nombre, descripcion, areas_ids, motivos_ids, destrezas_requeridas_ids, dificultades_ids, misiones_ids, justificacion_estrategica, objetivos_smart, fecha_inicio, fecha_fin_estimada, estado, prioridad_global, score_motivacional, score_alineacion, created_at, updated_at) FROM stdin;
10	mimochi7	Proyecto mimochi, entregar kits de mochilas a niños y niñas de bajjos recursos al cimienzo de clases en 2026. Tengo qeu contactar a emprsas de mochilas y útiles para que hagan kits baratos, tengo qeu conectar a empresas para que lancen compañas internas o se sumen. TEngo qeu conectar a merenderos que quieran particiapar. el Área es involucrarse, el motivo es impacto, status, desarrollo personal, desafío. Esta es una coordinación qeu la hago gratis, y la justifico como una forma de acercarme a emrpesas de todo tipo ysumar logos de empresas en mi web. Tener contacto con ellas para generar leads.\n\nLos objetivos son alcanzar las 4000 mochilas para ganar status. Sumar a 35 empresas. Contactar a 120 empresas. Salir en 3 medios de empresas. Este proyecto comenzará el 01 de diciembre y terminará el 29 de marzo. Las entregas de mohcilas se harán hasta el 7 de marzo. Y ahí te dejaría más información de pdf de ediciones anteriores para que tengas una idea. pero esto es solo para explicarte mi idea. Y la web de mimochi del año pasado también era esta\n\nLa emoción de un nuevo comienzo.\n\nSumate a Mimochi 2025\ny fomentá la igualdad educativa en Uruguay\n\n¿Qué es Mimochi?\nMimochi es mucho más que una campaña de útiles escolares. Es una oportunidad para que niños, niñas y adolescentes comiencen sus clases con herramientas nuevas y un corazón lleno de ilusión. Conectamos empresas solidarias con organizaciones que trabajan incansablemente para brindar a estos niños las condiciones educativas que merecen.\n\nHaz que su primer día de clases sea inolvidable. ¡Súmate hoy!\n\nFormas de Participar para Personas\n\n1 Mochi\nSumarte a través de mercadopago, y cambiale el comienzo de clase a 1 niño/a por solo $ 850.\n\nDonar 1 mochi\n\n2 Mochis\nSumarte a través de mercadopago, y cambiale el comienzo de clase a 2 niños/as por solo $ 1.700\n\nDonar 2 mochis\n\n3 Mochis\nSumarte a través de mercadopago, y cambiale el comienzo de clase a 3 niños/as por solo $ 2.500\n\nDonar 3 mochis\n4,014\nMochis en 2024\n68\nInstituciones en 2024\n47\nEmpresas sumadas\n23,400\nMochis desde 2018\nFormas de Participar para Empresas\n\nCampaña interna\nLa empresa realiza una campaña interna con sus colaboradores y luego arma los kits según la lista de Mimochi en una jornada de voluntariado corporativo .\n\n\nCompra y armado de kits\nLa empresa adquiere los kits escolares, organiza una jornada de voluntariado corporativo para ensamblarlos, fortaleciendo la cultura organizacional, y los entrega a las organizaciones asignadas. Ofrecemos apoyo en la planificación del voluntariado si lo necesitan.\n\n\nDonación de kits\nHemos establecido alianzas con mayoristas para facilitar a las empresas la adquisición del kit completo de Mimochi a precios preferenciales. Los kits pueden comprarse para que las empresas los armen en jornadas de voluntariado o para enviarlos directamente a las organizaciones asignadas, garantizando así un proceso práctico y accesible.\n\n\n\nEmpresas que son parte de nuestra comunidad\n\nLo que más valoran las empresas participantes\nUnir al equipo a través del voluntariado corporativo\nLas empresas aprecian cómo las jornadas solidarias fortalecen los lazos entre colaboradores, creando un ambiente de trabajo más positivo y comprometido.\n\nSer agentes de cambio en la comunidad\nParticipar en Mimochi les permite impactar directamente en la educación de niños, alineando sus valores con acciones significativas.\n\nReforzar su identidad como empresa solidaria\nValoran la oportunidad de asociar su marca con iniciativas que promuevan la igualdad y la educación, generando orgullo tanto dentro como fuera de la organización.\n\nSe parte de Mimochi\n¿A quiénes ayudamos?\nEn Mimochi, creemos que cada niña y niño en Uruguay merece comenzar el año escolar con ilusión, entusiasmo y las herramientas necesarias para aprender. Nos enfocamos en llegar a aquellos pequeños que, por diversas razones, no tienen la suerte de contar con útiles escolares nuevos.\n\nTrabajamos en conjunto con merenderos, escuelas en contextos vulnerables y clubes de niños que acompañan a estas familias durante todo el año. Gracias a estas organizaciones, podemos presenciar el impacto real de nuestra campaña: rostros iluminados, niños con confianza renovada y un nuevo entusiasmo por aprender.\n\nNo se trata solo de útiles escolares; se trata de brindarles una oportunidad, un mensaje de esperanza y un apoyo tangible para que sueñen en grande y enfrenten su futuro con dignidad.\n\nTu ayuda puede transformar vidas. Únete a nuestra campaña y sé parte de este momento único en la vida de un niño.\n\nNosotros también queremos ser parte.\nTestimonios de años anteriores\n“\n"Fundamental en el comienzo de clases para nuestros integrantes y una gran ayuda a sus familias"\n\nMerendero Nuestra Esperanza\nCapra\n“\n"Su apoyo es sumamente importante ya que le permitió a todos nuestros escolares empezar dignamente su ciclo escolar"\n\nMerendero y olla las cabañitas\nFlor de Maroñas\n“\n"Es una gran ayuda para niños y niñas que puedan tener su mochila y sus útiles. Verles la cara de felicidad no tiene nombre"\n\nUna Nueva Esperanza\n22 de Mayo\nSumarme\nNuestra Historia: De un Sueño Compartido a una Campaña Transformadora\nMimochi nació de un grupo de amigas que buscaban enseñar valores de solidaridad a sus hijos mientras marcaban una diferencia en la sociedad en 2017. Inspiradas en iniciativas solidarias de América Latina, comenzaron con un objetivo pequeño: ayudar a una escuela. En pocos días, superaron las expectativas y entregaron más de 1,400 mochilas completas en su primer año.\n\nCuando llegó la pandemia, enfrentamos el desafío de mantener nuestro impacto. Fue entonces que redoblamos esfuerzos, enfocándonos en colaborar con empresas y organizaciones comprometidas con la educación y la igualdad de oportunidades.\n\nTras un año de transición, en 2024 trabajamos de la mano con Involucrate para gestionar la campaña. Hoy, el legado continúa bajo su liderazgo, asegurando que cada donación siga llegando a los niños que más lo necesitan.\n\nTu aporte puede cambiar vidas. Súmate a Mimochi y sé parte de esta historia de generosidad y esperanza.\n\n\n¿Tienes dudas? Aquí te ayudamos a resolverlas:\n\nNo contamos con presupuesto disponible para esta iniciativa.\n \n\n¡No te preocupes! Puedes involucrar a tus colaboradores mediante colectas internas o pequeñas aportaciones individuales. Así, reduces costos y fomentas el trabajo en equipo dentro de tu empresa\n\n\nNo tenemos tiempo para coordinar esta actividad.\n \n\nNosotros nos encargamos de facilitar todo el proceso. Te apoyamos en la organización de jornadas de voluntariado y en la entrega directa de los kits, para que sea sencillo y eficiente.\n\n\nNo estamos seguros del impacto que tendrá nuestra donación.\n \n\nTu ayuda transforma vidas. Más de 23,400 mochilas entregadas y los testimonios de las organizaciones receptoras son prueba del cambio positivo que juntos podemos lograr.\n\n\n\n\n¡Haz la diferencia hoy!\nCompleta tus datos y súmate a esta iniciativa. Juntos, podemos cambiar el comienzo de clases para miles de niños.\n\n¡Quiero sumarme!	{2}	{1,2,3,4,5,6,8,9,10,11}	{1,2,4,5,6,7,8,10,11,12,13,16,19,20,26,36,37,38,39,40,41,42,43,46,50,57,58,59,60}	{1,2,3,4,5,6}	{1,2,3,4,5,6}	{"impacto": "alto", "riesgos": "Sobrecarga personal, falta de constancia, parálisis por perfeccionismo, baja conversión de empresas y tiempos logísticos ajustados antes de inicio de clases.", "urgencia": "alta", "alineacion": "Encaja directo con impacto social, desarrollo personal, status y creación de plataformas/proyectos con propósito.", "oportunidad": "Capitalizar el histórico de Mimochi, sumar logos y relaciones con empresas, y consolidar a Involucrate como referente en voluntariado corporativo.", "recursos_clave": "Red de organizaciones sociales, contactos empresariales, habilidades de comunicación, liderazgo, diseño de campañas y uso de IA para sistematizar."}	[{"relevant": "Aporta alto impacto social, refuerza tu rol de facilitador de bondad y creador de plataformas de impacto.", "specific": "Alcanzar la donación y entrega efectiva de al menos 4.000 mochilas completas a niños y niñas de bajos recursos en Uruguay.", "timebound": "Antes del 7 de marzo de 2026.", "achievable": "Ya se lograron 4.014 mochilas en 2024; con mejor organización y más empresas es alcanzable.", "measurable": "Número total de mochilas entregadas con registro por institución (meta: 4.000)."}, {"relevant": "Conecta con status, conexiones de red y generación de leads para futuros proyectos.", "specific": "Incorporar al menos 35 empresas participantes en Mimochi 2026 mediante campañas internas, compra o donación de kits.", "timebound": "Empresas confirmadas antes del 31 de enero de 2026.", "achievable": "En 2024 participaron 47 empresas; mantener o acercarse a ese volumen es realista.", "measurable": "Cantidad de empresas confirmadas con acuerdo básico y plan de acción (meta: 35)."}, {"relevant": "Aumenta tu red, oportunidades comerciales futuras y visibilidad de Involucrate.", "specific": "Contactar al menos 120 empresas con propuestas claras y segmentadas de participación en Mimochi.", "timebound": "Contactos iniciales enviados antes del 31 de diciembre de 2025.", "achievable": "Con plantillas, automatización ligera y bloques de trabajo es factible en 2 meses.", "measurable": "Número de empresas contactadas y registradas en un CRM simple (meta: 120)."}, {"relevant": "Refuerza tu marca personal, status en el sector y posiciona a Involucrate.", "specific": "Lograr al menos 3 apariciones en medios o espacios de comunicación empresariales hablando de Mimochi.", "timebound": "Antes del 29 de marzo de 2026.", "achievable": "Con datos de impacto y casos de éxito previos, el pitch es atractivo para medios.", "measurable": "Cantidad de notas, entrevistas, newsletters o podcasts de empresas/medios (meta: 3)."}]	\N	\N	planificacion	9.20	9.50	9.50	2025-12-04 15:13:29.895	2025-12-04 15:14:35.619
\.


--
-- Data for Name: registros; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.registros (id, descripcion, "duracionHoras", proyecto, "personasInvolucradas", categoria, "fechaActividad", "notaAudioId", "createdAt", "updatedAt") FROM stdin;
1	armando dos cosas a la vez, la primera es Mateos y la otra es llenado de un formulario postulación para ANDE	3	ANDE	{}	TRABAJO	2025-11-07 02:41:57.681	5	2025-11-07 02:41:57.683	2025-11-07 02:41:57.683
2	bajar a los niños y mirar videítos en el celular	1	\N	{Gaby}	PERSONAL	2025-11-07 02:42:29.691	6	2025-11-07 02:42:29.692	2025-11-07 02:42:29.692
3	respondí el mensaje que mandó Diego y estoy haciendo el formulario	\N	\N	{Diego}	TRABAJO	2025-11-07 02:42:53.831	7	2025-11-07 02:42:53.832	2025-11-07 02:42:53.832
4	hice toda la automatización y le agregué a Mateos la automatización del resumen del día	\N	\N	{Mateos}	TRABAJO	2025-11-07 04:25:59.844	8	2025-11-07 04:25:59.844	2025-11-07 04:25:59.844
5	estuve trabajando en mejorar la postulación de ANDE con CLOUD	2	ANDE	{}	TRABAJO	2025-11-07 15:41:46.85	14	2025-11-07 15:41:46.852	2025-11-07 15:41:46.852
6	tuve reunión con la energía	\N	\N	{}	TRABAJO	2025-11-07 15:42:21.405	15	2025-11-07 15:42:21.406	2025-11-07 15:42:21.406
7	tuve una reunión con Enzo y Germán de UCUBS donde me dijeron que estaban ayudando adelante del proyecto Re-Vincularse	\N	Re-Vincularse	{Enzo,Germán}	TRABAJO	2025-11-07 15:43:55.427	17	2025-11-07 15:43:55.428	2025-11-07 15:43:55.428
8	llevé a Feli a la práctica de fútbol de Mario y compré frutas y verduras en Los Patos	\N	\N	{Feli,Mario}	PERSONAL	2025-11-07 21:34:22.841	22	2025-11-07 21:34:22.842	2025-11-07 21:34:22.842
9	mandé un mail bastante complejo a Analia y Rochi para limpiar un poco la situación sobre la confirmación que estaba apurando	\N	\N	{Analia,Rochi}	TRABAJO	2025-11-07 21:35:19.356	23	2025-11-07 21:35:19.357	2025-11-07 21:35:19.357
11	revisé mis objetivos generales	2	\N	{}	PERSONAL	2025-11-17 17:02:16.617	58	2025-11-17 17:02:16.618	2025-11-17 17:02:16.618
10	gasté	\N	\N	{}	OTRO	2025-11-08 21:36:00	24	2025-11-07 21:36:27.676	2025-11-07 21:36:27.676
12	miré los avances y decidí posponer la postulación para el anda	\N	anda	{conciliador}	TRABAJO	2025-11-17 17:14:37.994	26	2025-11-17 17:14:37.995	2025-11-17 17:14:37.995
13	lavando platos y tratando de hacer el test de Involucra Hub de la base de datos	\N	Involucra Hub	{}	TRABAJO	2025-11-17 17:14:41.644	27	2025-11-17 17:14:41.645	2025-11-17 17:14:41.645
14	cociné unos fideos con huevo y tomate, hice unos pepinos al vinagre y lavé las frutas	\N	\N	{}	PERSONAL	2025-11-17 17:14:49.511	29	2025-11-17 17:14:49.512	2025-11-17 17:14:49.512
15	arreglé el puff y puse cintas en el vidrio que estaba rajado	\N	\N	{}	PERSONAL	2025-11-17 17:14:52.631	30	2025-11-17 17:14:52.632	2025-11-17 17:14:52.632
16	colgué la ropa y fui a tomar un helado con los niños y después jugamos en una placita	\N	\N	{"los niños"}	PERSONAL	2025-11-17 17:14:56.588	31	2025-11-17 17:14:56.589	2025-11-17 17:14:56.589
17	estuve en la unión de información fomento de la escuela y fui con Yanela a hablar con las personas que estaban en la obra de la placita	4	\N	{Yanela}	SOCIAL	2025-11-17 17:15:12.304	37	2025-11-17 17:15:12.305	2025-11-17 17:15:12.305
18	revisé a fondo la postulación de Verde Urbano a Ande y cambié cosas, hablé mucho con el emprendedor Álvaro	\N	Verde Urbano	{Álvaro}	TRABAJO	2025-11-17 17:15:19.43	39	2025-11-17 17:15:19.431	2025-11-17 17:15:19.431
19	estuve revisando la parte de la contabilidad de fibras	\N	fibras	{Leo,Fabián}	TRABAJO	2025-11-17 17:15:22.63	40	2025-11-17 17:15:22.631	2025-11-17 17:15:22.631
20	fui al comunal a hablar con el arquitecto, intenté contactarlo varias veces y hablé con la directora	\N	\N	{arquitecto,alcalde,directora,Álvaro}	TRABAJO	2025-11-17 17:15:39.116	46	2025-11-17 17:15:39.117	2025-11-17 17:15:39.117
21	estuve en consulta con Sara y le comenté sobre el tema de la frustración y cómo me impacta	\N	\N	{Sara}	PERSONAL	2025-11-17 17:15:43.874	49	2025-11-17 17:15:43.875	2025-11-17 17:15:43.875
22	Llevé a los niños al fútbol y estuve jugando un poco al básquetbol en la cancha nueva.	\N	\N	{Mario}	PERSONAL	2025-11-17 17:15:47.411	50	2025-11-17 17:15:47.412	2025-11-17 17:15:47.412
23	volví a casa y dormí hasta tarde	\N	\N	{}	PERSONAL	2025-11-17 17:15:50.425	51	2025-11-17 17:15:50.426	2025-11-17 17:15:50.426
24	fui a comprar el tarmo que me quedaba por comprar con el mate y estuve durmiendo	\N	\N	{}	PERSONAL	2025-11-17 17:15:53.578	52	2025-11-17 17:15:53.579	2025-11-17 17:15:53.579
25	lave un poco los platos, cocine el almuerzo para Gaby y para mi y me baño.	\N	\N	{Gaby}	PERSONAL	2025-11-17 17:15:56.756	53	2025-11-17 17:15:56.757	2025-11-17 17:15:56.757
26	fui a buscar a los pequeños a la casa de mi madre para ir al cumpleaños de Ximena	\N	\N	{Ximena}	SOCIAL	2025-11-17 17:16:00.164	54	2025-11-17 17:16:00.165	2025-11-17 17:16:00.165
27	fui con Facu al paseo de punta a espinillo	5	\N	{Facu}	PERSONAL	2025-11-17 22:55:51.256	118	2025-11-17 22:55:51.257	2025-11-17 22:55:51.257
28	traté de trabajar haciendo, revisando la parte de la automatización del día de este chatbot	\N	chatbot	{Facu}	TRABAJO	2025-11-17 22:56:11.746	119	2025-11-17 22:56:11.747	2025-11-17 22:56:11.747
29	estaba viendo el diseño de la revista de Involucrarse Transforma	\N	Involucrarse Transforma	{}	TRABAJO	2025-11-17 22:56:38.832	120	2025-11-17 22:56:38.833	2025-11-17 22:56:38.833
30	fui a buscar a Feli a la escuela	\N	\N	{Feli}	PERSONAL	2025-11-17 22:57:02.519	121	2025-11-17 22:57:02.52	2025-11-17 22:57:02.52
31	fui a Valdivia a comprar TNT para la escuela	\N	\N	{}	PERSONAL	2025-11-17 22:57:14.913	122	2025-11-17 22:57:14.914	2025-11-17 22:57:14.914
32	hice un escrito para enviar a los padres desde la Comisión Fomento	\N	Comisión Fomento	{Feli}	TRABAJO	2025-11-17 22:57:40.83	123	2025-11-17 22:57:40.833	2025-11-17 22:57:40.833
33	fui a la ortodoncista a ver cómo le estaba yendo a Feli y a cambiar mi ortodoncia	\N	\N	{Feli}	PERSONAL	2025-11-17 22:57:57.177	124	2025-11-17 22:57:57.178	2025-11-17 22:57:57.178
34	me sumé a la reunión de fe y alegría con el chatbot y pedí para poder generar un nuevo prompt	\N	\N	{}	TRABAJO	2025-11-17 22:58:17.852	125	2025-11-17 22:58:17.852	2025-11-17 22:58:17.852
35	pasé a buscar medicamentos y a comprar una garrafa	\N	\N	{}	PERSONAL	2025-11-17 22:58:46.295	126	2025-11-17 22:58:46.295	2025-11-17 22:58:46.295
36	escribí un escrito para Whatsapp para la rifa de mañana de la escuela	\N	rifa de la escuela	{}	SOCIAL	2025-11-17 22:59:05.072	127	2025-11-17 22:59:05.072	2025-11-17 22:59:05.072
37	le contesté a Valentina para poder tener una reunión el miércoles	\N	\N	{Valentina}	TRABAJO	2025-11-17 22:59:33.207	128	2025-11-17 22:59:33.207	2025-11-17 22:59:33.207
38	revisé la información del presupuesto participativo y aporté, hice un deep research para ver si realmente nos pueden o nos tienen que entregar los pliegos	\N	presupuesto participativo	{}	TRABAJO	2025-11-17 22:59:52.48	129	2025-11-17 22:59:52.48	2025-11-17 22:59:52.48
39	fui a sacar fotos a los de la escuela y a los del jardín	\N	\N	{}	SOCIAL	2025-12-02 18:13:05.593	134	2025-12-02 18:13:05.595	2025-12-02 18:13:05.595
40	me entretuve con las redes sociales	\N	\N	{}	SOCIAL	2025-12-02 18:13:32.285	135	2025-12-02 18:13:32.286	2025-12-02 18:13:32.286
41	revisé el tema de los test que hacen de EQ, los de Mensa	\N	\N	{}	OTRO	2025-12-02 18:14:01.881	136	2025-12-02 18:14:01.882	2025-12-02 18:14:01.882
42	hice un test de Mensa de Dinamarca	\N	\N	{}	PERSONAL	2025-12-02 18:14:44.396	137	2025-12-02 18:14:44.397	2025-12-02 18:14:44.397
\.


--
-- Data for Name: subtareas_estrategicas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.subtareas_estrategicas (id, tarea_estrategica_id, nombre, tiempo_estimado_minutos, moscow, destreza_principal_id, created_at, updated_at, fecha_inicio, fecha_fin, estado_kanban, fecha_done, proyecto_nombre) FROM stdin;
211	55	Configurar filtros emails	45	should	16	2025-12-04 15:14:35.729	2025-12-05 10:27:09.383	\N	\N	doing	\N	mimochi7
209	55	Definir ritual diario 30m	30	must	9	2025-12-04 15:14:35.729	2025-12-04 15:14:35.729	\N	\N	todo	\N	mimochi7
151	44	Revisar datos 2024	45	must	41	2025-12-04 15:14:35.658	2025-12-04 15:14:35.658	\N	\N	todo	\N	mimochi7
152	44	Definir metas numéricas	45	must	42	2025-12-04 15:14:35.658	2025-12-04 15:14:35.658	\N	\N	todo	\N	mimochi7
153	44	Diseñar niveles participación	60	must	20	2025-12-04 15:14:35.658	2025-12-04 15:14:35.658	\N	\N	todo	\N	mimochi7
154	44	Definir propuesta personas	45	should	26	2025-12-04 15:14:35.658	2025-12-04 15:14:35.658	\N	\N	todo	\N	mimochi7
155	44	Escribir one-pager Mimochi	45	must	26	2025-12-04 15:14:35.658	2025-12-04 15:14:35.658	\N	\N	todo	\N	mimochi7
156	45	Listar proveedores potenciales	45	must	10	2025-12-04 15:14:35.67	2025-12-04 15:14:35.67	\N	\N	todo	\N	mimochi7
157	45	Armar mail estándar proveedores	45	must	26	2025-12-04 15:14:35.67	2025-12-04 15:14:35.67	\N	\N	todo	\N	mimochi7
158	45	Enviar primer bloque contactos	60	must	6	2025-12-04 15:14:35.67	2025-12-04 15:14:35.67	\N	\N	todo	\N	mimochi7
159	45	Negociar precios y plazos	90	must	4	2025-12-04 15:14:35.67	2025-12-04 15:14:35.67	\N	\N	todo	\N	mimochi7
160	45	Definir kit estándar Mimochi	60	must	41	2025-12-04 15:14:35.67	2025-12-04 15:14:35.67	\N	\N	todo	\N	mimochi7
161	45	Documentar condiciones acuerdo	60	should	11	2025-12-04 15:14:35.67	2025-12-04 15:14:35.67	\N	\N	todo	\N	mimochi7
162	46	Recolectar testimonios 2024	45	should	6	2025-12-04 15:14:35.676	2025-12-04 15:14:35.676	\N	\N	todo	\N	mimochi7
163	46	Definir paquetes participación	60	must	42	2025-12-04 15:14:35.676	2025-12-04 15:14:35.676	\N	\N	todo	\N	mimochi7
164	46	Redactar dossier empresas	90	must	26	2025-12-04 15:14:35.676	2025-12-04 15:14:35.676	\N	\N	todo	\N	mimochi7
165	46	Crear presentación breve	75	should	19	2025-12-04 15:14:35.676	2025-12-04 15:14:35.676	\N	\N	todo	\N	mimochi7
166	46	Preparar guion pitch	45	must	5	2025-12-04 15:14:35.676	2025-12-04 15:14:35.676	\N	\N	todo	\N	mimochi7
167	47	Listar empresas conocidas	45	must	6	2025-12-04 15:14:35.681	2025-12-04 15:14:35.681	\N	\N	todo	\N	mimochi7
168	47	Investigar nuevas empresas	90	must	50	2025-12-04 15:14:35.681	2025-12-04 15:14:35.681	\N	\N	todo	\N	mimochi7
169	47	Crear hoja CRM simple	45	must	16	2025-12-04 15:14:35.681	2025-12-04 15:14:35.681	\N	\N	todo	\N	mimochi7
170	47	Clasificar por prioridad	45	should	41	2025-12-04 15:14:35.681	2025-12-04 15:14:35.681	\N	\N	todo	\N	mimochi7
171	47	Completar datos contacto	75	must	10	2025-12-04 15:14:35.681	2025-12-04 15:14:35.681	\N	\N	todo	\N	mimochi7
172	48	Crear plantillas email	60	must	26	2025-12-04 15:14:35.686	2025-12-04 15:14:35.686	\N	\N	todo	\N	mimochi7
173	48	Configurar bloques outreach	45	must	10	2025-12-04 15:14:35.686	2025-12-04 15:14:35.686	\N	\N	todo	\N	mimochi7
174	48	Enviar primer lote 20	75	must	6	2025-12-04 15:14:35.686	2025-12-04 15:14:35.686	\N	\N	todo	\N	mimochi7
175	48	Contactar vía LinkedIn	90	should	6	2025-12-04 15:14:35.686	2025-12-04 15:14:35.686	\N	\N	todo	\N	mimochi7
176	48	Hacer llamadas clave	90	should	5	2025-12-04 15:14:35.686	2025-12-04 15:14:35.686	\N	\N	todo	\N	mimochi7
177	48	Registrar respuestas CRM	60	must	11	2025-12-04 15:14:35.686	2025-12-04 15:14:35.686	\N	\N	todo	\N	mimochi7
178	49	Agendar llamadas seguimiento	60	must	10	2025-12-04 15:14:35.692	2025-12-04 15:14:35.692	\N	\N	todo	\N	mimochi7
179	49	Realizar reuniones clave	180	must	8	2025-12-04 15:14:35.692	2025-12-04 15:14:35.692	\N	\N	todo	\N	mimochi7
212	55	Crear tablero kanban simple	45	must	43	2025-12-04 15:14:35.729	2025-12-05 10:27:05.327	\N	\N	todo	\N	mimochi7
213	55	Definir reglas decir no	30	should	2	2025-12-04 15:14:35.729	2025-12-04 15:14:35.729	\N	\N	todo	\N	mimochi7
214	56	Consolidar métricas finales	60	must	41	2025-12-04 15:14:35.735	2025-12-04 15:14:35.735	\N	\N	todo	\N	mimochi7
215	56	Recolectar testimonios clave	60	should	1	2025-12-04 15:14:35.735	2025-12-04 15:14:35.735	\N	\N	todo	\N	mimochi7
216	56	Escribir informe resumen	75	should	26	2025-12-04 15:14:35.735	2025-12-04 15:14:35.735	\N	\N	todo	\N	mimochi7
217	56	Actualizar web y CV	60	could	18	2025-12-04 15:14:35.735	2025-12-04 15:14:35.735	\N	\N	todo	\N	mimochi7
180	49	Definir compromiso escrito	90	must	11	2025-12-04 15:14:35.692	2025-12-04 15:14:35.692	\N	\N	todo	\N	mimochi7
181	49	Enviar recap y próximos pasos	90	must	6	2025-12-04 15:14:35.692	2025-12-04 15:14:35.692	\N	\N	todo	\N	mimochi7
182	49	Actualizar tablero empresas	60	should	43	2025-12-04 15:14:35.692	2025-12-04 15:14:35.692	\N	\N	todo	\N	mimochi7
183	49	Identificar embajadores internos	60	could	1	2025-12-04 15:14:35.692	2025-12-04 15:14:35.692	\N	\N	todo	\N	mimochi7
218	56	Identificar aprendizajes clave	45	should	38	2025-12-04 15:14:35.735	2025-12-04 15:14:35.735	\N	\N	todo	\N	mimochi7
210	55	Bloquear tiempo outreach	30	must	10	2025-12-04 15:14:35.729	2025-12-04 15:14:35.729	\N	\N	todo	\N	mimochi7
208	54	Diseñar sistema registro	60	must	16	2025-12-04 15:14:35.723	2025-12-04 15:14:35.723	\N	\N	todo	\N	mimochi7
207	54	Crear checklist armado kits	45	must	43	2025-12-04 15:14:35.723	2025-12-05 11:48:02.78	\N	\N	todo	\N	mimochi7
206	54	Identificar apoyos logísticos	60	should	12	2025-12-04 15:14:35.723	2025-12-04 15:14:35.723	\N	\N	todo	\N	mimochi7
205	54	Definir calendario entregas	60	must	10	2025-12-04 15:14:35.723	2025-12-04 15:14:35.723	\N	\N	todo	\N	mimochi7
204	54	Mapear flujo completo	60	must	42	2025-12-04 15:14:35.723	2025-12-04 15:14:35.723	\N	\N	todo	\N	mimochi7
203	53	Registrar apariciones logradas	30	could	11	2025-12-04 15:14:35.717	2025-12-04 15:14:35.717	\N	\N	todo	\N	mimochi7
202	53	Preparar mensajes entrevista	45	should	5	2025-12-04 15:14:35.717	2025-12-04 15:14:35.717	\N	\N	todo	\N	mimochi7
201	53	Contactar periodistas clave	75	should	6	2025-12-04 15:14:35.717	2025-12-04 15:14:35.717	\N	\N	todo	\N	mimochi7
200	53	Redactar gacetilla prensa	60	must	26	2025-12-04 15:14:35.717	2025-12-04 15:14:35.717	\N	\N	todo	\N	mimochi7
199	53	Listar medios objetivos	45	must	10	2025-12-04 15:14:35.717	2025-12-04 15:14:35.717	\N	\N	todo	\N	mimochi7
198	52	Crear piezas PDF simples	60	should	18	2025-12-04 15:14:35.711	2025-12-04 15:14:35.711	\N	\N	todo	\N	mimochi7
197	52	Optimizar estructura web	75	should	19	2025-12-04 15:14:35.711	2025-12-05 11:48:07.201	\N	\N	todo	\N	mimochi7
196	52	Ajustar copy 2026	75	must	26	2025-12-04 15:14:35.711	2025-12-05 11:48:08.657	\N	\N	todo	\N	mimochi7
195	52	Actualizar cifras impacto	45	must	41	2025-12-04 15:14:35.711	2025-12-07 13:13:13.386	\N	\N	todo	\N	mimochi7
194	52	Revisar textos actuales	45	must	39	2025-12-04 15:14:35.711	2025-12-07 13:13:14.707	\N	\N	todo	\N	mimochi7
193	51	Armar plantilla agenda jornada	45	should	7	2025-12-04 15:14:35.704	2025-12-04 15:14:35.704	\N	\N	todo	\N	mimochi7
192	51	Definir mensajes claves valor	45	must	26	2025-12-04 15:14:35.704	2025-12-04 15:14:35.704	\N	\N	todo	\N	mimochi7
191	51	Redactar guía facilitación	60	should	59	2025-12-04 15:14:35.704	2025-12-04 15:14:35.704	\N	\N	todo	\N	mimochi7
190	51	Crear checklist empresas	45	must	43	2025-12-04 15:14:35.704	2025-12-04 15:14:35.704	\N	\N	todo	\N	mimochi7
189	51	Definir formatos jornada	60	must	20	2025-12-04 15:14:35.704	2025-12-04 15:14:35.704	\N	\N	todo	\N	mimochi7
188	50	Acordar puntos entrega	60	must	7	2025-12-04 15:14:35.699	2025-12-04 15:14:35.699	\N	\N	todo	\N	mimochi7
187	50	Asignar mochis por institución	75	must	41	2025-12-04 15:14:35.699	2025-12-04 15:14:35.699	\N	\N	todo	\N	mimochi7
186	50	Definir criterios prioridad	45	should	46	2025-12-04 15:14:35.699	2025-12-04 15:14:35.699	\N	\N	todo	\N	mimochi7
185	50	Enviar formulario cupos	45	must	6	2025-12-04 15:14:35.699	2025-12-04 15:14:35.699	\N	\N	todo	\N	mimochi7
184	50	Actualizar base instituciones	60	must	10	2025-12-04 15:14:35.699	2025-12-04 15:14:35.699	\N	\N	todo	\N	mimochi7
\.


--
-- Data for Name: tareas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.tareas (id, titulo, descripcion, "fechaVencimiento", prioridad, completada, "fechaCompletada", "notaAudioId", "createdAt", "updatedAt", proyecto_estrategico_id) FROM stdin;
4	Llenar planilla de estrategias de social media	Agarrar la planilla de estrategias de social media que me mandó Metricool y tratar de llenarla como para poder empezar a generar acciones y contenido.	2025-11-07 00:00:00	MEDIA	f	\N	9	2025-11-07 04:27:26.592	2025-11-07 04:27:26.592	\N
5	Escribirle a Adri	\N	2025-11-08 00:00:00	URGENTE	f	\N	12	2025-11-07 04:55:40.01	2025-11-07 04:55:40.01	\N
6	Hacer automatización para enviar WhatsApp	Crear una automatización que envíe un mensaje de WhatsApp a la persona o a la ONG cuando se envíe o llegue un mensaje de conexión.	\N	MEDIA	f	\N	13	2025-11-07 04:57:10.941	2025-11-07 04:57:10.941	\N
8	Armar esquema para Ateneo	Estudiar un poco más sobre los proyectos que vienen.	\N	MEDIA	f	\N	18	2025-11-07 15:44:49.922	2025-11-07 15:44:49.922	\N
3	Escribir a Diego Sastre	Revisar si me van a apoyar desde Fibras o si no.	2025-11-08 00:00:00	MEDIA	t	\N	4	2025-11-07 02:40:29.857	2025-11-07 02:40:29.857	\N
10	Copiar información a nueva base de datos	Copiar la información que tengo en las otras bases de datos y pegarlas a la nueva base de datos de involucrajado.	\N	MEDIA	f	\N	28	2025-11-17 17:14:46.792	2025-11-17 17:14:46.792	\N
12	Revisar idas y vueltas y plato lleno	Revisar de vuelta lo de idas y vueltas y lo del plato lleno, junto con las cosas que tengo que hacer.	\N	MEDIA	f	\N	33	2025-11-17 17:15:03.138	2025-11-17 17:15:03.138	\N
15	Enviar presentación a Analia y equipo de proyecto de impacto	Enviar la presentación que armé para la ANDE de involucrarse a Analia y las personas que están en proyecto de impacto para poder empezar a trabajar desde ahí.	\N	MEDIA	f	\N	42	2025-11-17 17:15:29.14	2025-11-17 17:15:29.14	\N
16	Contactar a Hecho sobre voluntaria	Arreglar la falta de respuesta de Hecho a la voluntaria que se contactó.	\N	MEDIA	f	\N	43	2025-11-17 17:15:31.701	2025-11-17 17:15:31.701	\N
7	Enviar respuestas del proyecto de Andes	Enviar las respuestas del proyecto de Andes al mail de Anaria, Rochi y Leo.	\N	MEDIA	t	\N	16	2025-11-07 15:42:53.243	2025-11-07 15:42:53.243	\N
9	Confirmar disposición de Rochi y Leo	Verificar si Rochi y Leo están dispuestos a hacer el esfuerzo para el proyecto.	\N	MEDIA	t	\N	19	2025-11-07 17:36:37.363	2025-11-07 17:36:37.363	\N
11	Revisar la postulación de Álvaro	Armar algo para que queden lindas las cosas de ella.	\N	MEDIA	t	\N	32	2025-11-17 17:14:59.866	2025-11-17 17:14:59.866	\N
13	Armar base de datos de POSGRES	Llenar las tablas de la base de datos para el proyecto 'Involúcrate'.	\N	MEDIA	t	\N	34	2025-11-17 17:15:05.993	2025-11-17 17:15:05.993	\N
14	Asistir a reunión del proyecto Fe y Alegría	Reunión con Diego y Pablo en Pixis.	2025-11-17 20:30:00	MEDIA	t	\N	41	2025-11-17 17:15:25.912	2025-11-17 17:15:25.912	\N
17	Asistir a la murga	Hoy de noche tengo murga también. De ocho y media a nueve a once.	2025-11-17 23:30:00	MEDIA	t	\N	44	2025-11-17 17:15:35.067	2025-11-17 17:15:35.067	\N
1	Llamar a María	Llamar a María mañana a las 3pm para revisar el proyecto	2025-11-08 15:00:00	MEDIA	t	\N	1	2025-11-07 01:36:32.201	2025-11-07 01:36:32.201	\N
2	Armar y escribir la sección 1 del formulario de capital Semilla	Escribir y organizar la primera sección del formulario de capital Semilla de Andes.	\N	MEDIA	t	\N	2	2025-11-07 02:38:56.187	2025-11-07 02:38:56.187	\N
\.


--
-- Data for Name: tareas_estrategicas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.tareas_estrategicas (id, proyecto_id, nombre, descripcion, orden, moscow, tiempo_estimado_horas, nivel_riesgo, prioridad_velocidad_perfeccion, created_at, updated_at, fecha_inicio, fecha_fin, estado_kanban, fecha_done, impacto, urgencia, eisenhower, energia_requerida, contexto_necesario, duracion_real_horas, bloqueada_por, fecha_estimada_desbloqueo) FROM stdin;
44	10	Definir alcance campaña	Clarificar alcance 2026, modelo de kits, cupos por institución y propuesta específica para empresas y personas.	1	must	4	medio	balanceado	2025-12-04 15:14:35.633	2025-12-04 15:14:35.633	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
45	10	Alianzas mochilas útiles	Cerrar acuerdos con proveedores de mochilas y útiles para kits a precio preferencial y condiciones claras.	2	must	6	alto	velocidad	2025-12-04 15:14:35.667	2025-12-04 15:14:35.667	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
46	10	Diseñar propuesta empresas	Crear propuesta clara y atractiva para empresas con beneficios, formatos de participación y casos de éxito.	3	must	5	medio	balanceado	2025-12-04 15:14:35.673	2025-12-04 15:14:35.673	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
47	10	Armar base empresas	Construir y organizar una base de al menos 120 empresas segmentadas y priorizadas para contacto.	4	must	4	medio	velocidad	2025-12-04 15:14:35.678	2025-12-04 15:14:35.678	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
48	10	Lanzar contactos empresas	Ejecutar el plan de contacto a 120 empresas mediante emails, LinkedIn y llamadas breves.	5	must	10	alto	velocidad	2025-12-04 15:14:35.684	2025-12-04 15:14:35.684	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
49	10	Gestionar empresas interesadas	Convertir interés en compromisos concretos, definiendo montos, formato de participación y próximos pasos.	6	must	12	alto	balanceado	2025-12-04 15:14:35.689	2025-12-04 15:14:35.689	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
50	10	Coordinar organizaciones sociales	Confirmar merenderos, escuelas y clubes de niños, cupos y logística básica de entrega.	7	must	6	medio	velocidad	2025-12-04 15:14:35.695	2025-12-04 15:14:35.695	\N	\N	backlog	\N	alto	media	cuadrante_2	\N	\N	\N	\N	\N
51	10	Plan voluntariado corporativo	Diseñar y ofrecer formatos simples de jornadas de armado de kits para las empresas.	8	should	4	medio	balanceado	2025-12-04 15:14:35.701	2025-12-04 15:14:35.701	\N	\N	backlog	\N	medio	media	cuadrante_2	\N	\N	\N	\N	\N
52	10	Actualizar web y materiales	Actualizar la web de Mimochi y piezas básicas de comunicación para 2026.	9	should	5	medio	perfeccion	2025-12-04 15:14:35.707	2025-12-04 15:14:35.707	\N	\N	backlog	\N	medio	media	cuadrante_2	\N	\N	\N	\N	\N
53	10	Gestión medios y prensa	Diseñar y ejecutar un mini plan de prensa para lograr al menos 3 apariciones en medios empresariales.	10	should	5	medio	velocidad	2025-12-04 15:14:35.715	2025-12-04 15:14:35.715	\N	\N	backlog	\N	medio	media	cuadrante_2	\N	\N	\N	\N	\N
54	10	Planificar logística entrega	Organizar el flujo de armado, almacenamiento y entrega de mochilas a tiempo.	11	must	6	alto	balanceado	2025-12-04 15:14:35.721	2025-12-04 15:14:35.721	\N	\N	backlog	\N	alto	media	cuadrante_1	\N	\N	\N	\N	\N
55	10	Sistema seguimiento personal	Crear un sistema mínimo para evitar procrastinación, gestionar mails y mantener constancia.	12	must	3	alto	velocidad	2025-12-04 15:14:35.726	2025-12-04 15:14:35.726	\N	\N	backlog	\N	alto	alta	cuadrante_1	\N	\N	\N	\N	\N
56	10	Documentar resultados cierre	Medir resultados, recopilar testimonios y dejar documentación para futuras ediciones y tu web.	13	should	4	bajo	perfeccion	2025-12-04 15:14:35.733	2025-12-04 15:14:35.733	\N	\N	backlog	\N	medio	baja	cuadrante_2	\N	\N	\N	\N	\N
\.


--
-- Data for Name: tareas_recurrentes; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.tareas_recurrentes (id, nombre, descripcion, area_id, proyecto_estrategico_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto, activa, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transcripciones; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.transcripciones (id, hora, texto, r2_url, r2_key, telegram_file_id, telegram_user_id, telegram_message_id, duracion_segundos, tamano_bytes, created_at, updated_at, estado, error_msg) FROM stdin;
1	2025-11-05 16:00:01.921+00	Bueno, vamos a ver si esta prueba funciona.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_1_1762358401938.ogg	audios/2025/11/audio_1_1762358401938.ogg	AwACAgEAAxkBAAM6aQt0foGCwVWHbOGUc4jwjZ4g1oEAAuoFAAL921lEnPNZYBv5QIo2BA	6365727491	58	4	83241	2025-11-05 16:00:01.921+00	2025-11-05 16:00:04.38+00	COMPLETADO	\N
2	2025-11-06 14:27:42.574+00	Hoy estuve como dos horas, desde que me desperté, tarde, como a las, no sé si a las 9, me desperté, como hasta las 11, tirado en la cama, exploreando redes sociales.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_2_1762439262621.ogg	audios/2025/11/audio_2_1762439262621.ogg	AwACAgEAAxkBAAM9aQywWYg5q1G7dqG0smfj4hFGqJAAAlMFAALtpWlE4RaiE0oxxss2BA	6365727491	61	17	351865	2025-11-06 14:27:42.574+00	2025-11-06 14:27:46.877+00	COMPLETADO	\N
3	2025-11-06 15:00:11.265+00	bueno ahora fui, tuve que ir al baño un rato, me quedé metiéndole a me metí en el link en telegram para ver esto y me quedé primero eliminando todos los contactos y después me metí en el bot de texto audio para poder este para ver cómo se usaba y bueno lo aprendí a utilizar y estuve escuchando el libro que estaba escribiendo y me dieron ganas de seguir escribiéndolo ahora voy a ver si puedo contestar todos los whatsapps, contactarme con el contador y dar una mirada clave de hacia dónde voy a ir	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_3_1762441211269.ogg	audios/2025/11/audio_3_1762441211269.ogg	AwACAgEAAxkBAANAaQy39iDkD0sxD7ms-qc6AzBoRicAAlgFAALtpWlEjZx2Gmegf3E2BA	6365727491	64	54	1115713	2025-11-06 15:00:11.265+00	2025-11-06 15:00:15.929+00	COMPLETADO	\N
4	2025-11-06 15:00:42.748+00	De 11 a 11 y media más o menos cuando me metí a trabajar estuve contestando a algunos whatsapp, algunas cosas de cloud que me pidió las preguntas para ver la arquitectura del programa que estoy haciendo de este de Mateos	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_4_1762441242749.ogg	audios/2025/11/audio_4_1762441242749.ogg	AwACAgEAAxkBAANDaQy4F7BB2PtchGe2B8Rz__RcR3EAAlkFAALtpWlEJs5P-XxksaI2BA	6365727491	67	26	555393	2025-11-06 15:00:42.748+00	2025-11-06 15:00:45.747+00	COMPLETADO	\N
5	2025-11-06 15:01:27.106+00	estoy teniendo problemas para poder visualizar todas las cutas que tengo que hacer como que ayer tenía muchas ganas de visualizarlas, bajarlas a tierra, ir haciéndolas dividiéndolas en poquitos el tema, son las 12 ahora y casi estuve todo el día, toda la mañana sin poder avanzar en nada	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_5_1762441287108.ogg	audios/2025/11/audio_5_1762441287108.ogg	AwACAgEAAxkBAANGaQy4Q60bZl915XzGOAAB2dYlV3jgAAJbBQAC7aVpRJ8t_ew_9zNqNgQ	6365727491	70	36	744089	2025-11-06 15:01:27.106+00	2025-11-06 15:01:31.705+00	COMPLETADO	\N
6	2025-11-06 16:57:28.154+00	Estuve revisando un poco la parte del nombre de cómo vamos a llamar voluntariado corporativo y estoy cambiando la parte de voluntariado corporativo por voluntariado en empresas para hacerlo más humano que no suene tanto a top y enfocado mucho en equipos de empresas más que nada de forma que sea en realidad el nombre largo sería como voluntariado de equipos de empresas pero para facilitar y bajarlo y que sea claro vamos a estar hablando de voluntariado en empresas.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_6_1762448248171.ogg	audios/2025/11/audio_6_1762448248171.ogg	AwACAgEAAxkBAANJaQzTc5IzWfhnNHsR6ToxAAE-I4krAAJwBQAC7aVpRI5XFQABGNHnHjYE	6365727491	73	48	992937	2025-11-06 16:57:28.154+00	2025-11-06 16:57:35.538+00	COMPLETADO	\N
7	2025-11-06 16:57:52.559+00	Ya hablé con... ya mandé email a Fabián, me respondió y voy a tener una reunión con él a las 3 de la tarde hoy.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_7_1762448272561.ogg	audios/2025/11/audio_7_1762448272561.ogg	AwACAgEAAxkBAANMaQzTjYzirjm3KQoCsIuKe9pQ8qcAAnEFAALtpWlEP5ajVsCvb6I2BA	6365727491	76	13	277705	2025-11-06 16:57:52.559+00	2025-11-06 16:57:54.465+00	COMPLETADO	\N
8	2025-11-06 16:58:46.361+00	Ya mandé el resumen de la reunión que tuve con las maestras por el viaje de la 190 y está todo en Comisión Fomento.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_8_1762448326373.ogg	audios/2025/11/audio_8_1762448326373.ogg	AwACAgEAAxkBAANPaQzTw_t3bMLyBXjuVa6MdmXdcAEAAnIFAALtpWlEBCosReL3blU2BA	6365727491	79	27	572697	2025-11-06 16:58:46.361+00	2025-11-06 16:58:49.423+00	COMPLETADO	\N
9	2025-11-07 02:38:50.747+00	Teo, hay que armar y escribir la sección 1 del formulario de capital Semilla de Andes.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_9_1762483130770.ogg	audios/2025/11/audio_9_1762483130770.ogg	AwACAgEAAxkBAANSaQ1bt9diFXJfCJyMJ5VY10yhoIkAAp4FAALtpWlEdztU7VrsD1c2BA	6365727491	82	14	304897	2025-11-07 02:38:50.747+00	2025-11-07 02:38:53.151+00	COMPLETADO	\N
10	2025-11-07 02:39:35.412+00	Compa, tengo una reunión con UQ Business School el viernes 7 a las 11 de la mañana, les envié un link de Google Meets	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_10_1762483175413.ogg	audios/2025/11/audio_10_1762483175413.ogg	AwACAgEAAxkBAANVaQ1b5KnhET8FPf43rGvuvNjBBd4AAp8FAALtpWlEc3UHdlMpgO02BA	6365727491	85	19	395537	2025-11-07 02:39:35.412+00	2025-11-07 02:39:37.631+00	COMPLETADO	\N
11	2025-11-07 02:40:26.264+00	Teo, tengo que escribirle a Diego Sastre mañana al mediodía para revisar a ver si me van a apoyar desde Fibras o si no.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_11_1762483226266.ogg	audios/2025/11/audio_11_1762483226266.ogg	AwACAgEAAxkBAANYaQ1cFzuiten0E6wv9U-ugKdwZyoAAqAFAALtpWlERAywmg13K342BA	6365727491	88	13	275233	2025-11-07 02:40:26.264+00	2025-11-07 02:40:27.848+00	COMPLETADO	\N
12	2025-11-07 02:41:52.118+00	Juan, estuve las últimas tres horas armando dos cosas a la vez, la primera es Mateos que ahora estoy usando y la otra es llenado de un formulario postulación para ANDE	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_12_1762483312119.ogg	audios/2025/11/audio_12_1762483312119.ogg	AwACAgEAAxkBAANbaQ1cbH0MCm8TWiFyU8F6UzbLOPgAAqEFAALtpWlE24FMm197ags2BA	6365727491	91	34	707833	2025-11-07 02:41:52.118+00	2025-11-07 02:41:55.261+00	COMPLETADO	\N
13	2025-11-07 02:42:26.509+00	Juan, llevo Gaby con los niños y los tuve que bajar y ahí empecé a... me enganché con el celular y creo que perdí una hora entera mirando videítos	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_13_1762483346511.ogg	audios/2025/11/audio_13_1762483346511.ogg	AwACAgEAAxkBAANeaQ1cj53Ovb2jr4rSxClCkVnVdxkAAqIFAALtpWlEZ3PR5kodNVU2BA	6365727491	94	17	365873	2025-11-07 02:42:26.509+00	2025-11-07 02:42:28.224+00	COMPLETADO	\N
14	2025-11-07 02:42:49.009+00	Juan, hice mucha fuerza y escuché el mensaje que mandó Diego, ya se lo respondí, ya le dije que estoy haciendo el formulario este.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_14_1762483369011.ogg	audios/2025/11/audio_14_1762483369011.ogg	AwACAgEAAxkBAANhaQ1cppdl4sV6UBcRlS4G4Xp1bfwAAqQFAALtpWlEVJRtbTwjn982BA	6365727491	97	16	344449	2025-11-07 02:42:49.009+00	2025-11-07 02:42:52.266+00	COMPLETADO	\N
15	2025-11-07 04:25:51.164+00	Juan, hice toda la automatización, le agregué a Mateos la automatización de el resumen del día así que el viernes a las 8 estaría llegando la primera automatización con todo lo que se hizo en el día	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_15_1762489551172.ogg	audios/2025/11/audio_15_1762489551172.ogg	AwACAgEAAxkBAANkaQ10y7Jl87ZJ7zKtYBiztrbWxScAAnEHAALtpXFEf1JNWMt-kHg2BA	6365727491	100	30	625433	2025-11-07 04:25:51.164+00	2025-11-07 04:25:54.845+00	COMPLETADO	\N
16	2025-11-07 04:27:19.279+00	Teo, el viernes 7 de noviembre lo que tengo que hacer es agarrar la planilla de estrategias de social media que me mandó Metricool y tratar de llenarla como para poder empezar a generar acciones y contenido	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_16_1762489639280.ogg	audios/2025/11/audio_16_1762489639280.ogg	AwACAgEAAxkBAANnaQ11JNVo_1C9dBHNiygVzxmlFEYAAnMHAALtpXFEmJRRQ50UIeo2BA	6365727491	103	23	484529	2025-11-07 04:27:19.279+00	2025-11-07 04:27:23.75+00	COMPLETADO	\N
17	2025-11-07 04:54:18.483+00	Idea, tengo que tener una tabla que pueda acceder desde acá desde nocodb para poder cambiar los nombres de los proyectos por ejemplo y poder cambiar también la parte de las personas etcétera, es decir que en verdad sería como una forma de que pueda hacer esos cambios y cuando dice personas involucradas por ejemplo en la tabla de registros ahí vamos a tener poner un id de persona que es z Diego capaz que se puede después arreglar un poco eso dependiendo del proyecto que Diego hay en ese proyecto y tratar de descubrir cuál es el id digamos de esa persona	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_17_1762491258485.ogg	audios/2025/11/audio_17_1762491258485.ogg	AwACAgEAAxkBAANqaQ17dgq41YyaDw2gtCzQ-VupSSAAAoQHAALtpXFEkX2OMySc7CY2BA	6365727491	106	84	1733713	2025-11-07 04:54:18.483+00	2025-11-07 04:54:25.341+00	COMPLETADO	\N
18	2025-11-07 04:55:03.75+00	Idea, pensé en comprar una maquina de sublimación y agregarlo en el ande, como, no sé.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_18_1762491303751.ogg	audios/2025/11/audio_18_1762491303751.ogg	AwACAgEAAxkBAANtaQ17pJCnBxP-MczflpPh5esDJg4AAoUHAALtpXFEjbCB_fY5QMQ2BA	6365727491	109	27	567753	2025-11-07 04:55:03.75+00	2025-11-07 04:55:07.106+00	COMPLETADO	\N
19	2025-11-07 04:55:36.097+00	Tengo que escribirle a Adri mañana sí o sí	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_19_1762491336098.ogg	audios/2025/11/audio_19_1762491336098.ogg	AwACAgEAAxkBAANwaQ17xeftZstdrDURFkktszYelKoAAoYHAALtpXFE_BlDw8ihHGs2BA	6365727491	112	4	87361	2025-11-07 04:55:36.097+00	2025-11-07 04:55:37.972+00	COMPLETADO	\N
20	2025-11-07 04:57:07.004+00	Tengo que hacer una automatización para cuando se envíe o llegue un mensaje de conexión enviar Whatsapp a la persona, a la ONG primero que nada.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_20_1762491427005.ogg	audios/2025/11/audio_20_1762491427005.ogg	AwACAgEAAxkBAANzaQ18IKMjz_-IBjFvQQqO0_GInoIAAocHAALtpXFEVXp8nS2CNhY2BA	6365727491	115	26	552097	2025-11-07 04:57:07.004+00	2025-11-07 04:57:09.544+00	COMPLETADO	\N
21	2025-11-07 15:41:41.44+00	Juan, estuve trabajando de 9 a 11 en mejorar la postulación de ANDE con CLOUD y ahora me quedé sin tokens en CLOUD, pero tengo que seguir.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_21_1762530101480.ogg	audios/2025/11/audio_21_1762530101480.ogg	AwACAgEAAxkBAAN2aQ4TMsj_U4llP70ixsHavxwRWx8AAsgGAAKtT3BEFvDEQ2VRDow2BA	6365727491	118	26	551273	2025-11-07 15:41:41.44+00	2025-11-07 15:41:44.388+00	COMPLETADO	\N
22	2025-11-07 15:42:16.128+00	Juan, tuve reunión con la energía, al final se puede llevar adelante la postulación de fibras, tengo que, bueno, y nada, eso, hablamos un poco de todo y me contó que creo que lo final es que lo que tengo que presentar tiene que tener sentido para mi proyecto.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_22_1762530136130.ogg	audios/2025/11/audio_22_1762530136130.ogg	AwACAgEAAxkBAAN5aQ4TVIudlfzbm6QVogc_-h4r0kYAAskGAAKtT3BEziJpkojGlac2BA	6365727491	121	32	669929	2025-11-07 15:42:16.128+00	2025-11-07 15:42:18.741+00	COMPLETADO	\N
23	2025-11-07 15:42:48.025+00	Teo, tengo que enviar las respuestas del proyecto de Andes al mail de Anaria y de Rochi y de Leo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_23_1762530168027.ogg	audios/2025/11/audio_23_1762530168027.ogg	AwACAgEAAxkBAAN8aQ4TdHYYXDnyxkXE8y77LbMZSakAAsoGAAKtT3BE5TnC5GhDw4c2BA	6365727491	124	27	569401	2025-11-07 15:42:48.025+00	2025-11-07 15:42:50.614+00	COMPLETADO	\N
24	2025-11-07 15:43:49.2+00	Juan, tuve una reunión con Enzo y Germán de UCUBS donde me dijeron que estaban ayudando adelante del proyecto Re-Vincularse y me invitaron a participar en un Ateneo el 10 de Diciembre para que presente algo sobre el voluntariado y las personas mayores.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_24_1762530229215.ogg	audios/2025/11/audio_24_1762530229215.ogg	AwACAgEAAxkBAAN_aQ4TsdvcIke6yIJ3iDlxmiGqZnUAAswGAAKtT3BESbtft6jYzAk2BA	6365727491	127	46	964921	2025-11-07 15:43:49.2+00	2025-11-07 15:43:53.062+00	COMPLETADO	\N
25	2025-11-07 15:44:45.258+00	Teo, tengo que armar como un esquema de lo que voy a decir en Ateneo y estudiar un poco más sobre los proyectos que vienen.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_25_1762530285261.ogg	audios/2025/11/audio_25_1762530285261.ogg	AwACAgEAAxkBAAOCaQ4T6j-7DiLRLamZNeR3Ap321bkAAs0GAAKtT3BEoRfGzB5iX682BA	6365727491	130	17	363401	2025-11-07 15:44:45.258+00	2025-11-07 15:44:47.881+00	COMPLETADO	\N
26	2025-11-07 17:36:31.699+00	Teo, envié el mail a Rochi, Leo, Diego y Analia para avisar que estaba con este proyecto y dar el ok en este sentido y a ver si Rochi y Leo están dispuestos a hacer el esfuerzo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_26_1762536991711.ogg	audios/2025/11/audio_26_1762536991711.ogg	AwACAgEAAxkBAAOFaQ4uHVFA-0_zQkMbwVRgST_f8cUAAuEGAAKtT3BEwdtQYYpwdUM2BA	6365727491	133	24	94888	2025-11-07 17:36:31.699+00	2025-11-07 17:36:34.422+00	COMPLETADO	\N
27	2025-11-07 21:31:04.885+00	Compa, le dije que sí a Pablo de Fiberas para participar en el grupito de Fe y Alegría para la puesta en marcha de eso, así que bueno, voy a... el lunes tenemos una reunión a la hora que teníamos antes la reunión de alianzas	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_27_1762551064916.ogg	audios/2025/11/audio_27_1762551064916.ogg	AwACAgEAAxkBAAOIaQ5lFdV9ZJ5wnlS3smqHeLTvY20AAhQHAAKtT3BEgSw9SbIlNto2BA	6365727491	136	37	780345	2025-11-07 21:31:04.885+00	2025-11-07 21:31:08.782+00	COMPLETADO	\N
41	2025-11-08 22:08:15.657+00	Teo, en proyecto involucrate, el paso que sigue es armar como la base de datos de POSGRES, llenar las tablas	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_41_1762639695658.ogg	audios/2025/11/audio_41_1762639695658.ogg	AwACAgEAAxkBAAO0aQ-_TD44NoiYRio7trw_8I2pXSQAAiIGAAIdx4FErchVVP7Cv1w2BA	6365727491	180	25	529849	2025-11-08 22:08:15.657+00	2025-11-08 22:08:19.14+00	COMPLETADO	\N
28	2025-11-07 21:32:14.12+00	Bueno, hoy estuve trabajando en la presentación para Andes y bajando un poco más a tierra todo y me da que... al final me dijeron de fibras que no me podían ayudar y me quedo ahí en la espera de si voy a hacer este... no sé todavía cómo voy a definir si voy a presentarme con otra IP o simplemente la dejo pasar	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_28_1762551134123.ogg	audios/2025/11/audio_28_1762551134123.ogg	AwACAgEAAxkBAAOLaQ5lWpuGSX4PFDcHws8MdOrWG34AAhUHAAKtT3BEvJRmOKT8GnE2BA	6365727491	139	42	881697	2025-11-07 21:32:14.12+00	2025-11-07 21:32:18.207+00	COMPLETADO	\N
29	2025-11-07 21:34:17.707+00	Juan, pasé también, fui a llevar a Feli a la práctica de fútbol de Mario, después pasé para casa. Pasé por casa, antes fui a comprar frutas y verduras en Los Patos. Y tenía que ir al dentista pero no llegué.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_29_1762551257709.ogg	audios/2025/11/audio_29_1762551257709.ogg	AwACAgEAAxkBAAOOaQ5l1ijefFWcDfuycCcCJ1Wo3WQAAhcHAAKtT3BEZLHiWAr6dAw2BA	6365727491	142	27	571873	2025-11-07 21:34:17.707+00	2025-11-07 21:34:20.595+00	COMPLETADO	\N
30	2025-11-07 21:35:11.964+00	Juan, mandé un mail bastante complejo a Analia, Rochi, y lo que fuere, toda la gente, para limpiar un poco mi... limpiar un poco, no sé, como que había recibido un mail de Analia, como que yo estaba apurando en las cosas y que... no sé, no se siente cómoda con lo que yo que sé, como si yo lo sentí un poco, como que me estaba diciendo que yo estaba apurando y en verdad lo único que quería era una confirmación sí, estaba apurando en la confirmación, pero era un tema de tiempos y que cualquier persona con empatía lo podría entender bueno, está	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_30_1762551311970.ogg	audios/2025/11/audio_30_1762551311970.ogg	AwACAgEAAxkBAAORaQ5mDBLimLkdo9T6lYB_ZD0kd-gAAhgHAAKtT3BEGQnGYtVc3SY2BA	6365727491	145	51	1063801	2025-11-07 21:35:11.964+00	2025-11-07 21:35:16.359+00	COMPLETADO	\N
31	2025-11-07 21:36:19.564+00	Juan, un poco gasté, ahora estoy bastante enojado y perturbado digamos, así que no sé bien qué voy a hacer todavía para llevar adelante esto y no sabría decirte. Tengo que definir si tengo que ir a otra IP o si lo dejo pasar y sumarme en alguna otra oportunidad.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_31_1762551379566.ogg	audios/2025/11/audio_31_1762551379566.ogg	AwACAgEAAxkBAAOUaQ5mUDotwI5fgJ06Jnr4xx9V0oMAAhkHAAKtT3BEzzQzdVzoDvw2BA	6365727491	148	59	1219537	2025-11-07 21:36:19.564+00	2025-11-07 21:36:23.088+00	COMPLETADO	\N
32	2025-11-07 23:56:18.452+00	Bueno, me mandó un mensaje Álvaro y me dijo que me pasó el contacto de Karina, que es de Ruta de Impacto, que es una IP chiquitita, pero que capaz que le puede llegar a servir, y hablé con Nota y después le dije que la iba a contactar y también después fui a escribirle a Santi para contarle a ver que onda, como es el tema del aborto, como lo maneja todo eso, así que bueno, veremos.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_32_1762559778474.ogg	audios/2025/11/audio_32_1762559778474.ogg	AwACAgEAAxkBAAOXaQ6HH_Hp21uYwkyAkdNrNApl8W4AAjoHAAKtT3BElvwzwFPV8dk2BA	6365727491	151	45	937729	2025-11-07 23:56:18.452+00	2025-11-07 23:56:21.967+00	COMPLETADO	\N
33	2025-11-08 17:11:06.629+00	Juan, hoy de mañana estuve mirando los avances que venía y decidí al final posponer un poco la postulación para el anda y hacerlo después, capaz que también con fibras, así que bueno, ya mandé mail para avisar, conciliador y bueno, dije que tenía ganas de verlo como para la próxima instancia.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_33_1762621866656.ogg	audios/2025/11/audio_33_1762621866656.ogg	AwACAgEAAxkBAAOcaQ95pwY4SOhm5vQ4oeexSnuxLOYAAmsFAAKtT3hENX42QDBX2JQ2BA	6365727491	156	38	149617	2025-11-08 17:11:06.629+00	2025-11-08 17:11:09.608+00	COMPLETADO	\N
34	2025-11-08 17:11:53.441+00	Juan, estuve, vamos pues, estuve lavando platos y tratando de, bueno, lavando platos mientras que ponía, trataba de hacer el test de Involucra Hub de la base de datos y no pude. No quedó pronto ese test y lo que me quedé pensando es que ya lo digo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_34_1762621913443.ogg	audios/2025/11/audio_34_1762621913443.ogg	AwACAgEAAxkBAAOfaQ951yjjiD0aLNyIIMcennnGU4AAAmwFAAKtT3hEUFkPbtzEwxs2BA	6365727491	159	40	152096	2025-11-08 17:11:53.441+00	2025-11-08 17:11:58.018+00	COMPLETADO	\N
35	2025-11-08 17:12:09.735+00	Tengo que copiar la información que tengo en las otras bases de datos y pegarlas a la nueva base de datos de involucrajado	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_35_1762621929737.ogg	audios/2025/11/audio_35_1762621929737.ogg	AwACAgEAAxkBAAOiaQ9557W6mzpRRV_XQdjf_5xgQlUAAm0FAAKtT3hEQskEwY219Og2BA	6365727491	162	14	54675	2025-11-08 17:12:09.735+00	2025-11-08 17:12:11.877+00	COMPLETADO	\N
36	2025-11-08 17:12:43.258+00	Juan, cociné unos fideos para todos con huevo y tomate y también hice unos pepinos al vinagre y también lavé las frutas para que queden prontas para comer.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_36_1762621963259.ogg	audios/2025/11/audio_36_1762621963259.ogg	AwACAgEAAxkBAAOlaQ96CQ6mczEe3OIAAeFT9ze-O3RJAAJuBQACrU94RJEoxOG9IyH3NgQ	6365727491	165	27	104188	2025-11-08 17:12:43.258+00	2025-11-08 17:12:45.471+00	COMPLETADO	\N
37	2025-11-08 21:41:36.504+00	Juan, hoy, mañana, arreglé el puff y también puse cintas en el vidrio que estaba rajado.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_37_1762638096522.ogg	audios/2025/11/audio_37_1762638096522.ogg	AwACAgEAAxkBAAOoaQ-5DVeGNuk9vxpmIozUvoA1or4AAhcGAAIdx4FElE5xFFwyA-M2BA	6365727491	168	13	282649	2025-11-08 21:41:36.504+00	2025-11-08 21:41:38.737+00	COMPLETADO	\N
38	2025-11-08 21:42:11.612+00	Juan, después enviamos, no, colgué el ropa y vinimos a tomar un helado con los niños y ahora estamos en una placita jugando, que hay una suerte de... pero hay cosas de inmigrantes, me encontré con llanices y bueno, estamos por acá.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_38_1762638131614.ogg	audios/2025/11/audio_38_1762638131614.ogg	AwACAgEAAxkBAAOraQ-5MP4-a6r2CwcSdw7_CsiwV_kAAhgGAAIdx4FEzVY9x1DBMLo2BA	6365727491	171	32	674049	2025-11-08 21:42:11.612+00	2025-11-08 21:42:14.587+00	COMPLETADO	\N
39	2025-11-08 21:44:16.884+00	Tengo que revisar la postulación de Álvaro y armarle ahí algo para que queden lindas las cosas de ella.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_39_1762638256886.ogg	audios/2025/11/audio_39_1762638256886.ogg	AwACAgEAAxkBAAOuaQ-5rheYrj4mYEwwF92xLbdv96UAAhoGAAIdx4FExmpANfmoxLY2BA	6365727491	174	14	305721	2025-11-08 21:44:16.884+00	2025-11-08 21:44:18.926+00	COMPLETADO	\N
40	2025-11-08 22:07:38.796+00	Teo, hay que revisar de vuelta lo de idas y vueltas y lo del plato lleno y las cosas que tengo que hacer en realidad es...	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_40_1762639658800.ogg	audios/2025/11/audio_40_1762639658800.ogg	AwACAgEAAxkBAAOxaQ-_J200x3JnLNco1Bak2xIMQYUAAiEGAAIdx4FEtIId4x_sq2M2BA	6365727491	177	20	418609	2025-11-08 22:07:38.796+00	2025-11-08 22:07:40.908+00	COMPLETADO	\N
42	2025-11-08 22:08:27.652+00	pero después es también importante poder armar el sistema de whatsapps	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_42_1762639707654.ogg	audios/2025/11/audio_42_1762639707654.ogg	AwACAgEAAxkBAAO3aQ-_Wcj0EG4FIUW36XAunRpCH6MAAiMGAAIdx4FEXuwAAZSV_Ed7NgQ	6365727491	183	10	211785	2025-11-08 22:08:27.652+00	2025-11-08 22:08:30.309+00	COMPLETADO	\N
63	2025-11-17 22:55:18.457+00	Bueno, hoy fui con Facu al paseo en Punta Espinilla.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_63_1763420118480.ogg	audios/2025/11/audio_63_1763420118480.ogg	AwACAgEAAxkBAAP_aRun0yFwQwG_UNGMPPC2P6HQ-9IAAioHAAKYwNhEhAJP8mFAHhU2BA	6365727491	255	5	115377	2025-11-17 22:55:18.457+00	2025-11-17 22:55:20.705+00	COMPLETADO	\N
43	2025-11-08 22:10:00.878+00	Y hay que revisar si será posible cambiar el sistema de whatsapp para el actual aplicación.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_43_1762639800879.ogg	audios/2025/11/audio_43_1762639800879.ogg	AwACAgEAAxkBAAO6aQ-_tXhCUznZidZHLBgycfdcD_kAAioGAAIdx4FEjHBigWw7WgABNgQ	6365727491	186	27	561161	2025-11-08 22:10:00.878+00	2025-11-08 22:10:04.213+00	COMPLETADO	\N
44	2025-11-10 19:59:40.089+00	Juan, hoy estuve en la mañana en la unión de información fomento de la escuela y después fui con Yanela a la placita a hablar con las personas que estaban en la obra de la placita	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_44_1762804780125.ogg	audios/2025/11/audio_44_1762804780125.ogg	AwACAgEAAxkBAAO_aRJEKLFNTHcET06KiyLdbywb4mgAAp8FAALHWpBEoq5hyW2t9Oo2BA	6365727491	191	24	498537	2025-11-10 19:59:40.089+00	2025-11-10 19:59:45.875+00	COMPLETADO	\N
45	2025-11-10 19:59:58.991+00	Compa, mañana tengo que ir al municipio a hablar con el arquitecto para preguntarle y poder pedirle cuáles son los planos y las instrucciones que le pasó a la empresa constructora.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_45_1762804798992.ogg	audios/2025/11/audio_45_1762804798992.ogg	AwACAgEAAxkBAAPCaRJEPJr9CVHKTgus-TigCJBYfkkAAqAFAALHWpBEqiE6GHjNhSQ2BA	6365727491	194	16	341153	2025-11-10 19:59:58.991+00	2025-11-10 20:00:01.853+00	COMPLETADO	\N
46	2025-11-10 20:00:41.787+00	Juan, hoy estuve revisando bien a fondo la postulación de Verde Urbano a Ande y estuve cambiando cosas y estuve hablando mucho con el emprendedor Álvaro y tengo como un buen caso de éxito en cuanto a presentación de proyectos al menos así quedó el emprendedor pese a que la presentación será ahora	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_46_1762804841790.ogg	audios/2025/11/audio_46_1762804841790.ogg	AwACAgEAAxkBAAPFaRJEZm2oYN1B5-TVQjUnYLSUkO4AAqEFAALHWpBEP_qoVwPnMcU2BA	6365727491	197	37	777873	2025-11-10 20:00:41.787+00	2025-11-10 20:00:46.364+00	COMPLETADO	\N
47	2025-11-10 20:01:09.681+00	Juan, estuve revisando la parte de la contabilidad de fibras, que Leo había dicho que había algo mal, pero ya veo que Fabián ya lo resolvió, así que seguimos adelante.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_47_1762804869683.ogg	audios/2025/11/audio_47_1762804869683.ogg	AwACAgEAAxkBAAPIaRJEgl-q2OYGdUTiTWDVfT-J5qUAAqIFAALHWpBEvS6v-umQKK42BA	6365727491	200	18	373289	2025-11-10 20:01:09.681+00	2025-11-10 20:01:14.247+00	COMPLETADO	\N
48	2025-11-10 20:01:37.697+00	Teo, me voy para Pixis ahora, cinco y media, a tener la reunión del proyecto Fe y Alegría con Diego y con Pablo.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_48_1762804897698.ogg	audios/2025/11/audio_48_1762804897698.ogg	AwACAgEAAxkBAAPLaRJEnrPRNaW_ihchOINBFRdzf8cAAqMFAALHWpBEgmBXYCh9z9Q2BA	6365727491	203	19	412017	2025-11-10 20:01:37.697+00	2025-11-10 20:01:39.24+00	COMPLETADO	\N
49	2025-11-10 20:02:25.776+00	Teo, voy a enviar la presentación que armé para la ANDE de involucrarse a Analia y las personas que están en proyecto de impacto para poder empezar a trabajar desde ahí.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_49_1762804945779.ogg	audios/2025/11/audio_49_1762804945779.ogg	AwACAgEAAxkBAAPOaRJEzrIjOo4TqfmH4PEDIHc8A-IAAqQFAALHWpBEXC7cJ5ebkt02BA	6365727491	206	26	538913	2025-11-10 20:02:25.776+00	2025-11-10 20:02:27.963+00	COMPLETADO	\N
50	2025-11-10 20:02:46.132+00	Teo, se comunicaron una voluntaria que se había contactado con Hecho y que no le han contestado. Tengo que arreglar eso y contactarme con ellos a ver si recibieron el contacto.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_50_1762804966134.ogg	audios/2025/11/audio_50_1762804966134.ogg	AwACAgEAAxkBAAPRaRJE49XyrP9WT4XRN4of-qkx5aAAAqUFAALHWpBErfKWczQWG5A2BA	6365727491	209	13	275233	2025-11-10 20:02:46.132+00	2025-11-10 20:02:48.243+00	COMPLETADO	\N
51	2025-11-10 20:03:31.905+00	Teo, hoy de noche tengo murga también. De ocho y media a nueve a once.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_51_1762805011906.ogg	audios/2025/11/audio_51_1762805011906.ogg	AwACAgEAAxkBAAPUaRJFEfnaqVt8OVo57ocbQx-zkU0AAqYFAALHWpBE7sFrDESUYc82BA	6365727491	212	9	206017	2025-11-10 20:03:31.905+00	2025-11-10 20:03:34.065+00	COMPLETADO	\N
52	2025-11-10 20:29:15.088+00	y de álvaro de verde urbano está fascinado por el trabajo que hice que en verdad me llevó tiempo sí que de hecho le dediqué mucho tiempo pero al mismo tiempo me dejó muy contento de que él estimara también el trabajo como así que bueno nada como quiero destacar también esa cualidad que tengo de poder presentar proyectos fuertes buenos por lo menos ahora	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_52_1762806555092.ogg	audios/2025/11/audio_52_1762806555092.ogg	AwACAgEAAxkBAAPXaRJLF72ScfNlNEyBmGB-vFGk2iIAAqkFAALHWpBEvG9snbV9SkY2BA	6365727491	215	48	995409	2025-11-10 20:29:15.088+00	2025-11-10 20:29:18.094+00	COMPLETADO	\N
53	2025-11-11 18:31:26.449+00	Juan, fui al comunal a hablar con el arquitecto que no estaba, me dijeron que me iban a llamar cuando llegó cuando llegó volví a ir para allá y cuando se iba ya no estaba, estaba hablando con el alcalde y ahora hablé con la directora, llamé de vuelta a la directora, la directora me dice que cuando la llamé de vuelta que estaba en una reunión con el alcalde con Álvaro, el otro arquitecto, pero bueno seguimos en la búsqueda de contactar para, en la búsqueda de poder generar como, no, tener el pliego de eso, de lo que le pidieron a la empresa	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_53_1762885886487.ogg	audios/2025/11/audio_53_1762885886487.ogg	AwACAgEAAxkBAAPbaROA-dFe85qVfMsXM7xQpGSWn84AAq0FAALHWphEq5MUPXqclVc2BA	6365727491	219	59	1222009	2025-11-11 18:31:26.449+00	2025-11-11 18:31:30.596+00	COMPLETADO	\N
54	2025-11-15 20:00:39.963+00	Bueno, solo para contar que el jueves estuve contactando con el municipio todo el tiempo para ver que me pase el proyecto bueno, el miércoles que fue 12 estuve de noche también armando la carta para hablar sobre y exponer en redes la parte de que no se están tomando en cuenta y que se está metiendo a la placita del barrio	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_54_1763236839984.ogg	audios/2025/11/audio_54_1763236839984.ogg	AwACAgEAAxkBAAPiaRjb5L84btmjr3YXoCwbaINLG10AAq8GAAIGYclE5euymxpXKzo2BA	6365727491	226	40	842969	2025-11-15 20:00:39.963+00	2025-11-15 20:00:43.563+00	COMPLETADO	\N
55	2025-11-15 20:01:01.551+00	Después, el viernes, estuve ayudando en la parte del viaje por la 190, y estuve todo el día ahí, con poca gente.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_55_1763236861552.ogg	audios/2025/11/audio_55_1763236861552.ogg	AwACAgEAAxkBAAPlaRjb-uA7Dss-A7yOlsoD6pIUIbkAArAGAAIGYclE1go81qQ-43g2BA	6365727491	229	21	433441	2025-11-15 20:01:01.551+00	2025-11-15 20:01:04.303+00	COMPLETADO	\N
64	2025-11-17 22:55:45.906+00	Juan, hoy fui con Facu al paseo de punta a espinillo durante toda la mañana de 8 a 1.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_64_1763420145908.ogg	audios/2025/11/audio_64_1763420145908.ogg	AwACAgEAAxkBAAIBAmkbp-8NeQh4PLTSy1FduJaG0scAAysHAAKYwNhEMex-pr_80Jc2BA	6365727491	258	14	299129	2025-11-17 22:55:45.906+00	2025-11-17 22:55:47.321+00	COMPLETADO	\N
56	2025-11-15 20:01:33.505+00	Juan, el viernes estuve en consulta con Sara y ahí le estuve comentando también sobre el tema de la frustración y cómo me impacta.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_56_1763236893506.ogg	audios/2025/11/audio_56_1763236893506.ogg	AwACAgEAAxkBAAPoaRjcGi0kyL7YSY33-zm23l33qTQAArEGAAIGYclEII1Mkt5L4Mg2BA	6365727491	232	22	472993	2025-11-15 20:01:33.505+00	2025-11-15 20:01:35.283+00	COMPLETADO	\N
57	2025-11-15 20:01:57.905+00	Juan, el viernes también estuve haciendo. Llevé a los niños al fútbol. Primero a lo de Mario, después al Palá y estuve jugando un poco al básquetbol en la cancha nueva.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_57_1763236917906.ogg	audios/2025/11/audio_57_1763236917906.ogg	AwACAgEAAxkBAAPraRjcMiMpApOfHcg0bhx8Q28D0v0AArIGAAIGYclEXcnu3ZqRbhw2BA	6365727491	235	19	410369	2025-11-15 20:01:57.905+00	2025-11-15 20:02:00.727+00	COMPLETADO	\N
65	2025-11-17 22:56:06.611+00	Juan, después volví con Facu también y traté de trabajar haciendo, revisando la parte de la automatización del día de este chatbot	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_65_1763420166612.ogg	audios/2025/11/audio_65_1763420166612.ogg	AwACAgEAAxkBAAIBBWkbqAMTUmZXF_vqRojo67M-CZXZAAIsBwACmMDYRC9iKjKskxPONgQ	6365727491	261	19	392241	2025-11-17 22:56:06.611+00	2025-11-17 22:56:09.308+00	COMPLETADO	\N
58	2025-11-15 20:02:06.476+00	Juan, después no tuve murga, así que volví a casa y dormí hasta tarde.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_58_1763236926477.ogg	audios/2025/11/audio_58_1763236926477.ogg	AwACAgEAAxkBAAPuaRjcPJjquGYzf8hi2m9urDgYLRoAArMGAAIGYclEuX_bVIpeCGk2BA	6365727491	238	7	149985	2025-11-15 20:02:06.476+00	2025-11-15 20:02:08.611+00	COMPLETADO	\N
59	2025-11-15 20:02:28.491+00	Juan, hoy fui a comprar el tarmo que me quedaba por comprar con el mate y estuve durmiendo, me dormí hasta muy tarde también.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_59_1763236948492.ogg	audios/2025/11/audio_59_1763236948492.ogg	AwACAgEAAxkBAAPxaRjcUTXJZGpbaGP_CW6RHT_EBnIAArQGAAIGYclEqKj84pg4lXc2BA	6365727491	241	13	282649	2025-11-15 20:02:28.491+00	2025-11-15 20:02:30.229+00	COMPLETADO	\N
66	2025-11-17 22:56:34.762+00	Juan, mientras tanto también estaba viendo el diseño de la revista de Involucrarse Transforma.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_66_1763420194764.ogg	audios/2025/11/audio_66_1763420194764.ogg	AwACAgEAAxkBAAIBCGkbqCC9IJQ4QCnm29Fi0BjnPH1wAAItBwACmMDYROCxUPLTyAhKNgQ	6365727491	264	13	286769	2025-11-17 22:56:34.762+00	2025-11-17 22:56:36.557+00	COMPLETADO	\N
60	2025-11-15 20:02:44.166+00	Juan, lave un poco los platos, cocine el almuerzo para Gaby y para mi y me baño.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_60_1763236964167.ogg	audios/2025/11/audio_60_1763236964167.ogg	AwACAgEAAxkBAAP0aRjcYZlRlNsuaeFPbcKofu3KeOQAArUGAAIGYclEwNkY8mboLZ02BA	6365727491	244	13	272761	2025-11-15 20:02:44.166+00	2025-11-15 20:02:45.529+00	COMPLETADO	\N
61	2025-11-15 20:03:00.654+00	Juan, ahora fuimos, venimos a buscar a los pequeños a la casa de mi madre para ir al cumpleaños de Ximena	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_61_1763236980657.ogg	audios/2025/11/audio_61_1763236980657.ogg	AwACAgEAAxkBAAP3aRjccRXTQjIP3m0lodNpTelsfaAAArYGAAIGYclEu_EXXdMVQRg2BA	6365727491	247	12	266993	2025-11-15 20:03:00.654+00	2025-11-15 20:03:02.648+00	COMPLETADO	\N
67	2025-11-17 22:56:57.945+00	Juan, después fui a buscar a Feli a la escuela.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_67_1763420217946.ogg	audios/2025/11/audio_67_1763420217946.ogg	AwACAgEAAxkBAAIBC2kbqDfwwglaCCEb6E-mLqA0UzAUAAIuBwACmMDYRMuEf_3ztZTINgQ	6365727491	267	11	240625	2025-11-17 22:56:57.945+00	2025-11-17 22:57:00.478+00	COMPLETADO	\N
62	2025-11-17 17:02:11.121+00	Juan, hoy de mañana revisé mis objetivos generales y ahora después te los voy a pasar.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_62_1763398931128.ogg	audios/2025/11/audio_62_1763398931128.ogg	AwACAgEAAxkBAAP8aRtUKGCDILloRW9x_vORWl-6O7oAAh8HAAIfothErtw8vlkbpf02BA	6365727491	252	11	244745	2025-11-17 17:02:11.121+00	2025-11-17 17:02:13.182+00	COMPLETADO	\N
68	2025-11-17 22:57:10.698+00	Juan, después fui a Valdivia a comprar TNT para la escuela.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_68_1763420230700.ogg	audios/2025/11/audio_68_1763420230700.ogg	AwACAgEAAxkBAAIBDmkbqERbG2Ql7uQ_2v9zqBlKHNOdAAIvBwACmMDYRIyY3PpFud-fNgQ	6365727491	270	10	208489	2025-11-17 22:57:10.698+00	2025-11-17 22:57:12.678+00	COMPLETADO	\N
69	2025-11-17 22:57:36.288+00	Juan, de tarde, antes de ir a buscar a Feli, hice un escrito para enviar a los padres desde la Comisión Fomento como fin de año.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_69_1763420256289.ogg	audios/2025/11/audio_69_1763420256289.ogg	AwACAgEAAxkBAAIBEWkbqF1zdYeg4sEJPzB6crSc-H3SAAIwBwACmMDYRKckBHwB3HOlNgQ	6365727491	273	23	475465	2025-11-17 22:57:36.288+00	2025-11-17 22:57:38.646+00	COMPLETADO	\N
70	2025-11-17 22:57:52.011+00	Juan, fui a la ortodoncista a ver cómo le estaba yendo a Feli y a cambiar mi ortodoncia.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_70_1763420272013.ogg	audios/2025/11/audio_70_1763420272013.ogg	AwACAgEAAxkBAAIBFGkbqG3eBrft9kKErwTI18Nig7gaAAIxBwACmMDYRISmPbx2p5spNgQ	6365727491	276	13	288417	2025-11-17 22:57:52.011+00	2025-11-17 22:57:54.488+00	COMPLETADO	\N
71	2025-11-17 22:58:14.276+00	Juan, en el medio me sumé a la reunión de fe y alegría con el chatbot y pedí para poder generar un nuevo prompt.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_71_1763420294277.ogg	audios/2025/11/audio_71_1763420294277.ogg	AwACAgEAAxkBAAIBF2kbqIOYxUpJsNOIGaRzA8i9iMzoAAIyBwACmMDYRHffb3XBBSQWNgQ	6365727491	279	19	408721	2025-11-17 22:58:14.276+00	2025-11-17 22:58:15.854+00	COMPLETADO	\N
72	2025-11-17 22:58:42.935+00	Juan, cuando venía para acá también pasé a buscar medicamentos y a comprar una garrafa.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_72_1763420322937.ogg	audios/2025/11/audio_72_1763420322937.ogg	AwACAgEAAxkBAAIBGmkbqKCwauEW5KNQFQiDWfjymTYfAAIzBwACmMDYRDD99rlQKsi_NgQ	6365727491	282	10	207665	2025-11-17 22:58:42.935+00	2025-11-17 22:58:44.783+00	COMPLETADO	\N
73	2025-11-17 22:59:01.76+00	Juan, mientras tanto también escribí un escrito para Whatsapp para la rifa de mañana de la escuela.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_73_1763420341765.ogg	audios/2025/11/audio_73_1763420341765.ogg	AwACAgEAAxkBAAIBHWkbqLNzsMc-SX3mvCTw9EfSa-0vAAI0BwACmMDYRLkhxm9gVAwdNgQ	6365727491	285	16	344449	2025-11-17 22:59:01.76+00	2025-11-17 22:59:03.366+00	COMPLETADO	\N
74	2025-11-17 22:59:25.809+00	Juan le contesté a Valentina para poder tener una reunión el miércoles a las de tarde.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_74_1763420365809.ogg	audios/2025/11/audio_74_1763420365809.ogg	AwACAgEAAxkBAAIBIGkbqMvO4e5EzIi9hHCqDTWqCHRrAAI1BwACmMDYREARc3I1fmz6NgQ	6365727491	288	16	341153	2025-11-17 22:59:25.809+00	2025-11-17 22:59:31.558+00	COMPLETADO	\N
75	2025-11-17 22:59:46.156+00	Juan, estuve revisando la información del presupuesto participativo y aportando y hice un deep research para ver si realmente nos pueden o nos tienen que entregar los pliegos.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_75_1763420386157.ogg	audios/2025/11/audio_75_1763420386157.ogg	AwACAgEAAxkBAAIBI2kbqN97q43gW0aEU5mKAxVr-GiLAAI2BwACmMDYRLd3KyBSkvuXNgQ	6365727491	291	18	384001	2025-11-17 22:59:46.156+00	2025-11-17 22:59:47.967+00	COMPLETADO	\N
76	2025-11-21 20:38:00.196+00	Bueno, hoy estuve mirando el supercampeonato de la revista y ya abrí a mí toda la parte de... de... de la historia y de por del final de la revista y así que yo al final no la voy a contar ahora porque voy a tener que accountar desde el principio	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_76_1763757480231.ogg	audios/2025/11/audio_76_1763757480231.ogg	AwACAgEAAxkBAAIBKmkgzaSilTnnFyWrmfjVhhL3-4G6AALQEQACdBEBRTiRGddH-KpKNgQ	6365727491	298	30	632849	2025-11-21 20:38:00.196+00	2025-11-21 20:38:05.491+00	COMPLETADO	\N
77	2025-11-21 20:38:15.87+00	¡SUSCRÍBETE!	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_77_1763757495871.ogg	audios/2025/11/audio_77_1763757495871.ogg	AwACAgEAAxkBAAIBLWkgzbXZJEmVE6AAAX9jmfgN3VQzWQAC0REAAnQRAUVA06uZRC18pjYE	6365727491	301	8	179649	2025-11-21 20:38:15.87+00	2025-11-21 20:38:17.3+00	COMPLETADO	\N
78	2025-11-21 20:38:27.658+00	Debo cambiar de ruido.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/11/audio_78_1763757507660.ogg	audios/2025/11/audio_78_1763757507660.ogg	AwACAgEAAxkBAAIBMGkgzcFIwFfgFShbSe5Jw_cJ1NsKAALSEQACdBEBRQagjig0_xWHNgQ	6365727491	304	9	194481	2025-11-21 20:38:27.658+00	2025-11-21 20:38:32.762+00	COMPLETADO	\N
79	2025-12-01 18:57:26.992+00	Idea, una de las cosas que podemos hacer también es poner una tabla de comunicación o de contenido para los proyectos, qué es lo que se puede decir y qué no, y qué es lo que, por dónde puede ir la información.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_79_1764615447032.ogg	audios/2025/12/audio_79_1764615447032.ogg	AwACAgEAAxkBAAIBPWkt5RMd7mSMlHJicxB7spFOFeNFAAIKBwAC9nlxRVAn2wpmKd-qNgQ	6365727491	317	24	496889	2025-12-01 18:57:26.992+00	2025-12-01 18:57:30.474+00	COMPLETADO	\N
80	2025-12-02 18:12:58.033+00	Juan, hoy fui a sacar fotos a los de la escuela y a los del jardín y llegué como a las diez y media, perdón, llegué como a las diez y media a casa.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_80_1764699178049.ogg	audios/2025/12/audio_80_1764699178049.ogg	AwACAgEAAxkBAAIBQWkvLCaK3SAwD60FtVkzgOQoXydmAAKwCAAC9nl5Rc8DvP742YwiNgQ	6365727491	321	17	357633	2025-12-02 18:12:58.033+00	2025-12-02 18:13:01.273+00	COMPLETADO	\N
81	2025-12-02 18:13:28.084+00	Juan, después me entretuve con las redes sociales, creo que recién a las 2 y media, recién pude encarar algo, perdón, o antes, como a las 2 y media.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_81_1764699208086.ogg	audios/2025/12/audio_81_1764699208086.ogg	AwACAgEAAxkBAAIBRGkvLEQpxPhcjrvX-npXicPsvspyAAKxCAAC9nl5RW0Wndy8U-JkNgQ	6365727491	324	24	501009	2025-12-02 18:13:28.084+00	2025-12-02 18:13:29.928+00	COMPLETADO	\N
82	2025-12-02 18:13:56.975+00	Juan, estuve también revisando el tema de los test que hacen de EQ, los de Mensa y viendo a ver qué tal era el EQ y qué tan complejo eran los test.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_82_1764699236977.ogg	audios/2025/12/audio_82_1764699236977.ogg	AwACAgEAAxkBAAIBR2kvLGGqmAEhIJUmtb40wOz96-VXAAKyCAAC9nl5RUxxPGX9p7qANgQ	6365727491	327	26	539737	2025-12-02 18:13:56.975+00	2025-12-02 18:13:58.875+00	COMPLETADO	\N
83	2025-12-02 18:14:38.637+00	Juan, hice un test de Dinamarca creo que era, de Mensa, porque no había más cupos en el test de este año y encontré que estoy por encima, así con 133%, 133% de IQ, perdón IQ, de IQ.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2025/12/audio_83_1764699278640.ogg	audios/2025/12/audio_83_1764699278640.ogg	AwACAgEAAxkBAAIBSmkvLIsDrSnkYa1PGotZ5tJdz_FeAAKzCAAC9nl5RTtfAifcqM2DNgQ	6365727491	330	38	786113	2025-12-02 18:14:38.637+00	2025-12-02 18:14:42.272+00	COMPLETADO	\N
84	2026-01-04 22:34:58.202+00	Idea? Tengo que hacer como un template de todos los proyectos clásicos, como un día para involucrarte, unidos para bregar, solo involucrate, mimochi, etc. Y eso dejarlo en los templates o en los prompts o en un lugar quizás que sea tipo de proyectos, donde cada vez que vayas a hacer un proyecto de esos, se lea dentro del contexto y ese contexto sea clásico.	https://377a56fa92f7e25c9951c8c32a720022.r2.cloudflarestorage.com/asistente-personal-prod/audios/2026/01/audio_84_1767566098233.ogg	audios/2026/01/audio_84_1767566098233.ogg	AwACAgEAAxkBAAIBc2la6w7_kf5ZEkfW8V4kv5ECziA4AAKZCAACULzYRnTnR9cQOeluOAQ	6365727491	371	46	962449	2026-01-04 22:34:58.202+00	2026-01-04 22:35:02.834+00	COMPLETADO	\N
\.


--
-- Name: areas_vida_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.areas_vida_id_seq', 20, true);


--
-- Name: bloques_tiempo_planificados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.bloques_tiempo_planificados_id_seq', 1, false);


--
-- Name: compromisos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.compromisos_id_seq', 3, true);


--
-- Name: destrezas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.destrezas_id_seq', 69, true);


--
-- Name: dificultades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.dificultades_id_seq', 9, true);


--
-- Name: disponibilidad_semanal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.disponibilidad_semanal_id_seq', 7, true);


--
-- Name: ideas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.ideas_id_seq', 3, true);


--
-- Name: instancias_tareas_recurrentes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.instancias_tareas_recurrentes_id_seq', 1, false);


--
-- Name: logs_generacion_ia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.logs_generacion_ia_id_seq', 1, true);


--
-- Name: misiones_vida_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.misiones_vida_id_seq', 6, true);


--
-- Name: motivos_personales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.motivos_personales_id_seq', 12, true);


--
-- Name: notas_audio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.notas_audio_id_seq', 138, true);


--
-- Name: proyectos_estrategicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.proyectos_estrategicos_id_seq', 10, true);


--
-- Name: registros_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.registros_id_seq', 42, true);


--
-- Name: subtareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.subtareas_id_seq', 218, true);


--
-- Name: tareas_estrategicas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.tareas_estrategicas_id_seq', 56, true);


--
-- Name: tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.tareas_id_seq', 17, true);


--
-- Name: tareas_recurrentes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.tareas_recurrentes_id_seq', 1, false);


--
-- Name: transcripciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.transcripciones_id_seq', 84, true);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: areas_vida areas_vida_nombre_key; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.areas_vida
    ADD CONSTRAINT areas_vida_nombre_key UNIQUE (nombre);


--
-- Name: areas_vida areas_vida_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.areas_vida
    ADD CONSTRAINT areas_vida_pkey PRIMARY KEY (id);


--
-- Name: bloques_tiempo_planificados bloques_tiempo_planificados_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.bloques_tiempo_planificados
    ADD CONSTRAINT bloques_tiempo_planificados_pkey PRIMARY KEY (id);


--
-- Name: compromisos compromisos_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.compromisos
    ADD CONSTRAINT compromisos_pkey PRIMARY KEY (id);


--
-- Name: configuracion_personal configuracion_personal_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.configuracion_personal
    ADD CONSTRAINT configuracion_personal_pkey PRIMARY KEY (clave);


--
-- Name: destrezas destrezas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.destrezas
    ADD CONSTRAINT destrezas_nombre_key UNIQUE (nombre);


--
-- Name: destrezas destrezas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.destrezas
    ADD CONSTRAINT destrezas_pkey PRIMARY KEY (id);


--
-- Name: dificultades dificultades_nombre_key; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.dificultades
    ADD CONSTRAINT dificultades_nombre_key UNIQUE (nombre);


--
-- Name: dificultades dificultades_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.dificultades
    ADD CONSTRAINT dificultades_pkey PRIMARY KEY (id);


--
-- Name: disponibilidad_semanal disponibilidad_semanal_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.disponibilidad_semanal
    ADD CONSTRAINT disponibilidad_semanal_pkey PRIMARY KEY (id);


--
-- Name: ideas_capturadas ideas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas_capturadas
    ADD CONSTRAINT ideas_pkey PRIMARY KEY (id);


--
-- Name: instancias_tareas_recurrentes instancias_tareas_recurrentes_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.instancias_tareas_recurrentes
    ADD CONSTRAINT instancias_tareas_recurrentes_pkey PRIMARY KEY (id);


--
-- Name: logs_generacion_ia logs_generacion_ia_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.logs_generacion_ia
    ADD CONSTRAINT logs_generacion_ia_pkey PRIMARY KEY (id);


--
-- Name: misiones_vida misiones_vida_nombre_key; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.misiones_vida
    ADD CONSTRAINT misiones_vida_nombre_key UNIQUE (nombre);


--
-- Name: misiones_vida misiones_vida_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.misiones_vida
    ADD CONSTRAINT misiones_vida_pkey PRIMARY KEY (id);


--
-- Name: motivos_personales motivos_personales_nombre_key; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.motivos_personales
    ADD CONSTRAINT motivos_personales_nombre_key UNIQUE (nombre);


--
-- Name: motivos_personales motivos_personales_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.motivos_personales
    ADD CONSTRAINT motivos_personales_pkey PRIMARY KEY (id);


--
-- Name: notas_audio notas_audio_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.notas_audio
    ADD CONSTRAINT notas_audio_pkey PRIMARY KEY (id);


--
-- Name: proyectos_estrategicos proyectos_estrategicos_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.proyectos_estrategicos
    ADD CONSTRAINT proyectos_estrategicos_pkey PRIMARY KEY (id);


--
-- Name: registros registros_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.registros
    ADD CONSTRAINT registros_pkey PRIMARY KEY (id);


--
-- Name: subtareas_estrategicas subtareas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.subtareas_estrategicas
    ADD CONSTRAINT subtareas_pkey PRIMARY KEY (id);


--
-- Name: tareas_estrategicas tareas_estrategicas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_estrategicas
    ADD CONSTRAINT tareas_estrategicas_pkey PRIMARY KEY (id);


--
-- Name: tareas tareas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT tareas_pkey PRIMARY KEY (id);


--
-- Name: tareas_recurrentes tareas_recurrentes_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_pkey PRIMARY KEY (id);


--
-- Name: transcripciones transcripciones_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.transcripciones
    ADD CONSTRAINT transcripciones_pkey PRIMARY KEY (id);


--
-- Name: disponibilidad_semanal unique_dia_semana; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.disponibilidad_semanal
    ADD CONSTRAINT unique_dia_semana UNIQUE (dia_semana);


--
-- Name: instancias_tareas_recurrentes unique_instancia_por_fecha; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.instancias_tareas_recurrentes
    ADD CONSTRAINT unique_instancia_por_fecha UNIQUE (tarea_recurrente_id, fecha_programada);


--
-- Name: compromisos_cumplido_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX compromisos_cumplido_idx ON public.compromisos USING btree (cumplido);


--
-- Name: compromisos_fechaLimite_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "compromisos_fechaLimite_idx" ON public.compromisos USING btree ("fechaLimite");


--
-- Name: compromisos_notaAudioId_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "compromisos_notaAudioId_idx" ON public.compromisos USING btree ("notaAudioId");


--
-- Name: compromisos_personaNombre_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "compromisos_personaNombre_idx" ON public.compromisos USING btree ("personaNombre");


--
-- Name: ideas_capturadas_categoria_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX ideas_capturadas_categoria_idx ON public.ideas_capturadas USING btree (categoria);


--
-- Name: ideas_capturadas_implementada_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX ideas_capturadas_implementada_idx ON public.ideas_capturadas USING btree (implementada);


--
-- Name: ideas_categoria_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX ideas_categoria_idx ON public.ideas_capturadas USING btree (categoria);


--
-- Name: ideas_implementada_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX ideas_implementada_idx ON public.ideas_capturadas USING btree (implementada);


--
-- Name: ideas_notaAudioId_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "ideas_notaAudioId_idx" ON public.ideas_capturadas USING btree ("notaAudioId");


--
-- Name: idx_bloques_area; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_area ON public.bloques_tiempo_planificados USING btree (area_vida_id);


--
-- Name: idx_bloques_completado; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_completado ON public.bloques_tiempo_planificados USING btree (completado);


--
-- Name: idx_bloques_fecha; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_fecha ON public.bloques_tiempo_planificados USING btree (fecha);


--
-- Name: idx_bloques_fecha_tipo; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_fecha_tipo ON public.bloques_tiempo_planificados USING btree (fecha, tipo_bloque);


--
-- Name: idx_bloques_google_calendar; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_google_calendar ON public.bloques_tiempo_planificados USING btree (google_calendar_event_id);


--
-- Name: idx_bloques_proyecto; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_proyecto ON public.bloques_tiempo_planificados USING btree (proyecto_estrategico_id);


--
-- Name: idx_bloques_sincronizado; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_sincronizado ON public.bloques_tiempo_planificados USING btree (sincronizado_calendar);


--
-- Name: idx_bloques_tarea_estrategica; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_tarea_estrategica ON public.bloques_tiempo_planificados USING btree (tarea_estrategica_id);


--
-- Name: idx_bloques_tipo; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_bloques_tipo ON public.bloques_tiempo_planificados USING btree (tipo_bloque);


--
-- Name: idx_configuracion_categoria; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_configuracion_categoria ON public.configuracion_personal USING btree (categoria);


--
-- Name: idx_disponibilidad_dia; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_disponibilidad_dia ON public.disponibilidad_semanal USING btree (dia_semana);


--
-- Name: idx_instancias_completada; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_instancias_completada ON public.instancias_tareas_recurrentes USING btree (completada);


--
-- Name: idx_instancias_fecha_estado; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_instancias_fecha_estado ON public.instancias_tareas_recurrentes USING btree (fecha_programada, completada, saltada);


--
-- Name: idx_instancias_fecha_programada; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_instancias_fecha_programada ON public.instancias_tareas_recurrentes USING btree (fecha_programada);


--
-- Name: idx_instancias_google_calendar; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_instancias_google_calendar ON public.instancias_tareas_recurrentes USING btree (google_calendar_event_id);


--
-- Name: idx_instancias_saltada; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_instancias_saltada ON public.instancias_tareas_recurrentes USING btree (saltada);


--
-- Name: idx_instancias_tarea_recurrente; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_instancias_tarea_recurrente ON public.instancias_tareas_recurrentes USING btree (tarea_recurrente_id);


--
-- Name: idx_subtareas_estado_kanban; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_subtareas_estado_kanban ON public.subtareas_estrategicas USING btree (estado_kanban);


--
-- Name: idx_subtareas_proyecto_nombre; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_subtareas_proyecto_nombre ON public.subtareas_estrategicas USING btree (proyecto_nombre);


--
-- Name: idx_tareas_eisenhower; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_eisenhower ON public.tareas_estrategicas USING btree (eisenhower);


--
-- Name: idx_tareas_estado_kanban; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_estado_kanban ON public.tareas_estrategicas USING btree (estado_kanban);


--
-- Name: idx_tareas_estrategicas_bloqueada; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_estrategicas_bloqueada ON public.tareas_estrategicas USING btree (estado_kanban) WHERE (bloqueada_por IS NOT NULL);


--
-- Name: idx_tareas_estrategicas_contexto; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_estrategicas_contexto ON public.tareas_estrategicas USING btree (contexto_necesario);


--
-- Name: idx_tareas_estrategicas_energia; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_estrategicas_energia ON public.tareas_estrategicas USING btree (energia_requerida);


--
-- Name: idx_tareas_estrategicas_fecha_desbloqueo; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_estrategicas_fecha_desbloqueo ON public.tareas_estrategicas USING btree (fecha_estimada_desbloqueo) WHERE (fecha_estimada_desbloqueo IS NOT NULL);


--
-- Name: idx_tareas_recurrentes_activa; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_recurrentes_activa ON public.tareas_recurrentes USING btree (activa);


--
-- Name: idx_tareas_recurrentes_area; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_recurrentes_area ON public.tareas_recurrentes USING btree (area_id);


--
-- Name: idx_tareas_recurrentes_criticidad; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_recurrentes_criticidad ON public.tareas_recurrentes USING btree (criticidad);


--
-- Name: idx_tareas_recurrentes_patron; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_recurrentes_patron ON public.tareas_recurrentes USING gin (patron_recurrencia);


--
-- Name: idx_tareas_recurrentes_proyecto; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_recurrentes_proyecto ON public.tareas_recurrentes USING btree (proyecto_estrategico_id);


--
-- Name: idx_tareas_recurrentes_tipo; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_tareas_recurrentes_tipo ON public.tareas_recurrentes USING btree (tipo);


--
-- Name: idx_transcripciones_created_at; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_transcripciones_created_at ON public.transcripciones USING btree (created_at);


--
-- Name: idx_transcripciones_estado; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_transcripciones_estado ON public.transcripciones USING btree (estado);


--
-- Name: idx_transcripciones_telegram_user; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX idx_transcripciones_telegram_user ON public.transcripciones USING btree (telegram_user_id);


--
-- Name: notas_audio_fechaGrabacion_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "notas_audio_fechaGrabacion_idx" ON public.notas_audio USING btree ("fechaGrabacion");


--
-- Name: notas_audio_procesado_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX notas_audio_procesado_idx ON public.notas_audio USING btree (procesado);


--
-- Name: notas_audio_tipoDetectado_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "notas_audio_tipoDetectado_idx" ON public.notas_audio USING btree ("tipoDetectado");


--
-- Name: notas_audio_transcripcionId_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "notas_audio_transcripcionId_idx" ON public.notas_audio USING btree ("transcripcionId");


--
-- Name: notas_audio_transcripcionId_key; Type: INDEX; Schema: public; Owner: asistente
--

CREATE UNIQUE INDEX "notas_audio_transcripcionId_key" ON public.notas_audio USING btree ("transcripcionId");


--
-- Name: registros_categoria_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX registros_categoria_idx ON public.registros USING btree (categoria);


--
-- Name: registros_fechaActividad_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "registros_fechaActividad_idx" ON public.registros USING btree ("fechaActividad");


--
-- Name: registros_notaAudioId_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "registros_notaAudioId_idx" ON public.registros USING btree ("notaAudioId");


--
-- Name: registros_proyecto_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX registros_proyecto_idx ON public.registros USING btree (proyecto);


--
-- Name: tareas_completada_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX tareas_completada_idx ON public.tareas USING btree (completada);


--
-- Name: tareas_fechaVencimiento_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "tareas_fechaVencimiento_idx" ON public.tareas USING btree ("fechaVencimiento");


--
-- Name: tareas_notaAudioId_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "tareas_notaAudioId_idx" ON public.tareas USING btree ("notaAudioId");


--
-- Name: tareas_prioridad_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX tareas_prioridad_idx ON public.tareas USING btree (prioridad);


--
-- Name: tareas_estrategicas trigger_calcular_eisenhower; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER trigger_calcular_eisenhower BEFORE INSERT OR UPDATE OF moscow, urgencia, impacto, nivel_riesgo ON public.tareas_estrategicas FOR EACH ROW EXECUTE FUNCTION public.calcular_eisenhower();


--
-- Name: subtareas_estrategicas trigger_set_subtarea_proyecto_nombre; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER trigger_set_subtarea_proyecto_nombre BEFORE INSERT ON public.subtareas_estrategicas FOR EACH ROW EXECUTE FUNCTION public.set_subtarea_proyecto_nombre();


--
-- Name: proyectos_estrategicos trigger_update_subtareas_proyecto_nombre; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER trigger_update_subtareas_proyecto_nombre AFTER UPDATE OF nombre ON public.proyectos_estrategicos FOR EACH ROW WHEN (((old.nombre)::text IS DISTINCT FROM (new.nombre)::text)) EXECUTE FUNCTION public.update_subtareas_proyecto_nombre();


--
-- Name: bloques_tiempo_planificados update_bloques_tiempo_updated_at; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER update_bloques_tiempo_updated_at BEFORE UPDATE ON public.bloques_tiempo_planificados FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: configuracion_personal update_configuracion_personal_updated_at; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER update_configuracion_personal_updated_at BEFORE UPDATE ON public.configuracion_personal FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: disponibilidad_semanal update_disponibilidad_semanal_updated_at; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER update_disponibilidad_semanal_updated_at BEFORE UPDATE ON public.disponibilidad_semanal FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: instancias_tareas_recurrentes update_instancias_recurrentes_updated_at; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER update_instancias_recurrentes_updated_at BEFORE UPDATE ON public.instancias_tareas_recurrentes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: tareas_recurrentes update_tareas_recurrentes_updated_at; Type: TRIGGER; Schema: public; Owner: asistente
--

CREATE TRIGGER update_tareas_recurrentes_updated_at BEFORE UPDATE ON public.tareas_recurrentes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: bloques_tiempo_planificados bloques_tiempo_planificados_area_vida_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.bloques_tiempo_planificados
    ADD CONSTRAINT bloques_tiempo_planificados_area_vida_id_fkey FOREIGN KEY (area_vida_id) REFERENCES public.areas_vida(id) ON DELETE SET NULL;


--
-- Name: bloques_tiempo_planificados bloques_tiempo_planificados_proyecto_estrategico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.bloques_tiempo_planificados
    ADD CONSTRAINT bloques_tiempo_planificados_proyecto_estrategico_id_fkey FOREIGN KEY (proyecto_estrategico_id) REFERENCES public.proyectos_estrategicos(id) ON DELETE SET NULL;


--
-- Name: bloques_tiempo_planificados bloques_tiempo_planificados_tarea_estrategica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.bloques_tiempo_planificados
    ADD CONSTRAINT bloques_tiempo_planificados_tarea_estrategica_id_fkey FOREIGN KEY (tarea_estrategica_id) REFERENCES public.tareas_estrategicas(id) ON DELETE SET NULL;


--
-- Name: bloques_tiempo_planificados bloques_tiempo_planificados_tarea_recurrente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.bloques_tiempo_planificados
    ADD CONSTRAINT bloques_tiempo_planificados_tarea_recurrente_id_fkey FOREIGN KEY (tarea_recurrente_id) REFERENCES public.tareas_recurrentes(id) ON DELETE SET NULL;


--
-- Name: compromisos compromisos_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.compromisos
    ADD CONSTRAINT "compromisos_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ideas_capturadas ideas_capturadas_proyecto_estrategico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas_capturadas
    ADD CONSTRAINT ideas_capturadas_proyecto_estrategico_id_fkey FOREIGN KEY (proyecto_estrategico_id) REFERENCES public.proyectos_estrategicos(id) ON DELETE SET NULL;


--
-- Name: ideas_capturadas ideas_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas_capturadas
    ADD CONSTRAINT "ideas_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: instancias_tareas_recurrentes instancias_tareas_recurrentes_tarea_recurrente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.instancias_tareas_recurrentes
    ADD CONSTRAINT instancias_tareas_recurrentes_tarea_recurrente_id_fkey FOREIGN KEY (tarea_recurrente_id) REFERENCES public.tareas_recurrentes(id) ON DELETE CASCADE;


--
-- Name: logs_generacion_ia logs_generacion_ia_proyecto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.logs_generacion_ia
    ADD CONSTRAINT logs_generacion_ia_proyecto_id_fkey FOREIGN KEY (proyecto_id) REFERENCES public.proyectos_estrategicos(id) ON DELETE SET NULL;


--
-- Name: registros registros_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.registros
    ADD CONSTRAINT "registros_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subtareas_estrategicas subtareas_destreza_principal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.subtareas_estrategicas
    ADD CONSTRAINT subtareas_destreza_principal_id_fkey FOREIGN KEY (destreza_principal_id) REFERENCES public.destrezas(id) ON DELETE SET NULL;


--
-- Name: subtareas_estrategicas subtareas_tarea_estrategica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.subtareas_estrategicas
    ADD CONSTRAINT subtareas_tarea_estrategica_id_fkey FOREIGN KEY (tarea_estrategica_id) REFERENCES public.tareas_estrategicas(id) ON DELETE RESTRICT;


--
-- Name: tareas_estrategicas tareas_estrategicas_proyecto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_estrategicas
    ADD CONSTRAINT tareas_estrategicas_proyecto_id_fkey FOREIGN KEY (proyecto_id) REFERENCES public.proyectos_estrategicos(id) ON DELETE RESTRICT;


--
-- Name: tareas tareas_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT "tareas_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tareas tareas_proyecto_estrategico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT tareas_proyecto_estrategico_id_fkey FOREIGN KEY (proyecto_estrategico_id) REFERENCES public.proyectos_estrategicos(id) ON DELETE SET NULL;


--
-- Name: tareas_recurrentes tareas_recurrentes_area_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas_vida(id) ON DELETE SET NULL;


--
-- Name: tareas_recurrentes tareas_recurrentes_proyecto_estrategico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_proyecto_estrategico_id_fkey FOREIGN KEY (proyecto_estrategico_id) REFERENCES public.proyectos_estrategicos(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

