import OpenAI from 'openai';
import { logger } from './logger';
import { WhisperTranscriptionResult } from '@/types';

// OpenAI client lazy initialization
let openai: OpenAI | null = null;

function getOpenAIClient(): OpenAI {
  if (openai) return openai;

  if (!process.env.OPENAI_API_KEY) {
    throw new Error('Missing OPENAI_API_KEY environment variable');
  }

  openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
  });

  return openai;
}

export async function transcribeAudio(
  audioBuffer: Buffer,
  mimeType: string
): Promise<WhisperTranscriptionResult> {
  try {
    logger.info('Starting Whisper transcription', {
      bufferSize: audioBuffer.length,
      mimeType,
    });

    // Determinar extensión del archivo
    let extension = 'ogg';
    if (mimeType.includes('mp3') || mimeType.includes('mpeg')) {
      extension = 'mp3';
    } else if (mimeType.includes('mp4') || mimeType.includes('m4a')) {
      extension = 'm4a';
    } else if (mimeType.includes('wav')) {
      extension = 'wav';
    } else if (mimeType.includes('webm')) {
      extension = 'webm';
    }

    // Crear File object para la API de OpenAI
    // Convertir Buffer a ArrayBuffer para compatibilidad con File API
    const arrayBuffer = audioBuffer.buffer.slice(
      audioBuffer.byteOffset,
      audioBuffer.byteOffset + audioBuffer.byteLength
    ) as ArrayBuffer;
    const file = new File([arrayBuffer], `audio.${extension}`, { type: mimeType });

    const client = getOpenAIClient();

    const transcription = await client.audio.transcriptions.create({
      file: file,
      model: 'whisper-1',
      language: 'es', // Español por defecto
      response_format: 'json',
    });

    logger.info('Whisper transcription completed', {
      textLength: transcription.text.length,
    });

    return {
      text: transcription.text,
      language: 'es',
    };
  } catch (error) {
    logger.error('Error in Whisper transcription', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    throw new Error(
      `Whisper transcription failed: ${error instanceof Error ? error.message : 'Unknown'}`
    );
  }
}

// Función con retry logic
export async function transcribeAudioWithRetry(
  audioBuffer: Buffer,
  mimeType: string,
  maxRetries: number = 2
): Promise<WhisperTranscriptionResult> {
  let lastError: Error;
  let delay = 1000;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await transcribeAudio(audioBuffer, mimeType);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error('Unknown error');

      if (attempt === maxRetries) {
        break;
      }

      logger.warn(`Transcription attempt ${attempt + 1} failed, retrying in ${delay}ms`, {
        error: lastError.message,
      });

      await new Promise(resolve => setTimeout(resolve, delay));
      delay *= 2; // Exponential backoff
    }
  }

  throw lastError!;
}
