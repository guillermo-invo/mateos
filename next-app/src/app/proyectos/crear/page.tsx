'use client';

import React, { useState, FormEvent, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

interface Option {
  id: number;
  nombre: string;
}

interface ProjectIdea {
  id: number;
  titulo: string;
  descripcion?: string;
}

function CrearProyectoContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [nombre, setNombre] = useState('');
  const [descripcion, setDescripcion] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<{ id: number; nombre: string } | null>(null);
  const [selectedIdeaId, setSelectedIdeaId] = useState<number | null>(null);
  const [projectIdeas, setProjectIdeas] = useState<ProjectIdea[]>([]);

  // Taxonomic data for selection
  const [areas, setAreas] = useState<Option[]>([]);
  const [motivos, setMotivos] = useState<Option[]>([]);

  // Manual text inputs for new entries
  const [nuevaAreaVida, setNuevaAreaVida] = useState('');
  const [nuevoMotivoPersonal, setNuevoMotivoPersonal] = useState('');

  // Selected IDs - Area is single select (radio), Motivos is multi-select (checkbox)
  const [selectedArea, setSelectedArea] = useState<number | null>(null);
  const [selectedMotivos, setSelectedMotivos] = useState<number[]>([]);


  useEffect(() => {
    async function fetchTaxonomicData() {
      try {
        const [areasRes, motivosRes, ideasRes] = await Promise.all([
          fetch('/api/areas-vida'),
          fetch('/api/motivos-personales'),
          fetch('/api/ideas/disponibles'), // Fetch only available ideas (not yet implemented)
        ]);

        const [areasData, motivosData, ideasData] = await Promise.all([
          areasRes.json(),
          motivosRes.json(),
          ideasRes.json(),
        ]);

        setAreas(areasData.data || []);
        setMotivos(motivosData.data || []);
        setProjectIdeas(ideasData.data || []);

        // Check if there's an ideaId in the URL query params
        const ideaIdParam = searchParams.get('ideaId');
        if (ideaIdParam) {
          const ideaId = parseInt(ideaIdParam);
          if (!isNaN(ideaId)) {
            setSelectedIdeaId(ideaId);
          }
        }

      } catch (err) {
        console.error('Error fetching data:', err);
        setError('Failed to load necessary data.');
      }
    }
    fetchTaxonomicData();
  }, [searchParams]);

  // Update description when a project idea is selected
  useEffect(() => {
    if (selectedIdeaId) {
      const idea = projectIdeas.find(idea => idea.id === selectedIdeaId);
      if (idea) {
        setDescripcion(idea.descripcion || '');
        setNombre(idea.titulo); // Pre-fill name with idea title
      }
    } else {
      // Clear fields if no idea is selected
      setDescripcion('');
      setNombre('');
    }
  }, [selectedIdeaId, projectIdeas]);


  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      // Always use AI generation endpoint
      const endpoint = '/api/proyectos-estrategicos/generar';

      const body: any = {
        nombre: nombre || 'Proyecto sin nombre',
        descripcion,
      };

      // Add ideaId if an idea was selected
      if (selectedIdeaId) {
        body.ideaId = selectedIdeaId;
      }

      // Add selected area (single selection)
      if (selectedArea) {
        body.areasIds = [selectedArea];
      } else if (nuevaAreaVida.trim()) {
        body.nuevaAreaVida = nuevaAreaVida.trim();
      }

      // Add selected motivos (multiple selection)
      if (selectedMotivos.length > 0) {
        body.motivosIds = selectedMotivos;
      }
      if (nuevoMotivoPersonal.trim()) {
        body.nuevoMotivoPersonal = nuevoMotivoPersonal.trim();
      }

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create project');
      }

      const result = await response.json();
      const projectId = result.data.id || result.data;
      const projectName = nombre || 'Proyecto sin nombre';
      
      // Show success message and stay on the page
      setSuccess({ id: projectId, nombre: projectName });
      
      // Reset form
      setNombre('');
      setDescripcion('');
      setSelectedArea(null);
      setSelectedMotivos([]);
      setNuevaAreaVida('');
      setNuevoMotivoPersonal('');
      setSelectedIdeaId(null);
      
      // Refresh available ideas list
      try {
        const ideasRes = await fetch('/api/ideas/disponibles');
        const ideasData = await ideasRes.json();
        setProjectIdeas(ideasData.data || []);
      } catch (e) {
        console.error('Failed to refresh ideas:', e);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleCheckboxChange = (
    id: number,
    setter: React.Dispatch<React.SetStateAction<number[]>>,
    currentSelection: number[]
  ) => {
    if (currentSelection.includes(id)) {
      setter(currentSelection.filter((item) => item !== id));
    } else {
      setter([...currentSelection, id]);
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6 text-gray-900 dark:text-white">Crear Nuevo Proyecto</h1>

      <form onSubmit={handleSubmit} className="bg-white p-8 rounded-lg shadow-md dark:bg-gray-800">
        {error && <div className="bg-red-100 text-red-700 p-3 rounded mb-4 dark:bg-red-900 dark:text-red-300">{error}</div>}
        {success && (
          <div className="bg-green-100 text-green-700 p-3 rounded mb-4 dark:bg-green-900 dark:text-green-300">
            ¡Proyecto creado exitosamente! El backend está poblando todas las tablas.
            <br />
            <a href={`/proyectos/${success.id}`} className="underline font-semibold mt-2 inline-block">
              Ver proyecto: {success.nombre}
            </a>
          </div>
        )}

        <div className="mb-4">
          <label htmlFor="selectIdea" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Convertir Idea Existente (Opcional)
          </label>
          <select
            id="selectIdea"
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
            value={selectedIdeaId || ''}
            onChange={(e) => setSelectedIdeaId(e.target.value ? parseInt(e.target.value, 10) : null)}
            disabled={loading}
          >
            <option value="">-- Seleccionar una idea de proyecto --</option>
            {projectIdeas.map(idea => (
              <option key={idea.id} value={idea.id}>{idea.titulo}</option>
            ))}
          </select>
          {projectIdeas.length === 0 && <p className="text-sm text-gray-500 mt-1">No hay ideas de proyecto pendientes.</p>}
        </div>

        <div className="mb-4">
          <label htmlFor="nombre" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Nombre del Proyecto
          </label>
          <input
            type="text"
            id="nombre"
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
            required
            disabled={loading || selectedIdeaId !== null} // Disable if idea is selected
          />
        </div>

        <div className="mb-4">
          <label htmlFor="descripcion" className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
            Descripción del Proyecto
          </label>
          <textarea
            id="descripcion"
            className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
            rows={5}
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
            required
            disabled={loading || selectedIdeaId !== null} // Disable if idea is selected
          ></textarea>
        </div>

            {/* Taxonomic data selections */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
                  Área de Vida (selecciona una)
                </label>
                <div className="max-h-40 overflow-y-auto border rounded p-2 dark:border-gray-600 dark:bg-gray-700">
                  {areas.map((area) => (
                    <div key={area.id} className="flex items-center mb-1">
                      <input
                        type="radio"
                        id={`area-${area.id}`}
                        name="area"
                        value={area.id}
                        checked={selectedArea === area.id}
                        onChange={() => setSelectedArea(area.id)}
                        className="form-radio h-4 w-4 text-blue-600"
                        disabled={loading || selectedIdeaId !== null}
                      />
                      <label htmlFor={`area-${area.id}`} className="ml-2 text-gray-700 dark:text-gray-300">
                        {area.nombre}
                      </label>
                    </div>
                  ))}
                </div>
                <div className="mt-2">
                  <input
                    type="text"
                    placeholder="O escribe una nueva área de vida..."
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
                    value={nuevaAreaVida}
                    onChange={(e) => setNuevaAreaVida(e.target.value)}
                    disabled={loading}
                  />
                </div>
              </div>

              <div>
                <label className="block text-gray-700 text-sm font-bold mb-2 dark:text-gray-300">
                  Motivos Personales (selecciona varios)
                </label>
                <div className="max-h-40 overflow-y-auto border rounded p-2 dark:border-gray-600 dark:bg-gray-700">
                  {motivos.map((motivo) => (
                    <div key={motivo.id} className="flex items-center mb-1">
                      <input
                        type="checkbox"
                        id={`motivo-${motivo.id}`}
                        checked={selectedMotivos.includes(motivo.id)}
                        onChange={() => handleCheckboxChange(motivo.id, setSelectedMotivos, selectedMotivos)}
                        className="form-checkbox h-4 w-4 text-blue-600"
                        disabled={loading || selectedIdeaId !== null}
                      />
                      <label htmlFor={`motivo-${motivo.id}`} className="ml-2 text-gray-700 dark:text-gray-300">
                        {motivo.nombre}
                      </label>
                    </div>
                  ))}
                </div>
                <div className="mt-2">
                  <input
                    type="text"
                    placeholder="O escribe un nuevo motivo personal..."
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline dark:bg-gray-700 dark:border-gray-600 dark:text-gray-200"
                    value={nuevoMotivoPersonal}
                    onChange={(e) => setNuevoMotivoPersonal(e.target.value)}
                    disabled={loading}
                  />
                </div>
              </div>
            </div>

            <div className="mb-4 p-4 bg-blue-50 dark:bg-blue-900 rounded">
              <p className="text-sm text-blue-800 dark:text-blue-200">
                <strong>Nota:</strong> El proyecto será generado automáticamente con IA. Las tareas, subtareas, destrezas requeridas, dificultades y misiones de vida serán determinadas por la IA basándose en la descripción del proyecto.
              </p>
            </div>

        <button
          type="submit"
          className="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
          disabled={loading}
        >
          {loading ? 'Generando proyecto con IA...' : 'Crear Proyecto'}
        </button>
      </form>
    </div>
  );
}

export default function CrearProyectoPage() {
  return (
    <Suspense fallback={<div className="p-6">Cargando...</div>}>
      <CrearProyectoContent />
    </Suspense>
  );
}
