import OpenAI from 'openai';
import {
  TipoMensaje,
  ExtraccionIA,
  TareaExtraida,
  CompromisoExtraido,
  RegistroExtraido,
  IdeaExtraida,
} from './types';

// ============================================
// Configuración de OpenAI
// ============================================

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';
const TEMPERATURE = parseFloat(process.env.OPENAI_TEMPERATURE || '0.1');
const MAX_TOKENS = parseInt(process.env.OPENAI_MAX_TOKENS || '4000', 10);

// ============================================
// Prompts Específicos por Tipo
// ============================================

const PROMPTS = {
  tarea: (texto: string) => `
Extrae de esta nota una TAREA (algo que debo hacer en el futuro).

Transcripción: "${texto}"

Extrae los siguientes campos en formato JSON:
{
  "titulo": "string (breve, verbo en infinitivo, max 100 caracteres)",
  "descripcion": "string (detalle completo, opcional)",
  "fecha_vencimiento": "string ISO date (inferir de 'mañana', 'el lunes', 'en 3 días', etc. Usa la fecha actual como referencia: ${new Date().toISOString().split('T')[0]}. Si no se menciona fecha, null)",
  "prioridad": "ALTA | MEDIA | BAJA | URGENTE (inferir del tono/urgencia, default MEDIA)"
}

Responde SOLO con el JSON, sin texto adicional.
`.trim(),

  registro: (texto: string) => `
Extrae de esta nota un REGISTRO de actividad PASADA (algo que YA HICE).

Transcripción: "${texto}"

Extrae los siguientes campos en formato JSON:
{
  "descripcion": "string (qué hice, en pasado)",
  "duracion_horas": "number (si menciona tiempo: '2 horas'=2, 'toda la mañana'=4, 'media hora'=0.5, sino null)",
  "proyecto": "string (si menciona nombre de proyecto/cliente, sino null)",
  "personas_involucradas": ["array de nombres de personas mencionadas"],
  "categoria": "TRABAJO | PERSONAL | SOCIAL | OTRO (inferir del contexto)"
}

Responde SOLO con el JSON, sin texto adicional.
`.trim(),

  compromiso: (texto: string) => `
Extrae de esta nota un COMPROMISO con otra persona.

Transcripción: "${texto}"

Extrae los siguientes campos en formato JSON:
{
  "titulo": "string (qué se comprometió, breve)",
  "descripcion": "string (contexto completo, opcional)",
  "persona": "string (nombre de la persona involucrada)",
  "fecha_limite": "string ISO date (si menciona 'para el viernes', etc. Usa fecha actual como referencia: ${new Date().toISOString().split('T')[0]}. Si no se menciona, null)",
  "yo_me_comprometi": "boolean (true si YO prometí hacer algo, false si OTRA PERSONA prometió)"
}

Responde SOLO con el JSON, sin texto adicional.
`.trim(),

  idea: (texto: string) => `
Extrae de esta nota una IDEA o pensamiento.

Transcripción: "${texto}"

Extrae los siguientes campos en formato JSON:
{
  "titulo": "string (resumen en 5-10 palabras)",
  "descripcion": "string (detalle completo)",
  "categoria": "string (tipo de idea: 'producto', 'mejora', 'estrategia', 'contenido', 'otro', etc.)"
}

Responde SOLO con el JSON, sin texto adicional.
`.trim(),
};

// ============================================
// Función Principal de Extracción
// ============================================

/**
 * Extrae entidades estructuradas de un texto usando OpenAI
 */
export async function extractEntities(
  texto: string,
  tipo: TipoMensaje
): Promise<ExtraccionIA | null> {
  if (tipo === 'sin_clasificar') {
    console.log('⚠️ No se puede extraer de tipo "sin_clasificar"');
    return null;
  }

  try {
    console.log(`🧠 Extrayendo ${tipo} con OpenAI...`);

    const prompt = PROMPTS[tipo](texto);

    const response = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        {
          role: 'system',
          content:
            'Eres un asistente que extrae información estructurada de notas de voz. Responde SIEMPRE con JSON válido, sin texto adicional.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: TEMPERATURE,
      max_tokens: MAX_TOKENS,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('OpenAI no devolvió contenido');
    }

    // Parse JSON
    const data = JSON.parse(content);

    console.log('✅ Extracción completada:', data);

    // Construir resultado según el tipo
    const resultado: ExtraccionIA = { tipo };

    switch (tipo) {
      case 'tarea':
        resultado.tarea = data as TareaExtraida;
        break;
      case 'registro':
        resultado.registro = data as RegistroExtraido;
        break;
      case 'compromiso':
        resultado.compromiso = data as CompromisoExtraido;
        break;
      case 'idea':
        resultado.idea = data as IdeaExtraida;
        break;
    }

    return resultado;
  } catch (error) {
    console.error('❌ Error extrayendo con OpenAI:', error);
    throw error;
  }
}

/**
 * Valida que la extracción tenga los campos mínimos requeridos
 */
export function validateExtraction(extraccion: ExtraccionIA): boolean {
  switch (extraccion.tipo) {
    case 'tarea':
      return !!extraccion.tarea?.titulo;
    case 'registro':
      return !!extraccion.registro?.descripcion;
    case 'compromiso':
      return !!extraccion.compromiso?.titulo && !!extraccion.compromiso?.persona;
    case 'idea':
      return !!extraccion.idea?.titulo;
    default:
      return false;
  }
}
