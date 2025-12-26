# _CONTEXT.md - Sistema de Contexto y Bitácoras

## PROPÓSITO

Esta carpeta contiene la **documentación del sistema de trabajo** del proyecto Mateos. Define cómo escribir contextos, mantener bitácoras, y organizar la memoria técnica del proyecto.

**NO contiene información personal del usuario**, solo metodología de trabajo.

---

## STACK TÉCNICO ESPECÍFICO

Este sistema de documentación usa:
- **Markdown** (GitHub Flavored Markdown)
- **Convenciones de nomenclatura:** `_CONTEXT.md` (contextos), `BITACORA.md` (bitácoras)
- **Formato ISO 8601** para fechas en bitácoras
- **Zona horaria:** America/Montevideo (implícita en todas las fechas)

---

## ARQUITECTURA DEL SISTEMA

### Jerarquía de Documentación

```
/home/azureuser/mateos/
│
├── _CONTEXT.md                    [Contexto arquitectónico global del proyecto]
│
├── Sistema/                        [Documentación del sistema de trabajo]
│   ├── _CONTEXT.md                [Este archivo - Meta-contexto]
│   ├── BITACORA.md                [Bitácora de cambios en el sistema]
│   ├── GUIA_ESCRITURA_CONTEXTOS.md    [Guía completa para escribir _CONTEXT.md]
│   ├── INSTRUCCIONES_BITACORA.md      [Guía completa para bitácoras]
│   └── CHECKLIST_CONTEXTO.md          [Checklist rápida pre-guardado]
│
├── [carpeta-relevante]/
│   └── _CONTEXT.md                [Contexto específico de esa carpeta]
│
└── [carpeta-principal]/
    └── BITACORA.md                [Bitácora de trabajo de esa carpeta]
```

### Principio de Cascada

La información fluye de **general a específica**:
1. `/home/azureuser/mateos/_CONTEXT.md` → Arquitectura global, stack principal
2. `/home/azureuser/mateos/next-app/_CONTEXT.md` → Específico de Next.js
3. `/home/azureuser/mateos/next-app/src/app/api/_CONTEXT.md` → Específico de API Routes

**Regla:** Cada nivel agrega información NUEVA. NO repite info del nivel superior.

---

## REGLAS Y RESTRICCIONES

### _CONTEXT.md

#### ✅ SIEMPRE:
- Incluir valores concretos (versiones, timeouts, rate limits)
- Usar formato imperativo (SIEMPRE/NUNCA/OBLIGATORIO)
- Documentar gotchas y errores comunes
- Mantener < 200 líneas (idealmente < 100)
- Actualizar cuando cambie arquitectura o stack

#### ❌ NUNCA:
- Repetir información del `_CONTEXT.md` padre
- Usar lenguaje vago ("maneja", "procesa", "gestiona")
- Incluir información personal del usuario
- Explicar conceptos obvios
- Escribir código completo (solo snippets críticos)

### BITACORA.md

#### ✅ SIEMPRE:
- Formato estándar: `## YYYY-MM-DD HH:mm | [carpeta] | [autor]`
- Orden cronológico inverso (más reciente arriba)
- Bullets concisos, NO párrafos
- Tag de subcarpeta si aplica: `[subcarpeta]`

#### ❌ NUNCA:
- Registrar cambios triviales (typos, reformateo)
- Incluir información personal
- Escribir "progreso operativo" sin decisiones
- Crear BITACORA.md en subcarpetas (solo en principales)

---

## CARPETAS CON _CONTEXT.MD

**Criterio:** Cualquier carpeta con decisiones arquitectónicas propias, stack específico, o reglas de negocio particulares.

### Lista de Carpetas Relevantes (13 carpetas):

1. `/home/azureuser/mateos/` (raíz) ✅ YA EXISTE
2. `/home/azureuser/mateos/next-app/`
3. `/home/azureuser/mateos/next-app/src/app/api/`
4. `/home/azureuser/mateos/next-app/src/components/`
5. `/home/azureuser/mateos/next-app/src/lib/`
6. `/home/azureuser/mateos/automatizaciones/`
7. `/home/azureuser/mateos/automatizaciones/src/ia/`
8. `/home/azureuser/mateos/automatizaciones/prisma/`
9. `/home/azureuser/mateos/telegram-bot/`
10. `/home/azureuser/mateos/scripts/db/`
11. `/home/azureuser/mateos/scripts/db/migrations/recurrentes/` ✅ YA DOCUMENTADO
12. `/home/azureuser/mateos/scripts/python/`
13. `/home/azureuser/mateos/docs/` (opcional)

**Nota:** La lista puede crecer si se agregan nuevos módulos con decisiones arquitectónicas propias.

---

## CARPETAS CON BITACORA.MD (SOLO PRINCIPALES)

**Criterio:** Puntos de entrada donde se trabaja recurrentemente, NO sus subcarpetas.

### Lista de Carpetas Principales (4 carpetas):

1. **`/home/azureuser/mateos/`** (raíz)
   - Cambios arquitectónicos globales
   - Actualizaciones de infraestructura (Docker, .env)
   - Operaciones DevOps

2. **`/home/azureuser/mateos/next-app/`**
   - Desarrollo frontend (páginas, componentes)
   - Nuevos endpoints API
   - Refactors en código Next.js

3. **`/home/azureuser/mateos/automatizaciones/`**
   - Procesamiento IA
   - Nuevos workflows
   - Cambios en prompts o modelos

4. **`/home/azureuser/mateos/scripts/`**
   - Nuevos scripts de automatización
   - Cambios en migraciones SQL
   - Mejoras en backups/health checks

**Importante:** Si trabajas en una subcarpeta (ej: `next-app/src/components/`), registras en la bitácora de la carpeta principal (`next-app/BITACORA.md`) con tag `[components]`.

---

## FORMATO ESTÁNDAR DE ENTRADA EN BITÁCORAS

```markdown
## YYYY-MM-DD HH:mm | [Carpeta-Principal] | [claude-code/manual/otro]

**Título de la actividad**
- **[Subcarpeta]:** Descripción de lo que se hizo (si aplica)
- Decisiones tomadas
- Próximos pasos (si los hay)
```

### Ejemplo Real:

```markdown
## 2025-12-26 14:30 | [next-app] | [claude-code]

**Implementar filtro de proyectos por estado**
- **[api]:** Nuevo endpoint `GET /api/proyectos?estado=DOING`
- **[proyectos]:** Agregar dropdown de filtro en página de lista
- Decisión: Usar query params en lugar de POST body
- Próximos pasos: Agregar filtro por área de vida
```

---

## 6 PREGUNTAS CLAVE: ¿VA EN _CONTEXT.MD O EN BITÁCORA?

| # | Pregunta | Si SÍ → | Si NO → |
|---|----------|---------|---------|
| 1 | ¿Es una decisión estratégica importante? | _CONTEXT.md | Bitácora |
| 2 | ¿Cambia el estado del proyecto (nueva feature, refactor)? | Bitácora | (no registrar) |
| 3 | ¿Es un contacto/persona clave nueva? | _CONTEXT.md | (no registrar) |
| 4 | ¿Aprendimos algo importante sobre cómo trabajar? | _CONTEXT.md | Bitácora |
| 5 | ¿Cambia el stack/herramientas? | _CONTEXT.md | Bitácora |
| 6 | ¿Es solo progreso operativo? | (no registrar) | (no registrar) |

**Regla práctica:**
- **_CONTEXT.md** = Conocimiento permanente (arquitectura, decisiones, gotchas)
- **BITACORA.md** = Registro temporal (qué se hizo, cuándo, por qué)

---

## FLUJO AUTOMÁTICO AL ACTUALIZAR BITÁCORA DESDE CLAUDE CODE

### Cuando Claude Code termina una sesión de trabajo:

1. **Detección automática:**
   - Analiza archivos modificados
   - Identifica carpeta principal afectada
   - Clasifica tipo de cambios

2. **Generación de entrada:**
   - Fecha/hora actual (America/Montevideo)
   - Tag `[claude-code]`
   - Título resumiendo cambios
   - Bullets con detalles técnicos

3. **Pregunta al usuario:**
   ```
   ¿Deseas actualizar la bitácora de [carpeta-principal]?
   ```

4. **Si usuario acepta:**
   - Inserta entrada al INICIO del `BITACORA.md` correspondiente
   - Muestra preview
   - Confirma guardado

5. **Si hay cambios en múltiples carpetas principales:**
   - Pregunta por cada una
   - Permite editar antes de guardar

---

## NOTAS PARA IA

### ⚠️ Al trabajar con _CONTEXT.md:
- SIEMPRE leer `GUIA_ESCRITURA_CONTEXTOS.md` antes de crear/editar
- SIEMPRE usar `CHECKLIST_CONTEXTO.md` antes de guardar
- NO repetir información de niveles superiores
- Validar con "Prueba de la IA" (ver checklist)

### ⚠️ Al trabajar con BITACORA.md:
- SIEMPRE leer `INSTRUCCIONES_BITACORA.md` para formato
- Insertar SIEMPRE al INICIO (orden cronológico inverso)
- Tag correcto de carpeta principal
- NO registrar cambios triviales

### ⚠️ Sincronización _CONTEXT.md ↔ BITACORA.md:
- Si descubres un gotcha importante en sesión → AMBOS
  - BITACORA.md: Registro del descubrimiento
  - _CONTEXT.md: Documentación permanente del gotcha
- Si haces cambio arquitectónico → AMBOS
  - BITACORA.md: Registro del cambio
  - _CONTEXT.md: Actualización de arquitectura

---

## ARCHIVOS CLAVE

- `GUIA_ESCRITURA_CONTEXTOS.md`: Guía completa de cómo escribir _CONTEXT.md (ejemplos, anti-patrones)
- `INSTRUCCIONES_BITACORA.md`: Guía completa de cómo mantener bitácoras (formato, flujo)
- `CHECKLIST_CONTEXTO.md`: Checklist rápida pre-guardado de _CONTEXT.md
- `_CONTEXT.md`: Este archivo (meta-contexto del sistema)
- `BITACORA.md`: Registro de cambios en el sistema de documentación

---

## MANTENIMIENTO

### Actualizar este archivo cuando:
- Se agregue nueva carpeta con _CONTEXT.md
- Se agregue nueva carpeta principal con BITACORA.md
- Cambien las reglas del sistema de documentación
- Se descubra un nuevo patrón o anti-patrón

### Revisar cada 3 meses:
- Lista de carpetas con _CONTEXT.md (agregar nuevas)
- Lista de carpetas principales con BITACORA.md
- Validar que guías sigan siendo relevantes

---

**Última actualización:** 2025-12-26
**Versión:** 1.0
**Autor:** Sistema de Contexto Mateos
