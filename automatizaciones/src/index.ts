import 'dotenv/config';
import express, { Request, Response } from 'express';
import cors from 'cors';
import { z } from 'zod';
import { processTranscription } from './processor';
import { disconnectDB } from './db-writer';
import { initScheduler, runDailySummaryNow } from './scheduler';
import { WebhookPayload } from './types';
import { sendHistoricalSummary } from './historical-summary';
import { generarEstructuraProyecto } from './ia/generador-proyectos'; // New import
import { guardarProyectoGenerado } from './ia/guardar-proyecto';     // New import
import { processProjectWithAI, saveProjectAnalysis, ProyectoData } from './project-creator';

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

const GenerarProyectoPayloadSchema = z.object({
  nombre: z.string().optional(),
  descripcion: z.string().min(1),
  areasIds: z.array(z.number().int()).optional(),
  motivosIds: z.array(z.number().int()).optional(),
  nuevaAreaVida: z.string().optional(),
  nuevoMotivoPersonal: z.string().optional(),
  documentosUrls: z.array(z.string().url()).optional(),
  ideaId: z.number().int().positive().optional(),
});

const ProyectoWebhookPayloadSchema = z.object({
  proyectoId: z.number().int().positive(),
  nombre: z.string().min(1),
  descripcion: z.string().nullable(),
  areasIds: z.array(z.number().int()).default([]),
  motivosIds: z.array(z.number().int()).default([]),
  destrezasRequeridasIds: z.array(z.number().int()).default([]),
  dificultadesIds: z.array(z.number().int()).default([]),
  misionesIds: z.array(z.number().int()).default([]),
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
  console.log('\n\x1b[38;5;208m\x1b[1m📨 Webhook recibido:\x1b[0m', new Date().toISOString());

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
 * Webhook para procesar proyectos estratégicos existentes con IA
 * Recibe un proyecto ya creado y lo analiza para generar tareas estratégicas
 */
app.post('/webhook/proyecto', async (req: Request, res: Response) => {
  console.log('\n\x1b[38;5;45m\x1b[1m🎯 Webhook Proyecto recibido:\x1b[0m', new Date().toISOString());

  try {
    // Validar payload
    const validationResult = ProyectoWebhookPayloadSchema.safeParse(req.body);

    if (!validationResult.success) {
      console.error('❌ Payload inválido:', validationResult.error);
      return res.status(400).json({
        success: false,
        error: 'Payload inválido',
        details: validationResult.error.issues,
      });
    }

    const payload = validationResult.data as ProyectoData & { proyectoId: number };

    // Responder rápido
    res.status(202).json({
      success: true,
      message: 'Procesamiento de proyecto iniciado',
      proyectoId: payload.proyectoId,
    });

    // Procesar async con IA
    console.log(`🤖 Procesando proyecto "${payload.nombre}" con IA...`);

    const proyectoData: ProyectoData = {
      id: payload.proyectoId,
      nombre: payload.nombre,
      descripcion: payload.descripcion,
      areasIds: payload.areasIds,
      motivosIds: payload.motivosIds,
      destrezasRequeridasIds: payload.destrezasRequeridasIds,
      dificultadesIds: payload.dificultadesIds,
      misionesIds: payload.misionesIds,
    };

    const analisis = await processProjectWithAI(proyectoData);

    await saveProjectAnalysis(payload.proyectoId, analisis);

    console.log(`✅ Proyecto ${payload.proyectoId} procesado exitosamente`);
  } catch (error) {
    console.error('❌ Error en webhook proyecto:', error);

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
 * Endpoint para generar y guardar un proyecto estratégico con IA
 */
app.post('/generar-proyecto', async (req: Request, res: Response) => {
  console.log('\n\x1b[38;5;208m\x1b[1m🧠 Generar Proyecto recibido:\x1b[0m', new Date().toISOString());

  try {
    const validationResult = GenerarProyectoPayloadSchema.safeParse(req.body);

    if (!validationResult.success) {
      console.error('❌ Payload inválido:', validationResult.error);
      return res.status(400).json({
        success: false,
        error: 'Payload inválido',
        details: validationResult.error.issues,
      });
    }

    const { nombre, descripcion, areasIds, motivosIds, nuevaAreaVida, nuevoMotivoPersonal, documentosUrls, ideaId } = validationResult.data;

    // 1. Generar estructura del proyecto con IA
    const estructuraGenerada = await generarEstructuraProyecto(descripcion, documentosUrls);

    // 2. Merge user input with AI generated data
    // User input takes precedence for areas and motivos
    const mergedEstructura = {
      ...estructuraGenerada,
      proyecto: {
        ...estructuraGenerada.proyecto,
        nombre: nombre || estructuraGenerada.proyecto.nombre || 'Proyecto sin nombre',
        descripcion: descripcion, // Always use user description
        areas_ids: areasIds && areasIds.length > 0 ? areasIds : estructuraGenerada.proyecto.areas_ids,
        motivos_ids: motivosIds && motivosIds.length > 0 ? motivosIds : estructuraGenerada.proyecto.motivos_ids,
      }
    };

    // 3. Guardar el proyecto generado en la BD
    const projectId = await guardarProyectoGenerado(
      mergedEstructura,
      "gpt-5.1", // Model used
      1000, // Placeholder for tokensUsados (TODO: get from OpenAI response)
      descripcion,
      JSON.stringify(estructuraGenerada)
    );

    // If an ideaId was provided, update the IdeaCapturada
    if (ideaId) {
      const { PrismaClient } = await import('@prisma/client');
      const prisma = new PrismaClient();
      await prisma.ideaCapturada.update({
        where: { id: ideaId },
        data: {
          implementada: true,
          proyectoEstrategicoId: projectId,
          fechaImplementacion: new Date(),
        },
      });
      await prisma.$disconnect(); // Disconnect Prisma Client
    }

    res.status(201).json({
      success: true,
      message: 'Proyecto generado y guardado exitosamente',
      projectId: projectId,
    });

  } catch (error) {
    console.error('❌ Error generando proyecto:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Error interno del servidor',
    });
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

/**
 * Test endpoint - Para ejecutar resumen histórico de una fecha específica
 */
app.post('/test/historical-summary/:year/:month/:day', async (req: Request, res: Response) => {
  try {
    const { year, month, day } = req.params;
    const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day)); // month-1 porque los meses en JS son 0-11

    console.log(`🧪 Ejecutando resumen histórico del ${date.toLocaleDateString('es-UY')}...`);

    // Responder rápido
    res.status(202).json({
      success: true,
      message: `Resumen histórico del ${date.toLocaleDateString('es-UY')} ejecutándose...`,
    });

    // Ejecutar en background
    const chatId = process.env.TELEGRAM_CHAT_ID;
    if (!chatId) {
      throw new Error('TELEGRAM_CHAT_ID no configurado');
    }

    await sendHistoricalSummary(chatId, date, true);

    console.log('✅ Resumen histórico completado');
  } catch (error) {
    console.error('❌ Error ejecutando resumen histórico:', error);

    if (!res.headersSent) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Error desconocido',
      });
    }
  }
});

/**
 * Test endpoint - Para reprocesar notas no procesadas en un rango de fechas
 * POST /test/reprocess-notes/:startDate/:endDate
 * Ej: /test/reprocess-notes/2025-11-08/2025-11-16
 */
app.post('/test/reprocess-notes/:startDate/:endDate', async (req: Request, res: Response) => {
  try {
    const { startDate, endDate } = req.params;

    console.log('\n\x1b[38;5;166m\x1b[1m🔄 ===== REPROCESANDO NOTAS =====\x1b[0m');
    console.log(`📅 Rango: ${startDate} a ${endDate}`);

    // Responder rápido
    res.status(202).json({
      success: true,
      message: `Reprocesamiento de notas iniciado (${startDate} a ${endDate})`,
    });

    // Procesar en background
    await reprocessNotesInDateRange(startDate, endDate);

    console.log('✅ Reprocesamiento completado');
  } catch (error) {
    console.error('❌ Error reprocesando notas:', error);

    if (!res.headersSent) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Error desconocido',
      });
    }
  }
});

// ============================================ 
// Función de Reprocesamiento
// ============================================ 

async function reprocessNotesInDateRange(startDateStr: string, endDateStr: string): Promise<void> {
  const { PrismaClient } = await import('@prisma/client');
  const prisma = new PrismaClient();

  try {
    const startDate = new Date(startDateStr);
    const endDate = new Date(endDateStr);
    endDate.setDate(endDate.getDate() + 1); // Incluir el último día completo

    console.log(`\n📊 Buscando notas sin procesar entre ${startDate.toISOString()} y ${endDate.toISOString()}...`);

    const notasAudio = await prisma.notaAudio.findMany({
      where: {
        procesado: false,
        createdAt: {
          gte: startDate,
          lt: endDate,
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    console.log(`📋 Encontradas ${notasAudio.length} notas sin procesar`);

    if (notasAudio.length === 0) {
      console.log('✅ No hay notas para procesar');
      return;
    }

    // Procesar cada nota
    for (let i = 0; i < notasAudio.length; i++) {
      const nota = notasAudio[i];
      console.log(`\n[${i + 1}/${notasAudio.length}] Procesando NotaAudio ID: ${nota.id}`);

      try {
        const result = await processTranscription({
          transcripcionId: nota.transcripcionId,
          texto: nota.transcripcionCompleta,
          archivoUrl: nota.archivoAudioUrl || undefined,
          fecha: nota.createdAt.toISOString(),
        }, true); // forceReprocess = true

        if (result.success) {
          console.log(`✅ Nota ${nota.id} procesada: ${result.tipo}`);
        } else {
          console.log(`⚠️ Nota ${nota.id} falló: ${result.error}`);
        }
      } catch (error) {
        console.error(`❌ Error procesando nota ${nota.id}:`, error);
      }

      // Pequeña pausa entre procesamientos para no sobrecargar OpenAI
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    console.log(`\n✅ Reprocesamiento finalizado: ${notasAudio.length} notas procesadas`);
  } finally {
    await prisma.$disconnect();
  }
}

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