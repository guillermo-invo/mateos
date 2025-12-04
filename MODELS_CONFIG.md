# Configuración de Modelos IA

Este sistema permite cambiar los modelos de IA utilizados en Mateos sin necesidad de reconstruir los contenedores Docker.

## Ubicación de Configuración

Los modelos están configurados en archivos JSON que se montan como volúmenes en los contenedores:

- **Automatizaciones**: `automatizaciones/models-config.json`
- **Next.js API**: `next-app/models-config.json`

Ambos archivos deben mantenerse sincronizados.

## Estructura de Configuración

```json
{
  "transcription": {
    "model": "whisper-1",
    "description": "Modelo para transcripción de audio"
  },
  "extraction": {
    "model": "gpt-5-mini",
    "temperature": 0,
    "maxTokens": 4000,
    "description": "Modelo para clasificar y extraer entidades del bot (tareas, compromisos, registros, ideas)"
  },
  "projectCreation": {
    "model": "gpt-5.1",
    "temperature": 0.7,
    "maxTokens": 8000,
    "description": "Modelo para crear proyectos estratégicos y tareas estratégicas con análisis profundo"
  },
  "dailySummary": {
    "model": "gpt-5-mini",
    "temperature": 0.5,
    "maxTokens": 4000,
    "description": "Modelo para resúmenes diarios automáticos"
  }
}
```

## Funciones de los Modelos

### 1. **transcription** (whisper-1)
- **Uso**: Transcripción de notas de voz a texto
- **Servicio**: `next-app` (whisper-client.ts)
- **Ubicación**: next-app/src/lib/whisper-client.ts:60

### 2. **extraction** (gpt-5-mini)
- **Uso**: Clasificación y extracción de entidades de transcripciones
  - Detectar tipo de mensaje (tarea, compromiso, registro, idea)
  - Extraer información estructurada (fechas, prioridades, personas, etc.)
- **Servicio**: `automatizaciones` (ai-extractor.ts)
- **Ubicación**: automatizaciones/src/ai-extractor.ts:131
- **Configuración actual**:
  - Temperature: 0 (respuestas determinísticas)
  - MaxTokens: 4000

### 3. **projectCreation** (gpt-5.1)
- **Uso**: Análisis estratégico de proyectos
  - Generar justificación estratégica
  - Crear objetivos SMART
  - Diseñar tareas estratégicas con dependencias
  - Calcular scores de motivación y alineación
  - Identificar riesgos y oportunidades
- **Servicio**: `automatizaciones` (project-creator.ts)
- **Ubicación**: automatizaciones/src/project-creator.ts:processProjectWithAI
- **Configuración actual**:
  - Temperature: 0.7 (balance creatividad/coherencia)
  - MaxTokens: 8000 (análisis profundo)

### 4. **dailySummary** (gpt-5-mini)
- **Uso**: Generación de resúmenes diarios automáticos por Telegram
- **Servicio**: `automatizaciones` (daily-summary.ts)
- **Ubicación**: automatizaciones/src/daily-summary.ts:256
- **Configuración actual**:
  - Temperature: 0.5
  - MaxTokens: 4000
- **Horario**: Configurable vía `DAILY_SUMMARY_TIME` (default: 20:00 UTC-3)

## Cómo Cambiar un Modelo

### Opción 1: Editar en Caliente (Sin Restart)

1. Editar el archivo de configuración:
   ```bash
   nano automatizaciones/models-config.json
   nano next-app/models-config.json
   ```

2. Cambiar el modelo deseado:
   ```json
   {
     "extraction": {
       "model": "gpt-4o",  // Cambiar de gpt-5-mini a gpt-4o
       "temperature": 0,
       "maxTokens": 4000
     }
   }
   ```

3. **NO es necesario reiniciar los contenedores**
   - El sistema recarga la configuración cada 5 segundos automáticamente
   - El cambio se aplica en la siguiente llamada al modelo

### Opción 2: Con Restart (Garantiza Aplicación Inmediata)

1. Editar los archivos de configuración (igual que arriba)

2. Reiniciar solo el servicio afectado:
   ```bash
   # Para cambios en extraction, projectCreation, dailySummary:
   docker compose restart automatizaciones

   # Para cambios en transcription:
   docker compose restart next-app
   ```

## Cache y TTL

- **TTL del Cache**: 5 segundos
- Los modelos se recargan automáticamente sin necesidad de restart
- Si necesitas forzar la recarga inmediata, reinicia el contenedor

## Modelos Recomendados por Función

### Para Producción (Balance Costo/Calidad)
```json
{
  "transcription": "whisper-1",
  "extraction": "gpt-5-mini",
  "projectCreation": "gpt-5.1",
  "dailySummary": "gpt-5-mini"
}
```

### Para Desarrollo (Costo Bajo)
```json
{
  "transcription": "whisper-1",
  "extraction": "gpt-5-mini",
  "projectCreation": "gpt-5-mini",
  "dailySummary": "gpt-5-mini"
}
```

### Para Máxima Calidad
```json
{
  "transcription": "whisper-1",
  "extraction": "gpt-5.1",
  "projectCreation": "gpt-5.1",
  "dailySummary": "gpt-5.1"
}
```

## Fallback y Valores por Defecto

Si el archivo `models-config.json` no existe o tiene errores:

1. El sistema intentará leer de múltiples ubicaciones:
   - `/app/models-config.json` (Docker)
   - `./models-config.json` (Desarrollo)
   - `../models-config.json` (Relativo a src)

2. Si no encuentra el archivo, usa valores por defecto:
   - Modelos configurados en el código
   - Variables de entorno (legacy): `OPENAI_MODEL`, `OPENAI_DAILY_MODEL`

3. Los logs mostrarán: `⚠️ models-config.json no encontrado, usando valores por defecto`

## Logs y Verificación

Para verificar qué modelo está usando el sistema:

```bash
# Ver logs de automatizaciones
docker logs mateos-automatizaciones --tail 100

# Buscar línea de configuración cargada:
# ✅ Configuración de modelos cargada: { transcription: 'whisper-1', extraction: 'gpt-5-mini', ... }
```

## Troubleshooting

### El modelo no cambia después de editar el archivo

1. Verificar que el archivo esté en la ubicación correcta
2. Verificar sintaxis JSON (usar `jq` o un validador online)
3. Esperar 5 segundos para que el cache expire
4. Si persiste, reiniciar el contenedor

### Error: "models-config.json no encontrado"

1. Verificar que el archivo existe en ambas ubicaciones:
   - `automatizaciones/models-config.json`
   - `next-app/models-config.json`
2. Verificar que docker-compose.yml tiene los volúmenes montados:
   ```yaml
   volumes:
     - ./automatizaciones/models-config.json:/app/models-config.json:ro
   ```
3. Rebuild y restart de los contenedores:
   ```bash
   docker compose up -d --build
   ```

### Errores de OpenAI API

Si aparecen errores como "model not found":
1. Verificar que el modelo existe en la API de OpenAI
2. Verificar que tienes acceso al modelo (algunos requieren permisos especiales)
3. Revisar la documentación de OpenAI para nombres correctos de modelos

## Integración con Proyectos Estratégicos

Cuando se crea un proyecto estratégico desde el frontend:

1. **Next.js API** recibe la petición (`/api/proyectos-estrategicos`)
2. Guarda el proyecto en la BD
3. Notifica a **automatizaciones** vía webhook (`/webhook/proyecto`)
4. **Automatizaciones** procesa con IA usando modelo `projectCreation`:
   - Analiza contexto personal (áreas, motivos, misiones)
   - Genera justificación estratégica
   - Crea objetivos SMART
   - Diseña 3-8 tareas estratégicas
   - Calcula scores y riesgos
5. Guarda el análisis y tareas en la BD

Todo esto sucede automáticamente, sin intervención manual.
