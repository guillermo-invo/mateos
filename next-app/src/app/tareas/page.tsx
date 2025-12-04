'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';

interface Subtarea {
  id: number;
  titulo: string;
  completada: boolean;
}

interface TareaEstrategica {
  id: number;
  nombre: string;
  descripcion?: string;
  estado: string;
  proyecto?: string; // Will need to fetch project name
  subtareas: Subtarea[];
}

export default function TareasPage() {
  const [tareas, setTareas] = useState<TareaEstrategica[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        // Fetch all strategic tasks.
        // In a real app, this would be paginated and filtered.
        const response = await fetch('/api/tareas-estrategicas');
        if (!response.ok) {
          throw new Error('Failed to fetch strategic tasks');
        }
        const result = await response.json();
        // Assuming the API returns a 'proyecto' name with each task or we fetch it separately
        // For simplicity, I'll just use the raw data returned by the API
        setTareas(result.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  const handleCompleteToggle = async (id: number, currentStatus: string) => {
    // Optimistic UI update
    setTareas(prevTareas => prevTareas.map(tarea => 
      tarea.id === id ? { ...tarea, estado: currentStatus === 'completada' ? 'por_hacer' : 'completada' } : tarea
    ));

    try {
      const response = await fetch(`/api/tareas-estrategicas/${id}/completar`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ estado: currentStatus === 'completada' ? 'por_hacer' : 'completada' }), // Send the new status
      });
      if (!response.ok) {
        throw new Error('Failed to toggle task completion');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error toggling task completion');
      // Revert optimistic update if API call fails
      setTareas(prevTareas => prevTareas.map(tarea => 
        tarea.id === id ? { ...tarea, estado: currentStatus } : tarea
      ));
    }
  };


  if (loading) return <div className="p-6">Cargando tareas estratégicas...</div>;
  if (error) return <div className="p-6 text-red-500">Error: {error}</div>;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6 text-gray-900 dark:text-white">Tareas Estratégicas</h1>
      
      {tareas.length === 0 ? (
        <p className="text-gray-700 dark:text-gray-300">No hay tareas estratégicas para mostrar.</p>
      ) : (
        <div className="space-y-4">
          {tareas.map((tarea) => (
            <div key={tarea.id} className="bg-white p-4 rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-xl font-semibold">{tarea.nombre}</h2>
                <button
                  onClick={() => handleCompleteToggle(tarea.id, tarea.estado)}
                  className={`py-1 px-3 rounded text-sm ${
                    tarea.estado === 'completada' ? 'bg-green-500 text-white' : 'bg-gray-200 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
                  }`}
                >
                  {tarea.estado === 'completada' ? 'Completada' : 'Marcar Completada'}
                </button>
              </div>
              <p className="text-gray-600 dark:text-gray-400 mb-2">{tarea.descripcion}</p>
              <p className="text-sm text-gray-500 dark:text-gray-500">Estado: {tarea.estado}</p>
              {tarea.proyecto && <p className="text-sm text-gray-500 dark:text-gray-500">Proyecto: {tarea.proyecto}</p>}

              {tarea.subtareas.length > 0 && (
                <div className="mt-4 border-t border-gray-200 pt-4 dark:border-gray-700">
                  <h3 className="font-semibold text-md mb-2">Subtareas:</h3>
                  <ul>
                    {tarea.subtareas.map((subtarea) => (
                      <li key={subtarea.id} className="text-sm text-gray-700 dark:text-gray-300">
                        {subtarea.completada ? '✅' : '⬜'} {subtarea.titulo}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
