import OpenAI from 'openai';
import { PrismaClient } from '@prisma/client';
import {
  TipoMensaje,
  ExtraccionIA,
  TareaExtraida,
  CompromisoExtraido,
  RegistroExtraido,
  IdeaExtraida,
} from './types';
import { getModelConfig } from './model-config';

// ============================================
// Configuración de OpenAI y Prisma
// ============================================

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const prisma = new PrismaClient();

// ============================================
// Helpers para contexto
// ============================================

let cachedAreas: string[] | null = null;
let cachedProyectos: string[] | null = null;

async function getAreasVida(): Promise<string[]> {
  if (!cachedAreas) {
    const areas = await prisma.areasVida.findMany({
      select: { nombre: true },
      orderBy: { nombre: 'asc' }
    });
    cachedAreas = areas.map(a => a.nombre);
  }
  return cachedAreas;
}

async function getProyectosActivos(): Promise<string[]> {
  if (!cachedProyectos) {
    const proyectos = await prisma.proyectoEstrategico.findMany({
      where: {
        estado: { in: ['planificacion', 'en_curso'] }
      },
      select: { nombre: true },
      orderBy: { nombre: 'asc' },
      take: 20 // Limitar a 20 proyectos más recientes
    });
    cachedProyectos = proyectos.map(p => p.nombre);
  }
  return cachedProyectos;
}

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

  registro: async (texto: string) => {
    const areas = await getAreasVida();
    const proyectos = await getProyectosActivos();
    
    return `
Extrae de esta nota un REGISTRO de actividad PASADA (algo que YA HICE).

Transcripción: "${texto}"

Extrae los siguientes campos en formato JSON:
{
  "descripcion": "string (qué hice, en pasado)",
  "duracion_horas": "number (si menciona tiempo: '2 horas'=2, 'toda la mañana'=4, 'media hora'=0.5, sino null)",
  "proyecto_nombre": "string (IMPORTANTE: Si menciona un proyecto, busca el nombre EXACTO en esta lista: [${proyectos.join(', ')}]. Si no coincide con ninguno o no menciona proyecto, usa 'otros')",
  "personas_involucradas": ["array de nombres de personas mencionadas"],
  "area_vida_nombre": "string (IMPORTANTE: Clasifica la actividad en UNA de estas áreas: [${areas.join(', ')}]. Elige la más apropiada según el contexto de la actividad)"
}

REGLAS IMPORTANTES:
- proyecto_nombre: DEBE ser uno de la lista de proyectos activos o 'otros'
- area_vida_nombre: DEBE ser exactamente uno de los nombres de la lista de áreas
- Si hay duda sobre el proyecto, usar 'otros'

Responde SOLO con el JSON, sin texto adicional.
`.trim();
  },

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

  proyecto: (texto: string) => `
Extrae de esta nota una IDEA DE PROYECTO.

Transcripción: "${texto}"

Extrae los siguientes campos en formato JSON:
{
  "titulo": "string (nombre del proyecto, breve)",
  "descripcion": "string (descripción completa del proyecto)",
  "categoria": "string (tipo: 'profesional', 'personal', 'social', 'otro')"
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

    // Obtener configuración de modelo
    const modelConfig = getModelConfig('extraction');

    // Generar prompt (puede ser async para registro)
    const promptFn = PROMPTS[tipo];
    const prompt = typeof promptFn === 'function' 
      ? await (promptFn as any)(texto)
      : promptFn;

    const response = await openai.chat.completions.create({
      model: modelConfig.model,
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
      temperature: modelConfig.temperature ?? 0,
      max_completion_tokens: modelConfig.maxTokens ?? 4000,
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
