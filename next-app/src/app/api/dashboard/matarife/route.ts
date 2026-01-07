import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper function to convert BigInt to Number in objects
function convertBigIntToNumber(obj: any): any {
  if (obj === null || obj === undefined) return obj;

  if (typeof obj === 'bigint') {
    return Number(obj);
  }

  if (Array.isArray(obj)) {
    return obj.map(convertBigIntToNumber);
  }

  if (typeof obj === 'object') {
    const converted: any = {};
    for (const key in obj) {
      converted[key] = convertBigIntToNumber(obj[key]);
    }
    return converted;
  }

  return obj;
}

export async function GET() {
  try {
    const veredictos = await prisma.$queryRaw`SELECT * FROM vista_matarife WHERE veredicto != 'OK' ORDER BY tarea_id DESC`;
    const serializedVeredictos = convertBigIntToNumber(veredictos);
    return NextResponse.json({ success: true, data: serializedVeredictos });
  } catch (error) {
    console.error('Error fetching "matarife" data:', error);
    return NextResponse.json({ success: false, error: 'Error fetching "matarife" data' }, { status: 500 });
  }
}
