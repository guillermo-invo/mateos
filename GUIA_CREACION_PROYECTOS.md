# Guía de Creación de Proyectos Estratégicos

## ✅ Sistema Implementado y Funcionando

El sistema de creación de proyectos con IA está **completamente funcional**. Los cambios implementados incluyen:

### 1. **Columnas de Fecha en Tareas y Subtareas** ✅

Se agregaron las columnas:
- `fecha_inicio` (DATE) en `tareas_estrategicas`
- `fecha_fin` (DATE) en `tareas_estrategicas`
- `fecha_inicio` (DATE) en `subtareas`
- `fecha_fin` (DATE) en `subtareas`

Estas columnas están disponibles en NocoDB para organizar tu día y visualizar en calendario.

### 2. **Procesamiento IA Automático** ✅

Cuando creas un proyecto desde https://mateos.involucrate.lat/proyectos/crear (modo manual), el sistema:

1. **Guarda el proyecto** con nombre, descripción, áreas y motivos que ingresaste
2. **Llama automáticamente a la IA** (gpt-5.1) en segundo plano
3. **Genera:**
   - Justificación estratégica (2-3 párrafos)
   - Objetivos SMART (3 objetivos)
   - 3-8 Tareas Estratégicas con:
     - Nombre y descripción
     - Prioridad MoSCoW (must/should/could/wont)
     - Tiempo estimado en horas
     - Nivel de riesgo (bajo/medio/alto/crítico)
     - Enfoque (velocidad/perfección/balanceado)
   - Scores de motivación y alineación (0-100)

## 🎯 Cómo Usar el Sistema

### Opción 1: Creación Manual (RECOMENDADO)

1. Ve a https://mateos.involucrate.lat/proyectos/crear
2. **NO marques** el checkbox "Generar con IA"
3. Completa:
   - **Descripción del Proyecto** (detallada, la IA usará esto)
   - **Nombre del Proyecto**
   - **Áreas de Vida** (selecciona las relevantes)
   - **Motivos Personales** (selecciona los que aplican)
4. Click en "Crear Proyecto Manual"
5. **Espera 10-30 segundos** mientras la IA procesa
6. Verás el proyecto con:
   - ✅ Justificación estratégica
   - ✅ Objetivos SMART
   - ✅ Tareas estratégicas generadas automáticamente

### Opción 2: Generación Completa con IA

1. Ve a https://mateos.involucrate.lat/proyectos/crear
2. **Marca** el checkbox "Generar con IA"
3. Solo completa:
   - **Descripción del Proyecto** (muy detallada)
4. Click en "Generar Proyecto con IA"
5. La IA generará TODO:
   - Nombre del proyecto
   - Áreas y motivos sugeridos
   - Tareas estratégicas

**Nota**: Esta opción llama a un endpoint diferente (`/generar-proyecto`) que aún está en desarrollo.

## 🔍 Verificar que Funcionó

### Método 1: Ver el Proyecto

1. Después de crear el proyecto, serás redirigido a `/proyectos/[id]`
2. Deberías ver:
   - **Justificación Estratégica**: Párrafos explicando por qué tiene sentido
   - **Objetivos SMART**: Lista de 3 objetivos
   - **Tareas Estratégicas**: 3-8 tareas con descripción detallada

### Método 2: Ver los Logs

```bash
# Ver logs de procesamiento IA
docker logs -f mateos-automatizaciones

# Deberías ver:
# 🎯 Webhook Proyecto recibido
# 🤖 Procesando proyecto "Tu Proyecto" con IA (gpt-5.1)...
# ✅ Configuración de modelos cargada
# ✅ Análisis de proyecto completado
# ✅ Proyecto X procesado exitosamente
```

## 📊 Ejemplo Real

El proyecto **"Mimochi2026"** (ID: 3) fue procesado exitosamente:

- ✅ Justificación estratégica: 3 párrafos detallados
- ✅ 3 Objetivos SMART con métricas claras
- ✅ 8 Tareas Estratégicas:
  1. Definir propuesta de valor 2026 (10h, must, riesgo medio)
  2. Diseñar arquitectura de alianzas (16h, must, riesgo alto)
  3. Segmentar y planificar 120 empresas (18h, must, velocidad)
  4. Campaña de comunicación 360 (22h, should, velocidad)
  5. Mapeo de merenderos (14h, must, balanceado)
  6. Logística de kits y voluntariado (20h, should, alto riesgo)
  7. Estrategia de prensa (15h, should, velocidad)
  8. Cierre y medición de impacto (16h, must, perfección)

Ver en: https://mateos.involucrate.lat/proyectos/3

## ⚙️ Configuración de Modelos IA

El sistema usa **gpt-5.1** para crear proyectos estratégicos (configurable en `models-config.json`):

```json
{
  "projectCreation": {
    "model": "gpt-5.1",
    "temperature": 0.7,
    "maxTokens": 8000,
    "description": "Modelo para crear proyectos estratégicos"
  }
}
```

## 🐛 Troubleshooting

### El proyecto no tiene tareas estratégicas

**Posible causa**: El webhook de IA tardó en procesar.

**Solución**:
1. Espera 30-60 segundos
2. Refresca la página del proyecto
3. Si aún no aparecen, revisa los logs:
```bash
docker logs mateos-automatizaciones --tail 50
```

### Error al crear proyecto

**Verifica**:
1. Que completaste el campo "Descripción" (obligatorio)
2. Que el servicio de automatizaciones esté funcionando:
```bash
curl https://mateos.involucrate.lat/api/health
```

### Las tareas no tienen fechas

**Esto es normal**. La IA NO asigna fechas automáticamente. Debes:
1. Ir a NocoDB
2. Abrir la tabla `tareas_estrategicas`
3. Asignar manualmente `fecha_inicio` y `fecha_fin`
4. Lo mismo para `subtareas`

Las fechas son para tu organización personal en calendario.

## 📝 Próximos Pasos

1. **Probar**: Crea un proyecto de prueba para familiarizarte
2. **Organizar en NocoDB**: Asigna fechas a las tareas
3. **Vista Calendario**: Configura la vista calendario en NocoDB usando `fecha_inicio` y `fecha_fin`

## 🔗 Recursos

- **Interfaz Web**: https://mateos.involucrate.lat/proyectos/crear
- **API Health**: https://mateos.involucrate.lat/api/health
- **Logs IA**: `docker logs -f mateos-automatizaciones`
- **Configuración Modelos**: `/home/azureuser/mateos/automatizaciones/models-config.json`

---

**¿Dudas?** Revisa los logs o verifica que los servicios estén corriendo:
```bash
docker ps | grep -E "mateos|transcripcion"
```
