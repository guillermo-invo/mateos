import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * GET /api/ideas/[id]
 * Returns a single idea by ID
 */
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const id = parseInt(params.id);

    if (isNaN(id)) {
      return NextResponse.json(
        { success: false, error: 'Invalid ID format' },
        { status: 400 }
      );
    }

    const idea = await prisma.ideaCapturada.findUnique({
      where: { id },
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
    });

    if (!idea) {
      return NextResponse.json(
        { success: false, error: 'Idea not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      data: idea,
    });
  } catch (error) {
    console.error('Error fetching idea:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to fetch idea',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

/**
 * PUT /api/ideas/[id]
 * Updates an existing idea
 * Body: {
 *   titulo?: string
 *   descripcion?: string
 *   categoria?: string
 * }
 */
export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const id = parseInt(params.id);

    if (isNaN(id)) {
      return NextResponse.json(
        { success: false, error: 'Invalid ID format' },
        { status: 400 }
      );
    }

    const body = await request.json();
    const { titulo, descripcion, categoria } = body;

    // Check if idea exists
    const existingIdea = await prisma.ideaCapturada.findUnique({
      where: { id },
    });

    if (!existingIdea) {
      return NextResponse.json(
        { success: false, error: 'Idea not found' },
        { status: 404 }
      );
    }

    // Build update data object (only include provided fields)
    const updateData: any = {};
    if (titulo !== undefined) updateData.titulo = titulo;
    if (descripcion !== undefined) updateData.descripcion = descripcion;
    if (categoria !== undefined) updateData.categoria = categoria;

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json(
        { success: false, error: 'No fields to update' },
        { status: 400 }
      );
    }

    const updatedIdea = await prisma.ideaCapturada.update({
      where: { id },
      data: updateData,
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
    });

    return NextResponse.json({
      success: true,
      data: updatedIdea,
      message: 'Idea updated successfully',
    });
  } catch (error) {
    console.error('Error updating idea:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to update idea',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/ideas/[id]
 * Deletes an idea (only if not implemented as a project)
 */
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const id = parseInt(params.id);

    if (isNaN(id)) {
      return NextResponse.json(
        { success: false, error: 'Invalid ID format' },
        { status: 400 }
      );
    }

    // Check if idea exists and is not implemented
    const existingIdea = await prisma.ideaCapturada.findUnique({
      where: { id },
    });

    if (!existingIdea) {
      return NextResponse.json(
        { success: false, error: 'Idea not found' },
        { status: 404 }
      );
    }

    if (existingIdea.proyectoEstrategicoId !== null) {
      return NextResponse.json(
        {
          success: false,
          error: 'Cannot delete idea that has been implemented as a project',
        },
        { status: 400 }
      );
    }

    await prisma.ideaCapturada.delete({
      where: { id },
    });

    return NextResponse.json({
      success: true,
      message: 'Idea deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting idea:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to delete idea',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
