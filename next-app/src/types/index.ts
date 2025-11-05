// Tipos compartidos de la aplicación

export interface ProcessAudioRequest {
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

export interface TranscriptionRecord {
  id: number;
  texto: string;
  r2_url: string | null;
  hora: Date;
}

export interface R2UploadResult {
  url: string;
  key: string;
  bucket: string;
}

export interface WhisperTranscriptionResult {
  text: string;
  language?: string;
  duration?: number;
}

export interface UploadOptions {
  filename: string;
  contentType: string;
}
