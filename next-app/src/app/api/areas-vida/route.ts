import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const areas = await prisma.areasVida.findMany({
      orderBy: { nombre: 'asc' }, // Order by name for consistency
    });
    return NextResponse.json({ success: true, data: areas });
  } catch (error) {
    console.error('Error fetching areas de vida:', error);
    return NextResponse.json({ success: false, error: 'Error fetching areas de vida' }, { status: 500 });
  }
}
