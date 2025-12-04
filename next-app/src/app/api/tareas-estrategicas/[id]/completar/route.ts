import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid strategic task ID' }, { status: 400 });
    }

    const updatedTarea = await prisma.tareaEstrategica.update({
      where: { id },
      data: {
        estadoKanban: 'done', // Set status to completed
        fechaDone: new Date(), // Update completion timestamp
      },
    });

    return NextResponse.json({ success: true, data: updatedTarea });
  } catch (error) {
    console.error('Error completing strategic task:', error);
    return NextResponse.json({ success: false, error: 'Error completing strategic task' }, { status: 500 });
  }
}
