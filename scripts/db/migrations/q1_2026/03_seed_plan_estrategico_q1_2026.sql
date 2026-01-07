-- ============================================
-- Seed: Plan Estratégico Q1 2026
-- Descripción: Inserta los 15 proyectos
--              del plan estratégico Q1 2026
--              en proyectos_estrategicos.
-- Nota: Las tareas, subtareas e items
--       se pueden extender en seeds
--       posteriores siguiendo este patrón.
-- Date: 2026-01-06
-- ============================================

BEGIN;

-- ------------------------------------------------
-- 1. PROYECTOS ESTRATÉGICOS (15 proyectos)
-- ------------------------------------------------
-- Regla general usada:
-- - fecha_inicio:      2026-01-01
-- - fecha_fin_estimada:2026-03-31
-- - estado:            'planificacion'
-- - prioridad_global:  1.0 para proyectos críticos,
--                      0.8 para alta, 0.6 para media
-- - areas_ids:         [1] para proyectos centrados en "involucrate"
--                      [2] para proyectos centrados en "involucrarse"
--                      [] para proyectos transversales/operativos
-- ------------------------------------------------

-- P1: Motor Básico Involucrate (Capa 1)
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Motor Basico Involucrate (Capa 1)',
  'Motor básico para aumentar la conversión voluntario → experiencia en involucrate.',
  ARRAY[1],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  1.0,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
);

-- P2: Motor Básico Involucrarse (Capa 1)
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Motor Basico Involucrarse (Capa 1)',
  'Motor básico B2B para involucrarse: jornadas y experiencias corporativas.',
  ARRAY[2],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  1.0,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrarse (Capa 1)'
);

-- P3: Mimochi 2026
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Mimochi 2026',
  'Proyecto de producto/experiencia Mimochi para reforzar comunidad y marca.',
  ARRAY[1],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Mimochi 2026'
);

-- P4: Infraestructura Compartida
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Infraestructura Compartida',
  'Infraestructura tecnológica compartida entre involucrate, involucrarse y agentes IA.',
  ARRAY[]::INTEGER[],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Infraestructura Compartida'
);

-- A1: Agente Guardian de Organizaciones
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Guardian de Organizaciones',
  'Agente IA para cuidado y reactivación de organizaciones en involucrate.',
  ARRAY[1],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Guardian de Organizaciones'
);

-- A2: Agente Asistente de Onboarding
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Asistente de Onboarding',
  'Agente IA que asiste el onboarding y verificación de organizaciones.',
  ARRAY[1],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Asistente de Onboarding'
);

-- A3: Agente Community Manager IA
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Community Manager IA',
  'Agente IA para generación y programación de contenido en redes.',
  ARRAY[]::INTEGER[],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Community Manager IA'
);

-- A4: Agente Matchmaker y Seguimiento
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Matchmaker y Seguimiento',
  'Agente IA que conecta voluntarios con organizaciones y hace seguimiento.',
  ARRAY[1],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Matchmaker y Seguimiento'
);

-- A5: Agente Chatbot de Soporte
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Chatbot de Soporte',
  'Agente IA para responder dudas frecuentes de voluntarios y organizaciones.',
  ARRAY[]::INTEGER[],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.6,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Chatbot de Soporte'
);

-- A6: Agente Asistente de Contenido B2B
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Asistente de Contenido B2B',
  'Agente IA para generación de contenido y materiales comerciales B2B.',
  ARRAY[2],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.6,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Asistente de Contenido B2B'
);

-- A7: Agente Prospector Automático
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Prospector Automatico',
  'Agente IA para prospección y armado de pipeline de empresas B2B.',
  ARRAY[2],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Prospector Automatico'
);

-- A8: Agente Generador de Propuestas
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Generador de Propuestas',
  'Agente IA para generar propuestas personalizadas para empresas.',
  ARRAY[2],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.6,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Generador de Propuestas'
);

-- A9: Agente Community Manager LinkedIn
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Agente Community Manager LinkedIn',
  'Agente IA para posicionamiento y contenido en LinkedIn (B2B).',
  ARRAY[2],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.6,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Agente Community Manager LinkedIn'
);

-- O1: Administración Urgente
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Administracion Urgente',
  'Proyecto operativo para resolver temas administrativos urgentes de Involucra.',
  ARRAY[]::INTEGER[],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  1.0,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Administracion Urgente'
);

-- O2: Contenido y Comunicación
INSERT INTO proyectos_estrategicos (
  nombre,
  descripcion,
  areas_ids,
  motivos_ids,
  destrezas_requeridas_ids,
  dificultades_ids,
  misiones_ids,
  justificacion_estrategica,
  objetivos_smart,
  fecha_inicio,
  fecha_fin_estimada,
  estado,
  prioridad_global,
  score_motivacional,
  score_alineacion
)
SELECT
  'Contenido y Comunicacion',
  'Proyecto operativo para coordinar contenido, newsletters y comunicación externa.',
  ARRAY[]::INTEGER[],
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  DATE '2026-01-01',
  DATE '2026-03-31',
  'planificacion',
  0.8,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM proyectos_estrategicos
  WHERE nombre = 'Contenido y Comunicacion'
);

-- ------------------------------------------------
-- 2. TAREAS ESTRATÉGICAS (Proyecto 1 - ejemplo completo)
-- ------------------------------------------------

WITH p1 AS (
  SELECT id
  FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
)
INSERT INTO tareas_estrategicas (
  proyecto_id,
  nombre,
  descripcion,
  orden,
  moscow,
  tiempo_estimado_horas,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  p1.id,
  'ENGRANAJE 1 - OFERTA (Organizaciones)',
  'Organizaciones activas publicando oportunidades reales',
  1,
  'must',
  45,
  DATE '2026-01-01',
  DATE '2026-03-31',
  DATE '2026-03-31'
FROM p1
WHERE NOT EXISTS (
  SELECT 1 FROM tareas_estrategicas t
  WHERE t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND t.proyecto_id = p1.id
);

WITH p1 AS (
  SELECT id
  FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
)
INSERT INTO tareas_estrategicas (
  proyecto_id,
  nombre,
  descripcion,
  orden,
  moscow,
  tiempo_estimado_horas,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  p1.id,
  'ENGRANAJE 2 - DEMANDA (Voluntarios)',
  'Captar voluntarios y completar proceso de registro',
  2,
  'must',
  48,
  DATE '2026-01-01',
  DATE '2026-03-31',
  DATE '2026-03-31'
FROM p1
WHERE NOT EXISTS (
  SELECT 1 FROM tareas_estrategicas t
  WHERE t.nombre = 'ENGRANAJE 2 - DEMANDA (Voluntarios)'
    AND t.proyecto_id = p1.id
);

WITH p1 AS (
  SELECT id
  FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
)
INSERT INTO tareas_estrategicas (
  proyecto_id,
  nombre,
  descripcion,
  orden,
  moscow,
  tiempo_estimado_horas,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  p1.id,
  'ENGRANAJE 3 - MATCH (Conexion)',
  'Conectar efectivamente voluntarios y organizaciones',
  3,
  'must',
  24,
  DATE '2026-01-01',
  DATE '2026-03-31',
  DATE '2026-03-31'
FROM p1
WHERE NOT EXISTS (
  SELECT 1 FROM tareas_estrategicas t
  WHERE t.nombre = 'ENGRANAJE 3 - MATCH (Conexion)'
    AND t.proyecto_id = p1.id
);

WITH p1 AS (
  SELECT id
  FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
)
INSERT INTO tareas_estrategicas (
  proyecto_id,
  nombre,
  descripcion,
  orden,
  moscow,
  tiempo_estimado_horas,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  p1.id,
  'ENGRANAJE 4 - EXPERIENCIA Y CICLO',
  'Diseñar experiencia satisfactoria que genere recurrencia',
  4,
  'must',
  22,
  DATE '2026-01-01',
  DATE '2026-03-31',
  DATE '2026-03-31'
FROM p1
WHERE NOT EXISTS (
  SELECT 1 FROM tareas_estrategicas t
  WHERE t.nombre = 'ENGRANAJE 4 - EXPERIENCIA Y CICLO'
    AND t.proyecto_id = p1.id
);

WITH p1 AS (
  SELECT id
  FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
)
INSERT INTO tareas_estrategicas (
  proyecto_id,
  nombre,
  descripcion,
  orden,
  moscow,
  tiempo_estimado_horas,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  p1.id,
  'ENGRANAJE 5 - MEDICION Y ANALISIS',
  'Dashboard y analisis trimestral de resultados',
  5,
  'must',
  13,
  DATE '2026-01-01',
  DATE '2026-03-31',
  DATE '2026-03-31'
FROM p1
WHERE NOT EXISTS (
  SELECT 1 FROM tareas_estrategicas t
  WHERE t.nombre = 'ENGRANAJE 5 - MEDICION Y ANALISIS'
    AND t.proyecto_id = p1.id
);

WITH p1 AS (
  SELECT id
  FROM proyectos_estrategicos
  WHERE nombre = 'Motor Basico Involucrate (Capa 1)'
)
INSERT INTO tareas_estrategicas (
  proyecto_id,
  nombre,
  descripcion,
  orden,
  moscow,
  tiempo_estimado_horas,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  p1.id,
  'ENGRANAJE 6 - CONTENIDO Y POSICIONAMIENTO',
  'Presencia digital sostenida basada en aprendizajes',
  6,
  'must',
  18,
  DATE '2026-01-01',
  DATE '2026-03-31',
  DATE '2026-03-31'
FROM p1
WHERE NOT EXISTS (
  SELECT 1 FROM tareas_estrategicas t
  WHERE t.nombre = 'ENGRANAJE 6 - CONTENIDO Y POSICIONAMIENTO'
    AND t.proyecto_id = p1.id
);

-- ------------------------------------------------
-- 3. SUBTAREAS ESTRATÉGICAS (subset representativo Proyecto 1)
-- ------------------------------------------------

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Auditoria y limpieza de base de datos',
  360,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Auditoria y limpieza de base de datos'
    AND s.tarea_estrategica_id = t_oferta.id
);

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Mapeo de estacionalidad',
  180,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Mapeo de estacionalidad'
    AND s.tarea_estrategica_id = t_oferta.id
);

-- ------------------------------------------------
-- 4. ITEMS ESTRATÉGICOS (subset representativo)
-- ------------------------------------------------

WITH st_auditoria AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Auditoria y limpieza de base de datos'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_auditoria.id,
  'Exportar todas las organizaciones registradas',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_auditoria
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Exportar todas las organizaciones registradas'
    AND i.subtarea_estrategica_id = st_auditoria.id
);

WITH st_auditoria AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Auditoria y limpieza de base de datos'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_auditoria.id,
  'Clasificar en Activas / Inactivas / No contactables',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_auditoria
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Clasificar en Activas / Inactivas / No contactables'
    AND i.subtarea_estrategica_id = st_auditoria.id
);

WITH st_auditoria AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Auditoria y limpieza de base de datos'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_auditoria.id,
  'Validar info de contacto de organizaciones activas',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_auditoria
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Validar info de contacto de organizaciones activas'
    AND i.subtarea_estrategica_id = st_auditoria.id
);

WITH st_auditoria AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Auditoria y limpieza de base de datos'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_auditoria.id,
  'Crear lista de reactivacion febrero',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_auditoria
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Crear lista de reactivacion febrero'
    AND i.subtarea_estrategica_id = st_auditoria.id
);

WITH st_mapeo AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Mapeo de estacionalidad'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_mapeo.id,
  'Identificar organizaciones por tipo de ciclo',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_mapeo
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Identificar organizaciones por tipo de ciclo'
    AND i.subtarea_estrategica_id = st_mapeo.id
);

-- Subtareas adicionales ENGRANAJE 1 - OFERTA (Organizaciones)

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Sistema de verificacion de organizaciones',
  300,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Sistema de verificacion de organizaciones'
    AND s.tarea_estrategica_id = t_oferta.id
);

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Campana reactivacion organizaciones inactivas',
  480,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Campana reactivacion organizaciones inactivas'
    AND s.tarea_estrategica_id = t_oferta.id
);

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Programa Organizaciones Verificadas Plus',
  600,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Programa Organizaciones Verificadas Plus'
    AND s.tarea_estrategica_id = t_oferta.id
);

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Expansion programa verificadas (Marzo)',
  480,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Expansion programa verificadas (Marzo)'
    AND s.tarea_estrategica_id = t_oferta.id
);

WITH t_oferta AS (
  SELECT t.id
  FROM tareas_estrategicas t
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
)
INSERT INTO subtareas_estrategicas (
  tarea_estrategica_id,
  nombre,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  t_oferta.id,
  'Activacion organizaciones educativas',
  300,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM t_oferta
WHERE NOT EXISTS (
  SELECT 1 FROM subtareas_estrategicas s
  WHERE s.nombre = 'Activacion organizaciones educativas'
    AND s.tarea_estrategica_id = t_oferta.id
);

-- Items para ST1.1.3 Sistema de verificacion de organizaciones

WITH st_verificacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Sistema de verificacion de organizaciones'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_verificacion.id,
  'Disenar checklist de verificacion (web, redes, contacto, personeria)',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_verificacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Disenar checklist de verificacion (web, redes, contacto, personeria)'
    AND i.subtarea_estrategica_id = st_verificacion.id
);

WITH st_verificacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Sistema de verificacion de organizaciones'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_verificacion.id,
  'Crear proceso documentado de verificacion',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_verificacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Crear proceso documentado de verificacion'
    AND i.subtarea_estrategica_id = st_verificacion.id
);

WITH st_verificacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Sistema de verificacion de organizaciones'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_verificacion.id,
  'Verificar 10 organizaciones piloto',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_verificacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Verificar 10 organizaciones piloto'
    AND i.subtarea_estrategica_id = st_verificacion.id
);

WITH st_verificacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Sistema de verificacion de organizaciones'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_verificacion.id,
  'Crear badge Verificada',
  false,
  NULL,
  'must',
  DATE '2026-01-01',
  DATE '2026-01-14',
  DATE '2026-01-14'
FROM st_verificacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Crear badge Verificada'
    AND i.subtarea_estrategica_id = st_verificacion.id
);

-- Items para ST1.1.4 Campana reactivacion organizaciones inactivas

WITH st_reactivacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Campana reactivacion organizaciones inactivas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_reactivacion.id,
  'Seleccionar 20 organizaciones inactivas potenciales',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_reactivacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Seleccionar 20 organizaciones inactivas potenciales'
    AND i.subtarea_estrategica_id = st_reactivacion.id
);

WITH st_reactivacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Campana reactivacion organizaciones inactivas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_reactivacion.id,
  'Contacto personalizado (llamada/WhatsApp)',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_reactivacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Contacto personalizado (llamada/WhatsApp)'
    AND i.subtarea_estrategica_id = st_reactivacion.id
);

WITH st_reactivacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Campana reactivacion organizaciones inactivas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_reactivacion.id,
  'Oferta Te ayudamos a crear primera oportunidad del ano',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_reactivacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Oferta Te ayudamos a crear primera oportunidad del ano'
    AND i.subtarea_estrategica_id = st_reactivacion.id
);

WITH st_reactivacion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Campana reactivacion organizaciones inactivas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_reactivacion.id,
  'Meta reactivar 10 organizaciones',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_reactivacion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Meta reactivar 10 organizaciones'
    AND i.subtarea_estrategica_id = st_reactivacion.id
);

-- Items para ST1.1.5 Programa Organizaciones Verificadas Plus

WITH st_plus AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Programa Organizaciones Verificadas Plus'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_plus.id,
  'Seleccionar 15 organizaciones activas 2025',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_plus
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Seleccionar 15 organizaciones activas 2025'
    AND i.subtarea_estrategica_id = st_plus.id
);

WITH st_plus AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Programa Organizaciones Verificadas Plus'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_plus.id,
  'Oferta Verificacion + visibilidad + acompanamiento',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_plus
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Oferta Verificacion + visibilidad + acompanamiento'
    AND i.subtarea_estrategica_id = st_plus.id
);

WITH st_plus AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Programa Organizaciones Verificadas Plus'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_plus.id,
  'Definir compromiso respuesta < 48hs y 1+ oportunidad/mes',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_plus
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Definir compromiso respuesta < 48hs y 1+ oportunidad/mes'
    AND i.subtarea_estrategica_id = st_plus.id
);

WITH st_plus AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Programa Organizaciones Verificadas Plus'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_plus.id,
  'Realizar llamada onboarding con cada organizacion',
  false,
  NULL,
  'must',
  DATE '2026-02-01',
  DATE '2026-02-14',
  DATE '2026-02-14'
FROM st_plus
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Realizar llamada onboarding con cada organizacion'
    AND i.subtarea_estrategica_id = st_plus.id
);

-- Items para ST1.1.6 Expansion programa verificadas (Marzo)

WITH st_expansion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Expansion programa verificadas (Marzo)'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_expansion.id,
  'Invitar 20 organizaciones mas',
  false,
  NULL,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM st_expansion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Invitar 20 organizaciones mas'
    AND i.subtarea_estrategica_id = st_expansion.id
);

WITH st_expansion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Expansion programa verificadas (Marzo)'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_expansion.id,
  'Meta 30 organizaciones verificadas activas',
  false,
  NULL,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM st_expansion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Meta 30 organizaciones verificadas activas'
    AND i.subtarea_estrategica_id = st_expansion.id
);

WITH st_expansion AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Expansion programa verificadas (Marzo)'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_expansion.id,
  'Crear ranking Mejores experiencias basado en reviews',
  false,
  NULL,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM st_expansion
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Crear ranking Mejores experiencias basado en reviews'
    AND i.subtarea_estrategica_id = st_expansion.id
);

-- Items para ST1.1.7 Activacion organizaciones educativas

WITH st_educativas AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Activacion organizaciones educativas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_educativas.id,
  'Contactar organizaciones ciclo educativo',
  false,
  NULL,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM st_educativas
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Contactar organizaciones ciclo educativo'
    AND i.subtarea_estrategica_id = st_educativas.id
);

WITH st_educativas AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Activacion organizaciones educativas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_educativas.id,
  'Mensaje Marzo arranca, necesitas voluntarios?',
  false,
  NULL,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM st_educativas
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Mensaje Marzo arranca, necesitas voluntarios?'
    AND i.subtarea_estrategica_id = st_educativas.id
);

WITH st_educativas AS (
  SELECT s.id
  FROM subtareas_estrategicas s
  JOIN tareas_estrategicas t ON t.id = s.tarea_estrategica_id
  JOIN proyectos_estrategicos p ON p.id = t.proyecto_id
  WHERE p.nombre = 'Motor Basico Involucrate (Capa 1)'
    AND t.nombre = 'ENGRANAJE 1 - OFERTA (Organizaciones)'
    AND s.nombre = 'Activacion organizaciones educativas'
)
INSERT INTO items_estrategicos (
  subtarea_estrategica_id,
  nombre,
  done,
  tiempo_estimado_minutos,
  moscow,
  fecha_inicio,
  fecha_fin,
  dead_line
)
SELECT
  st_educativas.id,
  'Facilitar publicacion rapida de oportunidades educativas',
  false,
  NULL,
  'must',
  DATE '2026-03-01',
  DATE '2026-03-14',
  DATE '2026-03-14'
FROM st_educativas
WHERE NOT EXISTS (
  SELECT 1 FROM items_estrategicos i
  WHERE i.nombre = 'Facilitar publicacion rapida de oportunidades educativas'
    AND i.subtarea_estrategica_id = st_educativas.id
);

COMMIT;

-- Nota: Actualmente el seed incluye todos los proyectos
-- y la cadena completa proyecto → tareas
-- para el Proyecto 1, con todas las
-- subtareas e items del ENGRANAJE 1 (Oferta).
-- Para cubrir el 100% del documento, se puede
-- continuar extendiendo este patrón para el resto
-- de tareas, subtareas e items descritos en
-- PLAN_ESTRATEGICO_Q1_2026.md.
