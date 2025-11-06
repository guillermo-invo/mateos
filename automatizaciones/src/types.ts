// ============================================
// Tipos para Webhook
// ============================================

export interface WebhookPayload {
  transcripcionId: number;
  texto: string;
  archivoUrl?: string;
  fecha: string;
}

// ============================================
// Tipos para Detección de Keywords
// ============================================

export type TipoMensaje = 'tarea' | 'registro' | 'idea' | 'compromiso' | 'sin_clasificar';

export interface DetectionResult {
  tipo: TipoMensaje;
  textoLimpio: string;
  confianza: number;
  keywordDetectada?: string;
}

// ============================================
// Tipos para Entidades Extraídas por IA
// ============================================

export interface TareaExtraida {
  titulo: string;
  descripcion?: string;
  fecha_vencimiento?: string; // ISO date
  prioridad: 'ALTA' | 'MEDIA' | 'BAJA' | 'URGENTE';
}

export interface CompromisoExtraido {
  titulo: string;
  descripcion?: string;
  persona: string;
  fecha_limite?: string; // ISO date
  yo_me_comprometi: boolean;
}

export interface RegistroExtraido {
  descripcion: string;
  duracion_horas?: number;
  proyecto?: string;
  personas_involucradas?: string[];
  categoria: 'TRABAJO' | 'PERSONAL' | 'SOCIAL' | 'OTRO';
}

export interface IdeaExtraida {
  titulo: string;
  descripcion?: string;
  categoria?: string;
}

export interface ExtraccionIA {
  tipo: TipoMensaje;
  tarea?: TareaExtraida;
  compromiso?: CompromisoExtraido;
  registro?: RegistroExtraido;
  idea?: IdeaExtraida;
}

// ============================================
// Tipos para Respuestas
// ============================================

export interface ProcessorResult {
  success: boolean;
  notaAudioId?: number;
  tipo: TipoMensaje;
  entidadesCreadas?: {
    tareas?: number;
    compromisos?: number;
    registros?: number;
    ideas?: number;
  };
  error?: string;
}
