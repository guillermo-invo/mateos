'use client';

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
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
  moscow?: 'must' | 'should' | 'could' | 'wont';
  subtareas: Subtarea[];
}

interface ProyectoEstrategico {
  id: number;
  nombre: string;
  descripcion?: string;
  estado: string;
  prioridadGlobal?: number | string | null;
  scoreMotivacional?: number | string | null;
  scoreAlineacion?: number | string | null;
  justificacionEstrategica?: any;
  objetivosSmart?: any;
  tareasEstrategicas: TareaEstrategica[];
}

const formatDecimal = (value: number | string | null | undefined): string => {
  if (value === null || value === undefined) {
    return '—';
  }

  const numericValue = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(numericValue)) {
    return '—';
  }

  return numericValue.toFixed(2);
};

export default function ProjectDetailsPage() {
  const { id } = useParams();
  const router = useRouter();
  const [proyecto, setProyecto] = useState<ProyectoEstrategico | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      if (!id) return;
      try {
        const response = await fetch(`/api/proyectos-estrategicos/${id}`);
        if (!response.ok) {
          throw new Error('Failed to fetch project details');
        }
        const result = await response.json();
        setProyecto(result.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, [id]);

  const handleDelete = async () => {
    if (!proyecto || !confirm(`¿Estás seguro de que quieres eliminar el proyecto "${proyecto.nombre}"?`)) {
      return;
    }
    setLoading(true);
    try {
      const response = await fetch(`/api/proyectos-estrategicos/${id}`, {
        method: 'DELETE',
      });
      if (!response.ok) {
        throw new Error('Failed to delete project');
      }
      router.push('/proyectos');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="p-6">Cargando detalles del proyecto...</div>;
  if (error) return <div className="p-6 text-red-500">Error: {error}</div>;
  if (!proyecto) return <div className="p-6">Proyecto no encontrado.</div>;

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-4 text-gray-900 dark:text-white">{proyecto.nombre}</h1>
      <p className="text-gray-600 dark:text-gray-400 mb-6">{proyecto.descripcion}</p>

      <div className="flex space-x-4 mb-6">
        <button onClick={handleDelete} className="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded">
          Eliminar Proyecto
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
          <h2 className="text-xl font-semibold mb-2">Estado</h2>
          <p>{proyecto.estado}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
          <h2 className="text-xl font-semibold mb-2">Prioridad Global</h2>
          <p>{formatDecimal(proyecto.prioridadGlobal)}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
          <h2 className="text-xl font-semibold mb-2">Alineación</h2>
          <p>{formatDecimal(proyecto.scoreAlineacion)}</p>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-md mb-8 dark:bg-gray-800 dark:text-gray-200">
        <h2 className="text-xl font-semibold mb-4">Justificación Estratégica</h2>
        <pre className="whitespace-pre-wrap text-sm bg-gray-50 p-4 rounded dark:bg-gray-700 dark:text-gray-300">
          {JSON.stringify(proyecto.justificacionEstrategica, null, 2)}
        </pre>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
        <h2 className="text-xl font-semibold mb-4">Tareas Estratégicas</h2>
        {proyecto.tareasEstrategicas.length === 0 ? (
          <p>No hay tareas estratégicas para este proyecto.</p>
        ) : (
          <ul>
            {proyecto.tareasEstrategicas.map((tarea) => (
              <li key={tarea.id} className="mb-4 p-4 border rounded-lg dark:border-gray-700">
                <h3 className="font-semibold text-lg">{tarea.nombre}</h3>
                <p className="text-gray-600 dark:text-gray-400 text-sm mb-2">{tarea.descripcion}</p>
                <p className="text-xs text-gray-500 dark:text-gray-500">Estado: {tarea.estado} | MoSCoW: {tarea.moscow}</p>
                
                {tarea.subtareas.length > 0 && (
                  <div className="mt-2 pl-4 border-l dark:border-gray-600">
                    <h4 className="text-md font-medium mb-1">Subtareas:</h4>
                    <ul>
                      {tarea.subtareas.map((subtarea) => (
                        <li key={subtarea.id} className="text-sm text-gray-700 dark:text-gray-300">
                          {subtarea.completada ? '✅' : '⬜'} {subtarea.titulo}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
