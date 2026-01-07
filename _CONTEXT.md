# Mateos - Sistema Personal de Gestión de Tiempo y Tareas

> **Propósito:** Sistema integral de gestión de tiempo, tareas y proyectos optimizado para productividad con TDAH, con captura por voz, planificación estratégica multinivel, y tracking de compromisos para marca personal.

**Última actualización:** 2025-12-24
**Estado:** En producción activa
**Branch principal:** `master`
**Branch actual:** `feature/ui-improvements`

---

## 🎯 Problema que Resuelve

Gestión de tiempo y tareas para personas con TDAH que necesitan:
- Captura rápida de tareas por voz (bajo friction)
- Planificación estratégica conectada con motivaciones personales
- Visibilidad de carga de trabajo real vs disponible
- Tracking riguroso de compromisos con terceros (crítico para marca personal)
- Sistema de tareas recurrentes que respete patrones de energía
- Integración con segundo cerebro (Obsidian) y calendario (Google Calendar)

**No es:** Un simple todo-list. Es un sistema de gestión de tiempo multinivel con fundamento metodológico.

---

## 🏗️ Stack Técnico

### Backend y Base de Datos
- **Base de datos:** PostgreSQL 16+ (NO MySQL, NO SQLite, NO otros motores)
- **ORM:** Prisma 5.x
- **Automatizaciones:** Node.js + n8n (workflows)
- **Scripts:** Python 3.10+ (generación de instancias, análisis)
- **Servidor:** Ubuntu 22.04 LTS en Azure VM (Linux 5.15.0-161-generic)

### Frontend
- **Framework:** Next.js 14+ (App Router)
- **UI:** React 18+ con TypeScript
- **Styling:** Tailwind CSS
- **Componentes:** shadcn/ui

### Infraestructura
- **Contenedores:** Docker + Docker Compose
- **Reverse Proxy:** Nginx (configurado)
- **SSL:** Certbot (Let's Encrypt)
- **Storage externo:** Cloudflare R2 (archivos de audio)

### Integraciones Externas
- **Telegram Bot:** Entrada principal de notas de voz
- **Google Calendar API:** Sincronización de bloques de tiempo (chunks)
- **Obsidian:** Segundo cerebro, planificación semanal (Obsidian Sync habilitado, KasmVNC para acceso web)
- **n8n:** Orquestación de workflows (transcripción, procesamiento IA)

---

## 📁 Estructura del Proyecto

```
/home/azureuser/mateos/
├── next-app/                    # Aplicación Next.js (frontend + API routes)
│   ├── src/
│   │   ├── app/                 # App Router (Next.js 14+)
│   │   ├── components/          # Componentes React
│   │   ├── lib/                 # Utilidades
│   │   └── styles/
│   ├── prisma/
│   │   └── schema.prisma        # Schema Prisma (sincronizado con automatizaciones)
│   └── package.json
│
├── automatizaciones/            # Backend de workflows con n8n
│   ├── prisma/
│   │   ├── schema.prisma        # Schema principal (source of truth)
│   │   └── migrations/          # Migraciones Prisma
│   ├── workflows/               # Definiciones de n8n
│   └── package.json
│
├── scripts/
│   ├── db/
│   │   ├── migrations/recurrentes/  # Migraciones sistema recurrentes (2025-12-24)
│   │   ├── queries_utiles.sql       # Vistas y funciones de análisis
│   │   └── seed-data.sql            # Datos iniciales
│   ├── python/
│   │   └── generar_instancias_recurrentes.py  # Generador automático
│   └── health-check.sh          # Monitoreo del sistema
│
├── obsidian/                    # Configuración de Obsidian (KasmVNC)
│   └── (configuración interna del contenedor)
│
├── backups/                     # Backups automáticos de PostgreSQL
│   └── asistente_db_backup_*.sql.gz
│
├── logs/                        # Logs de operaciones
│   └── generar_instancias.log
│
└── docker-compose.yml           # Orquestación de servicios
```

**Convención importante:** El schema de Prisma en `automatizaciones/prisma/schema.prisma` es el source of truth. El de `next-app` se sincroniza desde ahí.

---

## 🗄️ Base de Datos PostgreSQL

### Ubicación y Conexión

**Contenedor Docker:** `transcripcion-postgres`
- **Imagen:** `postgres:15.5-alpine`
- **Base de datos:** `asistente_db`
- **Usuario:** `asistente`
- **Password:** `n8npass`
- **Puerto host:** `1432` → `5432` (contenedor)
- **Volumen:** `mateos_postgres-data`
- **Ubicación física:** `/var/lib/docker/volumes/mateos_postgres-data/_data`

**Conexión desde host:**
```bash
docker exec -i transcripcion-postgres psql -U asistente -d asistente_db
```

### Diagrama de Estructura de Base de Datos

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ASISTENTE_DB                                  │
│                    (PostgreSQL 15.5)                                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ 1. CAPTURA DE NOTAS DE VOZ                                          │
├─────────────────────────────────────────────────────────────────────┤
│  transcripciones (legacy)                                           │
│  notas_audio (con IA)                                               │
│    └─→ tipos: tarea|registro|idea|compromiso|sin_clasificar        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ 2. JERARQUÍA DE PROYECTOS Y TAREAS                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  proyectos_estrategicos (id, nombre, estado, scores)               │
│         │                                                            │
│         ├─→ tareas_estrategicas (proyecto_id, estado_kanban)       │
│         │        │                                                   │
│         │        └─→ subtareas_estrategicas (tarea_estrategica_id) │
│         │                  │                                         │
│         │                  └─→ proyecto_nombre (denormalizado)      │
│         │                                                            │
│         └─→ ideas_capturadas (proyecto_estrategico_id)             │
│                                                                      │
│  tareas (legacy V1, sin proyecto)                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ 3. TABLAS TAXATIVAS (Referencia)                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  areas_vida ──┐                                                     │
│  motivos_personales ──┐                                             │
│  destrezas ──┐        │                                             │
│  dificultades ──┐     │                                             │
│  misiones_vida ──┐    │                                             │
│                  │    │                                             │
│                  └────┴─→ proyectos_estrategicos                    │
│                             (arrays de IDs)                         │
│                                                                      │
│  destrezas ──→ subtareas_estrategicas                               │
│                  (destreza_principal_id)                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ 4. COMPROMISOS (Crítico para Marca Personal)                        │
├─────────────────────────────────────────────────────────────────────┤
│  compromisos                                                         │
│    └─→ yo_me_comprometi (boolean) - CRÍTICO                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ 5. OTROS                                                             │
├─────────────────────────────────────────────────────────────────────┤
│  registros (actividades pasadas)                                    │
│  logs_generacion_ia (auditoría de IA)                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ RELACIONES CLAVE                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  proyectos_estrategicos (1) ──→ (N) tareas_estrategicas            │
│  tareas_estrategicas (1) ──→ (N) subtareas_estrategicas            │
│  destrezas (1) ──→ (N) subtareas_estrategicas                      │
│  proyectos_estrategicos (1) ──→ (N) ideas_capturadas               │
│  proyectos_estrategicos (1) ──→ (N) logs_generacion_ia             │
│                                                                      │
│  DENORMALIZACIÓN:                                                    │
│  subtareas_estrategicas.proyecto_nombre ← proyectos.nombre          │
│    (Auto-actualizado via triggers)                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Tablas Principales

#### 1. Captura de Notas de Voz
- **`transcripciones`**: Tabla original (legacy, compatibilidad con mateos-next-app)
- **`notas_audio`**: Copia enriquecida con procesamiento IA
  - Almacena transcripción completa, resumen ejecutivo, tipo detectado
  - Estados: `procesado` (boolean)
  - Tipos: `tarea`, `registro`, `idea`, `compromiso`, `sin_clasificar`

#### 2. Sistema de Tareas (Multi-nivel)
- **`tareas`**: Tareas simples extraídas de notas de voz (legacy V1)
- **`tareas_estrategicas`**: Tareas dentro de proyectos estratégicos (V2)
  - Campos clave: `estado_kanban`, `eisenhower`, `impacto`, `urgencia`, `moscow`
  - **NUEVOS (2025-12-24):** `energia_requerida`, `contexto_necesario`, `duracion_real_horas`, `bloqueada_por`, `fecha_estimada_desbloqueo`
- **`subtareas_estrategicas`**: Subtareas con vinculación a destrezas
- **`tareas_recurrentes`** (NUEVO 2025-12-24): Tareas que se repiten periódicamente
  - Patrón de recurrencia en JSONB (tipo: diaria, semanal, mensual, personalizada)
  - Clasificación: `habito`, `mantenimiento`, `comunicacion`, `administrativo`, `otro`
  - Criticidad: `must`, `should`, `could`
- **`instancias_tareas_recurrentes`** (NUEVO 2025-12-24): Instancias generadas de tareas recurrentes
  - Estados: `completada`, `saltada`
  - Tracking de `duracion_real_minutos` vs estimada
  - Campo `google_calendar_event_id` para sincronización

#### 3. Proyectos Estratégicos
- **`proyectos_estrategicos`**: Proyectos con planificación estratégica
  - Vinculación a áreas, motivos, destrezas, dificultades, misiones (arrays de IDs)
  - Scores: `score_motivacional`, `score_alineacion`, `prioridad_global`
  - Estados: `idea`, `planificacion`, `en_curso`, `pausado`, `completado`, `cancelado`, `archivado`
  - Campo `objetivos_smart` (JSONB)

#### 4. Compromisos (Crítico para Marca Personal)
- **`compromisos`**: Compromisos con terceros
  - `yo_me_comprometi` (boolean): true si YO prometí, false si otros prometieron
  - `persona_nombre`, `fecha_limite`, `cumplido`
  - **Uso crítico:** Tracking de promesas para marca personal

#### 5. Tablas Taxativas (Referencia)
- **`areas_vida`**: Áreas de vida (Trabajo, Salud, Personal, etc.)
- **`motivos_personales`**: Motivaciones personales con `peso_personal`
- **`destrezas`**: Habilidades con `nivel_actual`, `costo_energetico`, `mejor_momento_dia`
- **`dificultades`**: Limitaciones con `nivel_impacto`, `estrategia_mitigacion`
- **`misiones_vida`**: Misiones de largo plazo con `vision`

#### 6. Planificación de Tiempo (NUEVO 2025-12-24)
- **`disponibilidad_semanal`**: Horas productivas disponibles por día (1=lunes, 7=domingo)
  - `horas_disponibles`, `momento_optimo` (maniana, tarde, noche)
- **`bloques_tiempo_planificados`**: Chunks de tiempo para Google Calendar
  - **Importante:** Se planifican bloques por área/proyecto, NO tareas específicas
  - Tipos: `tarea_estrategica`, `tarea_recurrente`, `proyecto_foco`, `buffer`, `reunion`, `compromiso`, `otro`
  - Referencias opcionales a tareas, proyectos, áreas
  - Campo `sincronizado_calendar` (boolean)

#### 7. Configuración del Sistema (NUEVO 2025-12-24)
- **`configuracion_personal`**: Configuraciones JSONB flexible
  - Categorías: `tiempo`, `planificacion`, `integraciones`, `notificaciones`, `sistema`
  - Valores por defecto optimizados para TDAH

#### 8. Otros
- **`registros`**: Actividades ya realizadas (tracking de pasado)
- **`ideas_capturadas`**: Ideas sin implementar
- **`logs_generacion_ia`**: Logs de uso de IA (prompts, respuestas, tokens)

### Enums Importantes

```typescript
// Estados Kanban (6 estados, NO 5, NO 7)
enum TipoEstadoKanban {
  freezer   // Congelado, no trabajar ahora
  backlog   // Pendiente, sin priorizar
  waiting   // Esperando algo/alguien (bloqueada)
  todo      // Listo para hacer
  doing     // En progreso (MAX 3 proyectos aquí si TDAH)
  done      // Completado
}

// Matriz de Eisenhower (4 cuadrantes)
enum TipoEisenhower {
  cuadrante_1  // Urgente e Importante
  cuadrante_2  // No Urgente pero Importante (foco óptimo)
  cuadrante_3  // Urgente pero No Importante
  cuadrante_4  // Ni Urgente ni Importante
}

// MoSCoW
enum TipoMoscow {
  must    // Debe tener
  should  // Debería tener
  could   // Podría tener
  wont    // No tendrá (en este scope)
}

// Energía requerida
enum TipoEnergia {
  relax   // Descanso
  baja    // Tarea simple
  media   // Requiere concentración
  alta    // Requiere foco profundo
  pico    // Máximo esfuerzo
}
```

### Vistas Críticas (NUEVO 2025-12-24)

- **`disponibilidad_real_semanal`**: Horas teóricas - horas recurrentes = horas disponibles para proyectos
  - Estados: `SOBRECARGA`, `SATURADO`, `JUSTO`, `HOLGADO`
- **`vista_sobrecarga_semanal`**: Detección de sobrecarga con indicadores visuales
- **`tareas_sugeridas_hoy`**: Tareas priorizadas por score compuesto (Eisenhower + Impacto + Motivación)
- **`compromisos_proximos`**: Compromisos ordenados por urgencia
- **`planificacion_semana_completa`**: Vista consolidada (recurrentes + bloques planificados)
- **`metricas_tareas_recurrentes`**: Tasa de completitud últimos 30 días

### Funciones Importantes

- **`calcular_tiempo_disponible_dia(fecha)`**: Tiempo disponible considerando recurrentes y bloques
- **`obtener_disponibilidad_rango(fecha_inicio, fecha_fin)`**: Disponibilidad en rango de fechas
- **`get_config(clave)`**, **`set_config(clave, valor)`**: Gestión de configuración

---

## 🔄 Flujos de Trabajo Principales

### 1. Captura de Nota de Voz → Tarea

```
Usuario graba nota de voz en Telegram
  ↓
n8n recibe webhook de Telegram
  ↓
Audio se sube a Cloudflare R2
  ↓
IA transcribe (Whisper u otro)
  ↓
Se guarda en `transcripciones` y `notas_audio`
  ↓
IA procesa transcripción (detecta tipo)
  ↓
Si es "tarea": se crea en `tareas`
Si es "compromiso": se crea en `compromisos`
Si es "registro": se crea en `registros`
Si es "idea": se crea en `ideas_capturadas`
  ↓
Usuario ve en aplicación Next.js
```

### 2. Planificación Semanal (Sábado/Domingo)

```
Script lee Mateos:
  - Tareas estratégicas en TODO/DOING
  - Tareas recurrentes (instancias próxima semana)
  - Compromisos con fecha_limite próxima
  ↓
Script genera archivo Obsidian: YYYY-WXX-contexto.md
  ↓
Usuario revisa y ajusta en Obsidian
  ↓
Usuario bloquea CHUNKS en Google Calendar
  (Por área/proyecto, NO tareas específicas)
  ↓
Script sincroniza chunks → bloques_tiempo_planificados
  ↓
Usuario ve disponibilidad real en vistas SQL
```

### 3. Generación de Instancias Recurrentes (Automático)

```
Cron job diario ejecuta:
  generar_instancias_recurrentes.py
  ↓
Lee tareas_recurrentes WHERE activa = true
  ↓
Por cada tarea:
  - Calcula fechas según patron_recurrencia
  - Crea instancias en instancias_tareas_recurrentes
  - Evita duplicados (constraint UNIQUE)
  ↓
Log de resultados en /logs/generar_instancias.log
```

### 4. Priorización Diaria

```
Query a tareas_sugeridas_hoy
  ↓
Score compuesto =
  Peso Eisenhower +
  Peso Impacto +
  (Score Motivacional × Peso Motivacional)
  ↓
Ordenado por score DESC
  ↓
Filtrado por:
  - estado_kanban IN ('todo', 'doing')
  - fecha_inicio <= HOY
  - bloqueada_por IS NULL
  - proyecto.estado = 'en_curso'
  ↓
Usuario ve top 10 tareas sugeridas
```

---

## 🎨 Convenciones y Estándares

### Naming Conventions

**Base de datos:**
- Tablas: `snake_case` plural (ej: `tareas_estrategicas`)
- Columnas: `snake_case` (ej: `fecha_estimada_desbloqueo`)
- Enums: PascalCase con prefijo `Tipo` (ej: `TipoEstadoKanban`)
- Valores enum: `snake_case` (ej: `en_curso`, `cuadrante_1`)

**Prisma:**
- Modelos: PascalCase singular (ej: `TareaEstrategica`)
- Campos: camelCase (ej: `fechaEstimadaDesbloqueo`)
- Map a DB: `@@map("tareas_estrategicas")`, `@map("fecha_estimada_desbloqueo")`

**Frontend (TypeScript/React):**
- Componentes: PascalCase (ej: `KanbanTaskView.tsx`)
- Funciones/variables: camelCase
- Constantes: SCREAMING_SNAKE_CASE
- Tipos/Interfaces: PascalCase

### Campos de Auditoría Estándar

Todas las tablas tienen:
- `created_at TIMESTAMP DEFAULT NOW()`
- `updated_at TIMESTAMP DEFAULT NOW()` (con trigger auto-update)

### Estructura de patron_recurrencia (JSONB)

```json
{
  "tipo": "diaria|semanal|mensual|personalizada",
  "intervalo": 1,
  "diasSemana": [1,3,5],        // Solo si tipo=semanal (1=lun, 7=dom)
  "diaMes": 15,                 // Solo si tipo=mensual
  "horaPreferida": "09:00",     // Opcional
  "fechaInicio": "2025-01-01",  // Obligatorio
  "fechaFin": "2025-12-31"      // Opcional (null = indefinido)
}
```

### Patrón de Chunks en Google Calendar

**IMPORTANTE:** NO se bloquean tareas específicas en Google Calendar.

**Correcto:**
- "Lunes 9-11: [Mateos - Proyecto]"
- "Martes 14-16: [Trabajo - Área]"
- "Miércoles 10-12: Buffer"

**Incorrecto:**
- "Lunes 9-11: Programar endpoint /users/create"

**Razón:** Reduce fricción y da flexibilidad dentro del bloque (TDAH-friendly).

---

## 🧠 Metodologías Aplicadas

### Matriz de Eisenhower
- **Cuadrante 1** (Urgente + Importante): Hacer primero, peso 100
- **Cuadrante 2** (No Urgente + Importante): **FOCO ÓPTIMO**, peso 70
- **Cuadrante 3** (Urgente + No Importante): Delegar/Minimizar, peso 40
- **Cuadrante 4** (Ni Urgente ni Importante): Eliminar, peso 10

### MoSCoW (Priorización de Features)
- **Must**: Crítico para el proyecto
- **Should**: Importante pero no bloqueante
- **Could**: Deseable si hay tiempo
- **Won't**: Explícitamente fuera de scope

### Planificación Multinivel
1. **Anual**: Misiones de vida, proyectos grandes
2. **Trimestral**: Objetivos SMART de proyectos
3. **Mensual**: Hitos y revisión de finanzas (día 1)
4. **Semanal**: Planificación en Obsidian (sábado/domingo)
5. **Diaria**: MIT (Most Important Tasks) cada mañana

### Gestión para TDAH

**Principios:**
- **Horas realistas**: Configurar `disponibilidad_semanal` con horas REALES, no idealistas
- **Buffer time**: 20% del tiempo disponible como buffer
- **Max 3 proyectos en DOING**: Configuración `max_proyectos_paralelos`
- **Bajo friction**: Captura por voz, planificación semanal única
- **Visibilidad constante**: Vistas de sobrecarga, métricas de completitud
- **Chunks flexibles**: Bloques por área, no tareas específicas

**Configuraciones TDAH-friendly:**
```sql
horas_disponibles_promedio_dia: 5  -- NO 8, NO 10
max_proyectos_paralelos: 3         -- NO más
tiempo_buffer_porcentaje: 20       -- Siempre dejar margen
duracion_sesion_foco_minutos: 90   -- Pomodoro extendido
```

---

## 🔌 Integraciones Externas

### Telegram Bot
- **Propósito:** Entrada principal de notas de voz
- **Flow:** Usuario → Bot → Webhook n8n → Procesamiento
- **Campos:** `telegram_file_id`, `telegram_user_id`, `telegram_message_id`

### Google Calendar API
- **Propósito:** Sincronización bidireccional de eventos y análisis de disponibilidad real
- **Método:** Sincronización bidireccional (Mateos ↔ GCal)
- **Autenticación:** Service Account (`mateos@lifeos-463317.iam.gserviceaccount.com`)
- **Credenciales:** `/home/azureuser/mateos/secrets/google-calendar-service-account.json` (600 permisos)
- **Calendarios integrados:**
  - **trunches** (`c_0c44e02...@group.calendar.google.com`): Bloques de tiempo por área de vida (capacidad disponible)
  - **guillermo@involucrate.uy**: Citas, reuniones, tareas reales (eventos confirmados)
- **Scripts:**
  - `/automatizaciones/src/google-calendar-test.js`: Verificación de conexión
  - `/automatizaciones/src/calendar-sync.js`: Sincronización bidireccional y análisis
- **Funcionalidades:**
  - Leer bloques de trunches (capacidad por área)
  - Leer eventos del calendario personal (compromisos)
  - Calcular disponibilidad real (capacidad - compromisos)
  - Crear eventos desde Mateos en Calendar
  - Generar reportes de disponibilidad
- **Campo sync:** `google_calendar_event_id` en `bloques_tiempo_planificados`
- **Colores:** Configurables en `configuracion_personal` (trabajo=9, personal=7, habitos=2)
- **Comandos útiles:**
  - `node src/calendar-sync.js report` - Reporte de disponibilidad (7 días)
  - `node src/calendar-sync.js sync` - Sincronizar bloques planificados
  - `node src/calendar-sync.js availability` - JSON de disponibilidad

### Obsidian
- **Propósito:** Segundo cerebro, planificación semanal, contexto vivo
- **Implementación:** Contenedor Docker con KasmVNC (LinuxServer Obsidian)
- **Storage:** Bind mount en `/home/azureuser/obsidian` (migrado desde volume `obsidianGfork` el 2025-12-26)
- **Obsidian Sync:** Habilitado, sincronización 24/7 bidireccional (PC ↔ Cloud ↔ Server)
- **Acceso web:** `mateos.involucrate.lat/obsidian` (DESHABILITADO por seguridad, solo habilitar para mantenimiento/configuración)
- **Puertos:** 1420:3000 (web), 1421:3001 (https - no usado)
- **Redes:** `app-network`, `involucra-network` (para acceso desde nginx)
- **Permisos:** PUID=1001, PGID=1001 (matching azureuser UID/GID)
- **Archivos clave en vault:**
  - `Periodicas/Weekly/YYYY-WXX-contexto.md` (planificación semanal)
  - `Today.md` (generado cada mañana)
- **Flow:** Mateos genera markdown → Usuario edita en PC/móvil via Obsidian Sync → Mateos lee cambios desde `/home/azureuser/obsidian`
- **Acceso a archivos:** Scripts y aplicaciones pueden acceder directamente a `/home/azureuser/obsidian/ObsidianGfork/` sin necesidad de sudo
- **IMPORTANTE:** El vault sincroniza automáticamente. NO requiere acceso web para funcionamiento normal del Sync.

### Cloudflare R2
- **Propósito:** Storage de archivos de audio
- **Campos:** `r2_url`, `r2_key` en `transcripciones`

---

## ⚙️ Variables de Entorno Críticas

```bash
DATABASE_URL="postgresql://postgres:password@localhost:5432/mateos"
TELEGRAM_BOT_TOKEN="..."
GOOGLE_CALENDAR_API_KEY="..."
R2_ACCESS_KEY_ID="..."
R2_SECRET_ACCESS_KEY="..."
```

**Ubicación:**
- Next.js: `/home/azureuser/mateos/next-app/.env`
- Automatizaciones: `/home/azureuser/mateos/automatizaciones/.env`
- Scripts Python: Variable de entorno del sistema o `.env` en scripts/

---

## 🚦 Estado Actual (2026-01-03)

### ✅ Implementado
- [x] Captura de notas de voz vía Telegram
- [x] Transcripción y procesamiento con IA
- [x] Sistema de proyectos estratégicos (V2)
- [x] Tareas estratégicas con Kanban
- [x] Subtareas con destrezas
- [x] Compromisos con terceros
- [x] **Sistema de tareas recurrentes completo** (2025-12-24)
- [x] **Cálculo de disponibilidad real** (2025-12-24)
- [x] **Vistas de análisis y métricas** (2025-12-24)
- [x] **Detección de sobrecarga** (2025-12-24)
- [x] Priorización por score compuesto
- [x] UI mejorada con dark mode (feature/ui-improvements)
- [x] **Integración completa bidireccional con Google Calendar API** (2026-01-03)
- [x] **Scripts de sincronización automática con Calendar** (2026-01-03)
- [x] **Análisis de disponibilidad real cruzando múltiples calendarios** (2026-01-03)

### 🚧 En Desarrollo
- [ ] Dashboard visual de métricas en Next.js
- [ ] Generación automática de archivos Obsidian
- [ ] Notificaciones automáticas de compromisos
- [ ] API endpoints para sincronización automática con Calendar

### 📋 Roadmap Próximo
- [ ] Análisis predictivo de carga de trabajo
- [ ] Sugerencias de optimización automática
- [ ] Mobile app (React Native)
- [ ] Integración con Notion (opcional)

---

## 🎯 Casos de Uso Críticos

### 1. Crear Tarea Recurrente Diaria
```sql
INSERT INTO tareas_recurrentes (nombre, area_id, tipo, patron_recurrencia, duracion_estimada_minutos, criticidad)
VALUES (
  'Inbox Zero - Revisar emails',
  (SELECT id FROM areas_vida WHERE nombre LIKE '%Trabajo%' LIMIT 1),
  'comunicacion',
  '{"tipo": "diaria", "intervalo": 1, "diasSemana": [1,2,3,4,5], "horaPreferida": "09:00", "fechaInicio": "2025-01-01"}',
  30,
  'must'
);
```

### 2. Ver Disponibilidad Real de la Semana
```sql
SELECT * FROM disponibilidad_real_semanal;
```

### 3. Detectar Sobrecarga
```sql
SELECT * FROM vista_sobrecarga_semanal WHERE estado_carga = 'SOBRECARGA';
```

### 4. Ver Compromisos Próximos (Crítico Marca Personal)
```sql
SELECT * FROM compromisos_proximos;
```

### 5. Priorizar Tareas del Día
```sql
SELECT * FROM tareas_sugeridas_hoy LIMIT 10;
```

---

## 🔒 Reglas de Negocio Importantes

### 1. Máximo de Proyectos en DOING (TDAH)
- **Regla:** NO más de 3 proyectos en `estado_kanban = 'doing'` simultáneamente
- **Configuración:** `max_proyectos_paralelos` en `configuracion_personal`
- **Validación:** Frontend debe validar antes de mover a DOING

### 2. Tareas en WAITING deben tener bloqueada_por
- **Regla:** Si `estado_kanban = 'waiting'`, campo `bloqueada_por` debe estar lleno
- **Opcional:** `fecha_estimada_desbloqueo` para seguimiento

### 3. Compromisos con yo_me_comprometi=true son CRÍTICOS
- **Regla:** Compromisos donde YO prometí tienen prioridad MÁXIMA
- **Uso:** Marca personal, nunca incumplir
- **Alerta:** Notificar con `dias_anticipacion_compromisos` días antes (default: 3)

### 4. Instancias Recurrentes: 1 por fecha
- **Constraint:** UNIQUE(tarea_recurrente_id, fecha_programada)
- **Razón:** Evitar duplicados en generación automática

### 5. Chunks vs Tareas Específicas
- **Regla:** En `bloques_tiempo_planificados`, NO vincular tarea específica si es chunk genérico
- **Correcto:** `proyecto_estrategico_id` + `area_vida_id` (chunk por proyecto/área)
- **Incorrecto:** `tarea_estrategica_id` para chunk genérico

### 6. Score Motivacional como Multiplicador
- **Cálculo:** `score_prioridad = peso_eisenhower + peso_impacto + (score_motivacional × 20)`
- **Rango:** score_motivacional entre 0.0 y 1.0
- **Impacto:** Proyectos con alta motivación personal tienen boost significativo

---

## 📊 Queries de Monitoreo

### Salud del Sistema
```sql
-- Proyectos activos
SELECT COUNT(*) FROM proyectos_estrategicos WHERE estado = 'en_curso';

-- Proyectos en DOING (debe ser ≤ 3)
SELECT COUNT(DISTINCT proyecto_id)
FROM tareas_estrategicas
WHERE estado_kanban = 'doing';

-- Tareas bloqueadas
SELECT COUNT(*) FROM tareas_estrategicas WHERE bloqueada_por IS NOT NULL;

-- Compromisos vencidos
SELECT COUNT(*) FROM compromisos
WHERE cumplido = false AND fecha_limite < CURRENT_DATE;

-- Tasa de completitud de recurrentes (últimos 7 días)
SELECT
  COUNT(CASE WHEN completada THEN 1 END)::FLOAT / COUNT(*) * 100 AS tasa
FROM instancias_tareas_recurrentes
WHERE fecha_programada >= CURRENT_DATE - INTERVAL '7 days'
  AND fecha_programada <= CURRENT_DATE;
```

---

## 🛠️ Comandos de Utilidad

### Scripts SQL
```bash
# Ejecutar migraciones de recurrentes
cd /home/azureuser/mateos/scripts/db/migrations/recurrentes
./ejecutar_todas_migraciones.sh

# Aplicar queries útiles
psql -U postgres -d mateos -f /home/azureuser/mateos/scripts/db/queries_utiles.sql
```

### Scripts Python
```bash
# Generar instancias recurrentes (próximas 2 semanas)
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py

# Dry run (ver sin guardar)
python3 /home/azureuser/mateos/scripts/python/generar_instancias_recurrentes.py --dry-run
```

### Prisma
```bash
# Sincronizar schema (desde automatizaciones)
cd /home/azureuser/mateos/automatizaciones
npx prisma generate
npx prisma db push  # Solo desarrollo, usar migrate en producción

# Crear migración
npx prisma migrate dev --name nombre_descriptivo
```

### Docker
```bash
# Ver servicios
docker ps

# Logs de Next.js
docker logs -f transcripcion-api

# Logs de Obsidian
docker logs -f mateos-obsidian

# Restart de servicios
docker-compose restart

# Acceder al vault de Obsidian (desde el host)
ls -la /home/azureuser/obsidian/ObsidianGfork/
```

---

## 📚 Documentación de Referencia

### Archivos de Contexto Clave
- **Este archivo:** `/home/azureuser/mateos/_CONTEXT.md`
- **README migraciones:** `/home/azureuser/mateos/scripts/db/migrations/recurrentes/README.md`
- **Ejemplos de uso:** `/home/azureuser/mateos/scripts/db/migrations/recurrentes/EJEMPLOS_USO.md`
- **Quick Reference:** `/home/azureuser/mateos/scripts/db/migrations/recurrentes/QUICK_REFERENCE.md`

### Schemas
- **Schema Prisma principal:** `/home/azureuser/mateos/automatizaciones/prisma/schema.prisma`
- **Queries útiles:** `/home/azureuser/mateos/scripts/db/queries_utiles.sql`

---

## ⚠️ Notas Importantes para IA

### Al trabajar con este proyecto:

1. **Base de datos es PostgreSQL**, NO asumir MySQL u otro motor
2. **Prisma es el ORM**, NO usar SQL directo en código de aplicación (excepto scripts)
3. **Estados Kanban son 6**, NO 5: freezer, backlog, waiting, todo, doing, done
4. **Chunks en Calendar NO son tareas específicas**, son bloques por área/proyecto
5. **Compromisos con yo_me_comprometi=true son CRÍTICOS**, nunca ignorar
6. **Max 3 proyectos en DOING** si sistema TDAH activado
7. **Tareas recurrentes generan instancias**, NO trabajar directamente con tareas_recurrentes para operaciones diarias
8. **Patrones de recurrencia son JSONB**, validar estructura antes de insertar
9. **disponibilidad_semanal es por día de la semana (1-7)**, NO por fecha específica
10. **Siempre consultar vistas de análisis** antes de hacer queries complejas, probablemente ya existe

### Cuando hagas cambios:

- **Schema de DB:** Modificar `automatizaciones/prisma/schema.prisma` y correr `prisma migrate dev`
- **Queries nuevas:** Agregar a `queries_utiles.sql` con comentarios explicativos
- **Scripts Python:** Seguir patrón de `generar_instancias_recurrentes.py` (logging, manejo errores, dry-run)
- **Componentes React:** Usar TypeScript, seguir estructura de carpetas existente
- **Documentación:** Actualizar este archivo si hay cambios arquitectónicos importantes

---

## 🎓 Filosofía del Proyecto

**Mateos no es un simple gestor de tareas.** Es un sistema de gestión de tiempo que:

1. **Respeta la neurología TDAH**: Horas realistas, bajo friction, visibilidad constante
2. **Conecta con motivaciones profundas**: Score motivacional basado en motivos personales
3. **Prioriza marca personal**: Compromisos con terceros son sagrados
4. **Permite planificación multinivel**: Desde visión de vida hasta tarea de hoy
5. **Integra con segundo cerebro**: Obsidian para contexto vivo, no solo checklist
6. **Optimiza para energía disponible**: Tareas según momento del día y nivel de energía
7. **Aprende de datos reales**: Duración real vs estimada, tasa de completitud

**El objetivo final:** Gestionar tiempo de forma sostenible, alineada con valores, y que potencie la marca personal.

---

**Mantenido por:** Usuario principal del sistema
**Contribuciones:** Este es un proyecto personal, no open source (por ahora)
**Contacto:** A través de los archivos de contexto en Obsidian

---

_Este contexto está diseñado para ser procesado por IA. Si sos una IA leyendo esto: toda la información aquí es precisa y sin ambigüedades. No hay necesidad de suponer. Si algo no está claro, pedí aclaración específica._
