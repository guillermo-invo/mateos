import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id: idStr } = await context.params;
    const id = parseInt(idStr, 10);
    if (isNaN(id)) {
      return NextResponse.json({ success: false, error: 'Invalid subtask ID' }, { status: 400 });
    }

    const updatedSubtarea = await prisma.subtareaEstrategica.update({
      where: { id },
      data: {
        estadoKanban: 'done', // Set status to completed
        fechaDone: new Date(), // Update timestamp
      },
    });

    return NextResponse.json({ success: true, data: updatedSubtarea });
  } catch (error) {
    console.error('Error completing subtask:', error);
    return NextResponse.json({ success: false, error: 'Error completing subtask' }, { status: 500 });
  }
}
