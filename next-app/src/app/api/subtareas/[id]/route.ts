import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid subtask ID' }, { status: 400 });
    }

    const subtarea = await prisma.subtareaEstrategica.findUnique({
      where: { id },
    });

    if (!subtarea) {
      return NextResponse.json({ success: false, error: 'Subtask not found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: subtarea });
  } catch (error) {
    console.error('Error fetching subtask:', error);
    return NextResponse.json({ success: false, error: 'Error fetching subtask' }, { status: 500 });
  }
}

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid subtask ID' }, { status: 400 });
    }

    const body = await request.json();
    const { titulo, completada, ...rest } = body;

    const updatedSubtarea = await prisma.subtareaEstrategica.update({
      where: { id },
      data: {
        nombre: titulo,
        ...rest,
      },
    });

    return NextResponse.json({ success: true, data: updatedSubtarea });
  } catch (error) {
    console.error('Error updating subtask:', error);
    return NextResponse.json({ success: false, error: 'Error updating subtask' }, { status: 500 });
  }
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid subtask ID' }, { status: 400 });
    }

    const body = await request.json();
    const { estadoKanban } = body;

    if (!estadoKanban) {
      return NextResponse.json(
        { success: false, error: 'estadoKanban is required' },
        { status: 400 }
      );
    }

    // Validate estadoKanban value
    const validEstados = ['freezer', 'backlog', 'waiting', 'todo', 'doing', 'done'];
    if (!validEstados.includes(estadoKanban)) {
      return NextResponse.json(
        { success: false, error: `Invalid estadoKanban. Must be one of: ${validEstados.join(', ')}` },
        { status: 400 }
      );
    }

    // Build update data
    const updateData: any = {
      estadoKanban,
    };

    // If moving to 'done', set fechaDone
    if (estadoKanban === 'done') {
      updateData.fechaDone = new Date();
    }
    // If moving away from 'done', clear fechaDone
    else {
      updateData.fechaDone = null;
    }

    const updatedSubtarea = await prisma.subtareaEstrategica.update({
      where: { id },
      data: updateData,
    });

    return NextResponse.json({
      success: true,
      data: updatedSubtarea,
      message: 'Subtask estado updated successfully',
    });
  } catch (error) {
    console.error('Error updating subtask estado:', error);
    return NextResponse.json(
      { success: false, error: 'Error updating subtask estado' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid subtask ID' }, { status: 400 });
    }

    await prisma.subtareaEstrategica.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Subtask deleted successfully' }, { status: 200 });
  } catch (error) {
    console.error('Error deleting subtask:', error);
    return NextResponse.json({ success: false, error: 'Error deleting subtask' }, { status: 500 });
  }
}
