import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const energia = searchParams.get('energia');
    const horas = searchParams.get('horas');
    const momento = searchParams.get('momento');

    // For now, directly query the view.
    // In a more complex scenario, parameters might be used to filter the view or apply logic.
    const tareas = await prisma.$queryRaw`SELECT * FROM vista_que_hacer_ahora ORDER BY score_prioridad DESC`;

    return NextResponse.json({ success: true, data: tareas });
  } catch (error) {
    console.error('Error fetching "que-hacer-ahora" data:', error);
    return NextResponse.json({ success: false, error: 'Error fetching "que-hacer-ahora" data' }, { status: 500 });
  }
}
