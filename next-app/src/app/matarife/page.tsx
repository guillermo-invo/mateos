'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

interface VeredictoMatarife {
  tarea_id: number;
  tarea: string;
  proyecto: string;
  veredicto: string;
}

export default function MatarifePage() {
  const router = useRouter();
  const [veredictos, setVeredictos] = useState<VeredictoMatarife[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      const response = await fetch('/api/dashboard/matarife');
      if (!response.ok) {
        throw new Error('Failed to fetch Matarife data');
      }
      const result = await response.json();
      setVeredictos(result.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleDeleteTarea = async (tareaId: number) => {
    if (!confirm('¿Estás seguro de que quieres eliminar esta tarea? Esta acción es irreversible.')) {
      return;
    }
    setLoading(true);
    try {
      const response = await fetch(`/api/tareas-estrategicas/${tareaId}`, {
        method: 'DELETE',
      });
      if (!response.ok) {
        throw new Error('Failed to delete task');
      }
      // Remove the deleted task from the UI
      setVeredictos(prev => prev.filter(v => v.tarea_id !== tareaId));
      router.refresh(); // Refresh current route to refetch data from server components
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  // Placeholder for other actions like postpone, review, etc.
  const handlePostponeTarea = (tareaId: number) => {
    alert(`Posponer tarea ${tareaId} - (No implementado)`);
  };

  const handleReviewTarea = (tareaId: number) => {
    alert(`Revisar tarea ${tareaId} - (No implementado)`);
  };


  if (loading) return <div className="p-6">Cargando vista Matarife...</div>;
  if (error) return <div className="p-6 text-red-500">Error: {error}</div>;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6 text-gray-900 dark:text-white">Vista Matarife</h1>

      {veredictos.length === 0 ? (
        <p className="text-gray-700 dark:text-gray-300">No hay tareas que necesiten atención especial.</p>
      ) : (
        <div className="space-y-4">
          {veredictos.map((veredicto) => (
            <div key={veredicto.tarea_id} className="bg-white p-4 rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
              <h2 className="text-xl font-semibold mb-2">{veredicto.tarea}</h2>
              <p className="text-gray-600 dark:text-gray-400 mb-2">Proyecto: {veredicto.proyecto}</p>
              <p className="text-lg font-bold text-red-600 dark:text-red-400 mb-4">Veredicto: {veredicto.veredicto}</p>

              <div className="flex space-x-2">
                <button
                  onClick={() => handleDeleteTarea(veredicto.tarea_id)}
                  className="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded text-sm"
                  disabled={loading}
                >
                  Eliminar
                </button>
                <button
                  onClick={() => handlePostponeTarea(veredicto.tarea_id)}
                  className="bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-2 px-4 rounded text-sm"
                  disabled={loading}
                >
                  Posponer
                </button>
                <button
                  onClick={() => handleReviewTarea(veredicto.tarea_id)}
                  className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded text-sm"
                  disabled={loading}
                >
                  Revisar
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
