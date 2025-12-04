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

// Draggable Subtask Card
const DraggableSubtaskCard = ({ subtask }: { subtask: Subtask }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: subtask.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className="cursor-grab active:cursor-grabbing"
    >
      <Card shadow="sm" className="w-full mb-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 hover:border-blue-400 dark:hover:border-blue-600 transition-colors">
        <CardBody className="p-3 text-small flex flex-col gap-1">
          <p className="font-semibold text-gray-800 dark:text-gray-100">{subtask.title}</p>
          <div className="text-gray-600 dark:text-gray-400 text-xs flex flex-col">
            <span>Est: {subtask.estimate}</span>
            <div className="flex items-center gap-1 mt-1">
              <span>MoSCoW:</span>
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
      <CardBody className="p-3 text-small flex flex-col gap-1">
        <p className="font-semibold text-gray-800 dark:text-gray-100">{subtask.title}</p>
        <div className="text-gray-600 dark:text-gray-400 text-xs flex flex-col">
          <span>Est: {subtask.estimate}</span>
          <div className="flex items-center gap-1 mt-1">
            <span>MoSCoW:</span>
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
        </div>
      </CardBody>
    </Card>
  );
};

// Droppable Kanban Column
const DroppableKanbanColumn = ({
  status,
  colorClass,
  subtasks
}: {
  status: SubtaskStatus,
  colorClass: string,
  subtasks: Subtask[]
}) => {
  const filteredTasks = subtasks.filter(s => s.status === status);

  return (
    <div
      data-status={status}
      className={`h-full p-2 rounded-lg ${colorClass} dark:bg-opacity-40 flex flex-col gap-2 min-h-[150px] transition-colors`}
    >
      {filteredTasks.map(subtask => (
        <DraggableSubtaskCard key={subtask.id} subtask={subtask} />
      ))}
    </div>
  );
};

// Cabecera fija de la tabla (Waiting, Todo, etc.)
const KanbanHeaderRow = () => {
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

    // Determine the new status based on where it was dropped
    const newStatus = getStatusFromDroppable(over.id as string);
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

  // Helper function to determine status from droppable ID
  const getStatusFromDroppable = (id: string): SubtaskStatus | null => {
    // The droppable ID should be in format: "waiting", "todo", "doing", "done"
    // Or it could be a subtask ID (if dropped on a subtask)

    // First check if it's a status
    if (['waiting', 'todo', 'doing', 'done'].includes(id)) {
      return id as SubtaskStatus;
    }

    // If dropped on a subtask, find that subtask's status
    for (const area of data) {
      for (const project of area.projects) {
        for (const task of project.tasks) {
          const subtask = task.subtasks.find(s => s.id === id);
          if (subtask) {
            return subtask.status;
          }
        }
      }
    }

    return null;
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
                          <div className="grid grid-cols-[1fr_1fr_1fr_1fr] gap-4 py-2">
                            {columnsConfig.map((col) => (
                              <DroppableKanbanColumn
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

      {/* Drag Overlay */}
      <DragOverlay>
        {activeSubtask ? <SubtaskCard subtask={activeSubtask} /> : null}
      </DragOverlay>
    </DndContext>
  );
};

export default KanbanTaskView;
