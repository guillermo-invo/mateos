# INSTRUCCIONES PARA BITÁCORAS

## PROPÓSITO

Las bitácoras son el registro cronológico de trabajo en una carpeta/módulo específico. Sirven para:
- Rastrear qué se hizo, cuándo, y por qué
- Identificar patrones de trabajo
- Recordar decisiones pasadas
- Planificar próximos pasos

**Principio fundamental:** Registro operativo conciso, NO documentación técnica (eso va en _CONTEXT.md).

---

## UBICACIÓN DE BITÁCORAS

### Carpetas con BITACORA.md (SOLO las principales)
Estas son las carpetas donde se trabaja recurrentemente:

1. **`/home/azureuser/mateos/BITACORA.md`** (raíz)
   - Cambios arquitectónicos globales
   - Actualizaciones de infraestructura (Docker, .env, etc.)
   - Operaciones DevOps

2. **`/home/azureuser/mateos/next-app/BITACORA.md`**
   - Desarrollo frontend (páginas, componentes)
   - Nuevos endpoints API
   - Refactors en el código Next.js

3. **`/home/azureuser/mateos/automatizaciones/BITACORA.md`**
   - Procesamiento IA
   - Nuevos workflows
   - Cambios en prompts o modelos

4. **`/home/azureuser/mateos/scripts/BITACORA.md`**
   - Nuevos scripts de automatización
   - Cambios en migraciones SQL
   - Mejoras en backups/health checks

**IMPORTANTE:** NO crear BITACORA.md en subcarpetas. Si trabajas en `next-app/src/components/`, registras en `next-app/BITACORA.md` con tag `[components]`.

---

## FORMATO ESTÁNDAR DE ENTRADA

```markdown
## YYYY-MM-DD HH:mm | [Carpeta-Principal] | [claude-code/manual/otro]

**Título de la actividad**
- **[Subcarpeta]:** Descripción de lo que se hizo (si aplica)
- Decisiones tomadas
- Próximos pasos (si los hay)
```

### Componentes del Formato

1. **Fecha y Hora:** `YYYY-MM-DD HH:mm`
   - Formato ISO 8601
   - Zona horaria: America/Montevideo (implícita)

2. **[Carpeta-Principal]:** Tag de la carpeta principal
   - `[raiz]`: Para trabajos en `/home/azureuser/mateos/`
   - `[next-app]`: Para trabajos en `next-app/`
   - `[automatizaciones]`: Para trabajos en `automatizaciones/`
   - `[scripts]`: Para trabajos en `scripts/`

3. **[claude-code/manual/otro]:** Quién hizo el cambio
   - `[claude-code]`: Cambios hechos por Claude Code (IA)
   - `[manual]`: Cambios hechos manualmente por el usuario
   - `[otro]`: Cambios hechos por otros (scripts automáticos, CI/CD, etc.)

4. **Título:** Resumen en 1 línea de lo que se hizo

5. **[Subcarpeta]:** (Opcional) Si el trabajo fue en una subcarpeta específica
   - Ejemplos: `[api]`, `[components]`, `[ia]`, `[db]`

6. **Descripción:** Bullets con:
   - Qué se hizo (concreto)
   - Decisiones tomadas (si hubo)
   - Próximos pasos (si los hay)

---

## EJEMPLOS DE ENTRADAS

### Ejemplo 1: Desarrollo en Next.js
```markdown
## 2025-12-26 14:30 | [next-app] | [claude-code]

**Implementar filtro de proyectos por estado**
- **[api]:** Nuevo endpoint `GET /api/proyectos?estado=DOING`
  - Validación con Zod schema
  - Retorna array de proyectos con formato estándar
- **[proyectos]:** Agregar dropdown de filtro en página de lista
  - Componente `ProyectoFilter.tsx` (client component)
  - Estado local con useState
- Decisión: Usar query params en lugar de POST body
- Próximos pasos: Agregar filtro por área de vida
```

### Ejemplo 2: Migración de Base de Datos
```markdown
## 2025-12-26 09:15 | [scripts] | [manual]

**Ejecutar migración de tareas recurrentes**
- **[db/migrations/recurrentes]:** Ejecutadas migraciones 01-04
  - Tablas creadas: tarea_recurrente_plantilla, tarea_recurrente_instancia
  - Vistas: v_estado_recurrentes, v_pendientes_futuro
  - Funciones: generar_instancia_recurrente(), aplicar_sobreescritura()
- Decisión: NO ejecutar seed data aún, esperar a testing manual
- Próximos pasos: Probar generación de instancias con script Python
```

### Ejemplo 3: Cambio Arquitectónico Global
```markdown
## 2025-12-26 16:00 | [raiz] | [claude-code]

**Migrar de Vercel a Azure VM**
- **[docker-compose.yml]:** Agregar servicio nginx reverse proxy
- **[.env]:** Nuevas variables: NGINX_PORT, SSL_CERT_PATH
- **[scripts]:** Nuevo script `scripts/health-check.sh`
- Decisión: Usar certbot para SSL (Let's Encrypt)
- Próximos pasos: Configurar renovación automática de certificados
```

### Ejemplo 4: Trabajo en Automatizaciones IA
```markdown
## 2025-12-26 11:45 | [automatizaciones] | [claude-code]

**Optimizar prompts de generación de proyectos**
- **[ia/prompts-proyectos.ts]:** Reducir tamaño de prompt de 1.2K a 800 tokens
  - Remover ejemplos redundantes
  - Usar bullets en lugar de párrafos
- Testing: Generación mantiene calidad, reduce costo 33%
- Decisión: Mantener validación Zod estricta post-generación
- Próximos pasos: A/B testing con usuarios reales
```

---

## QUÉ INCLUIR Y QUÉ NO

### ✅ SÍ Incluir en Bitácora

1. **Cambios de código significativos**
   - Nueva feature
   - Refactor importante
   - Bug fix no trivial

2. **Decisiones técnicas**
   - "Decidimos usar X en lugar de Y porque..."
   - "Cambiamos el enfoque de A a B"

3. **Migraciones y cambios de esquema**
   - Cambios en DB
   - Cambios en estructura de archivos
   - Cambios en configuración

4. **Integraciones nuevas**
   - Nueva API externa
   - Nuevo servicio
   - Nueva dependencia crítica

5. **Próximos pasos planificados**
   - TODOs concretos
   - Tareas pendientes identificadas

### ❌ NO Incluir en Bitácora

1. **Cambios triviales**
   - Fix de typo en comentario
   - Reformateo de código
   - Cambio de nombre de variable local

2. **Progreso operativo repetitivo**
   - "Seguimos trabajando en X"
   - "Avance del 50%"
   - Updates de status sin decisiones

3. **Información que va en _CONTEXT.md**
   - Arquitectura del módulo
   - Reglas y restricciones
   - Documentación técnica

4. **Información personal**
   - Motivaciones personales
   - Contexto privado
   - Datos sensibles

5. **Logs automáticos**
   - Output de scripts (va en `logs/`)
   - Errores de compilación (va en _CONTEXT.md si es gotcha común)

---

## FLUJO RECOMENDADO AL TERMINAR SESIÓN

### Si trabajaste con Claude Code:

1. **Claude Code pregunta al finalizar:**
   ```
   ¿Debemos actualizar la bitácora?
   ```

2. **Tú respondes:** Sí/No (o especificas qué carpeta)

3. **Claude Code escribe entrada automáticamente:**
   - Analiza cambios hechos en la sesión
   - Detecta carpeta principal afectada
   - Escribe entrada con formato estándar
   - Tag: `[claude-code]`

4. **Tú revisas y editas si es necesario**

### Si trabajaste manualmente:

1. **Identifica carpeta principal afectada**
   - ¿Trabajaste en `next-app/`? → `next-app/BITACORA.md`
   - ¿Trabajaste en `scripts/`? → `scripts/BITACORA.md`
   - ¿Cambios globales? → `BITACORA.md` (raíz)

2. **Abre el archivo BITACORA.md correspondiente**

3. **Agrega entrada al INICIO del archivo** (orden cronológico inverso)

4. **Usa formato estándar** (ver arriba)

5. **Tag:** `[manual]`

---

## ORDEN CRONOLÓGICO: INVERSO (MÁS RECIENTE ARRIBA)

```markdown
# BITÁCORA - Next App

## 2025-12-26 16:30 | [next-app] | [claude-code]
**Último cambio realizado** ← MÁS RECIENTE

## 2025-12-26 14:15 | [next-app] | [manual]
**Cambio anterior**

## 2025-12-25 10:00 | [next-app] | [claude-code]
**Cambio más antiguo**
```

**Razón:** Al abrir bitácora, ves inmediatamente lo más reciente.

---

## 6 PREGUNTAS CLAVE: ¿VA EN _CONTEXT.MD O EN BITÁCORA?

Antes de escribir, pregúntate:

| # | Pregunta | Si SÍ → | Si NO → |
|---|----------|---------|---------|
| 1 | ¿Es una decisión estratégica importante? | _CONTEXT.md | Bitácora |
| 2 | ¿Cambia el estado del proyecto (nueva feature, refactor)? | Bitácora | (no registrar) |
| 3 | ¿Es un contacto/persona clave nueva? | _CONTEXT.md | (no registrar) |
| 4 | ¿Aprendimos algo importante sobre cómo trabajar? | _CONTEXT.md | Bitácora |
| 5 | ¿Cambia el stack/herramientas? | _CONTEXT.md | Bitácora |
| 6 | ¿Es solo progreso operativo? | (no registrar) | (no registrar) |

### Ejemplos:

**P1: Decidimos usar JWT en lugar de sessions**
→ _CONTEXT.md (decisión arquitectónica)
→ Bitácora (registro del cambio)

**P2: Agregamos botón de logout**
→ Bitácora (cambio de estado del proyecto)

**P3: Nuevo desarrollador en el equipo**
→ _CONTEXT.md (contacto clave)

**P4: Descubrimos que Whisper falla con audio < 0.1s**
→ _CONTEXT.md (gotcha importante)
→ Bitácora (registro del descubrimiento)

**P5: Migramos de PostgreSQL 14 a 15**
→ _CONTEXT.md (cambio de stack)
→ Bitácora (registro de la migración)

**P6: Avance del 70% en feature X**
→ NO registrar (progreso operativo)

---

## FLUJO AUTOMÁTICO AL ACTUALIZAR BITÁCORA DESDE CLAUDE CODE

### Paso 1: Detección Automática
Claude Code detecta automáticamente:
- Archivos modificados en la sesión
- Carpeta principal afectada
- Tipo de cambios (feature, bugfix, refactor, etc.)

### Paso 2: Generación de Entrada
Claude Code genera entrada con:
- Fecha/hora actual (America/Montevideo)
- Tag de carpeta principal
- Tag `[claude-code]`
- Título resumiendo cambios
- Bullets con detalles

### Paso 3: Inserción
Claude Code inserta entrada al INICIO del archivo BITACORA.md correspondiente.

### Paso 4: Confirmación
Claude Code muestra preview de la entrada y pregunta:
```
He agregado esta entrada a [carpeta]/BITACORA.md. ¿Deseas modificar algo?
```

---

## MANTENIMIENTO DE BITÁCORAS

### Cada 3 meses (aproximadamente):
1. Revisar entradas antiguas
2. Mover decisiones importantes a _CONTEXT.md
3. Archivar entradas > 6 meses (opcional):
   ```
   BITACORA.md → BITACORA_2025_Q1.md
   ```

### Si bitácora crece mucho (> 500 líneas):
1. Crear archivo de archivo: `BITACORA_YYYY_QN.md`
2. Mover entradas antiguas
3. Mantener solo último mes en BITACORA.md principal
4. Agregar link al archivo en la bitácora principal:
   ```markdown
   [Ver entradas anteriores: BITACORA_2025_Q1.md]
   ```

---

## RESUMEN EJECUTIVO

### Bitácora es para:
- ✅ Registro cronológico de cambios
- ✅ Decisiones tomadas durante implementación
- ✅ Próximos pasos identificados
- ✅ Tracking de trabajo recurrente

### Bitácora NO es para:
- ❌ Documentación técnica (va en _CONTEXT.md)
- ❌ Progreso operativo ("avance 50%")
- ❌ Cambios triviales (typos, reformateo)
- ❌ Información personal

### Reglas de Oro:
1. **Orden cronológico inverso** (más reciente arriba)
2. **Formato estándar** (fecha | carpeta | autor)
3. **Concisión** (bullets, no párrafos)
4. **Especificidad** (qué, dónde, por qué)

---

**Versión:** 1.0
**Fecha:** 2025-12-26
**Autor:** Sistema de Contexto Mateos
