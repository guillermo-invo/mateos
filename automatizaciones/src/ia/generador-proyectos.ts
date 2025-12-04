import { PROMPT_SISTEMA_PROYECTO } from './prompts-proyectos';
import { EstructuraProyecto } from '../types'; // Assuming types are here, will confirm

// Placeholder for Anthropic client. In a real scenario, this would be an actual API client.
// For now, it's mocked or requires a proper import and setup.
const anthropic = {
  messages: {
    create: async ({ model, temperature, max_tokens, messages }: any) => {
      // Mock response for now
      console.log(`Mocking AI call to ${model} with messages:`, messages);
      return {
        content: [{ text: JSON.stringify({
          proyecto: {
            justificacion_estrategica: "Justificación estratégica de prueba",
            areas_ids: [1],
            motivos_ids: [1],
            destrezas_requeridas_ids: [1],
            dificultades_ids: [1],
            misiones_ids: [1]
          },
          tareas: [{
            nombre: "Tarea de prueba",
            orden: 1,
            moscow: "must",
            tiempo_estimado_horas: 1,
            nivel_riesgo: "bajo",
            subtareas: [{ titulo: "Subtarea de prueba" }]
          }]
        }) }],
        usage: { total_tokens: 100 }
      };
    },
  },
};

// Placeholder functions - these would interact with the database or other parts of the system
async function obtenerContextoPersonal(): Promise<string> {
  // Logic to fetch personal context from DB or configuration
  return "Guillermo es un solopreneur social, interesado en impacto social y desarrollo personal.";
}

async function obtenerProyectosActivos(): Promise<string> {
  // Logic to fetch active projects from DB
  return "No hay proyectos activos.";
}

function buildPrompt(descripcion: string, contexto: string, proyectosActivos: string): string {
  // Logic to construct the full prompt for the AI
  return `Descripción del proyecto: ${descripcion}\nContexto: ${contexto}\nProyectos activos: ${proyectosActivos}`;
}

async function validarEstructura(estructura: EstructuraProyecto): Promise<void> {
  // Logic to validate the AI-generated structure
  console.log("Validando estructura:", estructura);
  // Throw error if invalid
}

function calcularScoreMotivos(motivos_ids: number[]): number {
  // Mock function, in real scenario this would call the DB function or replicate its logic
  console.log("Calculando score de motivos para IDs:", motivos_ids);
  return 8.5;
}

function calcularScoreAlineacion(misiones_ids: number[]): number {
  // Mock function, in real scenario this would call the DB function or replicate its logic
  console.log("Calculando score de alineación para IDs:", misiones_ids);
  return 9.2;
}


export async function generarEstructuraProyecto(
  descripcion: string,
  documentosUrls?: string[]
): Promise<EstructuraProyecto> {
  // 1. Obtener contexto personal
  const contexto = await obtenerContextoPersonal();
  
  // 2. Obtener proyectos activos
  const proyectosActivos = await obtenerProyectosActivos();
  
  // 3. Construir prompt
  const prompt = buildPrompt(descripcion, contexto, proyectosActivos);
  
  // 4. Llamar a Claude/GPT
  const response = await anthropic.messages.create({
    model: "claude-3-5-sonnet-20241022",
    temperature: 0.3,
    max_tokens: 8000,
    messages: [
      { role: "system", content: PROMPT_SISTEMA_PROYECTO },
      { role: "user", content: prompt }
    ]
  });
  
  // 5. Parsear y validar
  const estructura = JSON.parse(response.content[0].text);
  await validarEstructura(estructura);
  
  // 6. Enriquecer con cálculos
  estructura.proyecto.score_motivacional = calcularScoreMotivos(estructura.proyecto.motivos_ids);
  estructura.proyecto.score_alineacion = calcularScoreAlineacion(estructura.proyecto.misiones_ids);
  
  return estructura;
}
