import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const motivos = await prisma.motivosPersonales.findMany({
      orderBy: { nombre: 'asc' },
    });
    return NextResponse.json({ success: true, data: motivos });
  } catch (error) {
    console.error('Error fetching motivos personales:', error);
    return NextResponse.json({ success: false, error: 'Error fetching motivos personales' }, { status: 500 });
  }
}
