'use client';

import React, { useState } from 'react';
import { Accordion, AccordionItem, Progress, Card, CardBody, Chip } from "@heroui/react";
import {
  DndContext,
  DragEndEvent,
  DragOverlay,
  DragStartEvent,
  useSensor,
  useSensors,
  PointerSensor,
  closestCorners,
  useDroppable,
} from '@dnd-kit/core';
import { CSS } from '@dnd-kit/utilities';
import { useSortable } from '@dnd-kit/sortable';

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

// Draggable Subtask Card that also acts as a droppable
const DraggableSubtaskCard = ({ subtask }: { subtask: Subtask }) => {
  const {
    attributes,
    listeners,
    setNodeRef: setDraggableRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: subtask.id,
    data: {
      status: subtask.status, // Store the current status for dropping
    }
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <div
      ref={setDraggableRef}
      style={style}
      {...attributes}
      {...listeners}
      className="cursor-grab active:cursor-grabbing"
    >
      <Card shadow="sm" className="w-full mb-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 hover:border-blue-400 dark:hover:border-blue-600 transition-colors">
        <CardBody className="p-3 text-small flex flex-col gap-2">
          <p className="font-semibold text-gray-800 dark:text-gray-100">{subtask.title}</p>
          <div className="flex items-center gap-2 text-xs">
            <span className="text-gray-600 dark:text-gray-400">{subtask.estimate}</span>
            <Chip
              size="sm"
              variant="flat"
              color={
                subtask.moscow === 'Must' ? "danger" :
                subtask.moscow === 'Should' ? "warning" :
                "default"
              }
            >
              {subtask.moscow}
            </Chip>
          </div>
        </CardBody>
      </Card>
    </div>
  );
};

// Static Subtask Card for Overlay
const SubtaskCard = ({ subtask }: { subtask: Subtask }) => {
  return (
    <Card shadow="lg" className="w-full bg-white dark:bg-gray-800 border-2 border-blue-500">
      <CardBody className="p-3 text-small flex flex-col gap-2">
        <p className="font-semibold text-gray-800 dark:text-gray-100">{subtask.title}</p>
        <div className="flex items-center gap-2 text-xs">
          <span className="text-gray-600 dark:text-gray-400">{subtask.estimate}</span>
          <Chip
            size="sm"
            variant="flat"
            color={
              subtask.moscow === 'Must' ? "danger" :
              subtask.moscow === 'Should' ? "warning" :
              "default"
            }
          >
            {subtask.moscow}
          </Chip>
        </div>
      </CardBody>
    </Card>
  );
};

// Droppable Kanban Column
const DroppableKanbanColumn = ({
  status,
  colorClass,
  subtasks,
  taskId
}: {
  status: SubtaskStatus,
  colorClass: string,
  subtasks: Subtask[],
  taskId: string
}) => {
  const filteredTasks = subtasks.filter(s => s.status === status);

  // Create unique ID per task and status to avoid conflicts
  const droppableId = `${taskId}-${status}`;

  const { setNodeRef, isOver } = useDroppable({
    id: droppableId,
    data: {
      status, // Store status in data for retrieval in handleDragEnd
    }
  });

  return (
    <div
      ref={setNodeRef}
      data-status={status}
      className={`h-full p-2 rounded-lg ${colorClass} dark:bg-opacity-40 flex flex-col gap-2 min-h-[150px] transition-colors ${
        isOver ? 'ring-2 ring-blue-500 ring-offset-2' : ''
      }`}
    >
      {filteredTasks.map(subtask => (
        <DraggableSubtaskCard key={subtask.id} subtask={subtask} />
      ))}
    </div>
  );
};

// Cabecera fija de la tabla (Waiting, Todo, etc.)
const KanbanHeaderRow = ({
  totals
}: {
  totals: Record<SubtaskStatus, number>
}) => {
  // Helper para formatear minutos a horas y minutos
  const formatMinutes = (mins: number): string => {
    if (mins === 0) return '0min';
    const hours = Math.floor(mins / 60);
    const minutes = mins % 60;
    if (hours === 0) return `${minutes}min`;
    if (minutes === 0) return `${hours}h`;
    return `${hours}h ${minutes}min`;
  };

  return (
    <div className="grid grid-cols-[220px_1fr_1fr_1fr_1fr] gap-4 mb-2 px-4 font-bold text-center text-gray-700 dark:text-gray-300 uppercase text-sm sticky top-0 bg-white dark:bg-gray-900 z-10 py-2">
      <div>{/* Espacio vacío alineado con la jerarquía */}</div>
      <div className="bg-gray-200 dark:bg-gray-700 rounded py-2 flex flex-col">
        <span>Waiting</span>
        <span className="text-xs font-normal normal-case mt-1">{formatMinutes(totals.waiting)}</span>
      </div>
      <div className="bg-blue-200 dark:bg-blue-900 rounded py-2 flex flex-col">
        <span>Todo</span>
        <span className="text-xs font-normal normal-case mt-1">{formatMinutes(totals.todo)}</span>
      </div>
      <div className="bg-amber-200 dark:bg-amber-900 rounded py-2 flex flex-col">
        <span>Doing</span>
        <span className="text-xs font-normal normal-case mt-1">{formatMinutes(totals.doing)}</span>
      </div>
      <div className="bg-green-200 dark:bg-green-900 rounded py-2 flex flex-col">
        <span>Done</span>
        <span className="text-xs font-normal normal-case mt-1">{formatMinutes(totals.done)}</span>
      </div>
    </div>
  );
};

// --- 3. Componente Principal ---

const KanbanTaskView: React.FC<Props> = ({ data: initialData }) => {
  const [data, setData] = useState<AreaDeVida[]>(initialData);
  const [activeSubtask, setActiveSubtask] = useState<Subtask | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  // Función para calcular totales de minutos por status
  const calculateTotals = (): Record<SubtaskStatus, number> => {
    const totals: Record<SubtaskStatus, number> = {
      waiting: 0,
      todo: 0,
      doing: 0,
      done: 0,
    };

    data.forEach((area) => {
      area.projects.forEach((project) => {
        project.tasks.forEach((task) => {
          task.subtasks.forEach((subtask) => {
            // Parse estimate string (e.g., "120min" or "N/A")
            if (subtask.estimate && subtask.estimate !== 'N/A') {
              const match = subtask.estimate.match(/(\d+)min/);
              if (match) {
                const minutes = parseInt(match[1], 10);
                totals[subtask.status] += minutes;
              }
            }
          });
        });
      });
    });

    return totals;
  };

  // Configuración de columnas y sus colores
  const columnsConfig: { status: SubtaskStatus, color: string }[] = [
    { status: 'waiting', color: 'bg-gray-100' },
    { status: 'todo', color: 'bg-blue-100/80' },
    { status: 'doing', color: 'bg-amber-100/80' },
    { status: 'done', color: 'bg-green-100/80' },
  ];

  const handleDragStart = (event: DragStartEvent) => {
    const { active } = event;

    // Find the subtask being dragged
    for (const area of data) {
      for (const project of area.projects) {
        for (const task of project.tasks) {
          const subtask = task.subtasks.find(s => s.id === active.id);
          if (subtask) {
            setActiveSubtask(subtask);
            return;
          }
        }
      }
    }
  };

  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveSubtask(null);

    if (!over) return;

    // Extract status from droppable data
    const newStatus = over.data.current?.status as SubtaskStatus | undefined;
    if (!newStatus) return;

    // Find the subtask and update it
    const subtaskId = active.id as string;

    // Find the subtask in the data
    let foundSubtask: Subtask | null = null;
    let oldStatus: SubtaskStatus | null = null;

    for (const area of data) {
      for (const project of area.projects) {
        for (const task of project.tasks) {
          const subtask = task.subtasks.find(s => s.id === subtaskId);
          if (subtask) {
            foundSubtask = subtask;
            oldStatus = subtask.status;
            break;
          }
        }
        if (foundSubtask) break;
      }
      if (foundSubtask) break;
    }

    if (!foundSubtask || oldStatus === newStatus) return;

    // Optimistic update
    setData(prevData => {
      return prevData.map(area => ({
        ...area,
        projects: area.projects.map(project => ({
          ...project,
          tasks: project.tasks.map(task => ({
            ...task,
            subtasks: task.subtasks.map(subtask =>
              subtask.id === subtaskId
                ? { ...subtask, status: newStatus }
                : subtask
            ),
          })),
        })),
      }));
    });

    // Call API to update status
    try {
      const response = await fetch(`/api/subtareas/${subtaskId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          estadoKanban: newStatus,
        }),
      });

      if (!response.ok) {
        // Revert on error
        setData(prevData => {
          return prevData.map(area => ({
            ...area,
            projects: area.projects.map(project => ({
              ...project,
              tasks: project.tasks.map(task => ({
                ...task,
                subtasks: task.subtasks.map(subtask =>
                  subtask.id === subtaskId
                    ? { ...subtask, status: oldStatus! }
                    : subtask
                ),
              })),
            })),
          }));
        });

        console.error('Failed to update subtask status');
      }
    } catch (error) {
      // Revert on error
      setData(prevData => {
        return prevData.map(area => ({
          ...area,
          projects: area.projects.map(project => ({
            ...project,
            tasks: project.tasks.map(task => ({
              ...task,
              subtasks: task.subtasks.map(subtask =>
                subtask.id === subtaskId
                  ? { ...subtask, status: oldStatus! }
                  : subtask
              ),
            })),
          })),
        }));
      });

      console.error('Error updating subtask:', error);
    }
  };


  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="w-full max-w-7xl mx-auto p-4 bg-white dark:bg-gray-900">
        {/* Cabecera de columnas fija */}
        <KanbanHeaderRow totals={calculateTotals()} />

        {/* Nivel 1: Áreas de Vida */}
        <Accordion variant="splitted" className="px-0" defaultExpandedKeys="all" selectionMode="multiple">
          {data.map((area) => (
            <AccordionItem key={area.id} title={<span className="font-bold text-lg text-gray-900 dark:text-white">{area.title}</span>} className="bg-gray-50">
              {/* Nivel 2: Proyectos */}
              <Accordion variant="light" className="pl-2" defaultExpandedKeys="all" selectionMode="multiple">
                {area.projects.map((project) => (
                  <AccordionItem
                    key={project.id}
                    title={
                      <div className="flex items-center w-full gap-4 pr-4">
                        <span className="font-semibold text-gray-700 dark:text-gray-200 whitespace-nowrap">{project.title}</span>
                        <Progress
                          size="md"
                          value={project.progress}
                          color="primary"
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
                          <div className="grid grid-cols-[220px_1fr_1fr_1fr_1fr] gap-4 py-2">
                            {/* Espacio vacío para alinear con el header */}
                            <div></div>
                            {columnsConfig.map((col) => (
                              <DroppableKanbanColumn
                                key={`${task.id}-${col.status}`}
                                status={col.status}
                                colorClass={col.color}
                                subtasks={task.subtasks}
                                taskId={task.id}
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

      {/* Drag Overlay */}
      <DragOverlay>
        {activeSubtask ? <SubtaskCard subtask={activeSubtask} /> : null}
      </DragOverlay>
    </DndContext>
  );
};

export default KanbanTaskView;
