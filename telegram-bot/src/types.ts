// Tipos compartidos para el bot de Telegram

export interface ProcessAudioMetadata {
  telegramFileId: string;
  userId: number;
  messageId: number;
  duration?: number;
}

export interface ProcessAudioResponse {
  success: boolean;
  transcriptionId?: number;
  texto?: string;
  error?: string;
}
