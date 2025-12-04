'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { Accordion, AccordionItem, Button } from '@heroui/react';

interface Proyecto {
  id: number;
  nombre: string;
  estado: string;
  progreso: number;
  horasTotal: number;
  horasCompletadas: number;
  horasRestantes: number;
  descripcion: string | null;
}

interface Area {
  id: number;
  nombre: string;
  colorHex: string | null;
  proyectos: Proyecto[];
}

interface DashboardData {
  areas: Area[];
  totalProyectos: number;
}

// Estado badge color mapping
const estadoColors: Record<string, string> = {
  idea: 'bg-gray-200 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
  planificacion: 'bg-blue-200 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
  en_curso: 'bg-green-200 text-green-800 dark:bg-green-900 dark:text-green-300',
  pausado: 'bg-yellow-200 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
  completado: 'bg-green-500 text-white',
  cancelado: 'bg-red-200 text-red-800 dark:bg-red-900 dark:text-red-300',
  archivado: 'bg-gray-400 text-gray-800 dark:bg-gray-600 dark:text-gray-200',
};

const estadoLabels: Record<string, string> = {
  idea: 'Idea',
  planificacion: 'Planificación',
  en_curso: 'En Curso',
  pausado: 'Pausado',
  completado: 'Completado',
  cancelado: 'Cancelado',
  archivado: 'Archivado',
};

export default function ProyectosPage() {
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch('/api/proyectos/dashboard');
        if (!response.ok) {
          throw new Error('Failed to fetch projects dashboard');
        }
        const result = await response.json();
        setDashboardData(result.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-300 dark:bg-gray-700 rounded w-1/3 mb-6"></div>
          <div className="h-10 bg-gray-300 dark:bg-gray-700 rounded w-1/4 mb-6"></div>
          <div className="space-y-4">
            <div className="h-32 bg-gray-300 dark:bg-gray-700 rounded"></div>
            <div className="h-32 bg-gray-300 dark:bg-gray-700 rounded"></div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-100 text-red-700 p-4 rounded dark:bg-red-900 dark:text-red-300">
          Error: {error}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          Proyectos Estratégicos
        </h1>
        <div className="flex gap-3">
          <Button
            as={Link}
            href="/proyectos/ideas"
            color="default"
            variant="bordered"
          >
            💡 Ideas
          </Button>
          <Button
            as={Link}
            href="/proyectos/crear"
            color="primary"
          >
            + Crear Proyecto
          </Button>
        </div>
      </div>

      {!dashboardData || dashboardData.totalProyectos === 0 ? (
        <div className="text-center py-12">
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            No hay proyectos para mostrar.
          </p>
          <Button
            as={Link}
            href="/proyectos/crear"
            color="primary"
          >
            Crear tu primer proyecto
          </Button>
        </div>
      ) : (
        <div className="space-y-4">
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            Total de proyectos: {dashboardData.totalProyectos}
          </p>

          <Accordion
            variant="splitted"
            defaultExpandedKeys="all"
            selectionMode="multiple"
          >
            {dashboardData.areas.map((area) => (
              <AccordionItem
                key={area.id}
                title={
                  <div className="flex items-center gap-2">
                    {area.colorHex && (
                      <div
                        className="w-4 h-4 rounded"
                        style={{ backgroundColor: area.colorHex }}
                      />
                    )}
                    <span className="font-bold text-lg text-gray-900 dark:text-white">
                      {area.nombre}
                    </span>
                    <span className="text-sm text-gray-500 dark:text-gray-400">
                      ({area.proyectos.length} {area.proyectos.length === 1 ? 'proyecto' : 'proyectos'})
                    </span>
                  </div>
                }
              >
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4">
                  {area.proyectos.map((proyecto) => (
                    <Link
                      key={proyecto.id}
                      href={`/proyectos/${proyecto.id}`}
                      className="block"
                    >
                      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition-shadow p-5 h-full border border-gray-200 dark:border-gray-700">
                        {/* Header with name and estado */}
                        <div className="flex justify-between items-start mb-3">
                          <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex-1">
                            {proyecto.nombre}
                          </h3>
                          <span
                            className={`text-xs px-2 py-1 rounded whitespace-nowrap ml-2 ${
                              estadoColors[proyecto.estado] || estadoColors.idea
                            }`}
                          >
                            {estadoLabels[proyecto.estado] || proyecto.estado}
                          </span>
                        </div>

                        {/* Progress bar */}
                        <div className="mb-3">
                          <div className="flex justify-between items-center mb-1">
                            <span className="text-sm text-gray-600 dark:text-gray-400">
                              Progreso
                            </span>
                            <span className="text-sm font-medium text-gray-900 dark:text-white">
                              {proyecto.progreso.toFixed(1)}%
                            </span>
                          </div>
                          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                            <div
                              className="bg-blue-500 h-2 rounded-full transition-all"
                              style={{ width: `${Math.min(proyecto.progreso, 100)}%` }}
                            />
                          </div>
                        </div>

                        {/* Time information */}
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                          <span className="font-medium text-gray-900 dark:text-white">
                            {proyecto.horasCompletadas.toFixed(1)}h
                          </span>
                          {' / '}
                          <span className="font-medium text-gray-900 dark:text-white">
                            {proyecto.horasTotal.toFixed(1)}h
                          </span>
                          <span className="text-gray-500 dark:text-gray-500 ml-2">
                            ({proyecto.horasRestantes.toFixed(1)}h restantes)
                          </span>
                        </div>

                        {/* Description preview */}
                        {proyecto.descripcion && (
                          <p className="text-sm text-gray-600 dark:text-gray-400 mt-3 line-clamp-2">
                            {proyecto.descripcion}
                          </p>
                        )}
                      </div>
                    </Link>
                  ))}
                </div>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      )}
    </div>
  );
}
