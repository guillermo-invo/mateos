import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * GET /api/ideas/disponibles
 * Returns all ideas that haven't been implemented as projects yet
 * (where proyectoEstrategicoId is null)
 */
export async function GET() {
  try {
    const ideasDisponibles = await prisma.ideaCapturada.findMany({
      where: {
        proyectoEstrategicoId: null,
      },
      select: {
        id: true,
        titulo: true,
        descripcion: true,
        categoria: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return NextResponse.json({
      success: true,
      data: ideasDisponibles,
      count: ideasDisponibles.length,
    });
  } catch (error) {
    console.error('Error fetching available ideas:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to fetch available ideas',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
