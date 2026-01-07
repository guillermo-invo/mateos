'use client';

import { Card, CardBody, CardHeader, Progress, Chip } from " @heroui/react";
import Link from "next/link";

export type EstadoProyecto =
  | 'idea'
  | 'planificacion'
  | 'en_curso'
  | 'pausado'
  | 'completado'
  | 'cancelado'
  | 'archivado';

interface ProyectoCardProps {
  id: string;
  nombre: string;
  estado: EstadoProyecto;
  progreso: number;
  horasCompletadas: number;
  horasTotal: number;
  horasRestantes: number;
}

const estadoConfig: Record<EstadoProyecto, { color: any; label: string }> = {
  idea: { color: 'default', label: 'Idea' },
  planificacion: { color: 'primary', label: 'Planificación' },
  en_curso: { color: 'success', label: 'En Curso' },
  pausado: { color: 'warning', label: 'Pausado' },
  completado: { color: 'success', label: 'Completado' },
  cancelado: { color: 'danger', label: 'Cancelado' },
  archivado: { color: 'default', label: 'Archivado' },
};

// Helper function to safely format numbers with .toFixed()
const safeToFixed = (value: unknown, decimals: number = 1): string => {
  if (value === null || value === undefined) {
    return '0.0';
  }
  const numValue = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(numValue)) {
    return '0.0';
  }
  return numValue.toFixed(decimals);
};

export default function ProyectoCard({
  id,
  nombre,
  estado,
  progreso,
  horasCompletadas,
  horasTotal,
  horasRestantes,
}: ProyectoCardProps) {
  const estadoInfo = estadoConfig[estado];

  return (
    <Card
      className="w-full hover:shadow-lg transition-shadow cursor-pointer"
      isPressable
      as={Link}
      href={`/proyectos/${id}`}
    >
      <CardHeader className="flex justify-between items-center pb-0">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          {nombre}
        </h3>
        <Chip
          color={estadoInfo.color}
          variant="flat"
          size="sm"
        >
          {estadoInfo.label}
        </Chip>
      </CardHeader>

      <CardBody className="pt-2">
        {/* Barra de Progreso */}
        <Progress
          value={progreso}
          color={estadoInfo.color}
          showValueLabel
          className="mb-3"
        />

        {/* Información de Tiempo */}
        <div className="text-sm text-gray-600 dark:text-gray-400">
          <span className="font-medium">
            {safeToFixed(horasCompletadas, 1)}h
          </span>
          {' / '}
          <span className="font-medium">
            {safeToFixed(horasTotal, 1)}h
          </span>
          <span className="text-gray-500 dark:text-gray-500 ml-2">
            ({safeToFixed(horasRestantes, 1)}h restantes)
          </span>
        </div>
      </CardBody>
    </Card>
  );
}