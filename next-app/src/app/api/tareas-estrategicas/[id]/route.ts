import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid strategic task ID' }, { status: 400 });
    }

    const tarea = await prisma.tareaEstrategica.findUnique({
      where: { id },
      include: {
        subtareas: true,
      },
    });

    if (!tarea) {
      return NextResponse.json({ success: false, error: 'Strategic task not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: tarea });
  } catch (error) {
    console.error('Error fetching strategic task:', error);
    return NextResponse.json({ success: false, error: 'Error fetching strategic task' }, { status: 500 });
  }
}

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid strategic task ID' }, { status: 400 });
    }

    const body = await request.json();
    const { nombre, descripcion, estado, ...rest } = body;

    const updatedTarea = await prisma.tareaEstrategica.update({
      where: { id },
      data: {
        nombre,
        descripcion,
        estado,
        ...rest,
      },
    });

    return NextResponse.json({ success: true, data: updatedTarea });
  } catch (error) {
    console.error('Error updating strategic task:', error);
    return NextResponse.json({ success: false, error: 'Error updating strategic task' }, { status: 500 });
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid strategic task ID' }, { status: 400 });
    }

    await prisma.tareaEstrategica.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Strategic task deleted successfully' }, { status: 200 });
  } catch (error) {
    console.error('Error deleting strategic task:', error);
    return NextResponse.json({ success: false, error: 'Error deleting strategic task' }, { status: 500 });
  }
}
