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

export type TipoMensaje = 'tarea' | 'registro' | 'idea' | 'compromiso' | 'sin_clasificar' | 'proyecto';

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
  proyecto_nombre?: string; // Nombre del proyecto o "otros"
  personas_involucradas?: string[];
  area_vida_nombre: string; // Nombre del área de vida (debe existir en BD)
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

// ============================================
// Tipos para Generación de Proyectos por IA
// ============================================

export interface EstructuraProyecto {
  proyecto: ProyectoGenerado;
  tareas: TareaGenerada[];
}

export interface ProyectoGenerado {
  justificacion_estrategica: Record<string, any>; // JSONB type
  objetivos_smart?: Array<{
    specific: string;
    measurable: string;
    achievable: string;
    relevant: string;
    timebound: string;
  }>;
  areas_ids: number[];
  motivos_ids: number[];
  destrezas_requeridas_ids: number[];
  dificultades_ids: number[];
  misiones_ids: number[];
  prioridad_global?: number;
  score_motivacional?: number;
  score_alineacion?: number;
  nombre?: string;
  descripcion?: string;
}

export interface TareaGenerada {
  nombre: string;
  descripcion?: string;
  orden: number;
  moscow: 'must' | 'should' | 'could' | 'wont';
  tiempo_estimado_horas: number;
  nivel_riesgo: 'bajo' | 'medio' | 'alto' | 'critico';
  impacto?: 'alto' | 'medio' | 'bajo';
  urgencia?: 'alta' | 'media' | 'baja';
  prioridad_velocidad_perfeccion?: 'velocidad' | 'perfeccion' | 'balanceado';
  subtareas: SubtareaGenerada[];
}

export interface SubtareaGenerada {
  titulo: string;
  tiempo_estimado_minutos?: number;
  moscow?: 'must' | 'should' | 'could' | 'wont';
  destreza_principal_id?: number | null;
}