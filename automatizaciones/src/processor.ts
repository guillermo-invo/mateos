import { WebhookPayload, ProcessorResult } from './types';
import { detectTipoFromTranscription } from './keyword-matcher';
import { extractEntities, validateExtraction } from './ai-extractor';
import { createNotaAudio, saveExtraction, isTranscripcionProcessed } from './db-writer';

// ============================================
// Procesador Principal
// ============================================

/**
 * Procesa una transcripción completa:
 * 1. Detecta tipo con fuzzy matching
 * 2. Extrae entidades con OpenAI
 * 3. Guarda en BD extendida
 */
export async function processTranscription(payload: WebhookPayload): Promise<ProcessorResult> {
  console.log('\n🔧 ===== INICIANDO PROCESAMIENTO =====');
  console.log(`📋 Transcripción ID: ${payload.transcripcionId}`);
  console.log(`📝 Texto: "${payload.texto.substring(0, 100)}..."`);

  try {
    // Verificar si ya fue procesado
    const yaProcessed = await isTranscripcionProcessed(payload.transcripcionId);
    if (yaProcessed) {
      console.log('⚠️ Esta transcripción ya fue procesada, ignorando...');
      return {
        success: false,
        tipo: 'sin_clasificar',
        error: 'Ya procesado anteriormente',
      };
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

    // Si no se clasificó, guardar y terminar
    if (detection.tipo === 'sin_clasificar') {
      console.log('⚠️ No se detectó keyword, guardando como sin_clasificar');
      return {
        success: true,
        notaAudioId: notaAudio.id,
        tipo: 'sin_clasificar',
      };
    }

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
