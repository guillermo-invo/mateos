import OpenAI from 'openai';
import { PrismaClient } from '@prisma/client';
import { PROMPT_SISTEMA_PROYECTO } from './prompts-proyectos';
import { EstructuraProyecto } from '../types';
import { getModelConfig } from '../model-config';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const prisma = new PrismaClient();


export async function generarEstructuraProyecto(
  descripcion: string,
  documentosUrls?: string[]
): Promise<EstructuraProyecto> {
  try {
    console.log(`🤖 Generando estructura de proyecto con IA...`);
    console.log(`📝 Descripción: ${descripcion}`);

    const modelConfig = getModelConfig('projectCreation');

    // 1. Obtener contexto personal desde la BD
    const [areas, motivos, destrezas, dificultades, misiones] = await Promise.all([
      prisma.areasVida.findMany(),
      prisma.motivosPersonales.findMany(),
      prisma.destrezas.findMany(),
      prisma.dificultades.findMany(),
      prisma.misionesVida.findMany(),
    ]);

    const contextPersonal = {
      areasVida: areas.map((a) => ({ id: a.id, nombre: a.nombre })),
      motivosPersonales: motivos.map((m) => ({
        id: m.id,
        nombre: m.nombre,
        descripcion: m.descripcion,
      })),
      destrezas: destrezas.map((d) => ({
        id: d.id,
        nombre: d.nombre,
        nivel: d.nivelActual,
      })),
      dificultades: dificultades.map((d) => ({
        id: d.id,
        nombre: d.nombre,
        descripcion: d.descripcion,
      })),
      misiones: misiones.map((m) => ({
        id: m.id,
        nombre: m.nombre,
        descripcion: m.descripcion,
      })),
    };

    // 2. Obtener proyectos activos
    const proyectosActivos = await prisma.proyectoEstrategico.findMany({
      where: {
        estado: { in: ['planificacion', 'en_curso'] },
      },
      select: { id: true, nombre: true, estado: true },
      take: 10,
    });

    // 3. Construir proyecto propuesto
    const proyectoPropuesto = {
      nombre: 'Nuevo Proyecto',
      descripcion: descripcion,
    };

    // 4. Construir prompt final
    const finalPrompt = PROMPT_SISTEMA_PROYECTO.replace(
      /{contexto_personal}/g,
      JSON.stringify(contextPersonal, null, 2)
    )
      .replace(
        /{proyectos_activos}/g,
        JSON.stringify(proyectosActivos, null, 2)
      )
      .replace(
        /{proyecto_propuesto}/g,
        JSON.stringify(proyectoPropuesto, null, 2)
      );

    // 5. Llamar a OpenAI
    const response = await openai.chat.completions.create({
      model: modelConfig.model,
      messages: [
        {
          role: 'system',
          content: finalPrompt,
        },
      ],
      temperature: modelConfig.temperature ?? 0.7,
      max_completion_tokens: modelConfig.maxTokens ?? 8000,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('OpenAI no devolvió contenido');
    }

    // 6. Parsear respuesta
    const estructura = JSON.parse(content) as EstructuraProyecto;

    console.log('✅ Estructura de proyecto generada');
    return estructura;
  } catch (error) {
    console.error('❌ Error generando estructura de proyecto:', error);
    throw error;
  }
}
