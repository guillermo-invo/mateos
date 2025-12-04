import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const [
      totalProyectos,
      proyectosEnCurso,
      totalTareasEstrategicas,
      tareasEstrategicasPendientes,
      totalSubtareas,
      subtareasPendientes,
    ] = await Promise.all([
      prisma.proyectoEstrategico.count(),
      prisma.proyectoEstrategico.count({ where: { estado: 'en_curso' } }),
      prisma.tareaEstrategica.count(),
      prisma.tareaEstrategica.count({ where: { estadoKanban: { in: ['todo', 'doing'] } } }),
      prisma.subtareaEstrategica.count(),
      prisma.subtareaEstrategica.count({ where: { estadoKanban: { not: 'done' } } }),
    ]);

    return NextResponse.json({
      success: true,
      data: {
        totalProyectos,
        proyectosEnCurso,
        totalTareasEstrategicas,
        tareasEstrategicasPendientes,
        totalSubtareas,
        subtareasPendientes,
      },
    });
  } catch (error) {
    console.error('Error fetching dashboard metrics:', error);
    return NextResponse.json({ success: false, error: 'Error fetching dashboard metrics' }, { status: 500 });
  }
}
