# BITÁCORA - Proyecto Mateos (Raíz)

Esta bitácora registra cambios arquitectónicos globales, actualizaciones de infraestructura (Docker, .env), y operaciones DevOps del proyecto.

**Formato de entrada:**
```
## YYYY-MM-DD HH:mm | [raiz] | [claude-code/manual/otro]

**Título de la actividad**
- Descripción de cambios
- Decisiones tomadas
- Próximos pasos (si los hay)
```

---

## 2026

### Mayo

## 2026-05-21 15:30 | [docker] [seguridad] | [claude-code]

**Respuesta a incidente de seguridad crítico - Restricción de puertos de bases de datos**
- **[Contexto]:** Parte de la respuesta al incidente de seguridad del servidor (cryptominer detectado)
- **[Problema]:** PostgreSQL de transcripciones expuesto a `0.0.0.0:1432`
- **[Corrección]:** Modificado `docker-compose.yml`
  - Cambio: `"1432:5432"` → `"127.0.0.1:1432:5432"`
  - Contenedor `transcripcion-postgres` restringido a localhost
- **[Verificación]:** Puerto ahora solo accesible desde el servidor local
- **[Impacto]:** Cero - aplicaciones locales (next-app, automatizaciones) siguen funcionando
- **[Lección]:** Bases de datos no necesitan exposición externa para comunicación entre contenedores

### Enero

## 2026-01-03 10:00 | [database] [google-calendar] | [claude-code]

**Implementación completa del sistema de tareas recurrentes y integración con Google Calendar**

#### Base de Datos: Migraciones del Sistema de Tareas Recurrentes
- **[Migración 01]:** Tablas de tareas recurrentes
  - Creada tabla `tareas_recurrentes` (patrón de recurrencia en JSONB)
  - Creada tabla `instancias_tareas_recurrentes` (instancias generadas)
  - Creada tabla `disponibilidad_semanal` (horas productivas por día)
  - Índices optimizados para búsquedas por fecha y estado
  - Triggers para auto-actualización de `updated_at`

- **[Migración 02]:** Vistas de disponibilidad y carga semanal
  - Vista `disponibilidad_real_semanal`: Cálculo de horas disponibles por día
  - Vista `carga_semanal_recurrentes`: Tiempo ocupado por recurrentes
  - Vista `instancias_proxima_semana`: Instancias próximas a ejecutar
  - Vista `tareas_recurrentes_resumen`: Resumen por área de vida

- **[Migración 03]:** Modificaciones a tareas estratégicas
  - Agregados campos: `energia_requerida`, `contexto_necesario`, `duracion_real_horas`
  - Agregados campos de bloqueo: `bloqueada_por`, `fecha_estimada_desbloqueo`
  - Creada tabla `bloques_tiempo_planificados` (chunks para Google Calendar)
  - Índices para optimizar consultas de planificación

- **[Migración 04]:** Sistema de configuración personal
  - Creada tabla `configuracion_personal` (valores en JSONB)
  - Insertadas 29 configuraciones por defecto (TDAH-optimizado)
  - Funciones creadas: `get_config()`, `get_config_numero()`, `get_config_texto()`, `get_config_bool()`
  - Función `mateos_set_config()` para actualización de configuraciones

- **[Queries Útiles]:** Vistas de análisis y priorización
  - Vista `tareas_sugeridas_hoy`: Tareas priorizadas por score compuesto
  - Vista `vista_que_hacer_ahora`: Top 10 subtareas priorizadas
  - Vista `tareas_bloqueadas_atencion`: Tareas bloqueadas que requieren seguimiento
  - Vista `compromisos_proximos`: Compromisos ordenados por urgencia (crítico para marca personal)
  - Vista `planificacion_semana_completa`: Consolidado de recurrentes + bloques planificados
  - Vista `metricas_tareas_recurrentes`: Tasa de completitud últimos 30 días
  - Vista `precision_estimaciones`: Análisis de estimaciones vs realidad
  - Vista `tiempo_por_area_semana`: Distribución de tiempo por área
  - Vista `distribucion_porcentual_areas`: Porcentaje de tiempo por área
  - Vista `vista_sobrecarga_semanal`: Detección de sobrecarga con indicadores visuales

- **[Resultado]:** Sistema completo de gestión de tiempo con:
  - 5 tablas nuevas
  - 19 vistas de análisis
  - 29 configuraciones instaladas
  - Detección automática de sobrecarga
  - Priorización inteligente con score compuesto

#### Google Calendar API: Integración Completa
- **[Service Account]:** Configurado en Google Cloud Platform
  - Proyecto: `lifeos-463317`
  - Service Account: `mateos@lifeos-463317.iam.gserviceaccount.com`
  - Credenciales almacenadas en: `/home/azureuser/mateos/secrets/google-calendar-service-account.json`
  - Permisos: 600 (solo azureuser)

- **[Calendarios Integrados]:**
  - **trunches** (`c_0c44e02...@group.calendar.google.com`): Bloques de tiempo por área de vida (capacidad disponible)
    - Compartido con service account con permisos de escritura
    - Eventos: dormir, meditación, trabajo, baño, revisión de día
  - **guillermo@involucrate.uy**: Citas, reuniones, tareas reales (eventos confirmados)
    - Compartido con service account con permisos de escritura
    - Uso: eventos confirmados y compromisos reales

- **[Librería Instalada]:** `googleapis` (Node.js)
  - Instalado en `/home/azureuser/mateos/automatizaciones/node_modules`
  - Versión compatible con autenticación de Service Account

- **[Scripts Creados]:**
  1. **`/automatizaciones/src/google-calendar-test.js`**:
     - Verificación de conexión con ambos calendarios
     - Lectura de eventos próximos 7 días
     - Diagnóstico de permisos y errores
     - Uso: `node src/google-calendar-test.js`

  2. **`/automatizaciones/src/calendar-sync.js`**:
     - Sincronización bidireccional completa
     - Funciones principales:
       - `getTrunchesBlocks()`: Lee bloques de capacidad del calendario trunches
       - `getPersonalEvents()`: Lee eventos confirmados del calendario personal
       - `calculateAvailability()`: Calcula disponibilidad real (capacidad - compromisos)
       - `createPersonalEvent()`: Crea eventos en calendar desde Mateos
       - `syncPlannedBlocksToCalendar()`: Sincroniza bloques planificados de BD a Calendar
       - `printAvailabilityReport()`: Genera reporte de disponibilidad por día
     - Comandos CLI:
       - `node src/calendar-sync.js report [días]` - Reporte de disponibilidad
       - `node src/calendar-sync.js sync` - Sincronizar bloques planificados
       - `node src/calendar-sync.js availability` - JSON de disponibilidad

- **[Configuración en BD]:**
  - Calendar ID trunches guardado en `configuracion_personal`
  - Calendar ID personal guardado en `configuracion_personal`
  - Colores configurados para diferentes tipos de bloques

- **[Capacidades Implementadas]:**
  - ✅ Leer bloques de trunches (capacidad por área)
  - ✅ Leer eventos del calendario personal (compromisos)
  - ✅ Calcular disponibilidad real cruzando ambos calendarios
  - ✅ Crear eventos desde Mateos en Google Calendar
  - ✅ Generar reportes de disponibilidad por día
  - ✅ Detectar sobrecarga de tiempo
  - ⏳ Sincronización automática con cron (próximo paso)

#### Documentación Actualizada
- **[_CONTEXT.md]:** Actualizada sección de Google Calendar API
  - Documentados calendarios integrados
  - Documentados scripts y comandos
  - Actualizado estado del proyecto (integración completa)
- **[GOOGLE_CALENDAR_SETUP.md]:** Creada guía paso a paso para configuración
  - Instrucciones completas para crear Service Account
  - Pasos para compartir calendarios
  - Troubleshooting común
- **[secrets/README.md]:** Creado README en directorio de secrets
  - Documentación de archivos de credenciales
  - Instrucciones de permisos

#### Próximos Pasos
1. Configurar disponibilidad semanal real del usuario
2. Crear tareas recurrentes de ejemplo
3. Crear proyectos y tareas estratégicas
4. Implementar API endpoints en Next.js para sincronización automática
5. Configurar cron job para sincronización periódica
6. Implementar dashboard visual de métricas

---

## 2025

### Diciembre

## 2025-12-26 21:18 | [docker] | [claude-code]

**Migración de Obsidian vault de Named Volume a Bind Mount**
- **[Razón]:** Facilitar acceso desde scripts sin necesidad de sudo
- **[Backup]:** Creado backup completo del vault (467 archivos, 23 MB)
  - Ubicación backup: `/home/azureuser/backups/obsidian_migration/vault_backup_20251226_211356.tar.gz`
- **[Migración]:** Datos copiados de volume a `/home/azureuser/obsidian/`
  - Ruta antigua: `/var/lib/docker/volumes/mateos_obsidianGfork/_data`
  - Ruta nueva: `/home/azureuser/obsidian/`
  - Permisos: `azureuser:azureuser` (sin necesidad de sudo)
- **[docker-compose.yml]:** Cambiado de named volume a bind mount
  - ANTES: `obsidianGfork:/vaults`
  - DESPUÉS: `/home/azureuser/obsidian:/vaults`
  - Volume `obsidianGfork` comentado en sección volumes (pendiente eliminación)
- **[Contenedor]:** Recreado y funcionando correctamente con bind mount
- **[Verificación]:** 467 archivos accesibles, Obsidian Sync funcionando
- **[Documentación]:** Actualizada documentación en `_CONTEXT.md` con nuevas rutas
- Próximos pasos: Monitorear estabilidad 24-48h antes de eliminar volume antiguo

## 2025-12-26 23:50 | [docker] | [claude-code]

**Verificación post-migración y corrección de permisos Obsidian**
- **[Obsidian Sync]:** Confirmado funcionamiento bidireccional (PC ↔ Cloud ↔ Server)
  - Archivos creados en PC se sincronizan correctamente a servidor
  - Archivos creados en servidor se sincronizan a PC y celular
- **[Problema resuelto]:** Permisos incorrectos impedían indexación en contenedor
  - **Causa:** PUID=1000 en contenedor, pero azureuser tiene UID=1001
  - **Solución:** Actualizado docker-compose.yml con PUID=1001, PGID=1001
  - Container recreado exitosamente
- **[Seguridad]:** Acceso web a Obsidian deshabilitado después de configuración
  - nginx location block `/obsidian/` comentado
  - Obsidian Sync sigue funcionando internamente sin exposición web
  - Acceso web solo para mantenimiento/configuración futura
- **[Estado final]:** Sistema completamente funcional
  - 467 archivos migrados y accesibles
  - Scripts pueden acceder sin sudo a `/home/azureuser/obsidian/ObsidianGfork/`
  - Sync activo 24/7
- **[Documentación]:** Actualizada BITACORA.md y _CONTEXT.md con estado final
- Próximos pasos: Scripts de generación automática de archivos markdown desde Mateos

## 2025-12-26 19:40 | [docker] | [claude-code]

**Implementación de Obsidian con KasmVNC y Obsidian Sync**
- **[docker-compose.yml]:** Agregado contenedor `mateos-obsidian` (LinuxServer Obsidian image)
- **[Volumes]:** Creado volume `obsidianGfork` para persistencia del vault
  - Ubicación: `/var/lib/docker/volumes/mateos_obsidianGfork/_data`
  - Montado en `/vaults` dentro del contenedor
- **[Configuración]:** Carpeta `./obsidian` montada en `/config` para configuración de KasmVNC
- **[Redes]:** Contenedor conectado a `app-network` e `involucra-network`
- **[Puertos]:** 1420:3000 (web), 1421:3001 (https)
- **[Obsidian Sync]:** Configurado y funcionando 24/7 para sincronización con PC/móvil
- **[Acceso web]:** Proxy reverso en nginx configurado en `/obsidian` (posteriormente deshabilitado por seguridad)
- **[Integración]:** Otras aplicaciones pueden acceder al vault montando el volume `obsidianGfork`
- Próximos pasos: Scripts de generación automática de archivos markdown desde Mateos

## 2025-12-26 15:00 | [raiz] | [claude-code]

**Inicialización del sistema de contexto y bitácora**
- Creada carpeta `Sistema/` con guías completas de documentación
- Creados 10 archivos `_CONTEXT.md` en carpetas relevantes:
  - next-app/ y subcarpetas (api/, components/, lib/)
  - automatizaciones/ y subcarpetas (ia/, prisma/)
  - telegram-bot/
  - scripts/db/ y scripts/python/
- Creados 4 archivos `BITACORA.md` en carpetas principales (raíz, next-app, automatizaciones, scripts)
- Decisión: Sistema de documentación en cascada (general → específico, cero redundancia)
- Próximos pasos: Validar sistema con primera sesión de trabajo real
