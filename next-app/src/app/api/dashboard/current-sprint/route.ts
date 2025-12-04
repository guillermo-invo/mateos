import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Calcula el inicio del sprint actual (lunes de esta semana a las 00:00)
 */
function getSprintStart(): Date {
  const now = new Date();
  const dayOfWeek = now.getDay(); // 0 = Domingo, 1 = Lunes, ..., 6 = Sábado
  const daysToSubtract = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Si es domingo, retrocede 6 días

  const sprintStart = new Date(now);
  sprintStart.setDate(now.getDate() - daysToSubtract);
  sprintStart.setHours(0, 0, 0, 0);

  return sprintStart;
}

/**
 * GET /api/dashboard/current-sprint
 * Retorna las tareas del sprint actual organizadas por áreas de vida
 */
export async function GET() {
  try {
    const sprintStart = getSprintStart();

    console.log('📅 Sprint Start:', sprintStart.toISOString());

    // 1. Traer todas las áreas de vida
    const areas = await prisma.areasVida.findMany({
      where: { activa: true },
      orderBy: { ordenVisualizacion: 'asc' },
    });

    // 2. Traer todos los proyectos activos con sus relaciones
    const proyectos = await prisma.proyectoEstrategico.findMany({
      where: {
        estado: { in: ['planificacion', 'en_curso'] },
      },
      include: {
        tareasEstrategicas: {
          include: {
            subtareasEstrategicas: {
              where: {
                OR: [
                  // Subtareas en waiting, todo, doing
                  { estadoKanban: { in: ['waiting', 'todo', 'doing'] } },
                  // Subtareas done pero dentro del sprint
                  {
                    estadoKanban: 'done',
                    fechaDone: { gte: sprintStart },
                  },
                ],
              },
              orderBy: { createdAt: 'asc' },
            },
          },
          orderBy: { orden: 'asc' },
        },
      },
    });

    // 3. Organizar datos por áreas de vida
    const areasConDatos = areas.map((area) => {
      // Filtrar proyectos que pertenecen a esta área
      const proyectosDelArea = proyectos.filter((p) =>
        p.areasIds.includes(area.id)
      );

      // Filtrar proyectos que tienen al menos una tarea con subtareas en el sprint
      const proyectosConTareas = proyectosDelArea
        .map((proyecto) => {
          // Filtrar tareas que tienen subtareas en el sprint
          const tareasConSubtareas = proyecto.tareasEstrategicas.filter(
            (tarea) => tarea.subtareasEstrategicas.length > 0
          );

          if (tareasConSubtareas.length === 0) return null;

          // Calcular progreso del proyecto
          const totalSubtareas = tareasConSubtareas.reduce(
            (sum, tarea) => sum + tarea.subtareasEstrategicas.length,
            0
          );
          const subtareasDone = tareasConSubtareas.reduce(
            (sum, tarea) =>
              sum +
              tarea.subtareasEstrategicas.filter(
                (sub) => sub.estadoKanban === 'done'
              ).length,
            0
          );
          const progress =
            totalSubtareas > 0
              ? Math.round((subtareasDone / totalSubtareas) * 100)
              : 0;

          return {
            id: proyecto.id.toString(),
            title: proyecto.nombre,
            progress,
            tasks: tareasConSubtareas.map((tarea) => ({
              id: tarea.id.toString(),
              title: tarea.nombre,
              subtasks: tarea.subtareasEstrategicas.map((sub) => ({
                id: sub.id.toString(),
                title: sub.nombre,
                status: sub.estadoKanban as
                  | 'waiting'
                  | 'todo'
                  | 'doing'
                  | 'done',
                estimate: sub.tiempoEstimadoMinutos
                  ? `${sub.tiempoEstimadoMinutos}min`
                  : 'N/A',
                moscow: (sub.moscow
                  ? (sub.moscow.charAt(0).toUpperCase() +
                      sub.moscow.slice(1).toLowerCase())
                  : 'Should') as 'Must' | 'Should' | 'Could' | "Won't",
              })),
            })),
          };
        })
        .filter((p) => p !== null);

      return {
        id: area.id.toString(),
        title: area.nombre,
        projects: proyectosConTareas,
      };
    });

    // 4. Filtrar áreas que tienen proyectos con tareas
    const areasConProyectos = areasConDatos.filter(
      (area) => area.projects.length > 0
    );

    return NextResponse.json({
      success: true,
      sprintStart: sprintStart.toISOString(),
      data: areasConProyectos,
    });
  } catch (error) {
    console.error('❌ Error fetching sprint data:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Error fetching sprint data',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  } finally {
    await prisma.$disconnect();
  }
}
