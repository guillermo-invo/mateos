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
        areasIds: estructura.proyecto.areas_ids,
        motivosIds: estructura.proyecto.motivos_ids,
        destrezasRequeridasIds: estructura.proyecto.destrezas_requeridas_ids,
        dificultadesIds: estructura.proyecto.dificultades_ids,
        misionesIds: estructura.proyecto.misiones_ids,
        scoreMotivacional: estructura.proyecto.score_motivacional,
        scoreAlineacion: estructura.proyecto.score_alineacion,
      }
    });
    
    // 2. Crear tareas
    for (const tareaData of estructura.tareas) {
      const tarea = await tx.tareaEstrategica.create({
        data: {
          proyectoId: proyecto.id,
          nombre: tareaData.nombre,
          orden: tareaData.orden,
          moscow: tareaData.moscow,
          tiempoEstimadoHoras: tareaData.tiempo_estimado_horas,
          nivelRiesgo: tareaData.nivel_riesgo,
        }
      });
      
      // 3. Crear subtareas
      for (const subtareaData of tareaData.subtareas) {
        await tx.subtareaEstrategica.create({
          data: {
            tareaEstrategicaId: tarea.id,
            nombre: subtareaData.titulo,
          }
        });
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
  });
}
