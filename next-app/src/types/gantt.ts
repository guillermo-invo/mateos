// Types for Gantt API Response
export interface SubtareaGantt {
  id: number;
  nombre: string;
  fechaInicio: Date | null;
  fechaFin: Date | null;
}

export interface TareaGantt {
  id: number;
  nombre: string;
  orden: number;
  fechaInicio: Date | null;
  fechaFin: Date | null;
  subtareasEstrategicas: SubtareaGantt[];
}

export interface ProyectoGantt {
  id: number;
  nombre: string;
  fechaInicio: Date | null;
  fechaFinEstimada: Date | null;
  tareasEstrategicas: TareaGantt[];
}

// Types for Frappe Gantt
export interface FrappeGanttTask {
  id: string;
  name: string;
  start: string; // YYYY-MM-DD
  end: string;   // YYYY-MM-DD
  progress: number;
  custom_class: string;
  dependencies?: string;
}
