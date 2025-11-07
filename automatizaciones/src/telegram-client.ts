import TelegramBot from 'node-telegram-bot-api';

// ============================================
// Cliente de Telegram
// ============================================

let bot: TelegramBot | null = null;

/**
 * Inicializa el bot de Telegram
 */
export function initTelegramBot(): TelegramBot {
  if (!process.env.TELEGRAM_BOT_TOKEN) {
    throw new Error('TELEGRAM_BOT_TOKEN no configurado');
  }

  if (!bot) {
    bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN, { polling: false });
    console.log('✅ Bot de Telegram inicializado');
  }

  return bot;
}

/**
 * Envía un mensaje de texto al usuario
 */
export async function sendMessage(chatId: number | string, text: string): Promise<void> {
  const botInstance = bot || initTelegramBot();

  try {
    await botInstance.sendMessage(chatId, text, {
      parse_mode: 'Markdown',
    });
    console.log(`✅ Mensaje enviado a chat ${chatId}`);
  } catch (error) {
    console.error(`❌ Error enviando mensaje a chat ${chatId}:`, error);
    throw error;
  }
}

/**
 * Envía un mensaje largo (puede dividirse en chunks si es necesario)
 */
export async function sendLongMessage(chatId: number | string, text: string): Promise<void> {
  const MAX_LENGTH = 4000;

  if (text.length <= MAX_LENGTH) {
    await sendMessage(chatId, text);
    return;
  }

  // Dividir en chunks
  const chunks: string[] = [];
  let currentChunk = '';

  const lines = text.split('\n');

  for (const line of lines) {
    if (currentChunk.length + line.length + 1 > MAX_LENGTH) {
      chunks.push(currentChunk);
      currentChunk = line;
    } else {
      currentChunk += (currentChunk ? '\n' : '') + line;
    }
  }

  if (currentChunk) {
    chunks.push(currentChunk);
  }

  // Enviar cada chunk
  for (let i = 0; i < chunks.length; i++) {
    const prefix = chunks.length > 1 ? `*(${i + 1}/${chunks.length})*\n\n` : '';
    await sendMessage(chatId, prefix + chunks[i]);

    // Pequeña pausa entre mensajes para evitar rate limiting
    if (i < chunks.length - 1) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
}
