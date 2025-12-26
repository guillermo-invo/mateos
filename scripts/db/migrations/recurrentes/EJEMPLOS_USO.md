# Ejemplos Prácticos de Uso
## Sistema de Tareas Recurrentes - Mateos

---

## 🎯 Casos de Uso Reales

### Caso 1: Configurar Semana Laboral Estándar con TDAH

**Contexto:** Trabajas de lunes a viernes, pero con TDAH necesitas bloques de tiempo realistas.

#### 1. Configurar disponibilidad semanal

```sql
-- Actualizar disponibilidad considerando energía TDAH
UPDATE disponibilidad_semanal SET horas_disponibles = 4.5, momento_optimo = 'maniana', notas = 'Mejor focus antes del almuerzo' WHERE dia_semana = 1;
UPDATE disponibilidad_semanal SET horas_disponibles = 5.0, momento_optimo = 'maniana', notas = 'Día productivo' WHERE dia_semana = 2;
UPDATE disponibilidad_semanal SET horas_disponibles = 4.0, momento_optimo = 'maniana', notas = 'Mitad de semana, menos energía' WHERE dia_semana = 3;
UPDATE disponibilidad_semanal SET horas_disponibles = 5.0, momento_optimo = 'maniana', notas = 'Recuperación de energía' WHERE dia_semana = 4;
UPDATE disponibilidad_semanal SET horas_disponibles = 3.0, momento_optimo = 'maniana', notas = 'Viernes, cierre de semana' WHERE dia_semana = 5;
UPDATE disponibilidad_semanal SET horas_disponibles = 2.0, momento_optimo = 'tarde', notas = 'Proyectos personales' WHERE dia_semana = 6;
UPDATE disponibilidad_semanal SET horas_disponibles = 3.0, momento_optimo = 'tarde', notas = 'Planificación y review' WHERE dia_semana = 7;

-- Ver resultado
SELECT * FROM disponibilidad_real_semanal;
```

#### 2. Crear tareas recurrentes de trabajo

```sql
-- Revisión de emails (lunes a viernes, 9:00 AM)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Inbox Zero - Revisar emails',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'comunicacion',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5], "horaPreferida": "09:00", "fechaInicio": "2025-01-01"}',
  30,
  'baja',
  'anywhere',
  'must',
  'medio'
);

-- Daily standup (lunes a viernes, 10:00 AM)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Daily Standup con equipo',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'comunicacion',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5], "horaPreferida": "10:00", "fechaInicio": "2025-01-01"}',
  15,
  'baja',
  'oficina',
  'must',
  'alto'
);

-- Planificación diaria (todas las mañanas)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Planificar el día (MIT - Most Important Tasks)',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'habito',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5,6,7], "horaPreferida": "08:30", "fechaInicio": "2025-01-01"}',
  15,
  'media',
  'anywhere',
  'must',
  'alto'
);
```

#### 3. Generar instancias

```bash
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --semanas 2
```

#### 4. Ver carga de la semana

```sql
SELECT * FROM disponibilidad_real_semanal;
```

---

### Caso 2: Hábitos de Salud y Autocuidado

**Contexto:** Quieres trackear ejercicio, meditación, y revisión de salud mental.

```sql
-- Ejercicio (3 veces por semana)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Ejercicio / Caminar 30 min',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Salud%' OR nombre LIKE '%Personal%' LIMIT 1),
  'habito',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [1,3,5], "horaPreferida": "07:00", "fechaInicio": "2025-01-01"}',
  30,
  'media',
  'casa',
  'should',
  'alto'
);

-- Meditación diaria
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Meditación / Mindfulness',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Salud%' OR nombre LIKE '%Personal%' LIMIT 1),
  'habito',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5,6,7], "horaPreferida": "07:30", "fechaInicio": "2025-01-01"}',
  10,
  'baja',
  'anywhere',
  'should',
  'alto'
);

-- Journaling semanal (domingos)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Weekly Review - Reflexión semanal',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Personal%' LIMIT 1),
  'habito',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [7], "horaPreferida": "18:00", "fechaInicio": "2025-01-01"}',
  45,
  'media',
  'casa',
  'should',
  'alto'
);
```

---

### Caso 3: Marca Personal y Comunicación

**Contexto:** Necesitas publicar contenido regularmente para marca personal.

```sql
-- Publicar en LinkedIn (2 veces por semana)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Publicar post en LinkedIn',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' OR nombre LIKE '%Marca%' LIMIT 1),
  'comunicacion',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [2,5], "horaPreferida": "11:00", "fechaInicio": "2025-01-01"}',
  30,
  'media',
  'anywhere',
  'must',
  'alto'
);

-- Newsletter semanal
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Escribir y enviar newsletter semanal',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' OR nombre LIKE '%Marca%' LIMIT 1),
  'comunicacion',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [5], "horaPreferida": "15:00", "fechaInicio": "2025-01-01"}',
  90,
  'alta',
  'casa',
  'must',
  'alto'
);

-- Responder mensajes de networking
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Responder mensajes de networking',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'comunicacion',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [1,4], "horaPreferida": "16:00", "fechaInicio": "2025-01-01"}',
  45,
  'media',
  'anywhere',
  'should',
  'medio'
);
```

---

### Caso 4: Mantenimiento y Administración

**Contexto:** Tareas de mantenimiento que no quieres olvidar.

```sql
-- Revisión de finanzas (primer día del mes)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Revisión mensual de finanzas personales',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Personal%' LIMIT 1),
  'administrativo',
  '{"tipo": "mensual", "intervalo": 1, "diaMes": 1, "horaPreferida": "10:00", "fechaInicio": "2025-01-01"}',
  60,
  'media',
  'casa',
  'must',
  'alto'
);

-- Backup de datos (semanal, domingos)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Backup de datos y proyectos',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'mantenimiento',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [7], "horaPreferida": "20:00", "fechaInicio": "2025-01-01"}',
  20,
  'baja',
  'casa',
  'should',
  'medio'
);

-- Limpieza de inbox (viernes)
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, energia_requerida, contexto_necesario, criticidad, impacto)
VALUES (
  'Limpieza profunda de inbox (GTD)',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'mantenimiento',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [5], "horaPreferida": "17:00", "fechaInicio": "2025-01-01"}',
  45,
  'media',
  'anywhere',
  'should',
  'medio'
);
```

---

## 📊 Análisis y Monitoreo

### Ver Sobrecarga de la Semana

```sql
-- ¿Tengo días sobrecargados?
SELECT * FROM vista_sobrecarga_semanal
WHERE estado_carga IN ('SOBRECARGA', 'SATURADO');
```

### Analizar Completitud de Hábitos

```sql
-- ¿Estoy cumpliendo mis hábitos?
SELECT * FROM metricas_tareas_recurrentes
WHERE tipo = 'habito'
ORDER BY tasa_completitud ASC;
```

### Ver Tiempo por Área

```sql
-- ¿A qué le dedico más tiempo?
SELECT * FROM tiempo_por_area_semana
ORDER BY horas_totales DESC;
```

### Detectar Tareas con Estimaciones Incorrectas

```sql
-- Encontrar tareas recurrentes donde la duración real es muy diferente de la estimada
SELECT
  t.nombre,
  t.duracion_estimada_minutos,
  AVG(i.duracion_real_minutos) AS duracion_real_promedio,
  AVG(i.duracion_real_minutos) - t.duracion_estimada_minutos AS diferencia_minutos,
  COUNT(i.id) AS veces_completada
FROM tareas_recurrentes t
JOIN instancias_tareas_recurrentes i ON i.tarea_recurrente_id = t.id
WHERE i.completada = true
  AND i.duracion_real_minutos IS NOT NULL
GROUP BY t.id, t.nombre, t.duracion_estimada_minutos
HAVING ABS(AVG(i.duracion_real_minutos) - t.duracion_estimada_minutos) > 10
ORDER BY diferencia_minutos DESC;
```

---

## 🔄 Gestión de Instancias

### Marcar Instancia Completada con Duración Real

```sql
-- Completar tarea y registrar tiempo real
UPDATE instancias_tareas_recurrentes
SET
  completada = true,
  fecha_completada = NOW(),
  duracion_real_minutos = 45  -- ajustar según duración real
WHERE tarea_recurrente_id = (SELECT id FROM tareas_recurrentes WHERE nombre LIKE '%Inbox%' LIMIT 1)
  AND fecha_programada = CURRENT_DATE;
```

### Saltar Instancia (con razón)

```sql
-- Saltar tarea de ejercicio por enfermedad
UPDATE instancias_tareas_recurrentes
SET
  saltada = true,
  razon_saltada = 'Enfermo - gripe'
WHERE tarea_recurrente_id = (SELECT id FROM tareas_recurrentes WHERE nombre LIKE '%Ejercicio%' LIMIT 1)
  AND fecha_programada = CURRENT_DATE;
```

### Ver Instancias de Hoy

```sql
SELECT
  t.nombre,
  i.hora_inicio,
  t.duracion_estimada_minutos,
  t.energia_requerida,
  t.contexto_necesario,
  t.criticidad,
  i.completada,
  i.saltada
FROM instancias_tareas_recurrentes i
JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id
WHERE i.fecha_programada = CURRENT_DATE
ORDER BY
  CASE t.criticidad
    WHEN 'must' THEN 1
    WHEN 'should' THEN 2
    WHEN 'could' THEN 3
  END,
  i.hora_inicio NULLS LAST;
```

---

## 🎯 Planificación Semanal

### Workflow Completo de Planificación

#### Sábado/Domingo: Planificar la Semana

```sql
-- 1. Ver disponibilidad real
SELECT * FROM disponibilidad_real_semanal;

-- 2. Ver tareas recurrentes programadas
SELECT * FROM instancias_proxima_semana;

-- 3. Ver compromisos próximos (CRÍTICO para marca personal)
SELECT * FROM compromisos_proximos;

-- 4. Ver tareas estratégicas sugeridas
SELECT * FROM tareas_sugeridas_hoy LIMIT 20;

-- 5. Crear bloques de tiempo (chunks) para proyectos
INSERT INTO bloques_tiempo_planificados (fecha, hora_inicio, hora_fin, tipo_bloque, proyecto_estrategico_id, area_vida_id, notas)
VALUES
  -- Lunes: 2 horas para Proyecto Mateos
  ('2025-12-30', '14:00', '16:00', 'proyecto_foco',
   (SELECT id FROM proyectos_estrategicos WHERE nombre LIKE '%Mateos%' LIMIT 1),
   (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
   'Desarrollo de features - tareas recurrentes'),

  -- Martes: 3 horas para Proyecto Mateos
  ('2025-12-31', '10:00', '13:00', 'proyecto_foco',
   (SELECT id FROM proyectos_estrategicos WHERE nombre LIKE '%Mateos%' LIMIT 1),
   (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
   'Desarrollo de features + testing'),

  -- Miércoles: Buffer para imprevistos
  ('2026-01-01', '15:00', '16:00', 'buffer', NULL,
   (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
   'Tiempo buffer para imprevistos');
```

#### Cada Mañana: Revisar el Día

```sql
-- Ver planificación del día
SELECT * FROM planificacion_semana_completa
WHERE fecha = CURRENT_DATE
ORDER BY hora_inicio NULLS LAST;

-- Ver tiempo disponible restante
SELECT * FROM calcular_tiempo_disponible_dia(CURRENT_DATE);
```

---

## 🛠️ Mantenimiento

### Ajustar Duración Estimada Basándose en Datos Reales

```sql
-- Actualizar estimación basándose en promedio real
UPDATE tareas_recurrentes t
SET duracion_estimada_minutos = (
  SELECT ROUND(AVG(i.duracion_real_minutos))
  FROM instancias_tareas_recurrentes i
  WHERE i.tarea_recurrente_id = t.id
    AND i.completada = true
    AND i.duracion_real_minutos IS NOT NULL
)
WHERE id = (SELECT id FROM tareas_recurrentes WHERE nombre LIKE '%Inbox%' LIMIT 1)
  AND EXISTS (
    SELECT 1
    FROM instancias_tareas_recurrentes i
    WHERE i.tarea_recurrente_id = t.id
      AND i.completada = true
      AND i.duracion_real_minutos IS NOT NULL
  );
```

### Pausar Temporalmente una Tarea Recurrente

```sql
-- Pausar durante vacaciones
UPDATE tareas_recurrentes
SET activa = false
WHERE nombre LIKE '%Daily Standup%';

-- Reactivar después
UPDATE tareas_recurrentes
SET activa = true
WHERE nombre LIKE '%Daily Standup%';
```

### Modificar Patrón de Recurrencia

```sql
-- Cambiar de 3 días por semana a 5 días
UPDATE tareas_recurrentes
SET patron_recurrencia = '{"tipo": "semanal", "intervalo": 1, "diasSemana": [1,2,3,4,5], "horaPreferida": "07:00", "fechaInicio": "2025-01-01"}'
WHERE nombre LIKE '%Ejercicio%';

-- Regenerar instancias después del cambio
-- (ejecutar script Python)
```

---

## 📈 Reportes y Métricas

### Reporte Mensual de Productividad

```sql
-- Resumen del último mes
WITH mes_pasado AS (
  SELECT
    COUNT(*) AS total_instancias,
    COUNT(CASE WHEN completada THEN 1 END) AS completadas,
    COUNT(CASE WHEN saltada THEN 1 END) AS saltadas,
    ROUND(
      COUNT(CASE WHEN completada THEN 1 END)::NUMERIC /
      NULLIF(COUNT(*), 0) * 100,
      1
    ) AS tasa_completitud
  FROM instancias_tareas_recurrentes
  WHERE fecha_programada >= CURRENT_DATE - INTERVAL '30 days'
    AND fecha_programada <= CURRENT_DATE
)
SELECT
  total_instancias AS 'Total Programadas',
  completadas AS 'Completadas',
  saltadas AS 'Saltadas',
  (total_instancias - completadas - saltadas) AS 'Pendientes',
  tasa_completitud || '%' AS 'Tasa de Completitud'
FROM mes_pasado;
```

### Identificar Hábitos en Riesgo

```sql
-- Hábitos con tasa de completitud < 70%
SELECT
  nombre,
  tasa_completitud,
  CASE
    WHEN tasa_completitud < 50 THEN '🔴 Crítico'
    WHEN tasa_completitud < 70 THEN '🟡 Alerta'
    ELSE '✅ OK'
  END AS estado
FROM metricas_tareas_recurrentes
WHERE tipo = 'habito'
  AND tasa_completitud < 70
ORDER BY tasa_completitud ASC;
```

---

**¿Más ejemplos?** Consulta el README.md principal o los comentarios en queries_utiles.sql
