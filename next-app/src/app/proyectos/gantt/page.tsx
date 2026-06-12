'use client';

import { useEffect, useState, useRef } from 'react';
import Gantt from 'frappe-gantt';
import type { ProyectoGantt, FrappeGanttTask } from '@/types/gantt';

export default function GanttPage() {
  const [proyectos, setProyectos] = useState<ProyectoGantt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const ganttRef = useRef<HTMLDivElement>(null);
  const ganttInstance = useRef<Gantt | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch('/api/proyectos-estrategicos/gantt');
        const result = await response.json();

        if (result.success) {
          setProyectos(result.data);
        } else {
          setError('Error al cargar los datos');
        }
      } catch (err) {
        setError('Error al cargar los datos');
        console.error(err);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  useEffect(() => {
    if (!loading && proyectos.length > 0 && ganttRef.current) {
      const tasks = transformToGanttTasks(proyectos);

      if (ganttInstance.current) {
        ganttInstance.current.refresh(tasks);
      } else {
        ganttInstance.current = new Gantt(ganttRef.current, tasks, {
          view_mode: 'Month',
          bar_height: 20,
          bar_corner_radius: 3,
          arrow_curve: 5,
          padding: 18,
          language: 'es',
          custom_popup_html: function(task) {
            const start = new Date(task.start);
            const end = new Date(task.end);
            return `
              <div class="gantt-popup">
                <div class="gantt-popup-title">${task.name}</div>
                <div class="gantt-popup-dates">
                  ${start.toLocaleDateString('es-ES')} - ${end.toLocaleDateString('es-ES')}
                </div>
              </div>
            `;
          }
        });
      }
    }
  }, [loading, proyectos]);

  function transformToGanttTasks(proyectos: ProyectoGantt[]): FrappeGanttTask[] {
    const tasks: FrappeGanttTask[] = [];
    const today = new Date();
    const defaultEnd = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000); // +30 días

    proyectos.forEach((proyecto) => {
      // Agregar proyecto
      const proyectoStart = proyecto.fechaInicio ? new Date(proyecto.fechaInicio) : today;
      const proyectoEnd = proyecto.fechaFinEstimada ? new Date(proyecto.fechaFinEstimada) : defaultEnd;

      tasks.push({
        id: `proyecto-${proyecto.id}`,
        name: proyecto.nombre,
        start: formatDate(proyectoStart),
        end: formatDate(proyectoEnd),
        progress: 0,
        custom_class: 'gantt-proyecto',
      });

      // Agregar tareas
      proyecto.tareasEstrategicas.forEach((tarea) => {
        const tareaStart = tarea.fechaInicio ? new Date(tarea.fechaInicio) : proyectoStart;
        const tareaEnd = tarea.fechaFin ? new Date(tarea.fechaFin) : proyectoEnd;

        tasks.push({
          id: `tarea-${tarea.id}`,
          name: `  ${tarea.nombre}`,
          start: formatDate(tareaStart),
          end: formatDate(tareaEnd),
          progress: 0,
          custom_class: 'gantt-tarea',
        });

        // Agregar subtareas
        tarea.subtareasEstrategicas.forEach((subtarea) => {
          const subtareaStart = subtarea.fechaInicio ? new Date(subtarea.fechaInicio) : tareaStart;
          const subtareaEnd = subtarea.fechaFin ? new Date(subtarea.fechaFin) : tareaEnd;

          tasks.push({
            id: `subtarea-${subtarea.id}`,
            name: `    ${subtarea.nombre}`,
            start: formatDate(subtareaStart),
            end: formatDate(subtareaEnd),
            progress: 0,
            custom_class: 'gantt-subtarea',
          });
        });
      });
    });

    return tasks;
  }

  function formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-lg">Cargando...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-lg text-red-500">{error}</div>
      </div>
    );
  }

  if (proyectos.length === 0) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-lg">No hay proyectos activos para mostrar</div>
      </div>
    );
  }

  return (
    <div className="p-4">
      <h1 className="text-2xl font-bold mb-4">Vista Gantt - Proyectos Estratégicos</h1>
      <div className="gantt-container">
        <svg ref={ganttRef}></svg>
      </div>
    </div>
  );
}
