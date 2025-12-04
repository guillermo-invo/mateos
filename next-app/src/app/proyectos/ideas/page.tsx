'use client';

import React, { useState, FormEvent, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface Idea {
  id: number;
  titulo: string;
  descripcion?: string;
  categoria?: string;
  createdAt: string;
}

export default function IdeasPage() {
  const router = useRouter();
  const [ideas, setIdeas] = useState<Idea[]>([]);
  const [selectedIdeaId, setSelectedIdeaId] = useState<number | null>(null);
  const [titulo, setTitulo] = useState('');
  const [descripcion, setDescripcion] = useState('');
  const [categoria, setCategoria] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Load ideas on mount
  useEffect(() => {
    fetchIdeas();
  }, []);

  const fetchIdeas = async () => {
    try {
      const response = await fetch('/api/ideas/disponibles');
      const data = await response.json();
      if (data.success) {
        setIdeas(data.data || []);
      }
    } catch (err) {
      console.error('Error fetching ideas:', err);
    }
  };

  // Load selected idea data
  useEffect(() => {
    if (selectedIdeaId) {
      const idea = ideas.find((i) => i.id === selectedIdeaId);
      if (idea) {
        setTitulo(idea.titulo);
        setDescripcion(idea.descripcion || '');
        setCategoria(idea.categoria || '');
      }
    } else {
      clearForm();
    }
  }, [selectedIdeaId, ideas]);

  const clearForm = () => {
    setTitulo('');
    setDescripcion('');
    setCategoria('');
    setSelectedIdeaId(null);
    setError(null);
    setSuccessMessage(null);
  };

  const handleSaveIdea = async (e: FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const endpoint = selectedIdeaId
        ? `/api/ideas/${selectedIdeaId}`
        : '/api/ideas';

      const method = selectedIdeaId ? 'PUT' : 'POST';

      const body = {
        titulo,
        descripcion,
        categoria,
        // notaAudioId is automatically handled by the API for new ideas
      };

      const response = await fetch(endpoint, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to save idea');
      }

      setSuccessMessage(selectedIdeaId ? 'Idea actualizada exitosamente' : 'Idea guardada exitosamente');

      // Refresh ideas list
      await fetchIdeas();

      // Clear form after a delay
      setTimeout(() => {
        clearForm();
      }, 2000);

    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleConvertToProject = () => {
    if (selectedIdeaId) {
      // Navigate to crear page with the idea pre-selected
      router.push(`/proyectos/crear?ideaId=${selectedIdeaId}`);
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
        Gestionar Ideas de Proyectos
      </h1>

      <form onSubmit={handleSaveIdea} className="bg-white p-8 rounded-lg shadow-md dark:bg-gray-800">
        {error && (
          <div className="bg-red-100 text-red-700 p-3 rounded mb-4 dark:bg-red-900 dark:text-red-300">
            {error}
          </div>
        )}

        {successMessage && (
          <div className="bg-green-100 text-green-700 p-3 rounded mb-4 dark:bg-green-900 dark:text-green-300">
            {successMessage}
          </div>
        )}

        <div className="mb-4">
          <label htmlFor="selectIdea" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Cargar Idea Existente
          </label>
          <div className="flex gap-2">
            <select
              id="selectIdea"
              className="flex-1 shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
              value={selectedIdeaId || ''}
              onChange={(e) => setSelectedIdeaId(e.target.value ? parseInt(e.target.value) : null)}
              disabled={loading}
            >
              <option value="">-- Nueva Idea --</option>
              {ideas.map((idea) => (
                <option key={idea.id} value={idea.id}>
                  {idea.titulo}
                </option>
              ))}
            </select>
            <button
              type="button"
              onClick={clearForm}
              className="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
              disabled={loading}
            >
              Limpiar
            </button>
          </div>
          {ideas.length === 0 && (
            <p className="text-sm text-gray-500 mt-1 dark:text-gray-400">
              No hay ideas disponibles. Crea una nueva usando el formulario.
            </p>
          )}
        </div>

        <div className="mb-4">
          <label htmlFor="titulo" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Título de la Idea *
          </label>
          <input
            type="text"
            id="titulo"
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
            value={titulo}
            onChange={(e) => setTitulo(e.target.value)}
            required
            disabled={loading}
            placeholder="Ej: Crear un blog personal"
          />
        </div>

        <div className="mb-4">
          <label htmlFor="descripcion" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Descripción Detallada
          </label>
          <textarea
            id="descripcion"
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
            rows={6}
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
            disabled={loading}
            placeholder="Describe la idea en detalle: qué quieres lograr, por qué es importante, alcance aproximado..."
          ></textarea>
        </div>

        <div className="mb-4">
          <label htmlFor="categoria" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Categoría
          </label>
          <input
            type="text"
            id="categoria"
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
            value={categoria}
            onChange={(e) => setCategoria(e.target.value)}
            disabled={loading}
            placeholder="Ej: proyecto_potencial, aprendizaje, negocio, personal"
          />
        </div>

        <div className="mb-4 p-4 bg-blue-50 dark:bg-blue-900 rounded">
          <p className="text-sm text-blue-800 dark:text-blue-200">
            <strong>Nota:</strong> Esta es solo un borrador de idea. Cuando estés listo para convertirla en un proyecto completo con tareas y subtareas, usa el botón "Convertir en Proyecto".
          </p>
        </div>

        <div className="flex gap-3">
          <button
            type="submit"
            className="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            disabled={loading}
          >
            {loading ? 'Guardando...' : (selectedIdeaId ? 'Actualizar Idea' : 'Guardar Idea')}
          </button>

          {selectedIdeaId && (
            <button
              type="button"
              onClick={handleConvertToProject}
              className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
              disabled={loading}
            >
              Convertir en Proyecto
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
