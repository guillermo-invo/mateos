-- ============================================
-- TABLA: areas
-- ============================================

INSERT INTO areas_vida (nombre, descripcion, color_hex, orden_visualizacion, activa) VALUES
('involucrate', 'Plataforma de voluntariado corporativo y gestión de impacto social', '#FF6B6B', 1, true),
('involucrarse', 'Proyectos sociales directos y coordinación de iniciativas comunitarias', '#4ECDC4', 2, true),
('mateos', 'Metodología de gestión personal y sistema de decisiones (este proyecto)', '#95E1D3', 3, true),
('marcaPersonal', 'Construcción de marca, contenido, redes sociales y posicionamiento', '#F38181', 4, true),
('tdahAACC', 'Exploración y gestión de TDAH y Altas Capacidades', '#AA96DA', 5, true),
('fibras', 'Salud mental, bienestar emocional y terapia', '#FCBAD3', 6, true),
('gyermekClub', 'Proyectos con niños, educación y desarrollo infantil', '#FFFFD2', 7, true),
('murga', 'Expresión artística, murga, música y performance', '#FFD3B6', 8, true),
('placita', 'Proyectos barriales, espacio público y comunidad local', '#A8E6CF', 9, true),
('cfEscuela', 'Proyectos en escuela de los hijos', '#FFB6C1', 10, true),
('cfJardin', 'Proyectos en jardín de infantes', '#DDA0DD', 11, true),
('salud', 'Salud física, ejercicio, alimentación y bienestar', '#98D8C8', 12, true),
('finanzas', 'Gestión financiera personal, inversiones y economía', '#F7DC6F', 13, true),
('familia', 'Tiempo familiar, paternidad y relaciones', '#FF9AA2', 14, true);

COMMENT ON TABLE areas_vida IS 'Campos de vida donde Guillermo desarrolla proyectos';

-- ============================================
-- TABLA: motivos
-- ============================================

INSERT INTO motivos_personales (nombre, descripcion, icono, peso_personal) VALUES
('impacto_social', 'Generar cambio positivo medible en la sociedad', '🌍', 10),
('desarrollo_personal', 'Aprender, crecer y expandir capacidades', '📚', 9),
('status_reconocimiento', 'Ganar autoridad y reconocimiento en el sector', '⭐', 7),
('desafio_intelectual', 'Resolver problemas complejos y salir de zona de confort', '🧠', 9),
('ingresos_sostenibilidad', 'Generar ingresos para sostenibilidad económica', '💰', 8),
('conexiones_red', 'Ampliar red de contactos valiosos', '🤝', 7),
('creatividad_expresion', 'Expresar creatividad y crear algo único', '🎨', 8),
('legado_trascendencia', 'Dejar algo que trascienda en el tiempo', '🏛️', 8),
('comunidad_pertenencia', 'Fortalecer lazos comunitarios y sentido de pertenencia', '👥', 9),
('experimentacion', 'Probar cosas nuevas, iterar, aprender haciendo', '🔬', 9),
('libertad_autonomia', 'Trabajar con libertad de decisión y creatividad', '🦅', 9),
('diversion_disfrute', 'Disfrutar el proceso, pasarla bien', '😄', 8);

COMMENT ON TABLE motivos_personales IS 'Motivaciones que impulsan a Guillermo a llevar adelante proyectos';

-- ============================================
-- TABLA: destrezas (con metadata energética)
-- ============================================

INSERT INTO destrezas (
    nombre, 
    categoria, 
    nivel_actual, 
    descripcion,
    costo_energetico,
    mejor_momento_dia,
    requiere_flow,
    notas_contexto
) VALUES

-- HABILIDADES SOCIALES/INTERPERSONALES
('empatía', 'Social', 9, 'Capacidad de conectar emocionalmente con otros', 'media', ARRAY['cualquier_momento'], false, 'Natural, no me cansa'),
('asertivo', 'Social', 7, 'Expresar opiniones y límites con claridad', 'media', ARRAY['mañana', 'tarde'], false, 'Requiere estar descansado para no caer en agresividad'),
('confianza', 'Social', 8, 'Generar confianza en otros, ser confiable', 'baja', ARRAY['cualquier_momento'], false, 'Se construye con consistencia'),
('buenMediador', 'Social', 8, 'Facilitar acuerdos y resolver conflictos', 'alta', ARRAY['mañana'], false, 'Requiere paciencia y energía emocional'),
('oratoria', 'Social', 7, 'Hablar en público con claridad y persuasión', 'alta', ARRAY['mañana', 'tarde'], false, 'Mejor con preparación previa'),
('comunicación', 'Social', 8, 'Transmitir ideas claramente, escuchar activamente', 'media', ARRAY['cualquier_momento'], false, 'Core skill, uso constante'),
('manejoDeGrupos', 'Social', 8, 'Coordinar y facilitar dinámicas grupales', 'alta', ARRAY['mañana', 'tarde'], false, 'Requiere energía social alta'),

-- LIDERAZGO Y GESTIÓN
('liderazgo', 'Gestión', 8, 'Inspirar y guiar equipos hacia objetivos', 'alta', ARRAY['mañana'], false, 'Mejor en días con alta energía'),
('buenLíderPersonal', 'Gestión', 8, 'Gestionar mi propia vida y proyectos', 'media', ARRAY['mañana'], true, 'Requiere claridad mental'),
('hacerPlanes', 'Gestión', 9, 'Diseñar estrategias y roadmaps', 'media', ARRAY['mañana', 'noche'], true, 'Me gusta y me sale natural'),
('ordenDeIdeas', 'Gestión', 8, 'Estructurar pensamientos complejos', 'media', ARRAY['mañana'], true, 'Necesito tranquilidad'),
('voluntariadoGestion', 'Gestión', 9, 'Coordinar voluntarios y proyectos sociales', 'alta', ARRAY['mañana', 'tarde'], false, 'Expertise profesional'),

-- TECNOLOGÍA Y PROGRAMACIÓN
('inteligenciaArtificial', 'Técnica', 8, 'Crear automatizaciones y usar APIs de IA', 'pico', ARRAY['mañana_temprano', 'noche'], true, 'Requiere máxima concentración'),
('desarrolloCodigo', 'Técnica', 7, 'Programar en Python, JavaScript, TypeScript', 'pico', ARRAY['mañana_temprano'], true, 'Necesito flow completo, 2+ horas'),
('diseñoFuncional', 'Técnica', 7, 'Diseñar arquitecturas de sistemas', 'alta', ARRAY['mañana'], true, 'Requiere pensamiento profundo'),
('tecnologia', 'Técnica', 8, 'Entender y usar nuevas tecnologías', 'media', ARRAY['cualquier_momento'], false, 'Aprendizaje continuo'),
('teoríaDeComputadoras', 'Técnica', 6, 'Fundamentos de ciencias de la computación', 'alta', ARRAY['mañana'], true, 'Requiere estudio concentrado'),
('webDesign', 'Técnica', 6, 'Diseñar interfaces web', 'media', ARRAY['tarde', 'noche'], false, 'Creativo, no muy técnico'),
('UX', 'Técnica', 7, 'Diseño de experiencia de usuario', 'media', ARRAY['tarde'], false, 'Combina empatía y diseño'),
('designThinking', 'Técnica', 8, 'Metodología de innovación centrada en usuario', 'media', ARRAY['mañana', 'tarde'], false, 'Framework que uso mucho'),

-- CREATIVIDAD Y PRODUCCIÓN
('producción', 'Creativa', 7, 'Producir eventos, proyectos, contenido', 'alta', ARRAY['cualquier_momento'], false, 'Coordinar múltiples elementos'),
('ediciónDeVideo', 'Creativa', 6, 'Editar videos', 'alta', ARRAY['tarde', 'noche'], true, 'Requiere bloques largos'),
('ediciónDeAudio', 'Creativa', 7, 'Editar audio y podcasts', 'media', ARRAY['tarde', 'noche'], true, 'Me relaja más que video'),
('fotografía', 'Creativa', 6, 'Capturar fotos de calidad', 'baja', ARRAY['cualquier_momento'], false, 'Tarea ligera'),
('iluminación', 'Creativa', 5, 'Diseñar iluminación para eventos/video', 'media', ARRAY['tarde'], false, 'Técnico pero creativo'),
('copyEscritura', 'Creativa', 7, 'Escribir textos persuasivos', 'media', ARRAY['mañana', 'noche'], true, 'Requiere concentración'),

-- ARTE Y PERFORMANCE
('danza', 'Artística', 6, 'Bailar, coreografías', 'alta', ARRAY['tarde', 'noche'], false, 'Energético, me recarga'),
('musica', 'Artística', 6, 'Tocar instrumentos, componer', 'media', ARRAY['tarde', 'noche'], false, 'Expresión personal'),
('canto', 'Artística', 6, 'Cantar', 'media', ARRAY['cualquier_momento'], false, 'Liberador'),
('guitarra', 'Artística', 5, 'Tocar guitarra', 'media', ARRAY['tarde', 'noche'], false, 'Requiere práctica'),
('ukelele', 'Artística', 6, 'Tocar ukelele', 'baja', ARRAY['cualquier_momento'], false, 'Instrumento ligero'),
('rítmo', 'Artística', 7, 'Sentido del ritmo', 'baja', ARRAY['cualquier_momento'], false, 'Natural'),
('coreografías', 'Artística', 6, 'Crear coreografías de danza/murga', 'alta', ARRAY['tarde'], false, 'Requiere creatividad e imaginación'),
('actuarTeatro', 'Artística', 6, 'Actuar, performance teatral', 'alta', ARRAY['tarde', 'noche'], false, 'Requiere desinhibición'),
('chistes', 'Artística', 7, 'Hacer reír, humor', 'baja', ARRAY['cualquier_momento'], false, 'Natural, me sale espontáneo'),

-- CONOCIMIENTO Y ANÁLISIS
('solucionesDriven', 'Cognitiva', 9, 'Enfoque en soluciones, no problemas', 'media', ARRAY['cualquier_momento'], false, 'Mindset natural'),
('ingenio', 'Cognitiva', 9, 'Encontrar soluciones creativas con recursos limitados', 'media', ARRAY['mañana', 'tarde'], false, 'Fortaleza clave'),
('pensamientoPropio', 'Cognitiva', 9, 'Pensar críticamente, cuestionar status quo', 'media', ARRAY['mañana', 'noche'], true, 'Requiere soledad y silencio'),
('analisisCriticoDetallado', 'Cognitiva', 8, 'Analizar en profundidad', 'alta', ARRAY['mañana'], true, 'Requiere concentración máxima'),
('pensamientoRamificado', 'Cognitiva', 9, 'Ver múltiples caminos y conexiones', 'media', ARRAY['mañana'], false, 'TDAH advantage'),
('comprensionDeSystemas', 'Cognitiva', 9, 'Ver el todo, entender interdependencias', 'alta', ARRAY['mañana'], true, 'Pensamiento sistémico natural'),
('pensamientoEnSistemas', 'Cognitiva', 9, 'Modelar sistemas complejos', 'alta', ARRAY['mañana'], true, 'Core skill para proyectos'),
('esquemas', 'Cognitiva', 8, 'Crear diagramas y modelos visuales', 'media', ARRAY['mañana', 'tarde'], false, 'Ayuda a pensar mejor'),

-- CONOCIMIENTOS ESPECÍFICOS
('conocimientoFilosofía', 'Conocimiento', 7, 'Filosofía, historia del pensamiento', 'media', ARRAY['noche'], false, 'Lectura y reflexión'),
('existencialismo', 'Conocimiento', 8, 'Filosofía existencialista', 'media', ARRAY['noche'], false, 'Resonancia personal'),
('conocimientoPsicología', 'Conocimiento', 8, 'Psicología, comportamiento humano', 'media', ARRAY['cualquier_momento'], false, 'Estudio continuo'),
('eneagrama', 'Conocimiento', 7, 'Sistema de personalidad Eneagrama', 'baja', ARRAY['cualquier_momento'], false, 'Herramienta de autoconocimiento'),
('conocimientoEconomía', 'Conocimiento', 6, 'Economía y macroeconomía', 'alta', ARRAY['mañana'], true, 'Requiere concentración'),
('conocimientoFinanzas', 'Conocimiento', 6, 'Finanzas personales y empresariales', 'media', ARRAY['mañana', 'tarde'], false, 'Aprendizaje en progreso'),
('conocimientoNegocios', 'Conocimiento', 7, 'Estrategia de negocios, emprendimiento', 'media', ARRAY['mañana', 'tarde'], false, 'Experiencia práctica'),
('matematicas', 'Conocimiento', 7, 'Matemáticas, lógica', 'alta', ARRAY['mañana'], true, 'Requiere mente fresca'),

-- HABILIDADES PRÁCTICAS
('carpintería', 'Práctica', 5, 'Trabajar con madera', 'alta', ARRAY['mañana', 'tarde'], false, 'Físico, requiere energía'),
('bioconstrucción', 'Práctica', 5, 'Construcción sustentable', 'alta', ARRAY['mañana', 'tarde'], false, 'Físico y técnico'),
('cocinero', 'Práctica', 6, 'Cocinar', 'media', ARRAY['tarde', 'noche'], false, 'Tarea cotidiana'),
('atleta', 'Práctica', 6, 'Deportes, actividad física', 'alta', ARRAY['mañana', 'tarde'], false, 'Me recarga energéticamente'),
('facilidadDeportes', 'Práctica', 7, 'Aprender deportes rápidamente', 'media', ARRAY['cualquier_momento'], false, 'Natural'),
('facilidadParaCiencias', 'Práctica', 8, 'Entender conceptos científicos', 'alta', ARRAY['mañana'], true, 'Requiere concentración'),

-- EDUCACIÓN Y ENSEÑANZA
('pedagogía', 'Educativa', 7, 'Enseñar, facilitar aprendizaje', 'media', ARRAY['mañana', 'tarde'], false, 'Disfruto enseñar'),
('enseñanza', 'Educativa', 7, 'Transmitir conocimiento efectivamente', 'media', ARRAY['mañana', 'tarde'], false, 'Paciencia y claridad'),
('recreacion', 'Educativa', 8, 'Diseñar actividades recreativas', 'media', ARRAY['tarde'], false, 'Creativo y energético'),
('campamentero', 'Educativa', 7, 'Organizar campamentos, actividades outdoor', 'alta', ARRAY['cualquier_momento'], false, 'Requiere energía y coordinación'),

-- OTRAS HABILIDADES
('esfuerzo', 'Personal', 8, 'Capacidad de trabajar duro cuando es necesario', 'alta', ARRAY['mañana'], false, 'Intensidad cuando hace falta'),
('podcast', 'Media', 6, 'Crear y producir podcasts', 'media', ARRAY['tarde', 'noche'], false, 'Conversacional'),
('redesSociales', 'Media', 6, 'Gestionar redes sociales', 'baja', ARRAY['tarde', 'noche'], false, 'Tarea ligera'),
('buenPadre', 'Personal', 8, 'Ser presente y buen padre', 'alta', ARRAY['tarde', 'noche'], false, 'Requiere energía emocional'),
('impactoSocialAmbiental', 'Social', 9, 'Diseñar proyectos con impacto positivo', 'media', ARRAY['mañana', 'tarde'], false, 'Propósito de vida'),
('causasSociales', 'Social', 9, 'Trabajo en causas sociales', 'media', ARRAY['cualquier_momento'], false, 'Motivación intrínseca'),
('meditar', 'Personal', 6, 'Meditar, mindfulness', 'relax', ARRAY['mañana_temprano', 'noche'], false, 'Me recarga'),
('titulosAcademicos', 'Conocimiento', 7, 'Formación académica formal', 'media', ARRAY['cualquier_momento'], false, 'Base de conocimiento');

COMMENT ON TABLE destrezas IS 'Habilidades y capacidades de Guillermo con metadata de contexto de ejecución';

-- ============================================

-- ============================================
-- TABLA: dificultades
-- ============================================

INSERT INTO dificultades (
    nombre, 
    categoria, 
    nivel_impacto, 
    descripcion, 
    estrategia_mitigacion
) VALUES

('revisarMails', 'Temporal', 8, 
 'Procrastinación en revisar y responder emails. Se acumulan.',
 'Bloquear 30 min diarios específicos (15:00-15:30). Usar templates de respuesta. Regla 2 minutos: si toma menos, responder ya.'),

('constancia', 'Emocional', 9, 
 'Dificultad para mantener constancia en hábitos y tareas repetitivas. TDAH.',
 'Sistemas de accountability (check-ins con alguien). Vincular hábito a recompensa inmediata. Usar Habit Tracker visual. No confiar solo en motivación, crear fricción para NO hacer.'),

('exponerme', 'Emocional', 7, 
 'Miedo a exponerme públicamente, mostrar vulnerabilidad o imperfección.',
 'Empezar con audiencias pequeñas y seguras. Recordar que la perfección paraliza. Compartir proceso, no solo resultados. Terapia para trabajar miedo al juicio.'),

('responderRedes', 'Social', 7, 
 'Procrastinación en responder mensajes de redes sociales. Inbox de WhatsApp, LinkedIn, Instagram con mensajes sin leer.',
 'Igualar estrategia que emails: bloque de 20 min diarios. Usar respuestas rápidas. Comunicar "respondo lento" en bio. Delegar si es posible.'),

('mantenerPromesas', 'Social', 8, 
 'Sobre-comprometerme y luego no cumplir promesas. Decir "sí" cuando debería decir "no".',
 'Regla: ante propuesta nueva, decir "Déjame revisarlo y te confirmo". Calcular tiempo real × 1.5. Aprender a decir no con gracia. Recordar costo de oportunidad.'),

('darPasoAdelante', 'Emocional', 8, 
 'Paralización ante incertidumbre. Perfeccionismo que impide empezar.',
 'Mantra: "Done is better than perfect". Prototipar rápido. Timebox de decisiones (máximo X tiempo para decidir, luego ejecutar). Recordar que se aprende haciendo.'),

('ordenar', 'Práctica', 7, 
 'Dificultad para mantener espacios físicos ordenados. TDAH.',
 'Sistema de "un lugar para cada cosa". Reducir cantidad de objetos (minimalismo). Ordenar al final del día 10 minutos. No acumular, tirar/donar rápido.'),

('limpiar', 'Práctica', 6, 
 'Procrastinación en tareas de limpieza.',
 'Música alegre mientras limpio. Técnica Pomodoro (25 min limpieza). Recompensa post-limpieza (café, serie). Si es posible, delegar o contratar.'),

('recoger', 'Práctica', 7, 
 'Dejar cosas fuera de lugar. No recoger en el momento.',
 'Regla "one-touch": si toco algo, lo guardo ya. Baskets/cajas por área para "tirar" cosas temporalmente. Recordar que recoger ahora = 10 segundos, después = 5 minutos de buscar.');

COMMENT ON TABLE dificultades IS 'Desafíos personales de Guillermo con estrategias de mitigación';

-- ============================================
-- TABLA: misiones
-- ============================================

INSERT INTO misiones_vida (
    nombre, 
    descripcion, 
    vision, 
    prioridad
) VALUES

('facilitador_bondad', 
 'Facilitador de la ejecución de la bondad de los demás',
 'Ser el puente que conecta la intención de ayudar con la acción concreta. Que cuando alguien piense "quiero hacer algo bueno", yo sea quien lo hace posible. Multiplicar el impacto social facilitando que miles de personas ejecuten su bondad.',
 10),

('momentador_herramientas', 
 'Momentador y creador de herramientas para una sociedad más comunicada',
 'Crear sistemas y herramientas (digitales, metodológicas, conceptuales) que ayuden a las personas a comunicarse mejor, entenderse mejor, y coordinarse mejor. Que mis herramientas sean usadas por miles para mejorar su comunicación.',
 9),

('creador_plataformas', 
 'Creador de plataformas y proyectos para que las personas desarrollen su potencial',
 'Diseñar espacios (físicos, digitales, conceptuales) donde las personas puedan crecer, aprender, y convertirse en su mejor versión. Que al menos 10,000 personas hayan desarrollado su potencial gracias a mis plataformas.',
 9),

('creador_modelos_mentales', 
 'Creador de modelos mentales',
 'Crear frameworks, sistemas de pensamiento, y modelos mentales que ayuden a otros a pensar mejor, decidir mejor, y vivir mejor. Que mis modelos sean enseñados y replicados por otros.',
 8),

('money_maker', 
 'Money Maker - Generador de valor económico sostenible',
 'Crear ingresos suficientes para vivir bien, sostener a mi familia, y reinvertir en proyectos de impacto. Llegar a $10k USD/mes recurrentes con proyectos que amo. Libertad financiera sin sacrificar propósito.',
 8),

('creador_contenido', 
 'Creador de contenido que inspira y educa',
 'Crear contenido (escrito, audio, video) que inspire a otros a actuar, a pensar diferente, a crear impacto. Tener una audiencia de 10,000+ personas que esperan mi contenido y se transforman con él.',
 7);

COMMENT ON TABLE misiones_vida IS 'Roles de vida y propósitos de Guillermo a largo plazo';