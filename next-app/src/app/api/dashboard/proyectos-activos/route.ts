import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const proyectos = await prisma.$queryRaw`SELECT * FROM vista_proyectos_activos ORDER BY prioridad_global DESC`;
    return NextResponse.json({ success: true, data: proyectos });
  } catch (error) {
    console.error('Error fetching proyectos activos:', error);
    return NextResponse.json({ success: false, error: 'Error fetching proyectos activos' }, { status: 500 });
  }
}
