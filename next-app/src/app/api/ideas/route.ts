import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * GET /api/ideas
 * Returns all ideas with optional filtering
 * Query params:
 *   - implementada: "true" | "false" to filter by implementation status
 *   - categoria: string to filter by category
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const implementadaParam = searchParams.get('implementada');
    const categoria = searchParams.get('categoria');

    const where: any = {};

    // Filter by implementation status if specified
    if (implementadaParam !== null) {
      where.proyectoEstrategicoId = implementadaParam === 'true' ? { not: null } : null;
    }

    // Filter by category if specified
    if (categoria) {
      where.categoria = categoria;
    }

    const ideas = await prisma.ideaCapturada.findMany({
      where,
      include: {
        proyectoEstrategico: {
          select: {
            id: true,
            nombre: true,
            estado: true,
          },
        },
        notaAudio: {
          select: {
            id: true,
            fechaGrabacion: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return NextResponse.json({
      success: true,
      data: ideas,
      count: ideas.length,
    });
  } catch (error) {
    console.error('Error fetching ideas:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to fetch ideas',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

/**
 * POST /api/ideas
 * Creates a new idea
 * Body: {
 *   titulo: string (required)
 *   descripcion?: string
 *   categoria?: string
 *   notaAudioId?: number (optional - will create placeholder if not provided)
 * }
 */
export async function POST(request: Request) {
  try {
    const body = await request.json();
    let { titulo, descripcion, categoria, notaAudioId } = body;

    // Validate required fields
    if (!titulo) {
      return NextResponse.json(
        {
          success: false,
          error: 'Missing required field: titulo is required',
        },
        { status: 400 }
      );
    }

    // If no notaAudioId provided, create a placeholder for manual entries
    if (!notaAudioId) {
      // Create a placeholder NotaAudio for manually-created ideas
      const placeholderNota = await prisma.notaAudio.create({
        data: {
          transcripcionId: Math.floor(Date.now() / 1000), // Use timestamp as unique ID
          transcripcionCompleta: `[Idea creada manualmente: ${titulo}]`,
          resumenEjecutivo: descripcion || 'Idea capturada desde UI',
          tipoDetectado: 'idea',
          procesado: true,
          fechaGrabacion: new Date(),
        },
      });
      notaAudioId = placeholderNota.id;
    } else {
      // Verify that provided notaAudio exists
      const notaAudio = await prisma.notaAudio.findUnique({
        where: { id: notaAudioId },
      });

      if (!notaAudio) {
        return NextResponse.json(
          {
            success: false,
            error: `NotaAudio with id ${notaAudioId} not found`,
          },
          { status: 404 }
        );
      }
    }

    const nuevaIdea = await prisma.ideaCapturada.create({
      data: {
        titulo,
        descripcion,
        categoria,
        notaAudioId,
      },
      include: {
        notaAudio: {
          select: {
            id: true,
            fechaGrabacion: true,
          },
        },
      },
    });

    return NextResponse.json(
      {
        success: true,
        data: nuevaIdea,
        message: 'Idea created successfully',
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('Error creating idea:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to create idea',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
