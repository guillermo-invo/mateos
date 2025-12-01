import { PrismaClient } from '@prisma/client';
import { sendLongMessage } from './telegram-client';
import { generateAISummary, generateSimpleSummary, DailySummaryData } from './daily-summary';

const prisma = new PrismaClient();

/**
 * Obtiene todos los datos de una fecha específica
 */
export async function getDailyDataForDate(date: Date): Promise<DailySummaryData> {
  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0); // Inicio del día

  const endOfDay = new Date(startOfDay);
  endOfDay.setDate(endOfDay.getDate() + 1); // Fin del día

  console.log(`📊 Consultando datos del ${startOfDay.toLocaleDateString()}...`);

  // Consultar en paralelo
  const [registros, tareas, compromisos, ideas] = await Promise.all([
    // Registros de la fecha especificada
    prisma.registro.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lt: endOfDay,
        },
      },
      orderBy: { createdAt: 'asc' },
    }),

    // Tareas creadas en la fecha especificada
    prisma.tarea.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lt: endOfDay,
        },
        completada: false, // Solo las pendientes
      },
      orderBy: { prioridad: 'desc' },
    }),

    // Compromisos creados en la fecha especificada
    prisma.compromiso.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lt: endOfDay,
        },
        cumplido: false, // Solo los pendientes
      },
      orderBy: { fechaLimite: 'asc' },
    }),

    // Ideas de la fecha especificada
    prisma.ideaCapturada.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lt: endOfDay,
        },
      },
      orderBy: { createdAt: 'asc' },
    }),
  ]);

  console.log(`✅ Datos obtenidos: ${registros.length} registros, ${tareas.length} tareas, ${compromisos.length} compromisos, ${ideas.length} ideas`);

  return { registros, tareas, compromisos, ideas };
}

/**
 * Genera y envía un resumen de una fecha específica
 */
export async function sendHistoricalSummary(chatId: number | string, date: Date, useAI: boolean = true): Promise<void> {
  try {
    console.log('\n📊 ===== GENERANDO RESUMEN HISTÓRICO =====');
    console.log(`👤 Chat ID: ${chatId}`);
    console.log(`📅 Fecha: ${date.toLocaleDateString('es-UY')}`);
    console.log(`🧠 Usar IA: ${useAI ? 'Sí' : 'No'}`);

    // 1. Obtener datos
    const data = await getDailyDataForDate(date);

    // 2. Verificar si hay algo que reportar
    const totalItems = data.registros.length + data.tareas.length +
                       data.compromisos.length + data.ideas.length;

    if (totalItems === 0) {
      console.log('⚠️ No hay datos para el resumen de la fecha especificada');
      await sendLongMessage(
        chatId,
        `📅 *Resumen del Día - ${date.toLocaleDateString('es-UY', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}*\n\n` +
        'No registraste ninguna actividad, tarea, compromiso o idea en esta fecha.\n\n' +
        '💡 Tip: Usa las palabras clave (Teo, Juan, Ide, Compa) al inicio de tus mensajes de voz para que se procesen automáticamente.'
      );
      return;
    }

    // 3. Generar resumen
    const summary = useAI
      ? await generateAISummary(data)
      : generateSimpleSummary(data);

    // 4. Modificar el encabezado para mostrar la fecha correcta
    const dateHeader = `📅 *Resumen del Día - ${date.toLocaleDateString('es-UY', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}*`;
    const modifiedSummary = summary.replace(/📅 \*Resumen del Día.*\*/, dateHeader);

    // 5. Enviar por Telegram
    await sendLongMessage(chatId, modifiedSummary);

    console.log('✅ ===== RESUMEN HISTÓRICO ENVIADO =====\n');

  } catch (error) {
    console.error('❌ Error enviando resumen histórico:', error);
    throw error;
  }
}