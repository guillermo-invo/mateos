import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import prisma from '@/lib/prisma';
import { uploadToR2 } from '@/lib/r2-client';
import { transcribeAudioWithRetry } from '@/lib/whisper-client';
import { logger } from '@/lib/logger';
import { ProcessAudioResponse } from '@/types';

// Validación con Zod
const requestSchema = z.object({
  telegramFileId: z.string().min(1),
  userId: z.number().int().positive(),
  messageId: z.number().int().positive(),
  duration: z.number().int().positive().optional(),
});

export async function POST(request: NextRequest): Promise<NextResponse<ProcessAudioResponse>> {
  let transcriptionId: number | undefined;

  try {
    // 1. Parse FormData
    const formData = await request.formData();
    const audioFile = formData.get('audio') as File;
    const metadataStr = formData.get('metadata') as string;

    if (!audioFile) {
      return NextResponse.json(
        { success: false, error: 'No audio file provided' },
        { status: 400 }
      );
    }

    // 2. Validar metadata
    const metadata = requestSchema.parse(JSON.parse(metadataStr));

    logger.info('Processing audio', {
      telegramFileId: metadata.telegramFileId,
      userId: metadata.userId,
      fileSize: audioFile.size,
    });

    // 3. Convertir File a Buffer
    const arrayBuffer = await audioFile.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // 4. Crear registro inicial en DB
    const transcription = await prisma.transcripcion.create({
      data: {
        texto: '', // Se actualizará después
        estado: 'PROCESANDO',
        telegram_file_id: metadata.telegramFileId,
        telegram_user_id: BigInt(metadata.userId),
        telegram_message_id: BigInt(metadata.messageId),
        duracion_segundos: metadata.duration,
        tamano_bytes: BigInt(audioFile.size),
      },
    });

    transcriptionId = transcription.id;

    // 5. Ejecutar en paralelo: Subir a R2 y Transcribir
    const [r2Result, whisperResult] = await Promise.all([
      uploadToR2(buffer, {
        filename: `audio_${transcriptionId}_${Date.now()}.ogg`,
        contentType: audioFile.type || 'audio/ogg',
      }),
      transcribeAudioWithRetry(buffer, audioFile.type || 'audio/ogg'),
    ]);

    // 6. Actualizar registro con resultados
    const updatedTranscription = await prisma.transcripcion.update({
      where: { id: transcriptionId },
      data: {
        texto: whisperResult.text,
        r2_url: r2Result.url,
        r2_key: r2Result.key,
        estado: 'COMPLETADO',
      },
    });

    logger.info('Audio processed successfully', {
      transcriptionId,
      textLength: whisperResult.text.length,
    });

    return NextResponse.json({
      success: true,
      transcriptionId: updatedTranscription.id,
      texto: updatedTranscription.texto,
    });

  } catch (error) {
    logger.error('Error processing audio', {
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
      transcriptionId,
    });

    // Marcar como error en DB si ya se creó el registro
    if (transcriptionId) {
      await prisma.transcripcion.update({
        where: { id: transcriptionId },
        data: {
          estado: 'ERROR',
          error_msg: error instanceof Error ? error.message : 'Unknown error',
        },
      }).catch(dbError => {
        logger.error('Failed to update error state', { dbError });
      });
    }

    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error',
      },
      { status: 500 }
    );
  }
}

// Health check endpoint
export async function GET() {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return NextResponse.json({
      status: 'ok',
      service: 'next-app',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: 'error',
        message: 'Database connection failed',
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 503 }
    );
  }
}
