# Sistema de Gestión de Tareas Recurrentes - Mateos

**Fecha:** 2025-12-24
**Versión:** 1.0
**Autor:** Sistema Mateos

## 📋 Índice

1. [Introducción](#introducción)
2. [Instalación](#instalación)
3. [Estructura de Tablas](#estructura-de-tablas)
4. [Guía de Uso](#guía-de-uso)
5. [Scripts y Automatización](#scripts-y-automatización)
6. [Vistas y Queries Útiles](#vistas-y-queries-útiles)
7. [Integración con Google Calendar](#integración-con-google-calendar)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Introducción

Este sistema extiende la base de datos Mateos para soportar:

- **Tareas recurrentes** (hábitos, mantenimiento, comunicación, marca personal)
- **Cálculo de carga de tiempo** (recurrentes vs disponible para proyectos)
- **Planificación multinivel** (Anual → Trimestral → Mensual → Semanal → Diaria)
- **Integración con Google Calendar** mediante "chunks" (bloques por área, no tareas específicas)
- **Tracking de compromisos** con terceros (crítico para marca personal)

### Prioridades de Implementación

✅ **ALTA**: Tareas recurrentes y disponibilidad
⚡ **MEDIA**: Bloques de tiempo y modificaciones a tareas estratégicas
📅 **BAJA**: Configuración personal e integración completa con Google Calendar

---

## 🚀 Instalación

### Paso 1: Aplicar Migraciones por Prioridad

#### ALTA Prioridad (EJECUTAR PRIMERO)

```bash
# 1. Crear tablas de tareas recurrentes y disponibilidad
psql -U postgres -d mateos -f /home/azureuser/mateos/scripts/db/migrations/recurrentes/01_alta_prioridad_tareas_recurrentes.sql

# 2. Crear vistas de disponibilidad
psql -U postgres -d mateos -f /home/azureuser/mateos/scripts/db/migrations/recurrentes/02_alta_prioridad_vistas.sql
```

#### MEDIA Prioridad

```bash
# 3. Modificaciones a tareas estratégicas y bloques de tiempo
psql -U postgres -d mateos -f /home/azureuser/mateos/scripts/db/migrations/recurrentes/03_media_prioridad_modificaciones.sql
```

#### BAJA Prioridad

```bash
# 4. Configuración personal
psql -U postgres -d mateos -f /home/azureuser/mateos/scripts/db/migrations/recurrentes/04_baja_prioridad_configuracion.sql
```

#### Queries Útiles

```bash
# 5. Crear vistas y funciones de análisis
psql -U postgres -d mateos -f /home/azureuser/mateos/scripts/db/queries_utiles.sql
```

### Paso 2: Instalar Dependencias Python

```bash
cd /home/azureuser/mateos
pip install psycopg2-binary
```

### Paso 3: Configurar Variable de Entorno

```bash
export DATABASE_URL="postgresql://usuario:contraseña@localhost:5432/mateos"
```

O agregar al `.bashrc` o `.env`:

```bash
echo 'export DATABASE_URL="postgresql://usuario:contraseña@localhost:5432/mateos"' >> ~/.bashrc
source ~/.bashrc
```

### Paso 4: Verificar Instalación

```sql
-- Verificar que las tablas se crearon
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'tareas_recurrentes',
  'instancias_tareas_recurrentes',
  'disponibilidad_semanal',
  'bloques_tiempo_planificados',
  'configuracion_personal'
)
ORDER BY table_name;

-- Debería retornar las 5 tablas
```

---

## 📊 Estructura de Tablas

### 1. `tareas_recurrentes`

Tareas que se repiten periódicamente.

**Campos principales:**
- `nombre`: Nombre de la tarea
- `patron_recurrencia` (JSONB): Configuración de recurrencia
- `duracion_estimada_minutos`: Tiempo estimado
- `criticidad`: must, should, could
- `energia_requerida`: baja, media, alta
- `contexto_necesario`: casa, oficina, anywhere, movil

**Ejemplo de patrón de recurrencia:**

```json
{
  "tipo": "semanal",
  "intervalo": 1,
  "diasSemana": [1, 3, 5],
  "horaPreferida": "09:00",
  "fechaInicio": "2025-01-01",
  "fechaFin": null
}
```

### 2. `instancias_tareas_recurrentes`

Instancias generadas a partir de tareas recurrentes.

**Campos principales:**
- `tarea_recurrente_id`: FK a tareas_recurrentes
- `fecha_programada`: Día específico
- `completada`: ¿Se completó?
- `saltada`: ¿Se decidió saltar?
- `duracion_real_minutos`: Tiempo real (para aprender)
- `google_calendar_event_id`: ID en Google Calendar

### 3. `disponibilidad_semanal`

Horas disponibles por día de la semana.

**Campos principales:**
- `dia_semana`: 1=lunes, 7=domingo
- `horas_disponibles`: Horas productivas teóricas
- `momento_optimo`: mañana, tarde, noche

### 4. `bloques_tiempo_planificados`

Bloques de tiempo planificados (chunks para Google Calendar).

**Campos principales:**
- `fecha`, `hora_inicio`, `hora_fin`
- `tipo_bloque`: tarea_estrategica, proyecto_foco, buffer, etc.
- Referencias opcionales a tareas, proyectos, áreas
- `google_calendar_event_id`: ID del evento en Google Calendar

### 5. `configuracion_personal`

Configuraciones del sistema.

**Campos principales:**
- `clave`: Nombre de la configuración
- `valor` (JSONB): Valor flexible
- `categoria`: tiempo, planificacion, integraciones, etc.

---

## 📖 Guía de Uso

### Crear una Tarea Recurrente

#### Ejemplo 1: Tarea Diaria (Revisar emails)

```sql
INSERT INTO tareas_recurrentes (
  nombre,
  area_id,
  tipo,
  patron_recurrencia,
  duracion_estimada_minutos,
  energia_requerida,
  contexto_necesario,
  criticidad,
  impacto
) VALUES (
  'Revisar emails',
  (SELECT id FROM areas_vida WHERE nombre = 'Trabajo'),
  'comunicacion',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5], "horaPreferida": "09:00", "fechaInicio": "2025-01-01"}',
  30,
  'baja',
  'anywhere',
  'must',
  'medio'
);
```

#### Ejemplo 2: Tarea Semanal (Reunión de equipo)

```sql
INSERT INTO tareas_recurrentes (
  nombre,
  area_id,
  tipo,
  patron_recurrencia,
  duracion_estimada_minutos,
  energia_requerida,
  contexto_necesario,
  criticidad
) VALUES (
  'Reunión de equipo',
  (SELECT id FROM areas_vida WHERE nombre = 'Trabajo'),
  'comunicacion',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [2], "horaPreferida": "14:00", "fechaInicio": "2025-01-01"}',
  60,
  'media',
  'oficina',
  'must'
);
```

#### Ejemplo 3: Tarea Mensual (Revisión de finanzas)

```sql
INSERT INTO tareas_recurrentes (
  nombre,
  area_id,
  tipo,
  patron_recurrencia,
  duracion_estimada_minutos,
  energia_requerida,
  contexto_necesario,
  criticidad
) VALUES (
  'Revisión de finanzas personales',
  (SELECT id FROM areas_vida WHERE nombre = 'Personal'),
  'administrativo',
  '{"tipo": "mensual", "intervalo": 1, "diaMes": 1, "horaPreferida": "10:00", "fechaInicio": "2025-01-01"}',
  90,
  'media',
  'casa',
  'should'
);
```

### Generar Instancias de Tareas Recurrentes

#### Usando el Script Python

```bash
# Generar para las próximas 2 semanas (default)
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py

# Generar para las próximas 4 semanas
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --semanas 4

# Generar para un rango específico
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py \
  --desde 2025-01-01 \
  --hasta 2025-01-31

# Modo dry-run (ver qué se generaría sin guardar)
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --dry-run
```

### Configurar Disponibilidad Semanal

```sql
-- Actualizar horas disponibles de un día
UPDATE disponibilidad_semanal
SET horas_disponibles = 6.0,
    momento_optimo = 'maniana',
    notas = 'Aumenté capacidad'
WHERE dia_semana = 1; -- Lunes

-- Ver disponibilidad actual
SELECT * FROM disponibilidad_semanal ORDER BY dia_semana;
```

### Marcar Instancia como Completada

```sql
UPDATE instancias_tareas_recurrentes
SET completada = true,
    fecha_completada = NOW(),
    duracion_real_minutos = 25
WHERE id = 123;
```

### Saltar una Instancia

```sql
UPDATE instancias_tareas_recurrentes
SET saltada = true,
    razon_saltada = 'Día feriado'
WHERE tarea_recurrente_id = 5
  AND fecha_programada = '2025-12-25';
```

### Crear Bloque de Tiempo Planificado

```sql
INSERT INTO bloques_tiempo_planificados (
  fecha,
  hora_inicio,
  hora_fin,
  tipo_bloque,
  proyecto_estrategico_id,
  area_vida_id,
  notas
) VALUES (
  '2025-12-24',
  '09:00',
  '11:00',
  'proyecto_foco',
  (SELECT id FROM proyectos_estrategicos WHERE nombre = 'Mateos'),
  (SELECT id FROM areas_vida WHERE nombre = 'Trabajo'),
  'Desarrollo de features de tareas recurrentes'
);
```

---

## 🤖 Scripts y Automatización

### Script Python: `generar_instancias_recurrentes.py`

**Ubicación:** `/home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py`

**Función:** Genera instancias de tareas recurrentes automáticamente.

**Uso:**

```bash
# Ver ayuda
python3 generar_instancias_recurrentes.py --help

# Generar instancias
python3 generar_instancias_recurrentes.py --semanas 2
```

### Configurar Cron Job Diario

Agregar al crontab para ejecutar automáticamente cada día:

```bash
# Editar crontab
crontab -e

# Agregar línea (ejecutar diariamente a las 6:00 AM)
0 6 * * * /usr/bin/python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py >> /home/azureuser/mateos/logs/generar_instancias.log 2>&1
```

---

## 📊 Vistas y Queries Útiles

### Ver Disponibilidad Real de la Semana

```sql
SELECT * FROM disponibilidad_real_semanal;
```

**Resultado:**
```
dia_semana | dia_nombre | horas_teoricas | horas_recurrentes | horas_disponibles_proyectos | estado_carga
-----------+------------+----------------+-------------------+-----------------------------+--------------
1          | Lunes      | 5.0            | 2.5               | 2.5                         | JUSTO
2          | Martes     | 5.0            | 1.5               | 3.5                         | HOLGADO
...
```

### Ver Resumen de Salud de la Semana

```sql
SELECT * FROM resumen_salud_semana_actual;
```

### Ver Tareas Priorizadas para Hoy

```sql
SELECT * FROM tareas_sugeridas_hoy LIMIT 10;
```

### Ver Compromisos Próximos

```sql
SELECT * FROM compromisos_proximos;
```

### Ver Tiempo por Área de Vida

```sql
SELECT * FROM tiempo_por_area_semana;
```

### Ver Planificación Completa de la Semana

```sql
SELECT * FROM planificacion_semana_completa;
```

### Ver Métricas de Tareas Recurrentes

```sql
SELECT * FROM metricas_tareas_recurrentes;
```

### Obtener Disponibilidad en un Rango

```sql
SELECT * FROM obtener_disponibilidad_rango(
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '30 days'
);
```

### Calcular Tiempo Disponible de un Día

```sql
SELECT * FROM calcular_tiempo_disponible_dia('2025-12-24');
```

---

## 🗓️ Integración con Google Calendar

### Conceptos Importantes

**NO bloqueamos tareas específicas**, sino **tiempo por área/proyecto** (chunks).

**Ejemplo:**
- ❌ "Lunes 9-11: Programar endpoint /users/create"
- ✅ "Lunes 9-11: [Mateos - Proyecto]"

Esto reduce fricción y da flexibilidad dentro del bloque.

### Flujo de Trabajo

1. **Sábado/Domingo:** Planificación semanal
   - Script lee Mateos (tareas MUST, compromisos, recurrentes)
   - Usuario revisa en Obsidian
   - Usuario bloquea chunks en Google Calendar por área/proyecto
   - Script sincroniza chunks → `bloques_tiempo_planificados`

2. **Cada mañana:** Orientación diaria
   - Script genera vista de tareas del día
   - Usuario ve qué hacer hoy

3. **Durante semana:** Ajustes
   - Cambios se registran
   - Script actualiza bloques en BD y Google Calendar

### Sincronización Manual (Ejemplo)

```sql
-- Marcar bloque como sincronizado con Google Calendar
UPDATE bloques_tiempo_planificados
SET sincronizado_calendar = true,
    google_calendar_event_id = 'abc123xyz',
    ultimo_sync = NOW()
WHERE id = 456;
```

---

## 🔧 Troubleshooting

### Problema: Las instancias no se generan

**Verificar:**

1. La tarea está activa:
```sql
SELECT * FROM tareas_recurrentes WHERE id = 123;
```

2. El patrón de recurrencia es válido:
```sql
SELECT patron_recurrencia FROM tareas_recurrentes WHERE id = 123;
```

3. Ejecutar script en modo dry-run:
```bash
python3 generar_instancias_recurrentes.py --dry-run
```

### Problema: Error de conexión a la base de datos

**Solución:**

```bash
# Verificar que DATABASE_URL está configurada
echo $DATABASE_URL

# Si no está, configurar
export DATABASE_URL="postgresql://user:pass@localhost:5432/mateos"
```

### Problema: Disponibilidad real negativa (sobrecarga)

**Solución:**

1. Ver qué día está sobrecargado:
```sql
SELECT * FROM vista_sobrecarga_semanal
WHERE estado_carga = 'SOBRECARGA';
```

2. Reducir tareas recurrentes o aumentar disponibilidad:
```sql
-- Opción 1: Desactivar tarea recurrente no crítica
UPDATE tareas_recurrentes SET activa = false WHERE id = 123;

-- Opción 2: Aumentar horas disponibles del día
UPDATE disponibilidad_semanal
SET horas_disponibles = 6.0
WHERE dia_semana = 1;
```

### Problema: Instancias duplicadas

**Esto no debería pasar** (constraint UNIQUE). Si ocurre:

```sql
-- Ver duplicados
SELECT tarea_recurrente_id, fecha_programada, COUNT(*)
FROM instancias_tareas_recurrentes
GROUP BY tarea_recurrente_id, fecha_programada
HAVING COUNT(*) > 1;

-- Eliminar duplicados (mantener el más reciente)
DELETE FROM instancias_tareas_recurrentes
WHERE id NOT IN (
  SELECT MAX(id)
  FROM instancias_tareas_recurrentes
  GROUP BY tarea_recurrente_id, fecha_programada
);
```

---

## 📚 Recursos Adicionales

### Archivos Importantes

```
/home/azureuser/mateos/
├── scripts/
│   ├── db/
│   │   ├── migrations/recurrentes/
│   │   │   ├── 01_alta_prioridad_tareas_recurrentes.sql
│   │   │   ├── 02_alta_prioridad_vistas.sql
│   │   │   ├── 03_media_prioridad_modificaciones.sql
│   │   │   ├── 04_baja_prioridad_configuracion.sql
│   │   │   └── README.md (este archivo)
│   │   └── queries_utiles.sql
│   └── python/
│       └── generar_instancias_recurrentes.py
└── logs/
    └── generar_instancias.log
```

### Comandos Útiles

```bash
# Ver logs de generación de instancias
tail -f /home/azureuser/mateos/logs/generar_instancias.log

# Conectar a PostgreSQL
psql -U postgres -d mateos

# Backup de la base de datos
pg_dump -U postgres mateos > backup_mateos_$(date +%Y%m%d).sql

# Restaurar backup
psql -U postgres mateos < backup_mateos_20251224.sql
```

---

## ✅ Checklist de Implementación

- [ ] Ejecutar script 01 (ALTA prioridad - tablas)
- [ ] Ejecutar script 02 (ALTA prioridad - vistas)
- [ ] Configurar disponibilidad_semanal con tus horas reales
- [ ] Crear algunas tareas recurrentes de prueba
- [ ] Ejecutar generador de instancias
- [ ] Verificar que las instancias se crearon correctamente
- [ ] Ejecutar script 03 (MEDIA prioridad)
- [ ] Ejecutar script 04 (BAJA prioridad)
- [ ] Ejecutar queries_utiles.sql
- [ ] Configurar cron job para generación automática
- [ ] Probar vistas útiles

---

## 🎓 Próximos Pasos

1. **Integración completa con Google Calendar** (scripts Python para sync bidireccional)
2. **Dashboard en Obsidian** para visualización
3. **Scripts de planificación semanal** automatizada
4. **Análisis predictivo** de carga de trabajo
5. **Notificaciones** de compromisos y tareas bloqueadas

---

**¿Preguntas o problemas?** Revisar logs en `/home/azureuser/mateos/logs/` o consultar la base de datos directamente.

**Última actualización:** 2025-12-24
