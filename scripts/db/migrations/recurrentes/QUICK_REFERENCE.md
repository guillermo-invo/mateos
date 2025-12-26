# 🚀 Quick Reference Card
## Sistema de Tareas Recurrentes - Mateos

---

## ⚡ Comandos Más Usados

### Ejecutar Migraciones

```bash
# Script interactivo (RECOMENDADO)
cd /home/azureuser/mateos/scripts/db/migrations/recurrentes
./ejecutar_todas_migraciones.sh

# Manual - ALTA prioridad
psql -U postgres -d mateos -f 01_alta_prioridad_tareas_recurrentes.sql
psql -U postgres -d mateos -f 02_alta_prioridad_vistas.sql
```

### Generar Instancias

```bash
# Próximas 2 semanas (default)
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py

# Próximas 4 semanas
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --semanas 4

# Dry run (ver sin guardar)
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --dry-run
```

---

## 📊 Queries Esenciales

### Ver Disponibilidad de la Semana

```sql
SELECT * FROM disponibilidad_real_semanal;
```

### Ver Planificación Completa

```sql
SELECT * FROM planificacion_semana_completa;
```

### Ver Tareas de Hoy

```sql
SELECT
  t.nombre,
  i.hora_inicio,
  t.duracion_estimada_minutos / 60.0 AS horas,
  t.criticidad,
  i.completada
FROM instancias_tareas_recurrentes i
JOIN tareas_recurrentes t ON i.tarea_recurrente_id = t.id
WHERE i.fecha_programada = CURRENT_DATE
ORDER BY t.criticidad, i.hora_inicio NULLS LAST;
```

### Ver Sobrecarga

```sql
SELECT * FROM vista_sobrecarga_semanal;
```

### Ver Compromisos Próximos

```sql
SELECT * FROM compromisos_proximos;
```

### Ver Tiempo por Área

```sql
SELECT * FROM tiempo_por_area_semana;
```

---

## ✏️ Operaciones Comunes

### Crear Tarea Recurrente Diaria

```sql
INSERT INTO tareas_recurrentes (
  nombre, area_id, tipo, patron_recurrencia,
  duracion_estimada_minutos, energia_requerida,
  contexto_necesario, criticidad
) VALUES (
  'Nombre de la tarea',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Area%' LIMIT 1),
  'habito',  -- o 'mantenimiento', 'comunicacion', 'administrativo', 'otro'
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5], "horaPreferida": "09:00", "fechaInicio": "2025-01-01"}',
  30,
  'media',  -- 'baja', 'media', 'alta'
  'anywhere',  -- 'casa', 'oficina', 'anywhere', 'movil'
  'must'  -- 'must', 'should', 'could'
);
```

### Crear Tarea Recurrente Semanal

```sql
INSERT INTO tareas_recurrentes (
  nombre, area_id, tipo, patron_recurrencia,
  duracion_estimada_minutos, criticidad
) VALUES (
  'Nombre de la tarea',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Area%' LIMIT 1),
  'comunicacion',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [1,3,5], "horaPreferida": "14:00", "fechaInicio": "2025-01-01"}',
  60,
  'should'
);
```

### Marcar Instancia Completada

```sql
UPDATE instancias_tareas_recurrentes
SET completada = true,
    fecha_completada = NOW(),
    duracion_real_minutos = 45
WHERE tarea_recurrente_id = 123 AND fecha_programada = CURRENT_DATE;
```

### Saltar Instancia

```sql
UPDATE instancias_tareas_recurrentes
SET saltada = true,
    razon_saltada = 'Razón aquí'
WHERE tarea_recurrente_id = 123 AND fecha_programada = CURRENT_DATE;
```

### Actualizar Disponibilidad de un Día

```sql
UPDATE disponibilidad_semanal
SET horas_disponibles = 6.0,
    momento_optimo = 'maniana',
    notas = 'Más productivo'
WHERE dia_semana = 1;  -- 1=lunes, 7=domingo
```

---

## 🔧 Troubleshooting Rápido

### No se generan instancias

```sql
-- Verificar que la tarea está activa
SELECT * FROM tareas_recurrentes WHERE id = 123;

-- Si está inactiva, activar
UPDATE tareas_recurrentes SET activa = true WHERE id = 123;
```

### Sobrecarga detectada

```sql
-- Ver qué días están sobrecargados
SELECT * FROM vista_sobrecarga_semanal WHERE estado_carga = 'SOBRECARGA';

-- Opción 1: Desactivar tarea no crítica
UPDATE tareas_recurrentes SET activa = false WHERE id = 123;

-- Opción 2: Aumentar horas disponibles
UPDATE disponibilidad_semanal SET horas_disponibles = 6.0 WHERE dia_semana = 1;
```

### Ver logs

```bash
tail -f /home/azureuser/mateos/logs/generar_instancias.log
```

---

## 📖 Patrones de Recurrencia

### Diaria (Lunes a Viernes)

```json
{
  "tipo": "diaria",
  "intervalo": 1,
  "diasSemana": [1,2,3,4,5],
  "horaPreferida": "09:00",
  "fechaInicio": "2025-01-01"
}
```

### Semanal (Lunes, Miércoles, Viernes)

```json
{
  "tipo": "semanal",
  "intervalo": 1,
  "diasSemana": [1,3,5],
  "horaPreferida": "14:00",
  "fechaInicio": "2025-01-01"
}
```

### Mensual (Día 1 de cada mes)

```json
{
  "tipo": "mensual",
  "intervalo": 1,
  "diaMes": 1,
  "horaPreferida": "10:00",
  "fechaInicio": "2025-01-01"
}
```

### Cada 2 Semanas (Quincenal)

```json
{
  "tipo": "semanal",
  "intervalo": 2,
  "diasSemana": [2],
  "horaPreferida": "15:00",
  "fechaInicio": "2025-01-01"
}
```

---

## 🎯 Configuración Inicial Recomendada

### 1. Ajustar Disponibilidad

```sql
-- Lunes a viernes
UPDATE disponibilidad_semanal SET horas_disponibles = 5.0, momento_optimo = 'maniana' WHERE dia_semana BETWEEN 1 AND 5;

-- Fin de semana
UPDATE disponibilidad_semanal SET horas_disponibles = 3.0, momento_optimo = 'tarde' WHERE dia_semana IN (6, 7);
```

### 2. Crear Tareas Básicas

```sql
-- Planificación diaria
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, criticidad)
VALUES (
  'Planificar el día (MIT)',
  (SELECT id FROM areas_vida LIMIT 1),
  'habito',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5,6,7], "horaPreferida": "08:30", "fechaInicio": "2025-01-01"}',
  15,
  'must'
);

-- Review semanal
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, criticidad)
VALUES (
  'Weekly Review',
  (SELECT id FROM areas_vida LIMIT 1),
  'habito',
  '{"tipo": "semanal", "intervalo": 1, "diasSemana": [7], "horaPreferida": "18:00", "fechaInicio": "2025-01-01"}',
  60,
  'should'
);
```

### 3. Generar Instancias

```bash
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --semanas 2
```

### 4. Verificar

```sql
SELECT * FROM disponibilidad_real_semanal;
SELECT * FROM instancias_proxima_semana;
```

---

## 📁 Archivos de Referencia

| Archivo | Contenido |
|---------|-----------|
| `README.md` | Guía completa de instalación |
| `EJEMPLOS_USO.md` | Casos de uso con SQL completo |
| `RESUMEN_IMPLEMENTACION.md` | Resumen técnico de lo implementado |
| `QUICK_REFERENCE.md` | Esta referencia rápida |
| `queries_utiles.sql` | 17 vistas y funciones útiles |

---

## 🔗 Enlaces Útiles

```bash
# Documentación principal
cat /home/azureuser/mateos/scripts/db/migrations/recurrentes/README.md

# Ejemplos prácticos
cat /home/azureuser/mateos/scripts/db/migrations/recurrentes/EJEMPLOS_USO.md

# Conectar a base de datos
psql -U postgres -d mateos

# Ver logs
tail -f /home/azureuser/mateos/logs/generar_instancias.log
```

---

## 💡 Tips ADHD-Friendly

1. **Configurar horas realistas** en `disponibilidad_semanal` (no idealistas)
2. **Usar criticidad "must"** solo para lo verdaderamente crítico
3. **Crear buffer time** (20% del tiempo disponible)
4. **Review semanal** es clave para ajustar estimaciones
5. **No más de 3 proyectos en DOING** simultáneamente

---

**Última actualización:** 2025-12-24
