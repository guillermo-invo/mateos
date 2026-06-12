-- ============================================================================
-- MIGRACIÓN: Sistema de Personas, Organizaciones y Sub-proyectos
-- Fecha: 2026-01-30
-- Descripción: Agrega tablas para gestión de contactos, organizaciones,
--              sub-proyectos y sus relaciones
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. TABLA: personas
-- ============================================================================
CREATE TABLE IF NOT EXISTS personas (
    id SERIAL PRIMARY KEY,
    nombre_completo VARCHAR(255) NOT NULL,
    apodo VARCHAR(100),
    trato VARCHAR(50), -- formal, coloquial, informal, jocoso
    email VARCHAR(255),
    telefono VARCHAR(50),
    whatsapp VARCHAR(50),
    instagram VARCHAR(100),
    x_twitter VARCHAR(100),
    tiktok VARCHAR(100),
    linkedin VARCHAR(500),
    youtube VARCHAR(500),
    tipo_relacion VARCHAR(50), -- voluntario, cliente, colaborador, donante, beneficiario, aliado, mentor, amigo
    es_contacto_estrella BOOLEAN DEFAULT FALSE,
    puntuacion_importancia INTEGER CHECK (puntuacion_importancia >= 1 AND puntuacion_importancia <= 10),
    fecha_ultimo_contacto DATE,
    frecuencia_contacto_ideal VARCHAR(50), -- diario, semanal, quincenal, mensual, trimestral, semestral, anual
    eneatipo VARCHAR(50), -- 1-perfeccionista, 2-ayudador, etc.
    intereses TEXT[], -- Array de intereses
    otra_informacion TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_personas_nombre ON personas(nombre_completo);
CREATE INDEX idx_personas_tipo_relacion ON personas(tipo_relacion);
CREATE INDEX idx_personas_es_estrella ON personas(es_contacto_estrella);
CREATE INDEX idx_personas_puntuacion ON personas(puntuacion_importancia);

COMMENT ON TABLE personas IS 'Contactos personales y profesionales';
COMMENT ON COLUMN personas.trato IS 'Estilo de comunicación: formal, coloquial, informal, jocoso';
COMMENT ON COLUMN personas.tipo_relacion IS 'voluntario, cliente, colaborador, donante, beneficiario, aliado, mentor, amigo';
COMMENT ON COLUMN personas.frecuencia_contacto_ideal IS 'diario, semanal, quincenal, mensual, trimestral, semestral, anual';
COMMENT ON COLUMN personas.eneatipo IS '1-perfeccionista, 2-ayudador, 3-triunfador, 4-individualista, 5-investigador, 6-leal, 7-entusiasta, 8-desafiador, 9-pacificador';

-- ============================================================================
-- 2. TABLA: organizaciones
-- ============================================================================
CREATE TABLE IF NOT EXISTS organizaciones (
    id SERIAL PRIMARY KEY,
    nombre_organizacion VARCHAR(255) NOT NULL,
    nombre_corto VARCHAR(100),
    siglas VARCHAR(20),
    tipo_organizacion VARCHAR(50), -- ong, fundacion, empresa_social, empresa_privada, gobierno, universidad, colectivo, cooperativa, asociacion_civil, startup, multinacional
    sector_actividad VARCHAR(100), -- educacion, salud, medio_ambiente, derechos_humanos, tecnologia, arte_cultura, desarrollo_comunitario
    mi_vinculo TEXT,
    email_principal VARCHAR(255),
    telefono_principal VARCHAR(50),
    sitio_web VARCHAR(500),
    direccion TEXT,
    ciudad VARCHAR(100),
    pais VARCHAR(100) DEFAULT 'Uruguay',
    instagram VARCHAR(100),
    x_twitter VARCHAR(100),
    tiktok VARCHAR(100),
    linkedin VARCHAR(500),
    youtube VARCHAR(500),
    facebook VARCHAR(500),
    naturaleza_relacion VARCHAR(50), -- aliado_estrategico, proveedor_servicios, cliente, financiador, beneficiario, socio, competidor_amigable
    es_organizacion_estrella BOOLEAN DEFAULT FALSE,
    puntuacion_importancia INTEGER CHECK (puntuacion_importancia >= 1 AND puntuacion_importancia <= 10),
    fecha_primer_contacto DATE,
    fecha_ultimo_contacto DATE,
    frecuencia_contacto_ideal VARCHAR(50), -- diario, semanal, quincenal, mensual, trimestral, semestral, anual
    mision_vision TEXT,
    areas_trabajo TEXT[], -- Array de áreas de trabajo
    rse TEXT, -- Qué tipo de RSE tiene, qué proyectos llevan adelante
    hace_voluntariado TEXT, -- Qué tipo de voluntariado hacen o hicieron
    tamanio_organizacion VARCHAR(50), -- micro 1-10, pequena 11-50, mediana 51-200, grande 201+
    notas_adicionales TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_organizaciones_nombre ON organizaciones(nombre_organizacion);
CREATE INDEX idx_organizaciones_tipo ON organizaciones(tipo_organizacion);
CREATE INDEX idx_organizaciones_sector ON organizaciones(sector_actividad);
CREATE INDEX idx_organizaciones_es_estrella ON organizaciones(es_organizacion_estrella);
CREATE INDEX idx_organizaciones_puntuacion ON organizaciones(puntuacion_importancia);

COMMENT ON TABLE organizaciones IS 'Organizaciones con las que se relaciona el usuario';
COMMENT ON COLUMN organizaciones.tipo_organizacion IS 'ong, fundacion, empresa_social, empresa_privada, gobierno, universidad, colectivo, cooperativa, asociacion_civil, startup, multinacional';
COMMENT ON COLUMN organizaciones.sector_actividad IS 'educacion, salud, medio_ambiente, derechos_humanos, tecnologia, arte_cultura, desarrollo_comunitario';
COMMENT ON COLUMN organizaciones.naturaleza_relacion IS 'aliado_estrategico, proveedor_servicios, cliente, financiador, beneficiario, socio, competidor_amigable';
COMMENT ON COLUMN organizaciones.tamanio_organizacion IS 'micro 1-10, pequena 11-50, mediana 51-200, grande 201+';

-- ============================================================================
-- 3. TABLA: personas_organizaciones (relación persona-organización)
-- ============================================================================
CREATE TABLE IF NOT EXISTS personas_organizaciones (
    id SERIAL PRIMARY KEY,
    persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    organizacion_id INTEGER NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    cargo_titulo VARCHAR(255),
    tipo_vinculacion VARCHAR(50), -- empleado, voluntario, consultor, directivo, socio, fundador, asesor, pasante
    fecha_inicio DATE,
    fecha_fin DATE,
    es_actual BOOLEAN DEFAULT TRUE,
    nivel_decision VARCHAR(50), -- estrategico, tactico, operativo, ninguno
    responsabilidades TEXT,
    logros_destacados TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(persona_id, organizacion_id, cargo_titulo)
);

CREATE INDEX idx_personas_org_persona ON personas_organizaciones(persona_id);
CREATE INDEX idx_personas_org_organizacion ON personas_organizaciones(organizacion_id);
CREATE INDEX idx_personas_org_es_actual ON personas_organizaciones(es_actual);

COMMENT ON TABLE personas_organizaciones IS 'Relación entre personas y organizaciones (cargos, vínculos)';
COMMENT ON COLUMN personas_organizaciones.tipo_vinculacion IS 'empleado, voluntario, consultor, directivo, socio, fundador, asesor, pasante';
COMMENT ON COLUMN personas_organizaciones.nivel_decision IS 'estrategico, tactico, operativo, ninguno';

-- ============================================================================
-- 4. TABLA: sub_proyectos
-- ============================================================================
CREATE TABLE IF NOT EXISTS sub_proyectos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    nombre_corto VARCHAR(100),
    codigo_proyecto VARCHAR(50) UNIQUE,
    area_vida_id INTEGER REFERENCES areas_vida(id) ON DELETE SET NULL,
    proyecto_estrategico_id INTEGER REFERENCES proyectos_estrategicos(id) ON DELETE SET NULL,
    descripcion TEXT,
    objetivo_general TEXT,
    objetivos_especificos TEXT[], -- Array de objetivos
    estado VARCHAR(50) DEFAULT 'idea', -- idea, planificacion, aprobado, activo, pausado, completado, cancelado, archivado
    fecha_inicio DATE,
    fecha_fin_estimada DATE,
    fecha_fin_real DATE,
    duracion_estimada_meses INTEGER,
    prioridad VARCHAR(50) DEFAULT 'media', -- baja, media, alta, critica, estrategica
    porcentaje_completado INTEGER DEFAULT 0 CHECK (porcentaje_completado >= 0 AND porcentaje_completado <= 100),
    organizacion_lider_id INTEGER REFERENCES organizaciones(id) ON DELETE SET NULL,
    persona_lider_id INTEGER REFERENCES personas(id) ON DELETE SET NULL,
    mi_responsabilidad VARCHAR(50), -- liderar, liderar_seccion, participacion_horizontal, apoyar, asesorar, seguimiento
    presupuesto_estimado DECIMAL(15,2),
    presupuesto_aprobado DECIMAL(15,2),
    presupuesto_ejecutado DECIMAL(15,2),
    moneda VARCHAR(10) DEFAULT 'UYU',
    mis_horas_presupuestadas DECIMAL(8,2),
    mis_horas_ejecutadas DECIMAL(8,2),
    indicadores_exito TEXT[], -- Array de indicadores
    resultados_alcanzados TEXT,
    aprendizajes TEXT,
    etiquetas TEXT[], -- Tags libres
    notas_internas TEXT,
    como_surgio TEXT, -- Cómo fue que nos sumamos a este sub_proyecto
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sub_proyectos_nombre ON sub_proyectos(nombre);
CREATE INDEX idx_sub_proyectos_estado ON sub_proyectos(estado);
CREATE INDEX idx_sub_proyectos_prioridad ON sub_proyectos(prioridad);
CREATE INDEX idx_sub_proyectos_area_vida ON sub_proyectos(area_vida_id);
CREATE INDEX idx_sub_proyectos_proyecto_estrategico ON sub_proyectos(proyecto_estrategico_id);
CREATE INDEX idx_sub_proyectos_org_lider ON sub_proyectos(organizacion_lider_id);
CREATE INDEX idx_sub_proyectos_persona_lider ON sub_proyectos(persona_lider_id);

COMMENT ON TABLE sub_proyectos IS 'Sub-proyectos que surgen en la marcha (ej: alianzas, colaboraciones)';
COMMENT ON COLUMN sub_proyectos.estado IS 'idea, planificacion, aprobado, activo, pausado, completado, cancelado, archivado';
COMMENT ON COLUMN sub_proyectos.prioridad IS 'baja, media, alta, critica, estrategica';
COMMENT ON COLUMN sub_proyectos.mi_responsabilidad IS 'liderar, liderar_seccion, participacion_horizontal, apoyar, asesorar, seguimiento';

-- ============================================================================
-- 5. TABLA INTERMEDIA: sub_proyectos_organizaciones (organizaciones socias)
-- ============================================================================
CREATE TABLE IF NOT EXISTS sub_proyectos_organizaciones (
    id SERIAL PRIMARY KEY,
    sub_proyecto_id INTEGER NOT NULL REFERENCES sub_proyectos(id) ON DELETE CASCADE,
    organizacion_id INTEGER NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    rol_organizacion VARCHAR(100), -- Descripción del rol de la organización en el proyecto
    fecha_incorporacion DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(sub_proyecto_id, organizacion_id)
);

CREATE INDEX idx_sub_proy_org_sub_proyecto ON sub_proyectos_organizaciones(sub_proyecto_id);
CREATE INDEX idx_sub_proy_org_organizacion ON sub_proyectos_organizaciones(organizacion_id);

COMMENT ON TABLE sub_proyectos_organizaciones IS 'Organizaciones socias de cada sub-proyecto';

-- ============================================================================
-- 6. TABLA: contactos
-- ============================================================================
CREATE TABLE IF NOT EXISTS contactos (
    id SERIAL PRIMARY KEY,
    tipo_contacto VARCHAR(50), -- reunion, llamada, email, whatsapp, mensaje_directo, videollamada, evento, casual, almuerzo, cafe
    canal_contacto VARCHAR(50), -- presencial, zoom, meet, teams, telefono, instagram, linkedin, twitter, email, whatsapp
    fecha_contacto TIMESTAMP WITH TIME ZONE NOT NULL,
    asunto VARCHAR(500),
    resumen TEXT,
    acuerdos_alcanzados TEXT[], -- Array de acuerdos
    tareas_generadas TEXT[], -- Array de tareas (texto libre, sin FK)
    compromisos_generados TEXT[], -- Array de compromisos (texto libre, sin FK)
    requiere_seguimiento BOOLEAN DEFAULT FALSE,
    fecha_proximo_contacto DATE,
    notas_seguimiento TEXT,
    otras_personas_presentes TEXT[], -- Array de nombres (texto libre)
    documentos_adjuntos TEXT[], -- Array de URLs
    transcripcion_externa_id VARCHAR(255), -- ID o link externo a transcripción (no FK)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_contactos_fecha ON contactos(fecha_contacto);
CREATE INDEX idx_contactos_tipo ON contactos(tipo_contacto);
CREATE INDEX idx_contactos_canal ON contactos(canal_contacto);
CREATE INDEX idx_contactos_requiere_seguimiento ON contactos(requiere_seguimiento);
CREATE INDEX idx_contactos_fecha_proximo ON contactos(fecha_proximo_contacto);

COMMENT ON TABLE contactos IS 'Registro de contactos/interacciones con personas y organizaciones';
COMMENT ON COLUMN contactos.tipo_contacto IS 'reunion, llamada, email, whatsapp, mensaje_directo, videollamada, evento, casual, almuerzo, cafe';
COMMENT ON COLUMN contactos.canal_contacto IS 'presencial, zoom, meet, teams, telefono, instagram, linkedin, twitter, email, whatsapp';
COMMENT ON COLUMN contactos.transcripcion_externa_id IS 'ID o URL externa de transcripción (no es FK local)';

-- ============================================================================
-- 7. TABLAS INTERMEDIAS PARA CONTACTOS
-- ============================================================================

-- Contactos <-> Personas
CREATE TABLE IF NOT EXISTS contactos_personas (
    id SERIAL PRIMARY KEY,
    contacto_id INTEGER NOT NULL REFERENCES contactos(id) ON DELETE CASCADE,
    persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(contacto_id, persona_id)
);

CREATE INDEX idx_cont_pers_contacto ON contactos_personas(contacto_id);
CREATE INDEX idx_cont_pers_persona ON contactos_personas(persona_id);

-- Contactos <-> Organizaciones
CREATE TABLE IF NOT EXISTS contactos_organizaciones (
    id SERIAL PRIMARY KEY,
    contacto_id INTEGER NOT NULL REFERENCES contactos(id) ON DELETE CASCADE,
    organizacion_id INTEGER NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(contacto_id, organizacion_id)
);

CREATE INDEX idx_cont_org_contacto ON contactos_organizaciones(contacto_id);
CREATE INDEX idx_cont_org_organizacion ON contactos_organizaciones(organizacion_id);

-- Contactos <-> Sub-proyectos
CREATE TABLE IF NOT EXISTS contactos_sub_proyectos (
    id SERIAL PRIMARY KEY,
    contacto_id INTEGER NOT NULL REFERENCES contactos(id) ON DELETE CASCADE,
    sub_proyecto_id INTEGER NOT NULL REFERENCES sub_proyectos(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(contacto_id, sub_proyecto_id)
);

CREATE INDEX idx_cont_subproy_contacto ON contactos_sub_proyectos(contacto_id);
CREATE INDEX idx_cont_subproy_sub_proyecto ON contactos_sub_proyectos(sub_proyecto_id);

-- Contactos <-> Proyectos Estratégicos
CREATE TABLE IF NOT EXISTS contactos_proyectos_estrategicos (
    id SERIAL PRIMARY KEY,
    contacto_id INTEGER NOT NULL REFERENCES contactos(id) ON DELETE CASCADE,
    proyecto_estrategico_id INTEGER NOT NULL REFERENCES proyectos_estrategicos(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(contacto_id, proyecto_estrategico_id)
);

CREATE INDEX idx_cont_proy_contacto ON contactos_proyectos_estrategicos(contacto_id);
CREATE INDEX idx_cont_proy_proyecto ON contactos_proyectos_estrategicos(proyecto_estrategico_id);

-- ============================================================================
-- 8. TABLA: personas_proyectos (participación de personas en proyectos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS personas_proyectos (
    id SERIAL PRIMARY KEY,
    persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    proyecto_estrategico_id INTEGER REFERENCES proyectos_estrategicos(id) ON DELETE CASCADE,
    sub_proyecto_id INTEGER REFERENCES sub_proyectos(id) ON DELETE CASCADE,
    rol_proyecto VARCHAR(100), -- coordinador, voluntario, beneficiario, mentor, asesor, donante, facilitador
    fecha_inicio_participacion DATE,
    fecha_fin_participacion DATE,
    estado_participacion VARCHAR(50) DEFAULT 'activo', -- activo, inactivo, pausado, completado
    horas_dedicadas DECIMAL(8,2),
    contribucion_destacada TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (proyecto_estrategico_id IS NOT NULL OR sub_proyecto_id IS NOT NULL)
);

CREATE INDEX idx_pers_proy_persona ON personas_proyectos(persona_id);
CREATE INDEX idx_pers_proy_proyecto_estrategico ON personas_proyectos(proyecto_estrategico_id);
CREATE INDEX idx_pers_proy_sub_proyecto ON personas_proyectos(sub_proyecto_id);
CREATE INDEX idx_pers_proy_estado ON personas_proyectos(estado_participacion);

COMMENT ON TABLE personas_proyectos IS 'Participación de personas en proyectos estratégicos o sub-proyectos';
COMMENT ON COLUMN personas_proyectos.rol_proyecto IS 'coordinador, voluntario, beneficiario, mentor, asesor, donante, facilitador';
COMMENT ON COLUMN personas_proyectos.estado_participacion IS 'activo, inactivo, pausado, completado';

-- ============================================================================
-- 9. TRIGGERS PARA updated_at
-- ============================================================================

-- Función genérica para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para cada tabla con updated_at
CREATE TRIGGER update_personas_updated_at
    BEFORE UPDATE ON personas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizaciones_updated_at
    BEFORE UPDATE ON organizaciones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_personas_organizaciones_updated_at
    BEFORE UPDATE ON personas_organizaciones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sub_proyectos_updated_at
    BEFORE UPDATE ON sub_proyectos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contactos_updated_at
    BEFORE UPDATE ON contactos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_personas_proyectos_updated_at
    BEFORE UPDATE ON personas_proyectos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;

-- ============================================================================
-- RESUMEN DE TABLAS CREADAS:
-- ============================================================================
-- 1. personas                         - Contactos personales
-- 2. organizaciones                   - Organizaciones
-- 3. personas_organizaciones          - Relación persona-organización (cargos)
-- 4. sub_proyectos                    - Proyectos que surgen en la marcha
-- 5. sub_proyectos_organizaciones     - Organizaciones socias de sub-proyectos
-- 6. contactos                        - Registro de interacciones
-- 7. contactos_personas               - Personas en cada contacto
-- 8. contactos_organizaciones         - Organizaciones en cada contacto
-- 9. contactos_sub_proyectos          - Sub-proyectos relacionados al contacto
-- 10. contactos_proyectos_estrategicos - Proyectos estratégicos relacionados
-- 11. personas_proyectos              - Participación de personas en proyectos
-- ============================================================================
