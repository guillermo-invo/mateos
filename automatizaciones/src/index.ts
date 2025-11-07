import 'dotenv/config';
import express, { Request, Response } from 'express';
import cors from 'cors';
import { z } from 'zod';
import { processTranscription } from './processor';
import { disconnectDB } from './db-writer';
import { initScheduler, runDailySummaryNow } from './scheduler';
import { WebhookPayload } from './types';

// ============================================
// Configuración
// ============================================

const app = express();
const PORT = parseInt(process.env.PORT || '3100', 10);

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ============================================
// Schema de Validación
// ============================================

const WebhookPayloadSchema = z.object({
  transcripcionId: z.number().int().positive(),
  texto: z.string().min(1),
  archivoUrl: z.string().url().optional(),
  fecha: z.string().datetime(),
});

// ============================================
// Rutas
// ============================================

/**
 * Health check
 */
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'mateos-automatizaciones',
    timestamp: new Date().toISOString(),
  });
});

/**
 * Webhook principal - Recibe transcripciones de mateos
 */
app.post('/webhook', async (req: Request, res: Response) => {
  console.log('\n📨 Webhook recibido:', new Date().toISOString());

  try {
    // Validar payload
    const validationResult = WebhookPayloadSchema.safeParse(req.body);

    if (!validationResult.success) {
      console.error('❌ Payload inválido:', validationResult.error);
      return res.status(400).json({
        success: false,
        error: 'Payload inválido',
        details: validationResult.error.issues,
      });
    }

    const payload = validationResult.data as WebhookPayload;

    // Procesar en background (no bloquear respuesta)
    // En producción, esto debería ir a una queue (BullMQ)
    // Por ahora, procesamos directamente pero respondemos rápido
    res.status(202).json({
      success: true,
      message: 'Procesamiento iniciado',
      transcripcionId: payload.transcripcionId,
    });

    // Procesar async
    const result = await processTranscription(payload);

    if (!result.success) {
      console.error('❌ Procesamiento falló:', result.error);
    } else {
      console.log('✅ Procesamiento exitoso:', result);
    }
  } catch (error) {
    console.error('❌ Error en webhook:', error);

    // Si aún no respondimos, responder con error
    if (!res.headersSent) {
      res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
      });
    }
  }
});

/**
 * Test endpoint - Para probar fuzzy matching
 */
app.get('/test/keywords/:word', async (req: Request, res: Response) => {
  const { testKeywordMatching } = await import('./keyword-matcher');
  const word = req.params.word;

  testKeywordMatching(word);

  res.json({
    message: 'Ver logs del servidor para resultados',
    word,
  });
});

/**
 * Test endpoint - Para ejecutar resumen diario manualmente
 */
app.post('/test/daily-summary', async (req: Request, res: Response) => {
  try {
    console.log('🧪 Ejecutando resumen diario manual...');

    // Responder rápido
    res.status(202).json({
      success: true,
      message: 'Resumen diario ejecutándose...',
    });

    // Ejecutar en background
    await runDailySummaryNow();

    console.log('✅ Resumen diario manual completado');
  } catch (error) {
    console.error('❌ Error ejecutando resumen manual:', error);

    if (!res.headersSent) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Error desconocido',
      });
    }
  }
});

// ============================================
// Manejo de Errores
// ============================================

app.use((err: Error, _req: Request, res: Response, _next: any) => {
  console.error('❌ Error no manejado:', err);
  res.status(500).json({
    success: false,
    error: 'Error interno del servidor',
  });
});

// ============================================
// Inicio del Servidor
// ============================================

const server = app.listen(PORT, () => {
  console.log('\n🚀 ===== MATEOS AUTOMATIZACIONES =====');
  console.log(`✅ Servidor iniciado en puerto ${PORT}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
  console.log(`📨 Webhook: http://localhost:${PORT}/webhook`);
  console.log(`🧪 Test keywords: http://localhost:${PORT}/test/keywords/:word`);
  console.log(`🧪 Test resumen: POST http://localhost:${PORT}/test/daily-summary`);
  console.log('=====================================\n');

  // Inicializar scheduler (resúmenes diarios automáticos)
  initScheduler();
});

// ============================================
// Shutdown Graceful
// ============================================

process.on('SIGTERM', async () => {
  console.log('\n⚠️ SIGTERM recibido, cerrando servidor...');
  server.close(async () => {
    console.log('✅ Servidor cerrado');
    await disconnectDB();
    console.log('✅ BD desconectada');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.log('\n⚠️ SIGINT recibido, cerrando servidor...');
  server.close(async () => {
    console.log('✅ Servidor cerrado');
    await disconnectDB();
    console.log('✅ BD desconectada');
    process.exit(0);
  });
});
