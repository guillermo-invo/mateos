import { PrismaClient, Prioridad, Categoria } from '@prisma/client';
import { ExtraccionIA, DetectionResult } from './types';

const prisma = new PrismaClient();

// ============================================
// Funciones de Escritura en BD
// ============================================

/**
 * Crea NotaAudio en la BD extendida
 */
export async function createNotaAudio(
  transcripcionId: number,
  transcripcion: string,
  archivoUrl: string | undefined,
  detection: DetectionResult
) {
  console.log(`💾 Creando NotaAudio para transcripcionId: ${transcripcionId}`);

  const notaAudio = await prisma.notaAudio.create({
    data: {
      transcripcionId,
      transcripcionCompleta: transcripcion,
      archivoAudioUrl: archivoUrl,
      tipoDetectado: detection.tipo,
      confianzaDeteccion: detection.confianza,
      procesado: false,
    },
  });

  console.log(`✅ NotaAudio creada con ID: ${notaAudio.id}`);
  return notaAudio;
}

/**
 * Guarda la extracción de IA en las tablas correspondientes
 */
export async function saveExtraction(notaAudioId: number, extraccion: ExtraccionIA) {
  const entidadesCreadas = {
    tareas: 0,
    compromisos: 0,
    registros: 0,
    ideas: 0,
  };

  try {
    switch (extraccion.tipo) {
      case 'tarea':
        if (extraccion.tarea) {
          await prisma.tarea.create({
            data: {
              notaAudioId,
              titulo: extraccion.tarea.titulo,
              descripcion: extraccion.tarea.descripcion || null,
              fechaVencimiento: extraccion.tarea.fecha_vencimiento
                ? new Date(extraccion.tarea.fecha_vencimiento)
                : null,
              prioridad: extraccion.tarea.prioridad as Prioridad,
              completada: false,
            },
          });
          entidadesCreadas.tareas = 1;
          console.log('✅ Tarea creada');
        }
        break;

      case 'registro':
        if (extraccion.registro) {
          await prisma.registro.create({
            data: {
              notaAudioId,
              descripcion: extraccion.registro.descripcion,
              duracionHoras: extraccion.registro.duracion_horas || null,
              proyecto: extraccion.registro.proyecto || null,
              personasInvolucradas: extraccion.registro.personas_involucradas || [],
              categoria: extraccion.registro.categoria as Categoria,
              fechaActividad: new Date(),
            },
          });
          entidadesCreadas.registros = 1;
          console.log('✅ Registro creado');
        }
        break;

      case 'compromiso':
        if (extraccion.compromiso) {
          await prisma.compromiso.create({
            data: {
              notaAudioId,
              titulo: extraccion.compromiso.titulo,
              descripcion: extraccion.compromiso.descripcion || null,
              personaNombre: extraccion.compromiso.persona,
              fechaLimite: extraccion.compromiso.fecha_limite
                ? new Date(extraccion.compromiso.fecha_limite)
                : null,
              yoMeComprometi: extraccion.compromiso.yo_me_comprometi,
              cumplido: false,
            },
          });
          entidadesCreadas.compromisos = 1;
          console.log('✅ Compromiso creado');
        }
        break;

      case 'idea':
        if (extraccion.idea) {
          await prisma.ideaCapturada.create({
            data: {
              notaAudioId,
              titulo: extraccion.idea.titulo,
              descripcion: extraccion.idea.descripcion || null,
              categoria: extraccion.idea.categoria || null,
              implementada: false,
            },
          });
          entidadesCreadas.ideas = 1;
          console.log('✅ Idea creada');
        }
        break;
    }

    // Marcar NotaAudio como procesado
    await prisma.notaAudio.update({
      where: { id: notaAudioId },
      data: { procesado: true },
    });

    console.log('✅ NotaAudio marcada como procesada');
    return entidadesCreadas;
  } catch (error) {
    console.error('❌ Error guardando extracción:', error);
    throw error;
  }
}

/**
 * Verifica si una transcripción ya fue procesada
 */
export async function isTranscripcionProcessed(transcripcionId: number): Promise<boolean> {
  const existing = await prisma.notaAudio.findUnique({
    where: { transcripcionId },
  });
  return !!existing;
}

/**
 * Cierra la conexión de Prisma (para shutdown graceful)
 */
export async function disconnectDB() {
  await prisma.$disconnect();
}
