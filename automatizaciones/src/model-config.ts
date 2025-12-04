import fs from 'fs';
import path from 'path';

// ============================================
// Tipos de configuración de modelos
// ============================================

export interface ModelConfig {
  model: string;
  temperature?: number;
  maxTokens?: number;
  description?: string;
}

export interface ModelsConfiguration {
  transcription: ModelConfig;
  extraction: ModelConfig;
  projectCreation: ModelConfig;
  dailySummary: ModelConfig;
}

// ============================================
// Lectura de configuración
// ============================================

let cachedConfig: ModelsConfiguration | null = null;
let lastReadTime: number = 0;
const CACHE_TTL = 5000; // 5 segundos - permite cambios sin restart

/**
 * Lee la configuración de modelos desde el archivo JSON
 * Usa cache con TTL de 5 segundos para permitir cambios sin restart
 */
export function getModelsConfig(): ModelsConfiguration {
  const now = Date.now();

  // Si tenemos cache válido, lo usamos
  if (cachedConfig && (now - lastReadTime) < CACHE_TTL) {
    return cachedConfig;
  }

  try {
    // Buscar el archivo en múltiples ubicaciones
    const possiblePaths = [
      '/app/models-config.json', // Docker
      path.join(process.cwd(), 'models-config.json'), // Desarrollo
      path.join(__dirname, '../models-config.json'), // Relativo a src
    ];

    let configPath: string | null = null;
    for (const p of possiblePaths) {
      if (fs.existsSync(p)) {
        configPath = p;
        break;
      }
    }

    if (!configPath) {
      console.warn('⚠️ models-config.json no encontrado, usando valores por defecto');
      return getDefaultConfig();
    }

    const fileContent = fs.readFileSync(configPath, 'utf-8');
    const config = JSON.parse(fileContent) as ModelsConfiguration;

    // Actualizar cache
    cachedConfig = config;
    lastReadTime = now;

    console.log('✅ Configuración de modelos cargada:', {
      transcription: config.transcription.model,
      extraction: config.extraction.model,
      projectCreation: config.projectCreation.model,
      dailySummary: config.dailySummary.model,
    });

    return config;
  } catch (error) {
    console.error('❌ Error leyendo models-config.json:', error);
    console.warn('⚠️ Usando valores por defecto');
    return getDefaultConfig();
  }
}

/**
 * Obtiene la configuración de un modelo específico por función
 */
export function getModelConfig(modelType: keyof ModelsConfiguration): ModelConfig {
  const config = getModelsConfig();
  return config[modelType];
}

/**
 * Configuración por defecto (fallback)
 */
function getDefaultConfig(): ModelsConfiguration {
  return {
    transcription: {
      model: 'whisper-1',
      description: 'Modelo para transcripción de audio',
    },
    extraction: {
      model: process.env.OPENAI_MODEL || 'gpt-5-mini',
      temperature: parseFloat(process.env.OPENAI_TEMPERATURE || '0'),
      maxTokens: parseInt(process.env.OPENAI_MAX_TOKENS || '4000', 10),
      description: 'Modelo para clasificar y extraer entidades del bot',
    },
    projectCreation: {
      model: 'gpt-5.1',
      temperature: 0.7,
      maxTokens: 8000,
      description: 'Modelo para crear proyectos estratégicos',
    },
    dailySummary: {
      model: process.env.OPENAI_DAILY_MODEL || 'gpt-5-mini',
      temperature: 0.5,
      maxTokens: 4000,
      description: 'Modelo para resúmenes diarios',
    },
  };
}

/**
 * Fuerza la recarga de la configuración en el próximo get
 */
export function reloadModelsConfig(): void {
  cachedConfig = null;
  lastReadTime = 0;
  console.log('🔄 Cache de configuración de modelos limpiado');
}
