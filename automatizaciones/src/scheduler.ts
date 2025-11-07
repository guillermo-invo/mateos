import cron from 'node-cron';
import { sendDailySummary } from './daily-summary';
import { initTelegramBot } from './telegram-client';

// ============================================
// Configuración
// ============================================

const DAILY_SUMMARY_TIME = process.env.DAILY_SUMMARY_TIME || '0 20 * * *'; // Por defecto 8:00 PM
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;
const USE_AI_SUMMARY = process.env.USE_AI_SUMMARY !== 'false'; // Por defecto true

// ============================================
// Scheduler
// ============================================

/**
 * Inicializa todos los cron jobs
 */
export function initScheduler(): void {
  console.log('📅 ===== INICIALIZANDO SCHEDULER =====');

  if (!TELEGRAM_CHAT_ID) {
    console.warn('⚠️ TELEGRAM_CHAT_ID no configurado, scheduler deshabilitado');
    console.warn('   Configura TELEGRAM_CHAT_ID en .env para recibir resúmenes automáticos');
    return;
  }

  // Validar que el cron expression es válido
  if (!cron.validate(DAILY_SUMMARY_TIME)) {
    console.error(`❌ Cron expression inválido: ${DAILY_SUMMARY_TIME}`);
    return;
  }

  console.log(`✅ Chat ID configurado: ${TELEGRAM_CHAT_ID}`);
  console.log(`⏰ Horario de resumen: ${DAILY_SUMMARY_TIME} (${getCronDescription(DAILY_SUMMARY_TIME)})`);
  console.log(`🧠 Usar IA: ${USE_AI_SUMMARY ? 'Sí' : 'No'}`);

  // Inicializar bot de Telegram
  try {
    initTelegramBot();
  } catch (error) {
    console.error('❌ Error inicializando bot de Telegram:', error);
    return;
  }

  // Job 1: Resumen Diario
  const dailySummaryJob = cron.schedule(
    DAILY_SUMMARY_TIME,
    async () => {
      console.log('\n⏰ CRON JOB: Ejecutando resumen diario...');
      try {
        await sendDailySummary(TELEGRAM_CHAT_ID!, USE_AI_SUMMARY);
        console.log('✅ CRON JOB: Resumen diario completado\n');
      } catch (error) {
        console.error('❌ CRON JOB: Error en resumen diario:', error);
      }
    },
    {
      scheduled: true,
      timezone: process.env.TZ || 'America/Montevideo',
    }
  );

  console.log('✅ Resumen diario programado');
  console.log(`   Timezone: ${process.env.TZ || 'America/Montevideo'}`);

  // Agregar más jobs aquí si es necesario en el futuro
  // Ejemplo: recordatorios, backups, etc.

  console.log('📅 ===== SCHEDULER ACTIVO =====\n');

  // Manejar señales de terminación para detener los jobs gracefully
  process.on('SIGTERM', () => {
    console.log('\n⏸️ Deteniendo scheduler...');
    dailySummaryJob.stop();
    console.log('✅ Scheduler detenido');
  });

  process.on('SIGINT', () => {
    console.log('\n⏸️ Deteniendo scheduler...');
    dailySummaryJob.stop();
    console.log('✅ Scheduler detenido');
  });
}

/**
 * Obtiene una descripción legible del cron expression
 */
function getCronDescription(cronExpression: string): string {
  const parts = cronExpression.split(' ');

  if (parts.length !== 5) {
    return cronExpression;
  }

  const [minute, hour, dayOfMonth, month, dayOfWeek] = parts;

  let description = '';

  // Hora
  if (hour !== '*') {
    const h = parseInt(hour, 10);
    description += `a las ${h.toString().padStart(2, '0')}:${minute.padStart(2, '0')}`;
  }

  // Día
  if (dayOfWeek !== '*') {
    description += ' los ';
    const days = ['domingos', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábados'];
    description += days[parseInt(dayOfWeek, 10)];
  } else if (dayOfMonth !== '*') {
    description += ` el día ${dayOfMonth} de cada mes`;
  } else {
    description += ' todos los días';
  }

  return description;
}

/**
 * Ejecuta el resumen diario manualmente (para testing)
 */
export async function runDailySummaryNow(): Promise<void> {
  if (!TELEGRAM_CHAT_ID) {
    throw new Error('TELEGRAM_CHAT_ID no configurado');
  }

  console.log('🧪 Ejecutando resumen diario manualmente...');
  await sendDailySummary(TELEGRAM_CHAT_ID, USE_AI_SUMMARY);
}
