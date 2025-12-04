-- CreateEnum
CREATE TYPE "Prioridad" AS ENUM ('BAJA', 'MEDIA', 'ALTA', 'URGENTE');

-- CreateEnum
CREATE TYPE "Categoria" AS ENUM ('TRABAJO', 'PERSONAL', 'SOCIAL', 'OTRO');

-- CreateEnum
CREATE TYPE "TipoMoscow" AS ENUM ('must', 'should', 'could', 'wont');

-- CreateEnum
CREATE TYPE "TipoEnfoque" AS ENUM ('velocidad', 'perfeccion', 'balanceado');

-- CreateEnum
CREATE TYPE "TipoLibertad" AS ENUM ('receta', 'resultado', 'mixto');

-- CreateEnum
CREATE TYPE "TipoRiesgo" AS ENUM ('bajo', 'medio', 'alto', 'critico');

-- CreateEnum
CREATE TYPE "TipoEnergia" AS ENUM ('relax', 'baja', 'media', 'alta', 'pico');

-- CreateEnum
CREATE TYPE "TipoEstadoProyecto" AS ENUM ('idea', 'planificacion', 'en_curso', 'pausado', 'completado', 'cancelado', 'archivado');

-- CreateEnum
CREATE TYPE "TipoEstadoTarea" AS ENUM ('por_hacer', 'en_progreso', 'bloqueada', 'en_revision', 'completada', 'cancelada');

-- CreateTable
CREATE TABLE "notas_audio" (
    "id" SERIAL NOT NULL,
    "transcripcionId" INTEGER NOT NULL,
    "transcripcionCompleta" TEXT NOT NULL,
    "archivoAudioUrl" TEXT,
    "resumenEjecutivo" TEXT,
    "fechaGrabacion" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "procesado" BOOLEAN NOT NULL DEFAULT false,
    "tipoDetectado" TEXT,
    "confianzaDeteccion" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notas_audio_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tareas" (
    "id" SERIAL NOT NULL,
    "titulo" TEXT NOT NULL,
    "descripcion" TEXT,
    "fechaVencimiento" TIMESTAMP(3),
    "prioridad" "Prioridad" NOT NULL DEFAULT 'MEDIA',
    "completada" BOOLEAN NOT NULL DEFAULT false,
    "fechaCompletada" TIMESTAMP(3),
    "notaAudioId" INTEGER NOT NULL,
    "proyecto_estrategico_id" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tareas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "compromisos" (
    "id" SERIAL NOT NULL,
    "titulo" TEXT NOT NULL,
    "descripcion" TEXT,
    "personaNombre" TEXT NOT NULL,
    "fechaLimite" TIMESTAMP(3),
    "yoMeComprometi" BOOLEAN NOT NULL DEFAULT false,
    "cumplido" BOOLEAN NOT NULL DEFAULT false,
    "fechaCumplido" TIMESTAMP(3),
    "notaAudioId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "compromisos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registros" (
    "id" SERIAL NOT NULL,
    "descripcion" TEXT NOT NULL,
    "duracionHoras" DOUBLE PRECISION,
    "proyecto" TEXT,
    "personasInvolucradas" TEXT[],
    "categoria" "Categoria" NOT NULL DEFAULT 'TRABAJO',
    "fechaActividad" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notaAudioId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "registros_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ideas_capturadas" (
    "id" SERIAL NOT NULL,
    "titulo" TEXT NOT NULL,
    "descripcion" TEXT,
    "categoria" TEXT,
    "implementada" BOOLEAN NOT NULL DEFAULT false,
    "fechaImplementacion" TIMESTAMP(3),
    "notaAudioId" INTEGER NOT NULL,
    "proyecto_estrategico_id" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ideas_capturadas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "areas_vida" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "descripcion" TEXT,
    "color_hex" VARCHAR(7),
    "orden_visualizacion" INTEGER,
    "activa" BOOLEAN,

    CONSTRAINT "areas_vida_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "motivos_personales" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "descripcion" TEXT,
    "icono" VARCHAR(20),
    "peso_personal" INTEGER,

    CONSTRAINT "motivos_personales_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "destrezas" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "categoria" VARCHAR(50),
    "nivel_actual" INTEGER,
    "descripcion" TEXT,
    "costo_energetico" "TipoEnergia",
    "mejor_momento_dia" TEXT[],
    "requiere_flow" BOOLEAN,
    "notas_contexto" TEXT,

    CONSTRAINT "destrezas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dificultades" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "categoria" VARCHAR(50),
    "nivel_impacto" INTEGER,
    "descripcion" TEXT,
    "estrategia_mitigacion" TEXT,

    CONSTRAINT "dificultades_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "misiones_vida" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "descripcion" TEXT,
    "vision" TEXT,
    "prioridad" INTEGER,

    CONSTRAINT "misiones_vida_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "proyectos_estrategicos" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(200) NOT NULL,
    "descripcion" TEXT,
    "areas_ids" INTEGER[],
    "motivos_ids" INTEGER[],
    "destrezas_requeridas_ids" INTEGER[],
    "dificultades_ids" INTEGER[],
    "misiones_ids" INTEGER[],
    "justificacion_estrategica" JSONB,
    "objetivos_smart" JSONB,
    "fecha_inicio" DATE,
    "fecha_fin_estimada" DATE,
    "estado" "TipoEstadoProyecto" NOT NULL DEFAULT 'idea',
    "prioridad_global" DECIMAL(3,2),
    "score_motivacional" DECIMAL(3,2),
    "score_alineacion" DECIMAL(3,2),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "proyectos_estrategicos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tareas_estrategicas" (
    "id" SERIAL NOT NULL,
    "proyecto_id" INTEGER NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "descripcion" TEXT,
    "orden" INTEGER,
    "moscow" "TipoMoscow",
    "tiempo_estimado_horas" INTEGER,
    "nivel_riesgo" "TipoRiesgo",
    "prioridad_velocidad_perfeccion" "TipoEnfoque",
    "estado" "TipoEstadoTarea" NOT NULL DEFAULT 'por_hacer',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tareas_estrategicas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subtareas" (
    "id" SERIAL NOT NULL,
    "tarea_estrategica_id" INTEGER NOT NULL,
    "titulo" VARCHAR(255) NOT NULL,
    "completada" BOOLEAN NOT NULL DEFAULT false,
    "tiempo_estimado_minutos" INTEGER,
    "moscow" "TipoMoscow",
    "destreza_principal_id" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subtareas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "logs_generacion_ia" (
    "id" SERIAL NOT NULL,
    "proyecto_id" INTEGER,
    "tipo_generacion" VARCHAR(50),
    "modelo_ia" VARCHAR(100),
    "tokens_usados" INTEGER,
    "prompt" TEXT,
    "respuesta" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "logs_generacion_ia_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "notas_audio_transcripcionId_key" ON "notas_audio"("transcripcionId");

-- CreateIndex
CREATE INDEX "notas_audio_transcripcionId_idx" ON "notas_audio"("transcripcionId");

-- CreateIndex
CREATE INDEX "notas_audio_procesado_idx" ON "notas_audio"("procesado");

-- CreateIndex
CREATE INDEX "notas_audio_tipoDetectado_idx" ON "notas_audio"("tipoDetectado");

-- CreateIndex
CREATE INDEX "notas_audio_fechaGrabacion_idx" ON "notas_audio"("fechaGrabacion");

-- CreateIndex
CREATE INDEX "tareas_notaAudioId_idx" ON "tareas"("notaAudioId");

-- CreateIndex
CREATE INDEX "tareas_completada_idx" ON "tareas"("completada");

-- CreateIndex
CREATE INDEX "tareas_fechaVencimiento_idx" ON "tareas"("fechaVencimiento");

-- CreateIndex
CREATE INDEX "tareas_prioridad_idx" ON "tareas"("prioridad");

-- CreateIndex
CREATE INDEX "compromisos_notaAudioId_idx" ON "compromisos"("notaAudioId");

-- CreateIndex
CREATE INDEX "compromisos_cumplido_idx" ON "compromisos"("cumplido");

-- CreateIndex
CREATE INDEX "compromisos_fechaLimite_idx" ON "compromisos"("fechaLimite");

-- CreateIndex
CREATE INDEX "compromisos_personaNombre_idx" ON "compromisos"("personaNombre");

-- CreateIndex
CREATE INDEX "registros_notaAudioId_idx" ON "registros"("notaAudioId");

-- CreateIndex
CREATE INDEX "registros_fechaActividad_idx" ON "registros"("fechaActividad");

-- CreateIndex
CREATE INDEX "registros_categoria_idx" ON "registros"("categoria");

-- CreateIndex
CREATE INDEX "registros_proyecto_idx" ON "registros"("proyecto");

-- CreateIndex
CREATE INDEX "ideas_capturadas_notaAudioId_idx" ON "ideas_capturadas"("notaAudioId");

-- CreateIndex
CREATE INDEX "ideas_capturadas_implementada_idx" ON "ideas_capturadas"("implementada");

-- CreateIndex
CREATE INDEX "ideas_capturadas_categoria_idx" ON "ideas_capturadas"("categoria");

-- CreateIndex
CREATE UNIQUE INDEX "areas_vida_nombre_key" ON "areas_vida"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "motivos_personales_nombre_key" ON "motivos_personales"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "destrezas_nombre_key" ON "destrezas"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "dificultades_nombre_key" ON "dificultades"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "misiones_vida_nombre_key" ON "misiones_vida"("nombre");

-- AddForeignKey
ALTER TABLE "tareas" ADD CONSTRAINT "tareas_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES "notas_audio"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tareas" ADD CONSTRAINT "tareas_proyecto_estrategico_id_fkey" FOREIGN KEY ("proyecto_estrategico_id") REFERENCES "proyectos_estrategicos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "compromisos" ADD CONSTRAINT "compromisos_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES "notas_audio"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registros" ADD CONSTRAINT "registros_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES "notas_audio"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ideas_capturadas" ADD CONSTRAINT "ideas_capturadas_notaAudioId_fkey" FOREIGN KEY ("notaAudioId") REFERENCES "notas_audio"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ideas_capturadas" ADD CONSTRAINT "ideas_capturadas_proyecto_estrategico_id_fkey" FOREIGN KEY ("proyecto_estrategico_id") REFERENCES "proyectos_estrategicos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tareas_estrategicas" ADD CONSTRAINT "tareas_estrategicas_proyecto_id_fkey" FOREIGN KEY ("proyecto_id") REFERENCES "proyectos_estrategicos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subtareas" ADD CONSTRAINT "subtareas_tarea_estrategica_id_fkey" FOREIGN KEY ("tarea_estrategica_id") REFERENCES "tareas_estrategicas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subtareas" ADD CONSTRAINT "subtareas_destreza_principal_id_fkey" FOREIGN KEY ("destreza_principal_id") REFERENCES "destrezas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs_generacion_ia" ADD CONSTRAINT "logs_generacion_ia_proyecto_id_fkey" FOREIGN KEY ("proyecto_id") REFERENCES "proyectos_estrategicos"("id") ON DELETE SET NULL ON UPDATE CASCADE;
