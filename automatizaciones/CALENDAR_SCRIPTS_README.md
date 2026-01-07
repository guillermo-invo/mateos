# Scripts de Google Calendar - Documentación

## Descripción General

Esta carpeta contiene los scripts de integración con Google Calendar para el proyecto Mateos. Los scripts permiten sincronización bidireccional entre la base de datos de Mateos y Google Calendar.

## Prerrequisitos

- Service Account configurado en Google Cloud Platform
- Credenciales en: `/home/azureuser/mateos/secrets/google-calendar-service-account.json`
- Librería `googleapis` instalada: `npm install googleapis`
- Calendarios compartidos con el service account (`mateos@lifeos-463317.iam.gserviceaccount.com`)

## Scripts Disponibles

### 1. `google-calendar-test.js`

**Propósito**: Verificar la conexión con Google Calendar y diagnosticar problemas.

**Uso**:
```bash
cd /home/azureuser/mateos/automatizaciones
node src/google-calendar-test.js
```

**Qué hace**:
- Verifica que las credenciales sean válidas
- Prueba conexión con calendario **trunches** (bloques de tiempo por área)
- Prueba conexión con calendario **personal** (citas, reuniones)
- Muestra eventos de los próximos 7 días
- Diagnóstico de errores de permisos

**Salida esperada**:
```
🔄 Verificando credenciales...
✅ Credenciales cargadas: mateos@lifeos-463317.iam.gserviceaccount.com
✅ Autenticación exitosa

📅 Probando calendario TRUNCHES...
✅ Conexión exitosa - X eventos encontrados

📅 Probando calendario PERSONAL...
✅ Conexión exitosa - X eventos encontrados
```

**Errores comunes**:
- `404 Not Found`: El calendario no existe o no está compartido
- `403 Forbidden`: Sin permisos, verificar que compartiste el calendario
- `Archivo de credenciales no encontrado`: Verificar ruta de credenciales

---

### 2. `calendar-sync.js`

**Propósito**: Sincronización bidireccional completa con Google Calendar.

#### Comandos Disponibles

##### a) Reporte de Disponibilidad

Muestra un reporte detallado de disponibilidad cruzando bloques de trunches con eventos del calendario personal.

```bash
# Reporte de próximos 7 días (por defecto)
node src/calendar-sync.js report

# Reporte de 14 días
node src/calendar-sync.js report 14

# Reporte de 30 días
node src/calendar-sync.js report 30
```

**Salida**:
```
📊 REPORTE DE DISPONIBILIDAD

Período: 1/3/2026 - 1/10/2026

📅 lunes 2026-01-05
   Capacidad total: 14.5h
   Tiempo ocupado: 2.0h
   ✅ Disponible: 12.5h (86%)
   Bloques en trunches:
     • Trabajo: 12:00 p. m. - 05:00 p. m. (5.0h)
     • Meditación: 09:15 a. m. - 10:00 a. m. (0.8h)
   Eventos confirmados:
     🔴 Reunión con cliente: 02:00 p. m. - 04:00 p. m. (2.0h)
```

##### b) Sincronizar Bloques Planificados

Sincroniza bloques de `bloques_tiempo_planificados` (BD) → Google Calendar.

```bash
node src/calendar-sync.js sync
```

**Qué hace**:
1. Lee bloques con `sincronizado_calendar = false`
2. Crea eventos en Google Calendar (calendario personal)
3. Guarda `google_calendar_event_id` en la BD
4. Marca `sincronizado_calendar = true`

**Límite**: Sincroniza hasta 50 bloques por ejecución.

##### c) Ver Disponibilidad (JSON)

Obtiene disponibilidad en formato JSON para integración con otras herramientas.

```bash
node src/calendar-sync.js availability
```

**Salida**: JSON estructurado con disponibilidad por día.

---

## Funciones Principales (Clase CalendarSync)

### `getTrunchesBlocks(startDate, endDate)`
Lee bloques de tiempo del calendario **trunches** (capacidad por área).

**Parámetros**:
- `startDate` (Date): Fecha inicial
- `endDate` (Date): Fecha final

**Retorna**: Array de eventos de Google Calendar

---

### `getPersonalEvents(startDate, endDate)`
Lee eventos del calendario **personal** (citas, reuniones confirmadas).

**Parámetros**:
- `startDate` (Date): Fecha inicial
- `endDate` (Date): Fecha final

**Retorna**: Array de eventos de Google Calendar

---

### `calculateAvailability(startDate, endDate)`
Calcula disponibilidad real cruzando bloques de trunches con eventos del calendario personal.

**Lógica**:
```
Disponibilidad Real = Bloques de trunches - Eventos del calendario personal
```

**Retorna**: Objeto con disponibilidad por día:
```javascript
{
  "2026-01-05": {
    date: "2026-01-05",
    trunchesBlocks: [...],       // Bloques de capacidad
    personalEvents: [...],        // Eventos confirmados
    totalCapacityHours: 14.5,    // Capacidad total
    occupiedHours: 2.0,           // Tiempo ocupado
    availableHours: 12.5,         // Tiempo disponible
    utilizationPercent: "13.8"    // % de utilización
  }
}
```

---

### `createPersonalEvent(eventData)`
Crea un evento en el calendario personal desde Mateos.

**Parámetros**:
```javascript
{
  summary: "Título del evento",
  description: "Descripción",
  start: "2026-01-05T14:00:00-03:00",  // ISO 8601
  end: "2026-01-05T16:00:00-03:00",
  colorId: "9"  // Color en Google Calendar
}
```

**Retorna**: Objeto del evento creado con `id`, `htmlLink`, etc.

---

### `syncPlannedBlocksToCalendar()`
Sincroniza bloques planificados de la BD a Google Calendar.

**Query BD**:
```sql
SELECT * FROM bloques_tiempo_planificados
WHERE sincronizado_calendar = false
AND fecha >= CURRENT_DATE
ORDER BY fecha, hora_inicio
LIMIT 50
```

**Proceso**:
1. Por cada bloque:
   - Construye fecha/hora de inicio y fin
   - Obtiene nombre del área/proyecto
   - Crea evento en Google Calendar
   - Actualiza BD con `google_calendar_event_id`
   - Marca `sincronizado_calendar = true`

---

### `getColorForBlockType(tipo)`
Mapea tipo de bloque a color de Google Calendar.

**Mapeo**:
| Tipo | Color ID | Color Visual |
|------|----------|--------------|
| `tarea_estrategica` | 9 | Azul |
| `tarea_recurrente` | 2 | Verde |
| `proyecto_foco` | 11 | Rojo |
| `buffer` | 8 | Gris |
| `reunion` | 5 | Amarillo |
| `compromiso` | 4 | Naranja |
| `otro` | 7 | Celeste |

---

## Configuración en Base de Datos

Los IDs de los calendarios están guardados en `configuracion_personal`:

```sql
SELECT * FROM configuracion_personal WHERE clave LIKE 'google_calendar%';
```

| Clave | Valor |
|-------|-------|
| `google_calendar_trunches_id` | `c_0c44e02...@group.calendar.google.com` |
| `google_calendar_personal_id` | `guillermo@involucrate.uy` |
| `google_calendar_color_trabajo` | `"9"` |
| `google_calendar_color_personal` | `"7"` |
| `google_calendar_color_habitos` | `"2"` |

---

## Flujo Típico de Uso

### 1. Verificar Conexión (Primera vez)
```bash
node src/google-calendar-test.js
```

### 2. Ver Disponibilidad de la Semana
```bash
node src/calendar-sync.js report
```

### 3. Crear Bloques en BD (desde otra herramienta)
```sql
INSERT INTO bloques_tiempo_planificados (
  fecha, hora_inicio, hora_fin, tipo_bloque, area_vida_id, descripcion_libre
) VALUES (
  '2026-01-06', '09:00', '12:00', 'proyecto_foco', 1, 'Trabajo profundo en Mateos'
);
```

### 4. Sincronizar a Google Calendar
```bash
node src/calendar-sync.js sync
```

### 5. Verificar en Google Calendar
Los eventos aparecerán en el calendario personal con el color correspondiente.

---

## Integración con Cron (Sincronización Automática)

Para sincronización automática cada hora:

```bash
# Editar crontab
crontab -e

# Agregar línea (ejecutar cada hora)
0 * * * * cd /home/azureuser/mateos/automatizaciones && node src/calendar-sync.js sync >> /home/azureuser/mateos/logs/calendar-sync.log 2>&1
```

---

## Troubleshooting

### Error: "Module not found: googleapis"
```bash
cd /home/azureuser/mateos/automatizaciones
npm install googleapis
```

### Error: "Credentials not found"
Verificar que existe: `/home/azureuser/mateos/secrets/google-calendar-service-account.json`

### Error: "Calendar not found (404)"
El calendario no está compartido con el service account. Compartir con:
```
mateos@lifeos-463317.iam.gserviceaccount.com
```

### Error: "Forbidden (403)"
Sin permisos de escritura. Verificar que compartiste el calendario con permisos de "Make changes to events".

---

## Estructura de Archivos

```
/home/azureuser/mateos/
├── secrets/
│   └── google-calendar-service-account.json  # Credenciales (600)
├── automatizaciones/
│   ├── src/
│   │   ├── google-calendar-test.js           # Verificación
│   │   └── calendar-sync.js                  # Sincronización
│   └── package.json                          # Con googleapis
└── logs/
    └── calendar-sync.log                     # Logs de cron
```

---

## Próximos Pasos

1. **API Endpoints en Next.js**: Exponer funcionalidades vía HTTP
2. **Cron Job**: Automatizar sincronización periódica
3. **Webhooks**: Recibir notificaciones de cambios en Calendar
4. **Dashboard**: Visualización de disponibilidad en tiempo real

---

**Última actualización**: 2026-01-03
**Responsable**: Sistema Mateos
