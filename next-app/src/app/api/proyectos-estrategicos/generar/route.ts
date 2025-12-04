import { NextResponse } from 'next/server';

// Assuming the automatizaciones service is accessible via an environment variable or known URL
const AUTOMATIZACIONES_SERVICE_URL = process.env.AUTOMATIZACIONES_SERVICE_URL || 'http://localhost:1410'; // Default to 1410 as per plan

export async function POST(request: Request) {
  try {
    const { descripcion, documentosUrls, ideaId } = await request.json();

    if (!descripcion) {
      return NextResponse.json({ success: false, error: 'Description is required for project generation' }, { status: 400 });
    }

    // Call the automatizaciones service to generate and save the project
    const response = await fetch(`${AUTOMATIZACIONES_SERVICE_URL}/generar-proyecto`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ descripcion, documentosUrls, ideaId }), // Pass ideaId to automatizaciones service
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to generate project from automatizaciones service');
    }

    const result = await response.json();
    return NextResponse.json({ success: true, data: result.projectId }, { status: 201 });

  } catch (error) {
    console.error('Error generating proyecto estrategico:', error);
    return NextResponse.json({ success: false, error: error instanceof Error ? error.message : 'Error generating proyecto estrategico' }, { status: 500 });
  }
}