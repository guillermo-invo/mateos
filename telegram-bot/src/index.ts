import TelegramBot from 'node-telegram-bot-api';
import axios from 'axios';
import FormData from 'form-data';
import { logger } from './logger';
import { ProcessAudioResponse } from './types';

// Validar variables de entorno
if (!process.env.TELEGRAM_BOT_TOKEN) {
  throw new Error('Missing TELEGRAM_BOT_TOKEN');
}

if (!process.env.API_ENDPOINT) {
  throw new Error('Missing API_ENDPOINT');
}

const bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN, { polling: true });
const API_ENDPOINT = process.env.API_ENDPOINT;

logger.info('Telegram bot started', { endpoint: API_ENDPOINT });

// Comando /start
bot.onText(/\/start/, (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(
    chatId,
    '¡Hola! 👋\n\nSoy un bot de transcripción de notas de voz.\n\nEnvíame una nota de voz y la transcribiré para ti usando Whisper AI. 🎤\n\nComandos disponibles:\n/start - Ver este mensaje\n/help - Ayuda'
  );
});

// Comando /help
bot.onText(/\/help/, (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(
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
});

// Handler para notas de voz
bot.on('voice', async (msg) => {
  const chatId = msg.chat.id;
  const voice = msg.voice;

  if (!voice) return;

  try {
    logger.info('Received voice message', {
      userId: msg.from?.id,
      messageId: msg.message_id,
      fileId: voice.file_id,
      duration: voice.duration,
    });

    // Enviar mensaje de "procesando"
    const processingMsg = await bot.sendMessage(
      chatId,
      '⏳ Procesando tu nota de voz...\n\nEsto puede tomar unos segundos.'
    );

    // 1. Obtener URL del archivo de Telegram
    const fileLink = await bot.getFileLink(voice.file_id);

    logger.info('Got file link from Telegram', { fileLink });

    // 2. Descargar el audio
    const audioResponse = await axios.get(fileLink, {
      responseType: 'arraybuffer',
    });

    logger.info('Downloaded audio file', { size: audioResponse.data.length });

    // 3. Preparar FormData
    const formData = new FormData();
    formData.append('audio', Buffer.from(audioResponse.data), {
      filename: 'voice.ogg',
      contentType: 'audio/ogg',
    });

    formData.append(
      'metadata',
      JSON.stringify({
        telegramFileId: voice.file_id,
        userId: msg.from?.id || 0,
        messageId: msg.message_id,
        duration: voice.duration,
      })
    );

    // 4. Enviar a la API de Next.js
    logger.info('Sending to API', { endpoint: API_ENDPOINT });

    const apiResponse = await axios.post<ProcessAudioResponse>(
      API_ENDPOINT,
      formData,
      {
        headers: formData.getHeaders(),
        timeout: 120000, // 120 segundos (2 minutos)
      }
    );

    logger.info('API response received', {
      success: apiResponse.data.success,
      transcriptionId: apiResponse.data.transcriptionId,
    });

    // 5. Responder al usuario
    if (apiResponse.data.success && apiResponse.data.texto) {
      await bot.deleteMessage(chatId, processingMsg.message_id);

      // Dividir en mensajes si es muy largo (Telegram límite: 4096 caracteres)
      const texto = apiResponse.data.texto;
      const maxLength = 4000;

      if (texto.length <= maxLength) {
        await bot.sendMessage(
          chatId,
          `✅ *Transcripción completada:*\n\n${texto}`,
          { parse_mode: 'Markdown' }
        );
      } else {
        // Enviar en múltiples mensajes
        await bot.sendMessage(
          chatId,
          `✅ *Transcripción completada (mensaje largo):*`,
          { parse_mode: 'Markdown' }
        );

        for (let i = 0; i < texto.length; i += maxLength) {
          const chunk = texto.substring(i, i + maxLength);
          await bot.sendMessage(chatId, chunk);
        }
      }

      logger.info('Voice processed successfully', {
        transcriptionId: apiResponse.data.transcriptionId,
        userId: msg.from?.id,
      });
    } else {
      throw new Error(apiResponse.data.error || 'Unknown error');
    }
  } catch (error) {
    logger.error('Error processing voice', {
      error: error instanceof Error ? error.message : 'Unknown error',
      userId: msg.from?.id,
      stack: error instanceof Error ? error.stack : undefined,
    });

    await bot.sendMessage(
      chatId,
      '❌ Lo siento, hubo un error al procesar tu nota de voz.\n\n' +
      'Por favor, intenta de nuevo en unos momentos.\n\n' +
      'Si el problema persiste, contacta al administrador.'
    );
  }
});

// Handler para archivos de audio
bot.on('audio', async (msg) => {
  const chatId = msg.chat.id;
  const audio = msg.audio;

  if (!audio) return;

  try {
    logger.info('Received audio file', {
      userId: msg.from?.id,
      messageId: msg.message_id,
      fileId: audio.file_id,
      duration: audio.duration,
      mimeType: audio.mime_type,
    });

    const processingMsg = await bot.sendMessage(
      chatId,
      '⏳ Procesando tu archivo de audio...'
    );

    const fileLink = await bot.getFileLink(audio.file_id);
    const audioResponse = await axios.get(fileLink, {
      responseType: 'arraybuffer',
    });

    const formData = new FormData();
    formData.append('audio', Buffer.from(audioResponse.data), {
      filename: 'audio.mp3',
      contentType: audio.mime_type || 'audio/mpeg',
    });

    formData.append(
      'metadata',
      JSON.stringify({
        telegramFileId: audio.file_id,
        userId: msg.from?.id || 0,
        messageId: msg.message_id,
        duration: audio.duration,
      })
    );

    const apiResponse = await axios.post<ProcessAudioResponse>(
      API_ENDPOINT,
      formData,
      {
        headers: formData.getHeaders(),
        timeout: 120000,
      }
    );

    if (apiResponse.data.success && apiResponse.data.texto) {
      await bot.deleteMessage(chatId, processingMsg.message_id);

      const texto = apiResponse.data.texto;
      const maxLength = 4000;

      if (texto.length <= maxLength) {
        await bot.sendMessage(
          chatId,
          `✅ *Transcripción completada:*\n\n${texto}`,
          { parse_mode: 'Markdown' }
        );
      } else {
        await bot.sendMessage(
          chatId,
          `✅ *Transcripción completada (mensaje largo):*`,
          { parse_mode: 'Markdown' }
        );

        for (let i = 0; i < texto.length; i += maxLength) {
          const chunk = texto.substring(i, i + maxLength);
          await bot.sendMessage(chatId, chunk);
        }
      }

      logger.info('Audio processed successfully', {
        transcriptionId: apiResponse.data.transcriptionId,
        userId: msg.from?.id,
      });
    } else {
      throw new Error(apiResponse.data.error || 'Unknown error');
    }
  } catch (error) {
    logger.error('Error processing audio', {
      error: error instanceof Error ? error.message : 'Unknown error',
      userId: msg.from?.id,
    });

    await bot.sendMessage(
      chatId,
      '❌ Lo siento, hubo un error al procesar tu archivo de audio. Por favor, intenta de nuevo.'
    );
  }
});

// Handler de errores
bot.on('polling_error', (error) => {
  logger.error('Polling error', { error: error.message });
});

// Graceful shutdown
process.on('SIGINT', () => {
  logger.info('Stopping bot...');
  bot.stopPolling();
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('Stopping bot...');
  bot.stopPolling();
  process.exit(0);
});

logger.info('Bot is running and waiting for messages...');
