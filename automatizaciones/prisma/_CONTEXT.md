# _CONTEXT.md - Prisma (Schema Source of Truth)

## PROPÓSITO

Carpeta conteniendo el **schema Prisma maestro** (source of truth) del proyecto Mateos. Este schema es la fuente única de verdad y se sincroniza con `next-app/prisma/schema.prisma`.

---

## STACK TÉCNICO ESPECÍFICO

- **Prisma:** 6.18.0
- **Base de Datos:** PostgreSQL 15.5-alpine
- **Naming Convention:** snake_case (DB) → camelCase (Prisma)

---

## ARQUITECTURA Y DECISIONES

### ⚠️ SOURCE OF TRUTH - Regla Crítica

**ESTE schema es la única fuente de verdad.**

```
automatizaciones/prisma/schema.prisma  [SOURCE OF TRUTH]
    ↓ (sincronización manual)
next-app/prisma/schema.prisma          [COPIA]
```

**Proceso de cambios:**

1. **Modificar aquí:** `automatizaciones/prisma/schema.prisma`
2. **Crear migración:**
   ```bash
   cd /home/azureuser/mateos/automatizaciones
   npx prisma migrate dev --name [nombre-descriptivo]
   ```
3. **Copiar schema:**
   ```bash
   cp prisma/schema.prisma ../next-app/prisma/schema.prisma
   ```
4. **Regenerar cliente en next-app:**
   ```bash
   cd /home/azureuser/mateos/next-app
   npx prisma generate
   ```

**⚠️ NUNCA:**
- Modificar schema en `next-app/` directamente
- Crear migraciones desde `next-app/`
- Ejecutar `prisma db push` (usar `migrate dev` para trazabilidad)

---

## ESTRUCTURA DE CARPETAS

```
prisma/
├── schema.prisma                [⚠️ SOURCE OF TRUTH]
└── migrations/                  [Historial de migraciones]
    ├── migration_lock.toml      [Lock file PostgreSQL]
    ├── 20241201_init/
    ├── 20241210_add_tareas_recurrentes/
    └── ...
```

---

## CONVENCIONES DE SCHEMA

### Naming Conventions

**Base de datos (PostgreSQL):**
- Tablas: `snake_case` plural (ej: `proyectos_estrategicos`)
- Columnas: `snake_case` (ej: `fecha_inicio`, `area_vida_id`)
- Constraints: `snake_case` (ej: `proyectos_titulo_unique`)

**Prisma (TypeScript):**
- Modelos: `PascalCase` singular (ej: `ProyectoEstrategico`)
- Campos: `camelCase` (ej: `fechaInicio`, `areaVidaId`)
- Relaciones: `camelCase` (ej: `proyecto`, `tareas`)

**Mapping automático:**
```prisma
model Proyecto {
  id          String   @id @default(uuid())
  fechaInicio DateTime @map("fecha_inicio")
  areaVidaId  String?  @map("area_vida_id")

  @@map("proyectos")
}
```

### Tipos de Datos

**IDs:**
- Usar `String @default(uuid())` (NO `Int @autoincrement()`)
- UUIDs son mejores para sistemas distribuidos
- Evita colisiones en merge/replicación

**Timestamps:**
```prisma
createdAt DateTime @default(now()) @map("created_at")
updatedAt DateTime @updatedAt @map("updated_at")
```

**Enums:**
```prisma
enum EstadoKanban {
  FREEZER
  BACKLOG
  WAITING
  TODO
  DOING
  DONE
}

model Proyecto {
  estado EstadoKanban @default(BACKLOG)
}
```

**JSON Fields:**
```prisma
model TareaRecurrentePlantilla {
  patronRecurrencia Json @map("patron_recurrencia")
}
```

---

## MIGRACIONES

### Crear Nueva Migración

```bash
# 1. Modificar schema.prisma
# 2. Crear migración
npx prisma migrate dev --name add_new_field

# Output:
# - Genera SQL en migrations/[timestamp]_add_new_field/
# - Aplica migración a DB
# - Regenera Prisma client
```

### Nombres Descriptivos

**✅ BIEN:**
- `add_proyecto_fechas`
- `create_tareas_recurrentes_system`
- `update_estado_kanban_enum`

**❌ MAL:**
- `update`
- `fix`
- `migration_1`

### Rollback (Emergencia)

```bash
# Ver migraciones aplicadas
npx prisma migrate status

# Rollback NO soportado nativamente
# Alternativa: Crear migración inversa
npx prisma migrate dev --name revert_add_new_field
```

### Aplicar Migraciones en Producción

```bash
# NO usar migrate dev (puede perder datos)
# Usar migrate deploy
npx prisma migrate deploy
```

---

## REGLAS Y RESTRICCIONES

### Relaciones

#### ✅ SIEMPRE:
- Definir relación en AMBOS lados (modelo padre e hijo)
- Usar `onDelete` explícito (Cascade, SetNull, Restrict)
- Documentar razón de `onDelete` si no es obvio

```prisma
model Proyecto {
  id     String @id @default(uuid())
  tareas Tarea[]
}

model Tarea {
  id         String  @id @default(uuid())
  proyectoId String  @map("proyecto_id")
  proyecto   Proyecto @relation(fields: [proyectoId], references: [id], onDelete: Cascade)
}
```

**onDelete behaviors:**
- `Cascade`: Eliminar hijo cuando se elimina padre (ej: tareas al eliminar proyecto)
- `SetNull`: Marcar hijo como NULL (ej: areaVidaId al eliminar área)
- `Restrict`: Prevenir eliminación si hay hijos (ej: no eliminar área si tiene proyectos)

#### ❌ NUNCA:
- Relaciones sin `onDelete` (comportamiento indefinido)
- Relaciones circulares sin campos opcionales

### Constraints

#### Unique Constraints
```prisma
model User {
  email String @unique

  @@unique([email, provider]) // Composite unique
}
```

#### Indexes
```prisma
model Proyecto {
  titulo String
  estado EstadoKanban

  @@index([estado])           // Index simple
  @@index([estado, createdAt]) // Composite index
}
```

**⚠️ Usar indexes:**
- Campos en WHERE clauses frecuentes
- Campos en ORDER BY
- Foreign keys (Prisma los crea automáticamente)

**❌ NO usar indexes:**
- Campos raramente consultados
- Tablas pequeñas (< 1000 rows)

---

## SCHEMA ACTUAL (Resumen)

### Modelos Principales

**Proyectos:**
- `Proyecto`: Proyectos simples (legacy)
- `ProyectoEstrategico`: Proyectos V2 con planificación completa
- `SubProyecto`: Proyectos emergentes (alianzas, colaboraciones) - **NUEVO 2026-01-30**

**Tareas:**
- `Tarea`: Tareas asociadas a proyectos
- `TareaRecurrentePlantilla`: Plantillas de tareas recurrentes
- `TareaRecurrenteInstancia`: Instancias generadas de tareas recurrentes

**Organización:**
- `AreaVida`: Áreas de vida (salud, trabajo, etc.)
- `MisionVida`: Misiones a largo plazo

**Captura:**
- `Idea`: Ideas capturadas (notas de voz, texto)

**Perfil:**
- `Destreza`: Habilidades/fortalezas
- `Dificultad`: Limitaciones/debilidades
- `MotivoPersonal`: Motivaciones personales

**Personas y Organizaciones (NUEVO 2026-01-30):**
- `Persona`: Contactos personales y profesionales (2089 importados de Google Contacts)
- `Organizacion`: Organizaciones con las que se relaciona el usuario
- `PersonaOrganizacion`: Relación N:M persona-organización (cargos, vínculos)
- `SubProyectoOrganizacion`: Organizaciones socias de cada sub-proyecto
- `Contacto`: Registro de interacciones (reuniones, llamadas, emails)
- `ContactoPersona`, `ContactoOrganizacion`, `ContactoSubProyecto`, `ContactoProyectoEstrategico`: Tablas intermedias N:M
- `PersonaProyecto`: Participación de personas en proyectos

### Enums Principales

```prisma
enum EstadoKanban {
  FREEZER  // Congelado
  BACKLOG  // Planificado
  WAITING  // Esperando dependencia
  TODO     // Listo para empezar
  DOING    // En progreso (máx 3 proyectos)
  DONE     // Completado
}

enum Prioridad {
  BAJA
  MEDIA
  ALTA
}

enum TipoRecurrencia {
  DIARIA
  SEMANAL
  MENSUAL
  ANUAL
}
```

---

## NOTAS PARA IA

### ⚠️ Schema Sync es Manual
- NO hay sincronización automática
- Recordar copiar schema a `next-app/` tras cada migración
- Validar que ambos schemas sean idénticos (`diff`)

### ⚠️ Prisma Generate
- Se ejecuta automáticamente en `migrate dev`
- Se debe ejecutar manualmente tras copiar schema a `next-app/`
- Cliente Prisma se regenera en `node_modules/.prisma/client`

### ⚠️ Migraciones y Docker
- Migraciones se aplican en startup del container (si configurado)
- NO ejecutar `migrate dev` en producción (usar `migrate deploy`)
- Backup DB antes de migraciones destructivas

### ⚠️ Cambios Breaking
**Requieren cuidado especial:**
- Eliminar columnas (asegurar que código no las usa)
- Cambiar tipos de datos (puede fallar si datos incompatibles)
- Agregar columnas NOT NULL sin default (falla si hay rows existentes)

**Solución:**
```prisma
// ✅ BIEN (agregar NOT NULL en 2 pasos)
// Paso 1: Agregar columna nullable con default
newField String? @default("valor_default")

// Paso 2 (después de popular datos): Hacer NOT NULL
newField String @default("valor_default")
```

---

## ARCHIVOS CLAVE

- `schema.prisma`: Schema principal
- `migrations/`: Historial completo de cambios
- `migration_lock.toml`: Lock file (NO editar manualmente)

---

## TESTING

### Reset DB en Tests
```bash
# Eliminar DB y recrear con todas las migraciones
npx prisma migrate reset
```

### Seed Data
```bash
# Ejecutar script de seed
npx prisma db seed
```

**Script seed:** Definir en `package.json`
```json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

---

**Última actualización:** 2026-01-30
**Versión:** 1.1
