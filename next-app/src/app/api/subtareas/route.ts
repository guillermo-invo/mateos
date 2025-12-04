import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const tareaId = searchParams.get('tareaId');

    const subtareas = await prisma.subtareaEstrategica.findMany({
      where: tareaId ? { tareaEstrategicaId: parseInt(tareaId, 10) } : undefined,
      orderBy: { createdAt: 'asc' }, // Or by order field if available
    });
    return NextResponse.json({ success: true, data: subtareas });
  } catch (error) {
    console.error('Error fetching subtareas:', error);
    return NextResponse.json({ success: false, error: 'Error fetching subtareas' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    // Basic validation
    if (!body.titulo || !body.tareaEstrategicaId) {
      return NextResponse.json({ success: false, error: 'Subtask title and strategic task ID are required' }, { status: 400 });
    }

    const subtarea = await prisma.subtareaEstrategica.create({
      data: {
        nombre: body.titulo,
        tareaEstrategicaId: body.tareaEstrategicaId,
        estadoKanban: 'backlog',
        tiempoEstimadoMinutos: body.tiempoEstimadoMinutos,
        moscow: body.moscow,
        destrezaPrincipalId: body.destrezaPrincipalId,
      },
    });

    return NextResponse.json({ success: true, data: subtarea }, { status: 201 });
  } catch (error) {
    console.error('Error creating subtarea:', error);
    return NextResponse.json({ success: false, error: 'Error creating subtarea' }, { status: 500 });
  }
}
