import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { serializePrismaData } from '@/lib/serializePrisma';

export async function GET() {
  try {
    const proyectos = await prisma.proyectoEstrategico.findMany({
      where: {
        estado: {
          in: ['planificacion', 'en_curso'],
        },
      },
      select: {
        id: true,
        nombre: true,
        fechaInicio: true,
        fechaFinEstimada: true,
        tareasEstrategicas: {
          select: {
            id: true,
            nombre: true,
            orden: true,
            fechaInicio: true,
            fechaFin: true,
            subtareasEstrategicas: {
              select: {
                id: true,
                nombre: true,
                fechaInicio: true,
                fechaFin: true,
              },
              orderBy: {
                id: 'asc',
              },
            },
          },
          orderBy: {
            orden: 'asc',
          },
        },
      },
      orderBy: {
        id: 'asc',
      },
    });

    const serialized = serializePrismaData(proyectos);
    return NextResponse.json({ success: true, data: serialized });
  } catch (error) {
    console.error('Error fetching gantt data:', error);
    return NextResponse.json(
      { success: false, error: 'Error fetching gantt data' },
      { status: 500 }
    );
  }
}
