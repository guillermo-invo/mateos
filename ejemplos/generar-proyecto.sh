#!/bin/bash
# Script de ejemplo para generar un proyecto estratégico con IA

echo "🚀 Generando proyecto estratégico con IA..."
echo ""

# Opción 1: Proyecto nuevo desde cero
curl -s -X POST http://localhost:1410/generar-proyecto \
  -H "Content-Type: application/json" \
  -d '{
    "descripcion": "Quiero crear un sistema de gestión de voluntarios para Involucrate. El sistema debe permitir: 1) Inscripción de voluntarios con perfiles, 2) Asignación automática a proyectos según habilidades, 3) Tracking de horas de voluntariado, 4) Generación de reportes de impacto mensuales, 5) Dashboard para coordinadores con métricas en tiempo real."
  }' | python3 -m json.tool

echo ""
echo "✅ Proyecto creado!"
echo ""

# Ver el proyecto creado
echo "📊 Consultando proyecto generado..."
PROJECT_ID=$(docker-compose -f /home/azureuser/mateos/docker-compose.yml exec -T postgres-db psql -U asistente -d asistente_db -t -c "SELECT id FROM proyectos_estrategicos ORDER BY id DESC LIMIT 1;")

docker-compose -f /home/azureuser/mateos/docker-compose.yml exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT
  p.id,
  p.nombre,
  p.descripcion,
  p.estado,
  (SELECT COUNT(*) FROM tareas_estrategicas WHERE proyecto_id = p.id) as num_tareas,
  (SELECT COUNT(*) FROM subtareas s
   JOIN tareas_estrategicas t ON s.tarea_estrategica_id = t.id
   WHERE t.proyecto_id = p.id) as num_subtareas
FROM proyectos_estrategicos p
WHERE p.id = $PROJECT_ID;
"

echo ""
echo "📋 Tareas del proyecto:"
docker-compose -f /home/azureuser/mateos/docker-compose.yml exec -T postgres-db psql -U asistente -d asistente_db -c "
SELECT
  t.id,
  t.nombre,
  t.moscow,
  t.tiempo_estimado_horas as horas,
  (SELECT COUNT(*) FROM subtareas WHERE tarea_estrategica_id = t.id) as subtareas
FROM tareas_estrategicas t
WHERE t.proyecto_id = $PROJECT_ID
ORDER BY t.orden;
"
