import { WebhookPayload, ProcessorResult, TipoMensaje } from './types';
import { detectTipoFromTranscription } from './keyword-matcher';
import { extractEntities, validateExtraction } from './ai-extractor';
import { createNotaAudio, saveExtraction, isTranscripcionProcessed } from './db-writer';
import { PrismaClient } from '@prisma/client'; // Added PrismaClient import

const prisma = new PrismaClient(); // Initialize Prisma client

// ============================================
// Procesador Principal
// ============================================

/**
 * Procesa una transcripción completa:
 * 1. Detecta tipo con fuzzy matching
 * 2. Extrae entidades con OpenAI
 * 3. Guarda en BD extendida
 */
export async function processTranscription(payload: WebhookPayload, forceReprocess: boolean = false): Promise<ProcessorResult> {
  console.log('\n🔧 ===== INICIANDO PROCESAMIENTO =====');
  console.log(`📋 Transcripción ID: ${payload.transcripcionId}`);
  console.log(`📝 Texto: "${payload.texto.substring(0, 100)}..."`);
  if (forceReprocess) {
    console.log('🔄 Modo reprocesamiento forzado');
  }

  try {
    // Verificar si ya fue procesado (saltar si forceReprocess=true)
    if (!forceReprocess) {
      const yaProcessed = await isTranscripcionProcessed(payload.transcripcionId);
      if (yaProcessed) {
        console.log('⚠️ Esta transcripción ya fue procesada, ignorando...');
        return {
          success: false,
          tipo: 'sin_clasificar',
          error: 'Ya procesado anteriormente',
        };
      }
    }

    // Paso 1: Detectar tipo con keyword matching
    console.log('\n🔍 Paso 1: Detectando tipo...');
    const detection = detectTipoFromTranscription(payload.texto);

    console.log(`📊 Resultado: ${detection.tipo} (${Math.round(detection.confianza * 100)}%)`);
    console.log(`✂️ Texto limpio: "${detection.textoLimpio}"`);

    // Paso 2: Crear NotaAudio en BD
    console.log('\n💾 Paso 2: Creando NotaAudio...');
    const notaAudio = await createNotaAudio(
      payload.transcripcionId,
      payload.texto,
      payload.archivoUrl,
      detection
    );

    // Handle different types of messages
    if (detection.tipo === 'sin_clasificar') {
      console.log('⚠️ No se detectó keyword, guardando como sin_clasificar');
      return {
        success: true,
        notaAudioId: notaAudio.id,
        tipo: 'sin_clasificar',
      };
    } else if (detection.tipo === 'proyecto') {
        console.log('💡 Detectada idea de proyecto, creando IdeaCapturada...');
        const ideaId = await crearIdeaProyecto(detection.textoLimpio, notaAudio.id);
        await enviarNotificacion("💡 Idea de proyecto capturada. ¡Puedes desarrollarla en MATEOS!");
        return {
          success: true,
          notaAudioId: notaAudio.id,
          tipo: 'proyecto',
          entidadesCreadas: { ideas: 1 },
        };
    } else { // For 'tarea', 'registro', 'compromiso', 'idea' (classic extraction)
        // Paso 3: Extraer entidades con IA
        console.log(`\n🧠 Paso 3: Extrayendo ${detection.tipo} con OpenAI...`);
        const extraccion = await extractEntities(detection.textoLimpio, detection.tipo);

        if (!extraccion) {
          console.log('❌ No se pudo extraer entidades');
          return {
            success: false,
            notaAudioId: notaAudio.id,
            tipo: detection.tipo,
            error: 'Extracción falló',
          };
        }

        // Validar extracción
        const isValid = validateExtraction(extraccion);
        if (!isValid) {
          console.log('❌ Extracción inválida (faltan campos requeridos)');
          return {
            success: false,
            notaAudioId: notaAudio.id,
            tipo: detection.tipo,
            error: 'Extracción inválida',
          };
        }

        // Paso 4: Guardar en BD
        console.log('\n💾 Paso 4: Guardando entidades en BD...');
        const entidadesCreadas = await saveExtraction(notaAudio.id, extraccion);

        console.log('\n✅ ===== PROCESAMIENTO COMPLETADO =====');
        console.log(`📊 Entidades creadas:`, entidadesCreadas);

        return {
          success: true,
          notaAudioId: notaAudio.id,
          tipo: detection.tipo,
          entidadesCreadas,
        };
    }
  } catch (error) {
    console.error('\n❌ ===== ERROR EN PROCESAMIENTO =====');
    console.error(error);

    return {
      success: false,
      tipo: 'sin_clasificar',
      error: error instanceof Error ? error.message : 'Error desconocido',
    };
  }
}

async function crearIdeaProyecto(texto: string, notaAudioId: number): Promise<number> {
  const titulo = extraerTituloProyecto(texto);
  const idea = await prisma.ideaCapturada.create({
    data: {
      notaAudioId: notaAudioId,
      titulo: titulo,
      descripcion: texto,
      categoria: 'proyecto_potencial',
      // otros campos se dejan con sus valores por defecto
    }
  });
  return idea.id;
}

function extraerTituloProyecto(texto: string): string {
  // Simple heuristic: take the first sentence or first few words
  const firstSentence = texto.split('. ')[0];
  if (firstSentence.length > 50) {
    return firstSentence.substring(0, 50) + '...';
  }
  return firstSentence;
}

async function enviarNotificacion(mensaje: string): Promise<void> {
  console.log(`🔔 Notificación: ${mensaje}`);
  // Placeholder: In a real app, this would integrate with a notification service (e.g., Telegram, email).
}
