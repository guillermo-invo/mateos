'use client';

import React, { useEffect, useState } from 'react';

interface VeredictoMatarife {
  tarea_id: number;
  tarea: string;
  proyecto: string;
  veredicto: string;
}

export default function MatarifePanel() {
  const [veredictos, setVeredictos] = useState<VeredictoMatarife[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch('/api/dashboard/matarife');
        if (!response.ok) {
          throw new Error('Failed to fetch data');
        }
        const result = await response.json();
        setVeredictos(result.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  if (loading) return <div className="p-4 bg-white rounded shadow dark:bg-gray-800">Cargando veredictos Matarife...</div>;
  if (error) return <div className="p-4 bg-red-100 text-red-700 rounded shadow dark:bg-red-900 dark:text-red-300">Error: {error}</div>;

  return (
    <div className="p-4 bg-white rounded shadow dark:bg-gray-800 dark:text-gray-200">
      <h3 className="text-lg font-semibold mb-4">🔪 Vista Matarife</h3>
      {veredictos.length === 0 ? (
        <p>No hay tareas que necesiten revisión por el momento.</p>
      ) : (
        <ul>
          {veredictos.map((veredicto) => (
            <li key={veredicto.tarea_id} className="mb-2 p-3 border-b border-gray-200 last:border-b-0 dark:border-gray-700">
              <p className="font-medium">{veredicto.tarea} ({veredicto.proyecto})</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Veredicto: <span className="font-bold text-red-500">{veredicto.veredicto}</span></p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
