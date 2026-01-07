import { PrismaClient } from '@prisma/client';
import { EstructuraProyecto } from '../types';

const prisma = new PrismaClient();

export async function guardarProyectoGenerado(
  estructura: EstructuraProyecto,
  modeloIA: string,
  tokensUsados: number,
  prompt: string,
  respuesta: string
): Promise<number> {
  return await prisma.$transaction(async (tx) => {
    // 1. Crear proyecto
    const proyecto = await tx.proyectoEstrategico.create({
      data: {
        nombre: estructura.proyecto.nombre || "Proyecto sin nombre",
        descripcion: estructura.proyecto.descripcion,
        justificacionEstrategica: estructura.proyecto.justificacion_estrategica,
        objetivosSmart: estructura.proyecto.objetivos_smart ? estructura.proyecto.objetivos_smart : undefined,
        areasIds: estructura.proyecto.areas_ids || [],
        motivosIds: estructura.proyecto.motivos_ids || [],
        destrezasRequeridasIds: estructura.proyecto.destrezas_requeridas_ids || [],
        dificultadesIds: estructura.proyecto.dificultades_ids || [],
        misionesIds: estructura.proyecto.misiones_ids || [],
        prioridadGlobal: estructura.proyecto.prioridad_global || null,
        scoreMotivacional: estructura.proyecto.score_motivacional || null,
        scoreAlineacion: estructura.proyecto.score_alineacion || null,
        estado: 'planificacion', // Changed from default 'idea' to 'planificacion'
      }
    });
    
    // 2. Crear tareas
    for (const tareaData of estructura.tareas) {
      const tarea = await tx.tareaEstrategica.create({
        data: {
          proyectoId: proyecto.id,
          nombre: tareaData.nombre,
          descripcion: tareaData.descripcion || null,
          orden: tareaData.orden,
          moscow: tareaData.moscow,
          tiempoEstimadoHoras: tareaData.tiempo_estimado_horas || null,
          nivelRiesgo: tareaData.nivel_riesgo || 'medio',
          impacto: tareaData.impacto || null,
          urgencia: tareaData.urgencia || null,
          prioridadVelocidadPerfeccion: tareaData.prioridad_velocidad_perfeccion || null,
        }
      });
      
      // 3. Crear subtareas
      if (tareaData.subtareas && tareaData.subtareas.length > 0) {
        for (const subtareaData of tareaData.subtareas) {
          await tx.subtareaEstrategica.create({
            data: {
              tareaEstrategicaId: tarea.id,
              nombre: subtareaData.titulo,
              tiempoEstimadoMinutos: subtareaData.tiempo_estimado_minutos || null,
              moscow: subtareaData.moscow || null,
            }
          });
        }
      }
    }
    
    // 4. Log de generación
    await tx.logGeneracionIA.create({
      data: {
        proyectoId: proyecto.id,
        tipoGeneracion: 'inicial',
        modeloIa: modeloIA,
        tokensUsados: tokensUsados,
        prompt: prompt,
        respuesta: respuesta,
      }
    });
    
    return proyecto.id;
  }, {
    maxWait: 30000, // 30 segundos de espera máxima
    timeout: 30000, // 30 segundos de timeout
  });
}
