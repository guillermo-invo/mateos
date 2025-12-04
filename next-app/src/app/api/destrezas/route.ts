import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const destrezas = await prisma.destrezas.findMany({
      orderBy: { nombre: 'asc' },
    });
    return NextResponse.json({ success: true, data: destrezas });
  } catch (error) {
    console.error('Error fetching destrezas:', error);
    return NextResponse.json({ success: false, error: 'Error fetching destrezas' }, { status: 500 });
  }
}
