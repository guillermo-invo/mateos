'use client';

import React from 'react';
import { Accordion, AccordionItem, Progress, Card, CardBody, Chip } from "@heroui/react";

// --- 1. Definición de Interfaces de Datos (TypeScript) ---

export type SubtaskStatus = 'waiting' | 'todo' | 'doing' | 'done';
export type MoscowRating = 'Must' | 'Should' | 'Could' | "Won't";

export interface Subtask {
  id: string;
  title: string;
  status: SubtaskStatus;
  estimate: string; // Ej: "2h"
  moscow: MoscowRating;
}

export interface Task {
  id: string;
  title: string;
  subtasks: Subtask[];
}

export interface Project {
  id: string;
  title: string;
  progress: number; // Porcentaje de 0 a 100
  tasks: Task[];
}

export interface AreaDeVida {
  id: string;
  title: string;
  projects: Project[];
}

interface Props {
  data: AreaDeVida[];
}

// --- 2. Componentes Auxiliares ---

// Tarjeta individual para una Subtarea
const SubtaskCard = ({ subtask }: { subtask: Subtask }) => {
  return (
    <Card shadow="sm" className="w-full mb-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
      <CardBody className="p-3 text-small flex flex-col gap-1">
        <p className="font-semibold text-gray-800 dark:text-gray-100">{subtask.title}</p>
        <div className="text-gray-600 dark:text-gray-400 text-xs flex flex-col">            <span>Est: {subtask.estimate}</span>
            {/* Usamos un Chip pequeño para el MoSCoW para que resalte un poco */}
            <div className="flex items-center gap-1 mt-1">
                <span>MoSCoW:</span>
                <Chip size="sm" variant="flat" color={subtask.moscow === 'Must' ? "danger" : subtask.moscow === 'Should' ? "warning" : "default"}>
                    {subtask.moscow}
                </Chip>
            </div>
        </div>
      </CardBody>
    </Card>
  );
};

// Columna coloreada del Kanban (Waiting, Todo, Doing, Done)
const KanbanColumn = ({ status, colorClass, subtasks }: { status: SubtaskStatus, colorClass: string, subtasks: Subtask[] }) => {
  const filteredTasks = subtasks.filter(s => s.status === status);

  return (
    <div className={`h-full p-2 rounded-lg ${colorClass} dark:bg-opacity-40 flex flex-col gap-2 min-h-[150px]`}>
      {filteredTasks.map(subtask => (
        <SubtaskCard key={subtask.id} subtask={subtask} />
      ))}
    </div>
  );
};

// Cabecera fija de la tabla (Waiting, Todo, etc.)
const KanbanHeaderRow = () => {
    // Definimos el grid para alinear con el contenido de las tareas
    // La primera columna (vacia) representa el espacio de indentación del acordeón
  return (
    <div className="grid grid-cols-[220px_1fr_1fr_1fr_1fr] gap-4 mb-2 px-4 font-bold text-center text-gray-700 dark:text-gray-300 uppercase text-sm sticky top-0 bg-white dark:bg-gray-900 z-10 py-2">
      <div>{/* Espacio vacío alineado con la jerarquía */}</div>
      <div className="bg-gray-200 dark:bg-gray-700 rounded py-1">Waiting</div>
      <div className="bg-blue-200 dark:bg-blue-900 rounded py-1">Todo</div>
      <div className="bg-amber-200 dark:bg-amber-900 rounded py-1">Doing</div>
      <div className="bg-green-200 dark:bg-green-900 rounded py-1">Done</div>
    </div>
  );
};


// --- 3. Componente Principal ---

const KanbanTaskView: React.FC<Props> = ({ data }) => {

  // Configuración de columnas y sus colores (estilo Tailwind según la imagen)
  const columnsConfig: { status: SubtaskStatus, color: string }[] = [
    { status: 'waiting', color: 'bg-gray-100' },
    { status: 'todo', color: 'bg-blue-100/80' }, // Ajusté un poco el tono para que se parezca a la imagen
    { status: 'doing', color: 'bg-amber-100/80' },
    { status: 'done', color: 'bg-green-100/80' },
  ];

  return (
    <div className="w-full max-w-7xl mx-auto p-4 bg-white dark:bg-gray-900">

      {/* Cabecera de columnas fija */}
      <KanbanHeaderRow />

      {/* Nivel 1: Áreas de Vida */}
      <Accordion variant="splitted" className="px-0" defaultExpandedKeys="all" selectionMode="multiple">
        {data.map((area) => (
          <AccordionItem key={area.id} title={<span className="font-bold text-lg text-gray-900 dark:text-white">{area.title}</span>} className="bg-gray-50">

            {/* Nivel 2: Proyectos */}
            <Accordion variant="light" className="pl-2" defaultExpandedKeys="all" selectionMode="multiple">
              {area.projects.map((project) => (
                <AccordionItem
                  key={project.id}
                  // Personalizamos el título del acordeón para incluir la barra de progreso
                  title={
                    <div className="flex items-center w-full gap-4 pr-4">
                       <span className="font-semibold text-gray-700 dark:text-gray-200 whitespace-nowrap">{project.title}</span>
                       {/* Barra de Progreso de HeroUI */}
                       <Progress
                          size="md"
                          value={project.progress}
                          color="primary" // Color similar al de la imagen
                          showValueLabel={true}
                          className="max-w-md"
                        />
                    </div>
                  }
                >

                  {/* Nivel 3: Tareas */}
                  <Accordion variant="light" defaultExpandedKeys="all" selectionMode="multiple">
                    {project.tasks.map((task) => (
                      <AccordionItem key={task.id} title={<span className="text-gray-600 dark:text-gray-300">{task.title}</span>}>

                        {/* CONTENIDO DE LA TAREA: El Grid Kanban */}
                        {/* Usamos el mismo grid-cols que el header para mantener alineación */}
                        <div className="grid grid-cols-[1fr_1fr_1fr_1fr] gap-4 py-2">
                           {/* Mapeamos las 4 columnas configuradas arriba */}
                           {columnsConfig.map((col) => (
                             <KanbanColumn
                                key={col.status}
                                status={col.status}
                                colorClass={col.color}
                                subtasks={task.subtasks}
                             />
                           ))}
                        </div>

                      </AccordionItem>
                    ))}
                  </Accordion>

                </AccordionItem>
              ))}
            </Accordion>

          </AccordionItem>
        ))}
      </Accordion>
    </div>
  );
};

export default KanbanTaskView;
