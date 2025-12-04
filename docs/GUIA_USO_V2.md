# 📘 Guía de Uso - MATEOS V2

## 🎯 Cómo Generar Proyectos Estratégicos

### Opción 1: API REST (Recomendado)

#### Endpoint: `POST /generar-proyecto`

**URL:** `http://localhost:1410/generar-proyecto`

**Body (JSON):**
```json
{
  "descripcion": "Descripción detallada del proyecto que quieres crear",
  "documentosUrls": ["https://url-opcional.com/documento.pdf"],  // Opcional
  "ideaId": 123  // Opcional - ID de una idea existente para vincular
}
```

**Ejemplo con curl:**
```bash
curl -X POST http://localhost:1410/generar-proyecto \
  -H "Content-Type: application/json" \
  -d '{
    "descripcion": "Crear un sistema de gestión de voluntarios con inscripciones, asignación automática y reportes de impacto"
  }'
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "message": "Proyecto generado y guardado exitosamente",
  "projectId": 1
}
```

---

### Opción 2: Desde una Idea Capturada

Si ya tienes una idea guardada en el sistema:

```bash
# 1. Ver tus ideas pendientes
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT id, titulo, descripcion, categoria
FROM ideas_capturadas
WHERE implementada = false
ORDER BY id DESC
LIMIT 10;
"

# 2. Generar proyecto desde la idea
curl -X POST http://localhost:1410/generar-proyecto \
  -H "Content-Type: application/json" \
  -d '{
    "descripcion": "Descripción ampliada del proyecto",
    "ideaId": 3
  }'
```

Esto marcará la idea como implementada y la vinculará al proyecto.

---

### Opción 3: Por Voz (vía Telegram)

Envía un audio por Telegram que contenga palabras clave de proyecto:

> "Quiero hacer un **proyecto** para gestionar voluntarios..."

El sistema detectará automáticamente que es un proyecto y te preguntará si quieres desarrollarlo en MATEOS.

---

## 📊 Consultar Proyectos

### Ver todos los proyectos

```bash
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT
  p.id,
  p.nombre,
  p.estado,
  array_length(p.areas_ids, 1) as num_areas,
  array_length(p.motivos_ids, 1) as num_motivos,
  (SELECT COUNT(*) FROM tareas_estrategicas WHERE proyecto_id = p.id) as tareas,
  (SELECT COUNT(*) FROM subtareas s
   JOIN tareas_estrategicas t ON s.tarea_estrategica_id = t.id
   WHERE t.proyecto_id = p.id) as subtareas,
  created_at
FROM proyectos_estrategicos p
ORDER BY p.id DESC;
"
```

### Ver detalle de un proyecto específico

```bash
PROJECT_ID=1

docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT * FROM proyectos_estrategicos WHERE id = $PROJECT_ID \gx
"
```

### Ver tareas de un proyecto

```bash
PROJECT_ID=1

docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT
  t.id,
  t.nombre,
  t.orden,
  t.moscow,
  t.tiempo_estimado_horas,
  t.nivel_riesgo,
  t.estado,
  (SELECT COUNT(*) FROM subtareas WHERE tarea_estrategica_id = t.id) as subtareas_count
FROM tareas_estrategicas t
WHERE t.proyecto_id = $PROJECT_ID
ORDER BY t.orden;
"
```

### Ver subtareas de una tarea

```bash
TAREA_ID=1

docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT
  s.id,
  s.titulo,
  s.completada,
  s.tiempo_estimado_minutos,
  s.moscow,
  d.nombre as destreza_requerida
FROM subtareas s
LEFT JOIN destrezas d ON s.destreza_principal_id = d.id
WHERE s.tarea_estrategica_id = $TAREA_ID
ORDER BY s.id;
"
```

---

## 🎨 Consultar Datos Taxativos

### Áreas de Vida

```bash
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT id, nombre, descripcion, color_hex
FROM areas_vida
WHERE activa = true
ORDER BY orden_visualizacion;
"
```

### Motivos Personales

```bash
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT id, nombre, descripcion, icono, peso_personal
FROM motivos_personales
ORDER BY peso_personal DESC;
"
```

### Destrezas (con metadata de energía)

```bash
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT id, nombre, categoria, nivel_actual, costo_energetico, mejor_momento_dia, requiere_flow
FROM destrezas
ORDER BY categoria, nombre;
"
```

### Dificultades

```bash
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT id, nombre, nivel_impacto, estrategia_mitigacion
FROM dificultades
ORDER BY nivel_impacto DESC;
"
```

### Misiones de Vida

```bash
docker-compose exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT id, nombre, descripcion, vision, prioridad
FROM misiones_vida
ORDER BY prioridad DESC;
"
```

---

## 🔧 Uso Programático (Node.js/TypeScript)

### Crear proyecto con Prisma

```typescript
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// Crear proyecto manualmente
const proyecto = await prisma.proyectoEstrategico.create({
  data: {
    nombre: "Sistema de Gestión de Voluntarios",
    descripcion: "Plataforma completa para coordinar voluntarios",
    areasIds: [1, 2],  // involucrate, involucrarse
    motivosIds: [1, 2, 9],  // impacto_social, desarrollo_personal, comunidad_pertenencia
    destrezasRequeridasIds: [8, 10, 75],  // liderazgo, hacerPlanes, voluntariadoGestion
    dificultadesIds: [1],
    misionesIds: [1],
    estado: "planificacion",
    prioridadGlobal: 0.85,
    scoreMotivacional: 0.90,
    scoreAlineacion: 0.95
  }
});

// Crear tarea estratégica
const tarea = await prisma.tareaEstrategica.create({
  data: {
    proyectoId: proyecto.id,
    nombre: "Diseñar base de datos",
    descripcion: "Modelar entidades y relaciones del sistema",
    orden: 1,
    moscow: "must",
    tiempoEstimadoHoras: 8,
    nivelRiesgo: "medio",
    prioridadVelocidadPerfeccion: "balanceado",
    estado: "por_hacer"
  }
});

// Crear subtarea
const subtarea = await prisma.subtarea.create({
  data: {
    tareaEstrategicaId: tarea.id,
    titulo: "Crear diagrama ER",
    completada: false,
    tiempoEstimadoMinutos: 120,
    moscow: "must",
    destrezaPrincipalId: 76  // diseñoFuncional
  }
});
```

### Consultar con Prisma

```typescript
// Obtener proyecto con tareas y subtareas
const proyectoCompleto = await prisma.proyectoEstrategico.findUnique({
  where: { id: 1 },
  include: {
    tareas: {
      include: {
        subtareas: true
      }
    }
  }
});

// Obtener destrezas de alta energía
const destrezasIntensas = await prisma.destrezas.findMany({
  where: {
    costoEnergetico: {
      in: ['pico', 'alta']
    }
  }
});

// Completar subtarea
await prisma.subtarea.update({
  where: { id: subtareaId },
  data: {
    completada: true,
    updatedAt: new Date()
  }
});
```

---

## ⚠️ Notas Importantes

### Mock vs IA Real

**Actualmente el sistema usa datos de prueba (mock)** porque necesitas configurar la API key de Anthropic:

1. Verifica que tengas `ANTHROPIC_API_KEY` en tu archivo `.env`
2. Si no la tienes, el sistema generará proyectos con estructura mínima de prueba
3. Para producción real, asegúrate de tener la API key configurada

### Variables de Entorno Necesarias

```bash
# En /home/azureuser/mateos/.env
ANTHROPIC_API_KEY=tu-api-key-aquí
OPENAI_API_KEY=tu-openai-key  # Para procesamiento de audio
```

---

## 📈 Próximos Pasos

1. **Probar generación de proyecto** con el endpoint
2. **Verificar que se crean tareas y subtareas** correctamente
3. **Crear tu primer proyecto real** desde una descripción
4. **Explorar los datos taxativos** para entender el contexto
5. **Comenzar a usar el sistema** para gestionar tus proyectos

---

## 🆘 Troubleshooting

### El proyecto se crea pero sin tareas

- Verifica que `ANTHROPIC_API_KEY` esté configurada
- Revisa los logs: `docker-compose logs automatizaciones --tail 100`
- El sistema debería decir "Mocking AI call" si no hay API key

### Error de validación

- Asegúrate de no enviar `ideaId: null`, mejor omitirlo completamente
- La descripción debe tener al menos 1 carácter
- Los `documentosUrls` deben ser URLs válidas si se envían

### No se vincula a la idea

- Verifica que el `ideaId` existe en la tabla `ideas_capturadas`
- Asegúrate que no esté ya implementada (`implementada = false`)

---

¿Necesitas ayuda? Revisa los logs o consulta la documentación técnica en `/home/azureuser/mateos/DEPLOYMENT_V2_SUMMARY.md`
