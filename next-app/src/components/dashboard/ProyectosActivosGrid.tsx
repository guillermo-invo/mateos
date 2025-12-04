'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';

interface ProyectoActivo {
  id: number;
  nombre: string;
  estado: string;
  score_alineacion: number;
  prioridad_global: number;
  tareas_pendientes: number;
  porcentaje_completado: number;
  horas_restantes: number;
}

export default function ProyectosActivosGrid() {
  const [proyectos, setProyectos] = useState<ProyectoActivo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch('/api/dashboard/proyectos-activos'); // Assuming this endpoint exists or will be created
        if (!response.ok) {
          throw new Error('Failed to fetch data');
        }
        const result = await response.json();
        setProyectos(result.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  if (loading) return <div className="p-4 bg-white rounded shadow dark:bg-gray-800">Cargando proyectos activos...</div>;
  if (error) return <div className="p-4 bg-red-100 text-red-700 rounded shadow dark:bg-red-900 dark:text-red-300">Error: {error}</div>;

  return (
    <div className="p-4 bg-white rounded shadow dark:bg-gray-800 dark:text-gray-200">
      <h3 className="text-lg font-semibold mb-4">🚀 Proyectos Activos</h3>
      {proyectos.length === 0 ? (
        <p>No hay proyectos activos en este momento.</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {proyectos.map((proyecto) => (
            <Link href={`/proyectos/${proyecto.id}`} key={proyecto.id} className="block p-4 border border-gray-200 rounded-lg hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-700 transition-colors">
              <h4 className="font-bold text-lg mb-1">{proyecto.nombre}</h4>
              <p className="text-sm text-gray-600 dark:text-gray-400">Estado: {proyecto.estado}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Progreso: {proyecto.porcentaje_completado}%</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Tareas Pendientes: {proyecto.tareas_pendientes}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Horas Restantes: {proyecto.horas_restantes}</p>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
