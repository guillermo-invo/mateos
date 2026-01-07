import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { serializePrismaData } from '@/lib/serializePrisma';

const decimalFields = ['prioridadGlobal', 'scoreMotivacional', 'scoreAlineacion'] as const;
type DecimalField = typeof decimalFields[number];

const toNumberOrNull = (value: unknown): number | null => {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === 'number') {
    return value;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const serializeProyectoResponse = <T extends Record<string, unknown>>(data: T): T => {
  const serialized = serializePrismaData(data) as Record<string, unknown>;
  const normalized = { ...serialized };

  decimalFields.forEach((field: DecimalField) => {
    normalized[field] = toNumberOrNull(normalized[field]);
  });

  return normalized as T;
};

const serializeProyectosResponse = <T extends Record<string, unknown>>(items: T[]): T[] =>
  items.map((item) => serializeProyectoResponse(item));

// ============================================
// Función para notificar al servicio de automatizaciones
// ============================================

interface ProyectoWebhookPayload {

  proyectoId: number;
  nombre: string;
  descripcion: string | null;
  areasIds: number[];
  motivosIds: number[];
  destrezasRequeridasIds: number[];
  dificultadesIds: number[];
  misionesIds: number[];
}

async function notifyAutomatizacionesProyecto(payload: ProyectoWebhookPayload): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_AUTOMATIZACIONES_PROYECTO_URL || 'http://automatizaciones:3100/webhook/proyecto';

  try {
    console.log('📨 Notificando a automatizaciones:', webhookUrl);

    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`Webhook respondió con status ${response.status}`);
    }

    console.log('✅ Webhook notificado exitosamente');
  } catch (error) {
    console.error('❌ Error notificando webhook proyecto:', error);
    throw error;
  }
}

export async function GET() {
  try {
    const proyectos = await prisma.proyectoEstrategico.findMany({
      orderBy: { createdAt: 'desc' },
    });
    const serialized = serializeProyectosResponse(proyectos);
    return NextResponse.json({ success: true, data: serialized });
  } catch (error) {
    console.error('Error fetching proyectos estrategicos:', error);
    return NextResponse.json({ success: false, error: 'Error fetching proyectos estrategicos' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { ideaId, nombre, descripcion, areasIds, motivosIds, destrezasRequeridasIds, dificultadesIds, misionesIds, justificacionEstrategica, objetivosSmart, fechaInicio, fechaFinEstimada, estado, prioridadGlobal, scoreMotivacional, scoreAlineacion } = body;

    // Basic validation
    if (!nombre) {
      return NextResponse.json({ success: false, error: 'Project name is required' }, { status: 400 });
    }

    const proyecto = await prisma.proyectoEstrategico.create({
      data: {
        nombre,
        descripcion,
        areasIds: areasIds || [],
        motivosIds: motivosIds || [],
        destrezasRequeridasIds: destrezasRequeridasIds || [],
        dificultadesIds: dificultadesIds || [],
        misionesIds: misionesIds || [],
        justificacionEstrategica,
        objetivosSmart,
        fechaInicio: fechaInicio ? new Date(fechaInicio) : undefined,
        fechaFinEstimada: fechaFinEstimada ? new Date(fechaFinEstimada) : undefined,
        estado,
        prioridadGlobal,
        scoreMotivacional,
        scoreAlineacion,
      },
    });

    // If ideaId is provided, update the IdeaCapturada
    if (ideaId) {
      await prisma.ideaCapturada.update({
        where: { id: ideaId },
        data: {
          implementada: true,
          proyectoEstrategicoId: proyecto.id,
          fechaImplementacion: new Date(),
        },
      });
    }

    // ✨ Notificar a automatizaciones para procesamiento con IA
    // No bloqueamos la respuesta, ejecutamos en background
    notifyAutomatizacionesProyecto({
      proyectoId: proyecto.id,
      nombre: proyecto.nombre,
      descripcion: proyecto.descripcion,
      areasIds: proyecto.areasIds as number[],
      motivosIds: proyecto.motivosIds as number[],
      destrezasRequeridasIds: proyecto.destrezasRequeridasIds as number[],
      dificultadesIds: proyecto.dificultadesIds as number[],
      misionesIds: proyecto.misionesIds as number[],
    }).catch(error => {
      console.error('Error notificando webhook proyecto:', error);
    });

    const serialized = serializeProyectoResponse(proyecto);
    return NextResponse.json({ success: true, data: serialized }, { status: 201 });
  } catch (error) {
    console.error('Error creating proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: 'Error creating proyecto estrategico' }, { status: 500 });
  }
}