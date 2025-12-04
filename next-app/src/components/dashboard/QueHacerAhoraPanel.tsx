'use client';

import React, { useEffect, useState } from 'react';

interface TareaQueHacerAhora {
  id: number;
  titulo: string;
  tarea: string;
  proyecto: string;
  nivel_energia_requerido: string;
  mejor_momento: string[];
  tiempo_estimado_minutos: number;
  score_prioridad: number;
}

export default function QueHacerAhoraPanel() {
  const [tareas, setTareas] = useState<TareaQueHacerAhora[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch('/api/dashboard/que-hacer-ahora');
        if (!response.ok) {
          throw new Error('Failed to fetch data');
        }
        const result = await response.json();
        setTareas(result.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  if (loading) return <div className="p-4 bg-white rounded shadow dark:bg-gray-800">Cargando tareas...</div>;
  if (error) return <div className="p-4 bg-red-100 text-red-700 rounded shadow dark:bg-red-900 dark:text-red-300">Error: {error}</div>;

  return (
    <div className="p-4 bg-white rounded shadow dark:bg-gray-800 dark:text-gray-200">
      <h3 className="text-lg font-semibold mb-4">💡 Qué Hacer Ahora</h3>
      {tareas.length === 0 ? (
        <p>No hay tareas urgentes o prioritarias en este momento.</p>
      ) : (
        <ul>
          {tareas.map((tarea) => (
            <li key={tarea.id} className="mb-2 p-3 border-b border-gray-200 last:border-b-0 dark:border-gray-700">
              <p className="font-medium">{tarea.titulo}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Proyecto: {tarea.proyecto} | Tarea: {tarea.tarea}</p>
              <p className="text-xs text-gray-500 dark:text-gray-500">Energía: {tarea.nivel_energia_requerido} | Momento: {tarea.mejor_momento?.join(', ')} | Tiempo: {tarea.tiempo_estimado_minutos} min | Prioridad: {tarea.score_prioridad}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
