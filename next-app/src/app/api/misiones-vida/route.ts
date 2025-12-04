import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const misiones = await prisma.misionesVida.findMany({
      orderBy: { nombre: 'asc' },
    });
    return NextResponse.json({ success: true, data: misiones });
  } catch (error) {
    console.error('Error fetching misiones de vida:', error);
    return NextResponse.json({ success: false, error: 'Error fetching misiones de vida' }, { status: 500 });
  }
}
