import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const veredictos = await prisma.$queryRaw`SELECT * FROM vista_matarife WHERE veredicto != 'OK' ORDER BY tarea_id DESC`;
    return NextResponse.json({ success: true, data: veredictos });
  } catch (error) {
    console.error('Error fetching "matarife" data:', error);
    return NextResponse.json({ success: false, error: 'Error fetching "matarife" data' }, { status: 500 });
  }
}
