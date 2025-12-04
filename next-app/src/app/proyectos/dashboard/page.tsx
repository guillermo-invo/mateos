'use client';

import React, { useEffect, useState } from 'react';
import KanbanTaskView, { AreaDeVida } from '@/components/KanbanTaskView';
import { Spinner } from '@heroui/react';

export default function DashboardPage() {
  const [data, setData] = useState<AreaDeVida[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sprintStart, setSprintStart] = useState<string | null>(null);

  useEffect(() => {
    const fetchSprintData = async () => {
      try {
        setLoading(true);
        const response = await fetch('/api/dashboard/current-sprint');
        const result = await response.json();

        if (!result.success) {
          throw new Error(result.error || 'Error fetching data');
        }

        setData(result.data);
        setSprintStart(result.sprintStart);
      } catch (err) {
        console.error('Error fetching sprint data:', err);
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    };

    fetchSprintData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Spinner size="lg" label="Cargando sprint actual..." />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-red-600 mb-2">Error</h2>
          <p className="text-gray-600">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8">
      <div className="max-w-7xl mx-auto px-4">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Sprint Actual
          </h1>
          {sprintStart && (
            <p className="text-gray-600 dark:text-gray-400">
              Inicio del sprint:{' '}
              {new Date(sprintStart).toLocaleDateString('es-UY', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
              })}
            </p>
          )}
        </div>

        {/* Kanban View */}
        {data.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500 dark:text-gray-400 text-lg">
              No hay tareas en el sprint actual.
            </p>
            <p className="text-gray-400 dark:text-gray-500 mt-2">
              Las subtareas deben estar en estado waiting, todo, doing o done
              para aparecer aquí.
            </p>
          </div>
        ) : (
          <KanbanTaskView data={data} />
        )}
      </div>
    </div>
  );
}
