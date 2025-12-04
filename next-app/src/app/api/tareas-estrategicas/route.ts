import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const proyectoId = searchParams.get('proyectoId');

    const tareas = await prisma.tareaEstrategica.findMany({
      where: proyectoId ? { proyectoId: parseInt(proyectoId, 10) } : undefined,
      orderBy: { orden: 'asc' },
      include: {
        subtareas: true,
      },
    });
    return NextResponse.json({ success: true, data: tareas });
  } catch (error) {
    console.error('Error fetching tareas estrategicas:', error);
    return NextResponse.json({ success: false, error: 'Error fetching tareas estrategicas' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    // Basic validation
    if (!body.nombre || !body.proyectoId) {
      return NextResponse.json({ success: false, error: 'Task name and project ID are required' }, { status: 400 });
    }

    const tarea = await prisma.tareaEstrategica.create({
      data: {
        nombre: body.nombre,
        descripcion: body.descripcion,
        proyectoId: body.proyectoId,
        orden: body.orden,
        moscow: body.moscow,
        tiempoEstimadoHoras: body.tiempoEstimadoHoras,
        nivelRiesgo: body.nivelRiesgo,
        prioridadVelocidadPerfeccion: body.prioridadVelocidadPerfeccion,
        estado: body.estado,
      },
    });

    return NextResponse.json({ success: true, data: tarea }, { status: 201 });
  } catch (error) {
    console.error('Error creating tarea estrategica:', error);
    return NextResponse.json({ success: false, error: 'Error creating tarea estrategica' }, { status: 500 });
  }
}
