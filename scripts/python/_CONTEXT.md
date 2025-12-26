# _CONTEXT.md - Scripts Python

## PROPÓSITO

Scripts Python para automatización de tareas, especialmente generación de instancias de tareas recurrentes. Ejecutados vía CRON diariamente.

---

## STACK TÉCNICO ESPECÍFICO

- **Python:** 3.10+
- **DB Driver:** psycopg2 (PostgreSQL)
- **Logging:** logging (stdlib)
- **Scheduler:** CRON (sistema)

---

## ARCHIVOS CLAVE

### generar_instancias_recurrentes.py (14KB, executable)

**Propósito:** Genera instancias de tareas recurrentes basándose en plantillas y patrones JSONB.

**Ejecutable:** `chmod +x generar_instancias_recurrentes.py`

**Ubicación:** `/home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py`

**Funcionalidad:**
1. Lee plantillas de `tarea_recurrente_plantilla`
2. Calcula próximas ocurrencias basadas en `patron_recurrencia` JSONB
3. Genera instancias en `tarea_recurrente_instancia`
4. Loggea resultados en `logs/generar_instancias.log`

**Patrón de recurrencia (JSONB):**
```json
{
  "tipo": "SEMANAL",
  "frecuencia": 1,
  "dias_semana": [1, 3, 5],  // Lunes, Miércoles, Viernes
  "hora_preferida": "09:00",
  "fecha_inicio": "2025-01-01",
  "fecha_fin": null
}
```

**Tipos soportados:**
- `DIARIA`: Frecuencia en días (ej: cada 2 días)
- `SEMANAL`: Días específicos de la semana (ej: Lunes y Miércoles)
- `MENSUAL`: Día del mes (ej: día 15 de cada mes)
- `ANUAL`: Fecha específica (ej: 01/01 de cada año)

**Flags:**
```bash
# Dry run (NO genera instancias, solo muestra qué haría)
python3 generar_instancias_recurrentes.py --dry-run

# Verbose (logging detallado)
python3 generar_instancias_recurrentes.py --verbose

# Rango de fechas
python3 generar_instancias_recurrentes.py --start-date 2025-01-01 --end-date 2025-01-31
```

---

## ARQUITECTURA Y FLUJO

### Conexión a PostgreSQL

```python
import psycopg2
import os

def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME', 'mateos'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD')
    )
```

**⚠️ Usar connection pooling si se ejecuta frecuentemente:**
```python
from psycopg2 import pool

connection_pool = pool.SimpleConnectionPool(1, 20, ...)
```

### Lógica de Generación

```python
def generar_instancias(plantilla, fecha_inicio, fecha_fin):
    """
    Genera instancias de tarea recurrente.

    Args:
        plantilla: Dict con datos de plantilla
        fecha_inicio: datetime
        fecha_fin: datetime

    Returns:
        List[Dict]: Instancias generadas
    """
    patron = plantilla['patron_recurrencia']
    tipo = patron['tipo']

    if tipo == 'DIARIA':
        return generar_instancias_diarias(plantilla, fecha_inicio, fecha_fin)
    elif tipo == 'SEMANAL':
        return generar_instancias_semanales(plantilla, fecha_inicio, fecha_fin)
    # ...
```

### Manejo de Duplicados

**⚠️ CRÍTICO:** NO generar instancias duplicadas.

```python
def instancia_existe(plantilla_id, fecha_programada):
    """Verifica si ya existe instancia para esa fecha."""
    query = """
        SELECT COUNT(*) FROM tarea_recurrente_instancia
        WHERE plantilla_id = %s
          AND fecha_programada::DATE = %s::DATE
    """
    cur.execute(query, (plantilla_id, fecha_programada))
    count = cur.fetchone()[0]
    return count > 0
```

---

## REGLAS Y RESTRICCIONES

### Conexión DB

#### ✅ SIEMPRE:
- Cerrar conexiones en finally block
- Usar context manager (`with`)
- Manejar excepciones de conexión
- NO dejar conexiones abiertas

```python
import psycopg2

try:
    conn = get_db_connection()
    cur = conn.cursor()

    # Operaciones...

    conn.commit()
except psycopg2.Error as e:
    logger.error(f"Error de DB: {e}")
    conn.rollback()
finally:
    cur.close()
    conn.close()
```

#### ❌ NUNCA:
- Hardcodear credenciales
- Dejar conexiones sin cerrar
- Ignorar errores de DB

### Logging

#### ✅ SIEMPRE:
- Loggear inicio y fin de ejecución
- Loggear cantidad de instancias generadas
- Loggear errores con traceback
- Usar levels apropiados (DEBUG, INFO, ERROR)

```python
import logging

logging.basicConfig(
    filename='logs/generar_instancias.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

logger.info("Iniciando generación de instancias")
logger.info(f"Generadas {count} instancias")
logger.error(f"Error: {e}", exc_info=True)
```

### Dry Run Mode

#### ✅ SIEMPRE implementar dry-run:
```python
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--dry-run', action='store_true',
                    help='Mostrar qué se haría sin ejecutar')
args = parser.parse_args()

if args.dry_run:
    logger.info(f"[DRY RUN] Generaría instancia: {instancia}")
else:
    cur.execute("INSERT INTO ...", instancia)
```

---

## CONFIGURACIÓN

### Variables de Entorno (.env)

```bash
# Database
DB_HOST=postgres  # Docker service name
DB_PORT=5432
DB_NAME=mateos
DB_USER=postgres
DB_PASSWORD=...

# Logging
LOG_LEVEL=INFO
LOG_FILE=/home/azureuser/mateos/logs/generar_instancias.log

# Timezone
TZ=America/Montevideo
```

### CRON Job

**Schedule:** Diariamente a las 00:05

```cron
# Generar instancias recurrentes
5 0 * * * /usr/bin/python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py >> /home/azureuser/mateos/logs/cron.log 2>&1
```

**⚠️ Path absoluto:** CRON NO hereda PATH completo.

---

## NOTAS PARA IA

### ⚠️ Timezone Awareness

```python
import datetime
import pytz

# SIEMPRE usar timezone aware datetimes
tz = pytz.timezone('America/Montevideo')
now = datetime.datetime.now(tz)

# NO usar naive datetimes
# now = datetime.datetime.now()  # ❌ MAL
```

### ⚠️ PostgreSQL JSON Handling

```python
import json

# Leer JSONB desde PostgreSQL
cur.execute("SELECT patron_recurrencia FROM ...")
row = cur.fetchone()
patron = row[0]  # Ya es dict (psycopg2 lo parsea automáticamente)

# Escribir JSONB a PostgreSQL
import json
patron_json = json.dumps(patron)
cur.execute("INSERT INTO ... VALUES (%s)", (patron_json,))
```

### ⚠️ Dates vs Datetimes

```python
# PostgreSQL DATE
fecha_programada = datetime.date(2025, 1, 1)

# PostgreSQL TIMESTAMPTZ
created_at = datetime.datetime.now(tz)

# Conversión
fecha_programada = created_at.date()
```

### ⚠️ Transacciones

```python
try:
    conn = get_db_connection()
    cur = conn.cursor()

    # Múltiples inserts
    for instancia in instancias:
        cur.execute("INSERT INTO ...", instancia)

    # Commit al final (todo o nada)
    conn.commit()
except Exception as e:
    # Rollback si algo falla
    conn.rollback()
    logger.error(f"Error, rollback: {e}")
    raise
```

---

## TESTING

### Manual Testing

```bash
# Dry run (ver qué se generaría)
python3 generar_instancias_recurrentes.py --dry-run --verbose

# Ejecutar con rango de fechas
python3 generar_instancias_recurrentes.py --start-date 2025-01-01 --end-date 2025-01-07
```

### Unit Tests

```python
import unittest
from datetime import date, timedelta

class TestGenerarInstancias(unittest.TestCase):
    def test_generar_instancias_diarias(self):
        patron = {
            'tipo': 'DIARIA',
            'frecuencia': 2,  # Cada 2 días
        }
        start = date(2025, 1, 1)
        end = date(2025, 1, 10)

        instancias = generar_instancias_diarias(patron, start, end)

        # Debe generar 5 instancias (días 1, 3, 5, 7, 9)
        self.assertEqual(len(instancias), 5)

if __name__ == '__main__':
    unittest.main()
```

---

## PRÓXIMOS PASOS (Planificados)

- [ ] Implementar retry logic para errores de DB
- [ ] Agregar notificación (email/Telegram) si falla generación
- [ ] Optimizar queries (batch inserts)
- [ ] Agregar métricas (cuántas instancias/día, tiempo de ejecución)
- [ ] Soporte para excepciones (feriados, vacaciones)

---

**Última actualización:** 2025-12-26
**Versión:** 1.0
