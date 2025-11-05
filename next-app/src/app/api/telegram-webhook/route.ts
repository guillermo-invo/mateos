import { NextRequest, NextResponse } from 'next/server';
import TelegramBot from 'node-telegram-bot-api';
import axios from 'axios';
import FormData from 'form-data';
import { logger } from '@/lib/logger';
import { ProcessAudioResponse } from '@/types';

// La URL base de tu propia aplicación para llamar al otro endpoint
const NEXT_APP_URL = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';

// Lazy initialization del bot
let bot: TelegramBot | null = null;

function getBot(): TelegramBot {
  if (!process.env.TELEGRAM_BOT_TOKEN) {
    throw new Error('Missing TELEGRAM_BOT_TOKEN');
  }

  if (!bot) {
    bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN);
  }

  return bot;
}

// =================================================================
// Handler principal de Webhook
// =================================================================
export async function POST(request: NextRequest) {
  try {
    const update: TelegramBot.Update = await request.json();
    logger.info('Received update from Telegram', { updateId: update.update_id });

    // Procesar el update en segundo plano para responder rápido a Telegram
    handleUpdate(update).catch(error => {
      logger.error('Error handling update in background', {
        error: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : undefined,
      });
    });

    // Responder inmediatamente a Telegram con un 200 OK
    return NextResponse.json({ status: 'ok' });

  } catch (error) {
    logger.error('Error in webhook POST handler', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    return NextResponse.json(
      { success: false, error: 'Failed to process update' },
      { status: 500 }
    );
  }
}

// =================================================================
// Lógica para procesar cada tipo de update
// =================================================================
async function handleUpdate(update: TelegramBot.Update) {
  const message = update.message;

  if (!message) {
    logger.warn('Update without message received', { update });
    return;
  }

  const chatId = message.chat.id;
  const botInstance = getBot();

  // Manejar comandos de texto
  if (message.text) {
    if (message.text.startsWith('/start')) {
      return botInstance.sendMessage(
        chatId,
        '¡Hola! 👋\n\nSoy un bot de transcripción de notas de voz.\n\nEnvíame una nota de voz y la transcribiré para ti usando Whisper AI. 🎤\n\nComandos disponibles:\n/start - Ver este mensaje\n/help - Ayuda'
      );
    }
    if (message.text.startsWith('/help')) {
      return botInstance.sendMessage(
        chatId,
        '📝 *Cómo usar este bot:*\n\n' +
        '1. Envía una nota de voz\n' +
        '2. Espera a que se procese\n' +
        '3. Recibirás la transcripción\n\n' +
        'Formatos soportados:\n' +
        '• Notas de voz de Telegram\n' +
        '• Archivos de audio (MP3, OGG, WAV, M4A)',
        { parse_mode: 'Markdown' }
      );
    }
  }

  // Manejar notas de voz o archivos de audio
  const voice = message.voice;
  const audio = message.audio;

  if (voice || audio) {
    const fileId = voice?.file_id || audio?.file_id!;
    const duration = voice?.duration || audio?.duration!;
    const mimeType = voice?.mime_type || audio?.mime_type || 'audio/ogg';
    const type = voice ? 'voice' : 'audio';

    await processAudioMessage(chatId, message.message_id, fileId, duration, mimeType, type, message.from);
  }
}

// =================================================================
// Lógica para procesar un mensaje con audio
// =================================================================
async function processAudioMessage(
  chatId: number,
  messageId: number,
  fileId: string,
  duration: number,
  mimeType: string,
  type: 'voice' | 'audio',
  from: TelegramBot.User | undefined
) {
  let processingMsg: TelegramBot.Message | undefined;
  const botInstance = getBot();

  try {
    logger.info(`Received ${type} message`, {
      userId: from?.id,
      messageId: messageId,
      fileId: fileId,
    });

    processingMsg = await botInstance.sendMessage(
      chatId,
      `⏳ Procesando tu ${type === 'voice' ? 'nota de voz' : 'archivo de audio'}...`
    );

    // 1. Obtener URL del archivo de Telegram
    const fileLink = await botInstance.getFileLink(fileId);
    logger.info('Got file link from Telegram', { fileLink });

    // 2. Descargar el audio
    const audioResponse = await axios.get(fileLink, { responseType: 'arraybuffer' });
    const audioBuffer = Buffer.from(audioResponse.data);
    logger.info('Downloaded audio file', { size: audioBuffer.length });

    // 3. Preparar FormData para enviar al endpoint de procesamiento
    const formData = new FormData();
    formData.append('audio', audioBuffer, {
      filename: `audio.${mimeType.split('/')[1] || 'ogg'}`,
      contentType: mimeType,
    });
    formData.append(
      'metadata',
      JSON.stringify({
        telegramFileId: fileId,
        userId: from?.id || 0,
        messageId: messageId,
        duration: duration,
      })
    );

    // 4. Enviar a la API interna de Next.js (/api/process-audio)
    const endpoint = `${NEXT_APP_URL}/api/process-audio`;
    logger.info('Sending to internal API', { endpoint });

    const apiResponse = await axios.post<ProcessAudioResponse>(endpoint, formData, {
      headers: formData.getHeaders(),
      timeout: 120000, // 2 minutos
    });

    // 5. Responder al usuario
    if (processingMsg) {
      await botInstance.deleteMessage(chatId, processingMsg.message_id);
    }

    if (apiResponse.data.success && apiResponse.data.texto) {
      const texto = apiResponse.data.texto;
      const maxLength = 4000;

      if (texto.length <= maxLength) {
        await botInstance.sendMessage(chatId, `✅ *Transcripción completada:*\n\n${texto}`, { parse_mode: 'Markdown' });
      } else {
        await botInstance.sendMessage(chatId, `✅ *Transcripción completada (mensaje largo):*`, { parse_mode: 'Markdown' });
        for (let i = 0; i < texto.length; i += maxLength) {
          const chunk = texto.substring(i, i + maxLength);
          await botInstance.sendMessage(chatId, chunk);
        }
      }
      logger.info('Audio processed successfully', { transcriptionId: apiResponse.data.transcriptionId });
    } else {
      throw new Error(apiResponse.data.error || 'Unknown error from process-audio API');
    }
  } catch (error) {
    logger.error(`Error processing ${type}`, {
      error: error instanceof Error ? error.message : 'Unknown error',
      userId: from?.id,
      stack: error instanceof Error ? error.stack : undefined,
    });

    if (processingMsg) {
      await botInstance.deleteMessage(chatId, processingMsg.message_id);
    }

    await botInstance.sendMessage(
      chatId,
      '❌ Lo siento, hubo un error al procesar tu audio. Por favor, intenta de nuevo.'
    );
  }
}
