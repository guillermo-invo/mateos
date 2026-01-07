# Changelog de Cambios

## [2026-01-03] - Sistema de Tareas Recurrentes e Integración con Google Calendar

### 🆕 Nuevas Características

#### Sistema de Tareas Recurrentes
- **Tablas de Base de Datos**:
  - `tareas_recurrentes`: Definición de tareas que se repiten periódicamente
  - `instancias_tareas_recurrentes`: Instancias generadas automáticamente
  - `disponibilidad_semanal`: Configuración de horas productivas por día
  - `bloques_tiempo_planificados`: Chunks de tiempo para sincronizar con Calendar
  - `configuracion_personal`: Sistema de configuración flexible con 29 parámetros

- **Vistas de Análisis** (19 vistas totales):
  - `vista_que_hacer_ahora`: Top 10 subtareas priorizadas
  - `tareas_sugeridas_hoy`: Tareas del día con score compuesto
  - `disponibilidad_real_semanal`: Tiempo disponible vs ocupado
  - `vista_sobrecarga_semanal`: Detección de sobrecarga con indicadores
  - `compromisos_proximos`: Compromisos ordenados por urgencia
  - `planificacion_semana_completa`: Consolidado de toda la planificación
  - `metricas_tareas_recurrentes`: Tasa de completitud
  - `precision_estimaciones`: Análisis de estimaciones vs realidad
  - Y 11 vistas más de análisis de tiempo y productividad

#### Integración con Google Calendar
- **Autenticación**: Service Account configurado en Google Cloud Platform
  - Proyecto: `lifeos-463317`
  - Email: `mateos@lifeos-463317.iam.gserviceaccount.com`

- **Calendarios Integrados**:
  - **trunches**: Bloques de tiempo por área de vida (capacidad disponible)
  - **guillermo@involucrate.uy**: Citas, reuniones, tareas reales

- **Scripts de Sincronización**:
  - `google-calendar-test.js`: Verificación de conexión
  - `calendar-sync.js`: Sincronización bidireccional completa
    - Lectura de bloques de capacidad
    - Lectura de eventos confirmados
    - Cálculo de disponibilidad real
    - Creación de eventos desde Mateos
    - Reportes de disponibilidad

- **Capacidades**:
  - ✅ Análisis de disponibilidad cruzando múltiples calendarios
  - ✅ Detección automática de sobrecarga de tiempo
  - ✅ Sincronización de bloques planificados
  - ✅ Reportes de disponibilidad por día

### 🔄 Cambios Realizados

#### Migraciones de Base de Datos
- Ejecutadas 4 migraciones de alta y media prioridad
- Modificada tabla `tareas_estrategicas` con campos de energía y bloqueo
- Implementado sistema de triggers para actualización automática
- Creadas funciones auxiliares para configuración

#### Documentación
- Actualizado `_CONTEXT.md` con integración completa de Google Calendar
- Actualizada sección de estado del proyecto (fecha 2026-01-03)
- Creado `GOOGLE_CALENDAR_SETUP.md` con guía paso a paso
- Creado `secrets/README.md` para gestión de credenciales

#### Configuración
- Directorio `secrets/` creado con permisos 700
- Credenciales de Google Calendar almacenadas de forma segura
- Configuraciones guardadas en BD (calendar IDs, colores, etc.)

### 📋 Archivos Creados
- `/secrets/google-calendar-service-account.json` - Credenciales de Service Account
- `/automatizaciones/src/google-calendar-test.js` - Script de prueba
- `/automatizaciones/src/calendar-sync.js` - Script de sincronización
- `/GOOGLE_CALENDAR_SETUP.md` - Guía de configuración
- `/secrets/README.md` - Documentación de secrets

### 📝 Scripts Útiles

```bash
# Reporte de disponibilidad (próximos 7 días)
node src/calendar-sync.js report

# Reporte de 14 días
node src/calendar-sync.js report 14

# Sincronizar bloques planificados a Calendar
node src/calendar-sync.js sync

# Ver disponibilidad en formato JSON
node src/calendar-sync.js availability
```

### 🎯 Próximos Pasos
1. Configurar disponibilidad semanal real del usuario
2. Crear tareas recurrentes de ejemplo
3. Implementar API endpoints en Next.js
4. Configurar cron job para sincronización automática
5. Dashboard visual de métricas

---

## [2025-11-07] - Versión Actual

### 🆕 Nuevas Características
- **Configuración de NocoDB**: Se agregó documentación completa para conectar NocoDB a la base de datos `asistente_db` del proyecto Mateos.

### 🔄 Cambios Realizados

#### 1. Configuración de Base de Datos para NocoDB
- **Archivo creado**: [`NOCDB_CONFIG.md`](mateos/NOCDB_CONFIG.md)
- **Propósito**: Documentar los parámetros de conexión necesarios para que NocoDB se conecte a la base de datos PostgreSQL del proyecto Mateos a través de la red `involucra-network`.

#### 2. Parámetros de Conexión Documentados
- **Host**: `postgres-db` (nombre del servicio en Docker Compose)
- **Puerto**: `5432` (puerto interno del contenedor)
- **Usuario**: `asistente`
- **Contraseña**: `n8npass`
- **Base de Datos**: `asistente_db`
- **SSL**: No requerido para comunicación entre contenedores

#### 3. Requisitos de Red
- **Red Docker**: `involucra-network` (red externa compartida)
- **Visibilidad**: Los contenedores pueden comunicarse usando nombres de servicio
- **Seguridad**: La comunicación es interna y segura dentro de la red Docker

### 📋 Archivos Modificados
- [`docker-compose.yml`](mateos/docker-compose.yml): Se agregó el servicio `telegram-bot` (cambio previo)

### 📝 Notas Importantes
- La configuración permite a NocoDB acceder a la base de datos `asistente_db` utilizada por el servicio de automatizaciones
- No se requiere SSL para la conexión entre contenedores en la misma red Docker
- La documentación incluye ejemplos de configuración para contenedores NocoDB

### 🔗 URL de Conexión Completa
```
postgresql://asistente:n8npass@postgres-db:5432/asistente_db
```

---

## Historial de Versiones Anteriores

*Para versiones anteriores, consultar el historial de commits en el repositorio.*