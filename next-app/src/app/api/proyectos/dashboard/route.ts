import { NextResponse } from 'next/server';
import { PrismaClient, TipoEstadoProyecto } from '@prisma/client';

const prisma = new PrismaClient();

const ESTADOS_VISIBLES: TipoEstadoProyecto[] = [
  TipoEstadoProyecto.planificacion,
  TipoEstadoProyecto.en_curso,
];

interface ProyectoConCalculos {




  id: number;
  nombre: string;
  estado: string;
  progreso: number;
  horasTotal: number;
  horasCompletadas: number;
  horasRestantes: number;
  descripcion: string | null;
  areasIds: number[];
}

interface AreaConProyectos {
  id: number;
  nombre: string;
  colorHex: string | null;
  proyectos: ProyectoConCalculos[];
}

/**
 * GET /api/proyectos/dashboard
 * Returns all projects organized by life areas with time calculations
 */
export async function GET() {
  try {
    // Get all projects with their subtasks
    const estadosActivos: Array<'planificacion' | 'en_curso'> = ['planificacion', 'en_curso'];

    const proyectos = await prisma.proyectoEstrategico.findMany({
      where: {
        estado: {
          in: ['planificacion', 'en_curso'],
        },
      },
      include: {
        tareasEstrategicas: {
          include: {
            subtareasEstrategicas: {
              select: {
                tiempoEstimadoMinutos: true,
                estadoKanban: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });




    // Get all areas de vida
    const areas = await prisma.areasVida.findMany({
      where: {
        activa: true,
      },
      orderBy: {
        ordenVisualizacion: 'asc',
      },
    });

    // Calculate time metrics for each project
    const proyectosConCalculos: ProyectoConCalculos[] = proyectos.map((proyecto) => {
      // Get all subtasks from all tasks
      const todasLasSubtareas = proyecto.tareasEstrategicas.flatMap(
        (tarea) => tarea.subtareasEstrategicas
      );

      // Calculate total estimated time (convert minutes to hours)
      const minutosTotal = todasLasSubtareas.reduce(
        (sum, subtarea) => sum + (subtarea.tiempoEstimadoMinutos || 0),
        0
      );
      const horasTotal = minutosTotal / 60;

      // Calculate completed time
      const minutosCompletados = todasLasSubtareas
        .filter((subtarea) => subtarea.estadoKanban === 'done')
        .reduce((sum, subtarea) => sum + (subtarea.tiempoEstimadoMinutos || 0), 0);
      const horasCompletadas = minutosCompletados / 60;

      // Calculate remaining time
      const horasRestantes = horasTotal - horasCompletadas;

      // Calculate progress percentage
      const progreso = horasTotal > 0 ? (horasCompletadas / horasTotal) * 100 : 0;

      return {
        id: proyecto.id,
        nombre: proyecto.nombre,
        estado: proyecto.estado,
        progreso: Math.round(progreso * 10) / 10, // Round to 1 decimal
        horasTotal: Math.round(horasTotal * 10) / 10,
        horasCompletadas: Math.round(horasCompletadas * 10) / 10,
        horasRestantes: Math.round(horasRestantes * 10) / 10,
        descripcion: proyecto.descripcion,
        areasIds: proyecto.areasIds,
      };
    });

    // Organize projects by area
    const areaMap: Map<number, AreaConProyectos> = new Map();

    // Initialize areas
    areas.forEach((area) => {
      areaMap.set(area.id, {
        id: area.id,
        nombre: area.nombre,
        colorHex: area.colorHex,
        proyectos: [],
      });
    });

    // Assign projects to areas
    proyectosConCalculos.forEach((proyecto) => {
      proyecto.areasIds.forEach((areaId) => {
        const area = areaMap.get(areaId);
        if (area) {
          area.proyectos.push(proyecto);
        }
      });
    });

    // Convert map to array and filter out areas without projects
    const areasConProyectos = Array.from(areaMap.values()).filter(
      (area) => area.proyectos.length > 0
    );

    // Also include projects without area
    const proyectosSinArea = proyectosConCalculos.filter(
      (p) => p.areasIds.length === 0
    );

    if (proyectosSinArea.length > 0) {
      areasConProyectos.push({
        id: 0,
        nombre: 'Sin Área Asignada',
        colorHex: '#808080',
        proyectos: proyectosSinArea,
      });
    }

    return NextResponse.json({
      success: true,
      data: {
        areas: areasConProyectos,
        totalProyectos: proyectos.length,
      },
    });
  } catch (error) {
    console.error('Error fetching proyectos dashboard:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to fetch proyectos dashboard',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
