import { PrismaClient } from '@prisma/client';
import OpenAI from 'openai';
import { sendLongMessage } from './telegram-client';
import { getModelConfig } from './model-config';

const prisma = new PrismaClient();
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// ============================================
// Tipos
// ============================================

export interface DailySummaryData {
  registros: Array<{
    id: number;
    descripcion: string;
    duracionHoras: number | null;
    proyectoNombre: string | null;
    personasInvolucradas: string[];
    areaVidaId: number | null;
  }>;
  tareas: Array<{
    id: number;
    titulo: string;
    descripcion: string | null;
    prioridad: string;
    fechaVencimiento: Date | null;
  }>;
  compromisos: Array<{
    id: number;
    titulo: string;
    personaNombre: string;
    fechaLimite: Date | null;
    yoMeComprometi: boolean;
  }>;
  ideas: Array<{
    id: number;
    titulo: string;
    descripcion: string | null;
    categoria: string | null;
  }>;
}

// ============================================
// Funciones de Consulta
// ============================================

/**
 * Obtiene todos los datos desde las 20:04 del día anterior hasta las 20:00 de hoy
 */
export async function getDailyData(): Promise<DailySummaryData> {
  // Fecha de inicio: Ayer a las 20:04
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 1); // Día anterior
  startDate.setHours(20, 4, 0, 0); // 20:04:00

  // Fecha de fin: Hoy a las 20:00
  const endDate = new Date();
  endDate.setHours(20, 0, 0, 0); // 20:00:00

  console.log(`📊 Consultando datos desde ${startDate.toLocaleString('es-UY')} hasta ${endDate.toLocaleString('es-UY')}...`);

  // Consultar en paralelo
  const [registros, tareas, compromisos, ideas] = await Promise.all([
    // Registros desde las 20:04 del día anterior hasta las 20:00 de hoy
    prisma.registro.findMany({
      where: {
        createdAt: {
          gte: startDate,
          lt: endDate,
        },
      },
      orderBy: { createdAt: 'asc' },
    }),

    // Tareas creadas en el período (que debo hacer)
    prisma.tarea.findMany({
      where: {
        createdAt: {
          gte: startDate,
          lt: endDate,
        },
        completada: false, // Solo las pendientes
      },
      orderBy: { prioridad: 'desc' },
    }),

    // Compromisos creados en el período
    prisma.compromiso.findMany({
      where: {
        createdAt: {
          gte: startDate,
          lt: endDate,
        },
        cumplido: false, // Solo los pendientes
      },
      orderBy: { fechaLimite: 'asc' },
    }),

    // Ideas del período
    prisma.ideaCapturada.findMany({
      where: {
        createdAt: {
          gte: startDate,
          lt: endDate,
        },
      },
      orderBy: { createdAt: 'asc' },
    }),
  ]);

  console.log(`✅ Datos obtenidos: ${registros.length} registros, ${tareas.length} tareas, ${compromisos.length} compromisos, ${ideas.length} ideas`);

  return { registros, tareas, compromisos, ideas };
}

// ============================================
// Generación de Resumen
// ============================================

/**
 * Genera un resumen en texto plano (sin IA)
 */
export function generateSimpleSummary(data: DailySummaryData): string {
  const today = new Date().toLocaleDateString('es-UY', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  let summary = `📅 *Resumen del Día - ${today}*\n\n`;

  // Registros (lo que hice)
  if (data.registros.length > 0) {
    summary += `✅ *LO QUE HICISTE HOY* (${data.registros.length})\n`;
    summary += `━━━━━━━━━━━━━━━━━━━━\n`;

    data.registros.forEach((reg, idx) => {
      const duracion = reg.duracionHoras ? ` (${reg.duracionHoras}h)` : '';
      const proyecto = reg.proyectoNombre ? ` - ${reg.proyectoNombre}` : '';
      const personas = reg.personasInvolucradas.length > 0
        ? ` con ${reg.personasInvolucradas.join(', ')}`
        : '';

      summary += `${idx + 1}. ${reg.descripcion}${duracion}${proyecto}${personas}\n`;
    });
    summary += '\n';
  } else {
    summary += `⚠️ No registraste actividades hoy\n\n`;
  }

  // Tareas pendientes
  if (data.tareas.length > 0) {
    summary += `📋 *TAREAS PENDIENTES* (${data.tareas.length})\n`;
    summary += `━━━━━━━━━━━━━━━━━━━━\n`;

    data.tareas.forEach((tarea, idx) => {
      const prioridad = tarea.prioridad === 'URGENTE' ? '🔴' :
                        tarea.prioridad === 'ALTA' ? '🟠' :
                        tarea.prioridad === 'MEDIA' ? '🟡' : '🟢';
      const vencimiento = tarea.fechaVencimiento
        ? ` - vence ${new Date(tarea.fechaVencimiento).toLocaleDateString()}`
        : '';

      summary += `${idx + 1}. ${prioridad} ${tarea.titulo}${vencimiento}\n`;

      if (tarea.descripcion) {
        summary += `   _${tarea.descripcion}_\n`;
      }
    });
    summary += '\n';
  } else {
    summary += `✅ No hay tareas pendientes\n\n`;
  }

  // Compromisos
  if (data.compromisos.length > 0) {
    summary += `🤝 *COMPROMISOS* (${data.compromisos.length})\n`;
    summary += `━━━━━━━━━━━━━━━━━━━━\n`;

    data.compromisos.forEach((comp, idx) => {
      const quien = comp.yoMeComprometi ? '(yo me comprometí)' : `(${comp.personaNombre} se comprometió)`;
      const limite = comp.fechaLimite
        ? ` - para ${new Date(comp.fechaLimite).toLocaleDateString()}`
        : '';

      summary += `${idx + 1}. ${comp.titulo} ${quien}${limite}\n`;
    });
    summary += '\n';
  }

  // Ideas
  if (data.ideas.length > 0) {
    summary += `💡 *IDEAS* (${data.ideas.length})\n`;
    summary += `━━━━━━━━━━━━━━━━━━━━\n`;

    data.ideas.forEach((idea, idx) => {
      const categoria = idea.categoria ? ` [${idea.categoria}]` : '';
      summary += `${idx + 1}. ${idea.titulo}${categoria}\n`;

      if (idea.descripcion) {
        summary += `   _${idea.descripcion}_\n`;
      }
    });
    summary += '\n';
  }

  // Footer
  summary += `\n━━━━━━━━━━━━━━━━━━━━\n`;
  summary += `🤖 _Resumen generado automáticamente a las ${new Date().toLocaleTimeString('es-UY')}_`;

  return summary;
}

/**
 * Genera un resumen con IA (más natural y contextualizado)
 */
export async function generateAISummary(data: DailySummaryData): Promise<string> {
  console.log('🧠 Generando resumen con IA...');

  const prompt = `
Sos el asistente personal de Guille. Generá el resumen del día en formato BULLET POINTS concreto.

Datos del día:

**Registros (lo que hizo hoy):**
${JSON.stringify(data.registros, null, 2)}

**Tareas pendientes:**
${JSON.stringify(data.tareas, null, 2)}

**Compromisos:**
${JSON.stringify(data.compromisos, null, 2)}

**Ideas:**
${JSON.stringify(data.ideas, null, 2)}

FORMATO OBLIGATORIO - solo bullets, cero párrafos:

📅 *Resumen del día*

✅ *Lo que hiciste*
• Resumen concreto de cada registro (1 línea c/u)

📋 *Tareas pendientes*
• Tarea con prioridad y vencimiento si tiene

🤝 *Compromisos*
• Compromiso + con quién + deadline

💡 *Ideas*
• Idea + categoría

⚡ *Para mañana*
• Si hay tareas pendientes o compromisos próximos, 1-2 bullets de lo más urgente

REGLAS:
- CERO párrafos narrados. Solo bullets concretos.
- CERO saludos, cierres motivacionales ni relleno.
- Cada bullet = 1 hecho/tarea/idea. Max 15 palabras por bullet.
- Si una sección no tiene datos, no la incluyas.
- Emojis solo en los títulos de sección.
- Max 400 palabras total.
`;

  try {
    // Obtener configuración de modelo
    const modelConfig = getModelConfig('dailySummary');

    const response = await openai.chat.completions.create({
      model: modelConfig.model,
      messages: [
        {
          role: 'system',
          content: 'Eres un asistente personal amigable y motivador que ayuda a resumir el día.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: modelConfig.temperature ?? 1,
      max_completion_tokens: modelConfig.maxTokens ?? 1500,
    });

    const summary = response.choices[0]?.message?.content || '';
    console.log('✅ Resumen IA generado');
    return summary;

  } catch (error) {
    console.error('❌ Error generando resumen con IA:', error);
    // Fallback a resumen simple
    return generateSimpleSummary(data);
  }
}

// ============================================
// Función Principal
// ============================================

/**
 * Genera y envía el resumen diario al usuario por Telegram
 */
export async function sendDailySummary(chatId: number | string, useAI: boolean = true): Promise<void> {
  try {
    console.log('\n📊 ===== GENERANDO RESUMEN DIARIO =====');
    console.log(`👤 Chat ID: ${chatId}`);
    console.log(`🧠 Usar IA: ${useAI ? 'Sí' : 'No'}`);

    // 1. Obtener datos
    const data = await getDailyData();

    // 2. Verificar si hay algo que reportar
    const totalItems = data.registros.length + data.tareas.length +
                       data.compromisos.length + data.ideas.length;

    if (totalItems === 0) {
      console.log('⚠️ No hay datos para el resumen de hoy');
      await sendLongMessage(
        chatId,
        '📅 *Resumen del Día*\n\n' +
        'No registraste ninguna actividad, tarea, compromiso o idea hoy.\n\n' +
        '💡 Tip: Usa las palabras clave (Teo, Juan, Ide, Compa) al inicio de tus mensajes de voz para que se procesen automáticamente.'
      );
      return;
    }

    // 3. Generar resumen
    const summary = useAI
      ? await generateAISummary(data)
      : generateSimpleSummary(data);

    // 4. Enviar por Telegram
    await sendLongMessage(chatId, summary);

    console.log('✅ ===== RESUMEN DIARIO ENVIADO =====\n');

  } catch (error) {
    console.error('❌ Error enviando resumen diario:', error);
    throw error;
  }
}
