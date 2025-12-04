import OpenAI from 'openai';
import { PrismaClient } from '@prisma/client';
import { getModelConfig } from './model-config';
import { PROMPT_SISTEMA_PROYECTO } from './ia/prompts-proyectos';
import { EstructuraProyecto } from './types';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const prisma = new PrismaClient();

// Este tipo se necesita localmente y se exporta para que index.ts lo use
export interface ProyectoData {
  id: number;
  nombre: string;
  descripcion: string | null;
  areasIds: number[];
  motivosIds: number[];
  destrezasRequeridasIds: number[];
  dificultadesIds: number[];
  misionesIds: number[];
}

/**
 * Procesa un proyecto con IA para generar análisis y tareas estratégicas
 */
export async function processProjectWithAI(
  proyectoData: ProyectoData
): Promise<EstructuraProyecto> {
  try {
    console.log(`🤖 Procesando proyecto "${proyectoData.nombre}" con IA...`);

    const modelConfig = getModelConfig('projectCreation');

    // Traer TODAS las opciones disponibles para que la IA pueda seleccionar
    const [areas, motivos, destrezas, dificultades, misiones] =
      await Promise.all([
        prisma.areasVida.findMany(),
        prisma.motivosPersonales.findMany(),
        prisma.destrezas.findMany(),
        prisma.dificultades.findMany(),
        prisma.misionesVida.findMany(),
      ]);

    const contextPersonal = {
      areasVida: areas.map((a) => ({ id: a.id, nombre: a.nombre })),
      motivosPersonales: motivos.map((m) => ({
        id: m.id,
        nombre: m.nombre,
        descripcion: m.descripcion,
      })),
      destrezas: destrezas.map((d) => ({
        id: d.id,
        nombre: d.nombre,
        nivel: d.nivelActual,
      })),
      dificultades: dificultades.map((d) => ({
        id: d.id,
        nombre: d.nombre,
        descripcion: d.descripcion,
      })),
      misiones: misiones.map((m) => ({
        id: m.id,
        nombre: m.nombre,
        descripcion: m.descripcion,
      })),
    };

    const proyectosActivos = await prisma.proyectoEstrategico.findMany({
      where: {
        estado: { in: ['planificacion', 'en_curso'] },
        id: { not: proyectoData.id },
      },
      select: { id: true, nombre: true, estado: true },
      take: 10,
    });
    
    const proyectoPropuesto = {
      id: proyectoData.id,
      nombre: proyectoData.nombre,
      descripcion: proyectoData.descripcion || 'Sin descripción',
    };

    const finalPrompt = PROMPT_SISTEMA_PROYECTO.replace(
      /{contexto_personal}/g,
      JSON.stringify(contextPersonal, null, 2)
    )
      .replace(
        /{proyectos_activos}/g,
        JSON.stringify(proyectosActivos, null, 2)
      )
      .replace(
        /{proyecto_propuesto}/g,
        JSON.stringify(proyectoPropuesto, null, 2)
      );

    const response = await openai.chat.completions.create({
      model: modelConfig.model,
      messages: [
        {
          role: 'system',
          content: finalPrompt,
        },
      ],
      temperature: modelConfig.temperature ?? 0.7,
      max_completion_tokens: modelConfig.maxTokens ?? 8000,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('OpenAI no devolvió contenido');
    }

    const analisis = JSON.parse(content) as EstructuraProyecto;

    console.log('✅ Análisis de proyecto completado');
    return analisis;
  } catch (error) {
    console.error('❌ Error procesando proyecto con IA:', error);
    throw error;
  }
}

/**
 * Guarda el análisis y las tareas estratégicas en la BD
 */
export async function saveProjectAnalysis(
  proyectoId: number,
  analisis: EstructuraProyecto
): Promise<void> {
  try {
    console.log(`💾 Guardando análisis para proyecto ${proyectoId}...`);

    const { proyecto, tareas } = analisis;

    // 1. Transformar y actualizar el proyecto principal
    await prisma.proyectoEstrategico.update({
      where: { id: proyectoId },
      data: {
        justificacionEstrategica:
          (proyecto.justificacion_estrategica as any) || {},
        objetivosSmart: (proyecto.objetivos_smart as any) || [],
        areasIds: proyecto.areas_ids || [],
        motivosIds: proyecto.motivos_ids || [],
        destrezasRequeridasIds: proyecto.destrezas_requeridas_ids || [],
        dificultadesIds: proyecto.dificultades_ids || [],
        misionesIds: proyecto.misiones_ids || [],
        prioridadGlobal: proyecto.prioridad_global || null,
        scoreMotivacional: proyecto.score_motivacional || null,
        scoreAlineacion: proyecto.score_alineacion || null,
      },
    });
    console.log('✅ Proyecto estratégico actualizado con justificación, objetivos SMART, scores y IDs.');

    // 2. Transformar y crear tareas y subtareas
    let tareasCreadasCount = 0;
    let subtareasCreadasCount = 0;

    for (const tarea of tareas) {
      const tareaCreada = await prisma.tareaEstrategica.create({
        data: {
          proyectoId: proyectoId,
          nombre: tarea.nombre,
          descripcion: tarea.descripcion || null,
          orden: tarea.orden,
          moscow: tarea.moscow,
          tiempoEstimadoHoras: tarea.tiempo_estimado_horas,
          nivelRiesgo: tarea.nivel_riesgo,
          estadoKanban: 'backlog',
          impacto: tarea.impacto || null,
          urgencia: tarea.urgencia || null,
          prioridadVelocidadPerfeccion: tarea.prioridad_velocidad_perfeccion || null,
        },
      });
      tareasCreadasCount++;

      if (tarea.subtareas && tarea.subtareas.length > 0) {
        const subtareasData = tarea.subtareas.map((sub) => ({
          tareaEstrategicaId: tareaCreada.id,
          nombre: sub.titulo,
          estadoKanban: 'backlog' as const,
          tiempoEstimadoMinutos: sub.tiempo_estimado_minutos || null,
          moscow: sub.moscow || null,
          destrezaPrincipalId: sub.destreza_principal_id || null,
        }));

        await prisma.subtareaEstrategica.createMany({
          data: subtareasData,
        });
        subtareasCreadasCount += subtareasData.length;
      }
    }

    console.log(`✅ Análisis guardado: ${tareasCreadasCount} tareas y ${subtareasCreadasCount} subtareas creadas.`);
  } catch (error) {
    console.error('❌ Error guardando análisis:', error);
    throw error;
  }
}

