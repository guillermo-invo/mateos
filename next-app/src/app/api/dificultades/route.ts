import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const dificultades = await prisma.dificultades.findMany({
      orderBy: { nombre: 'asc' },
    });
    return NextResponse.json({ success: true, data: dificultades });
  } catch (error) {
    console.error('Error fetching dificultades:', error);
    return NextResponse.json({ success: false, error: 'Error fetching dificultades' }, { status: 500 });
  }
}
