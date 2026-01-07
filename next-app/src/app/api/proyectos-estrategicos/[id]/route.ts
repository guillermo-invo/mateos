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

  // Convert decimal fields (which may be strings, Decimals, or null) to numbers
  decimalFields.forEach((field: DecimalField) => {
    const value = normalized[field];
    if (value !== null && value !== undefined) {
      // Handle both Prisma Decimal objects and string representations
      const stringValue = typeof value === 'string' ? value : String(value);
      const numValue = parseFloat(stringValue);
      normalized[field] = Number.isFinite(numValue) ? numValue : null;
    } else {
      normalized[field] = null;
    }
  });

  return normalized as T;
};

const parseIdParam = async (context: { params: Promise<{ id: string }> }): Promise<number | null> => {
  const { id: idStr } = await context.params;
  const id = parseInt(idStr, 10);
  return Number.isFinite(id) && id > 0 ? id : null;
};

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const id = await parseIdParam(context);
    if (id === null) {
      return NextResponse.json({ success: false, error: 'Invalid project ID' }, { status: 400 });
    }

    const proyecto = await prisma.proyectoEstrategico.findUnique({
      where: { id },
      include: {
        tareasEstrategicas: {
          select: {
            id: true,
            nombre: true,
            descripcion: true,
            orden: true,
            moscow: true,
            tiempoEstimadoHoras: true,
            nivelRiesgo: true,
            estadoKanban: true,
            fechaDone: true,
            impacto: true,
            urgencia: true,
            eisenhower: true,
            subtareasEstrategicas: {
              select: {
                id: true,
                nombre: true,
                estadoKanban: true,
                fechaDone: true,
                tiempoEstimadoMinutos: true,
                moscow: true,
              },
            },
          },
        },
      },
    });

    if (!proyecto) {
      return NextResponse.json({ success: false, error: 'Project not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: serializeProyectoResponse(proyecto) });
  } catch (error) {
    console.error('Error fetching proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: 'Error fetching proyecto estrategico' }, { status: 500 });
  }
}

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const id = await parseIdParam(context);
    if (id === null) {
      return NextResponse.json({ success: false, error: 'Invalid project ID' }, { status: 400 });
    }

    const body = await request.json();
    const { nombre, descripcion, estado, ...rest } = body;

    const updatedProyecto = await prisma.proyectoEstrategico.update({
      where: { id },
      data: {
        nombre,
        descripcion,
        estado,
        ...rest,
      },
    });

    return NextResponse.json({ success: true, data: serializeProyectoResponse(updatedProyecto) });
  } catch (error) {
    console.error('Error updating proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: 'Error updating proyecto estrategico' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const id = await parseIdParam(context);
    if (id === null) {
      return NextResponse.json({ success: false, error: 'Invalid project ID' }, { status: 400 });
    }

    await prisma.proyectoEstrategico.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Project deleted successfully' }, { status: 200 });
  } catch (error) {
    console.error('Error deleting proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: 'Error deleting proyecto estrategico' }, { status: 500 });
  }
}
