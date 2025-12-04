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
-- Name: Prioridad; Type: TYPE; Schema: public; Owner: asistente
--

CREATE TYPE public."Prioridad" AS ENUM (
    'BAJA',
    'MEDIA',
    'ALTA',
    'URGENTE'
);


ALTER TYPE public."Prioridad" OWNER TO asistente;

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
-- Name: ideas; Type: TABLE; Schema: public; Owner: asistente
--

CREATE TABLE public.ideas (
    id integer NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    categoria text,
    implementada boolean DEFAULT false NOT NULL,
    "fechaImplementacion" timestamp(3) without time zone,
    "notaAudioId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.ideas OWNER TO asistente;

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

ALTER SEQUENCE public.ideas_id_seq OWNED BY public.ideas.id;


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
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.tareas OWNER TO asistente;

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
-- Name: compromisos id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.compromisos ALTER COLUMN id SET DEFAULT nextval('public.compromisos_id_seq'::regclass);


--
-- Name: ideas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas ALTER COLUMN id SET DEFAULT nextval('public.ideas_id_seq'::regclass);


--
-- Name: notas_audio id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.notas_audio ALTER COLUMN id SET DEFAULT nextval('public.notas_audio_id_seq'::regclass);


--
-- Name: registros id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.registros ALTER COLUMN id SET DEFAULT nextval('public.registros_id_seq'::regclass);


--
-- Name: tareas id; Type: DEFAULT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas ALTER COLUMN id SET DEFAULT nextval('public.tareas_id_seq'::regclass);


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
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
-- Data for Name: ideas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.ideas (id, titulo, descripcion, categoria, implementada, "fechaImplementacion", "notaAudioId", "createdAt", "updatedAt") FROM stdin;
1	Mejora en la gestión de proyectos	Necesidad de tener una tabla accesible desde nocodb para cambiar nombres de proyectos y gestionar personas involucradas, incluyendo la identificación de cada persona por su ID en relación a los proyectos.	mejora	f	\N	10	2025-11-07 04:54:27.038	2025-11-07 04:54:27.038
2	Compra de máquina de sublimación	Pensé en comprar una máquina de sublimación y agregarlo en el ande, como, no sé.	producto	f	\N	11	2025-11-07 04:55:09.283	2025-11-07 04:55:09.283
3	Implementar tabla de comunicación para proyectos	Proponer la creación de una tabla que defina el tipo de contenido y la línea de comunicación permitida para los proyectos, especificando qué información se puede compartir y qué no.	estrategia	f	\N	133	2025-12-01 18:57:33.659	2025-12-01 18:57:33.659
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
\.


--
-- Data for Name: tareas; Type: TABLE DATA; Schema: public; Owner: asistente
--

COPY public.tareas (id, titulo, descripcion, "fechaVencimiento", prioridad, completada, "fechaCompletada", "notaAudioId", "createdAt", "updatedAt") FROM stdin;
1	Llamar a María	Llamar a María mañana a las 3pm para revisar el proyecto	2025-11-08 15:00:00	MEDIA	f	\N	1	2025-11-07 01:36:32.201	2025-11-07 01:36:32.201
2	Armar y escribir la sección 1 del formulario de capital Semilla	Escribir y organizar la primera sección del formulario de capital Semilla de Andes.	\N	MEDIA	f	\N	2	2025-11-07 02:38:56.187	2025-11-07 02:38:56.187
4	Llenar planilla de estrategias de social media	Agarrar la planilla de estrategias de social media que me mandó Metricool y tratar de llenarla como para poder empezar a generar acciones y contenido.	2025-11-07 00:00:00	MEDIA	f	\N	9	2025-11-07 04:27:26.592	2025-11-07 04:27:26.592
5	Escribirle a Adri	\N	2025-11-08 00:00:00	URGENTE	f	\N	12	2025-11-07 04:55:40.01	2025-11-07 04:55:40.01
6	Hacer automatización para enviar WhatsApp	Crear una automatización que envíe un mensaje de WhatsApp a la persona o a la ONG cuando se envíe o llegue un mensaje de conexión.	\N	MEDIA	f	\N	13	2025-11-07 04:57:10.941	2025-11-07 04:57:10.941
7	Enviar respuestas del proyecto de Andes	Enviar las respuestas del proyecto de Andes al mail de Anaria, Rochi y Leo.	\N	MEDIA	f	\N	16	2025-11-07 15:42:53.243	2025-11-07 15:42:53.243
8	Armar esquema para Ateneo	Estudiar un poco más sobre los proyectos que vienen.	\N	MEDIA	f	\N	18	2025-11-07 15:44:49.922	2025-11-07 15:44:49.922
3	Escribir a Diego Sastre	Revisar si me van a apoyar desde Fibras o si no.	2025-11-08 00:00:00	MEDIA	t	\N	4	2025-11-07 02:40:29.857	2025-11-07 02:40:29.857
9	Confirmar disposición de Rochi y Leo	Verificar si Rochi y Leo están dispuestos a hacer el esfuerzo para el proyecto.	\N	MEDIA	f	\N	19	2025-11-07 17:36:37.363	2025-11-07 17:36:37.363
10	Copiar información a nueva base de datos	Copiar la información que tengo en las otras bases de datos y pegarlas a la nueva base de datos de involucrajado.	\N	MEDIA	f	\N	28	2025-11-17 17:14:46.792	2025-11-17 17:14:46.792
11	Revisar la postulación de Álvaro	Armar algo para que queden lindas las cosas de ella.	\N	MEDIA	f	\N	32	2025-11-17 17:14:59.866	2025-11-17 17:14:59.866
12	Revisar idas y vueltas y plato lleno	Revisar de vuelta lo de idas y vueltas y lo del plato lleno, junto con las cosas que tengo que hacer.	\N	MEDIA	f	\N	33	2025-11-17 17:15:03.138	2025-11-17 17:15:03.138
13	Armar base de datos de POSGRES	Llenar las tablas de la base de datos para el proyecto 'Involúcrate'.	\N	MEDIA	f	\N	34	2025-11-17 17:15:05.993	2025-11-17 17:15:05.993
14	Asistir a reunión del proyecto Fe y Alegría	Reunión con Diego y Pablo en Pixis.	2025-11-17 20:30:00	MEDIA	f	\N	41	2025-11-17 17:15:25.912	2025-11-17 17:15:25.912
15	Enviar presentación a Analia y equipo de proyecto de impacto	Enviar la presentación que armé para la ANDE de involucrarse a Analia y las personas que están en proyecto de impacto para poder empezar a trabajar desde ahí.	\N	MEDIA	f	\N	42	2025-11-17 17:15:29.14	2025-11-17 17:15:29.14
16	Contactar a Hecho sobre voluntaria	Arreglar la falta de respuesta de Hecho a la voluntaria que se contactó.	\N	MEDIA	f	\N	43	2025-11-17 17:15:31.701	2025-11-17 17:15:31.701
17	Asistir a la murga	Hoy de noche tengo murga también. De ocho y media a nueve a once.	2025-11-17 23:30:00	MEDIA	f	\N	44	2025-11-17 17:15:35.067	2025-11-17 17:15:35.067
\.


--
-- Name: compromisos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.compromisos_id_seq', 3, true);


--
-- Name: ideas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.ideas_id_seq', 3, true);


--
-- Name: notas_audio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.notas_audio_id_seq', 133, true);


--
-- Name: registros_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.registros_id_seq', 38, true);


--
-- Name: tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: asistente
--

SELECT pg_catalog.setval('public.tareas_id_seq', 17, true);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: compromisos compromisos_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.compromisos
    ADD CONSTRAINT compromisos_pkey PRIMARY KEY (id);


--
-- Name: ideas ideas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_pkey PRIMARY KEY (id);


--
-- Name: notas_audio notas_audio_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.notas_audio
    ADD CONSTRAINT notas_audio_pkey PRIMARY KEY (id);


--
-- Name: registros registros_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.registros
    ADD CONSTRAINT registros_pkey PRIMARY KEY (id);


--
-- Name: tareas tareas_pkey; Type: CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT tareas_pkey PRIMARY KEY (id);


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
-- Name: ideas_categoria_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX ideas_categoria_idx ON public.ideas USING btree (categoria);


--
-- Name: ideas_implementada_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX ideas_implementada_idx ON public.ideas USING btree (implementada);


--
-- Name: ideas_notaAudioId_idx; Type: INDEX; Schema: public; Owner: asistente
--

CREATE INDEX "ideas_notaAudioId_idx" ON public.ideas USING btree ("notaAudioId");


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
-- Name: compromisos compromisos_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.compromisos
    ADD CONSTRAINT "compromisos_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ideas ideas_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT "ideas_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: registros registros_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.registros
    ADD CONSTRAINT "registros_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tareas tareas_notaAudioId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asistente
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT "tareas_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES public.notas_audio(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

