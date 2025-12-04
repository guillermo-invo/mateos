import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
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
              }
            }
          },
        },
      },
    });

    if (!proyecto) {
      return NextResponse.json({ success: false, error: 'Project not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: proyecto });
  } catch (error) {
    console.error('Error fetching proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: 'Error fetching proyecto estrategico' }, { status: 500 });
  }
}

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid project ID' }, { status: 400 });
    }

    const body = await request.json();
    const { nombre, descripcion, estado, ...rest } = body; // Destructure to safely update

    const updatedProyecto = await prisma.proyectoEstrategico.update({
      where: { id },
      data: {
        nombre,
        descripcion,
        estado,
        ...rest, // Allow other fields to be updated if provided
      },
    });

    return NextResponse.json({ success: true, data: updatedProyecto });
  } catch (error) {
    console.error('Error updating proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: 'Error updating proyecto estrategico' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
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
