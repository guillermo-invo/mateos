# GUÍA DE ESCRITURA DE ARCHIVOS _CONTEXT.md

## PROPÓSITO

Los archivos `_CONTEXT.md` son la memoria técnica del proyecto. Proveen a la IA (Claude Code) del contexto necesario para trabajar efectivamente en una carpeta/módulo específico **sin necesidad de explorar o inferir**.

**Principio fundamental:** Especificidad técnica, precisión absoluta, cero redundancia.

---

## PRINCIPIOS CORE

### 1. ESPECIFICIDAD SOBRE GENERALIDAD
❌ MAL: "Este módulo maneja la autenticación de usuarios"
✅ BIEN: "Este módulo implementa autenticación JWT con refresh tokens (7d expiry). Middleware `authMiddleware.ts` valida tokens en cada request. Tokens se almacenan en cookies httpOnly."

### 2. DECISIONES ARQUITECTÓNICAS, NO DESCRIPCIONES
❌ MAL: "Aquí están los componentes React del dashboard"
✅ BIEN: "Componentes dashboard usan React Server Components por defecto. SOLO usar 'use client' si necesitan: estado local, event handlers, o hooks de navegación."

### 3. RESTRICCIONES Y REGLAS, NO POSIBILIDADES
❌ MAL: "Puedes usar axios o fetch para llamadas API"
✅ BIEN: "SIEMPRE usar `apiClient.ts` para llamadas API. NO usar fetch/axios directamente. El cliente maneja automáticamente: auth tokens, retry logic, error formatting."

### 4. CERO REDUNDANCIA CON OTROS NIVELES
- Si algo está en `/home/user/proyecto/_CONTEXT.md`, NO repetirlo en `/home/user/proyecto/src/api/_CONTEXT.md`
- Cada nivel debe agregar información ESPECÍFICA de ese nivel
- Jerarquía: Proyecto → Módulo → Componente (cascada de especificidad)

### 5. INFORMACIÓN TÉCNICA, NO MOTIVACIONAL
❌ MAL: "Este es un módulo importante que nos ayuda a..."
✅ BIEN: "Rate limit: 100 req/min por IP. Implementado con `express-rate-limit` + Redis cache."

---

## ESTRUCTURA ESTÁNDAR

```markdown
# _CONTEXT.md - [Nombre del Módulo/Carpeta]

## PROPÓSITO
[1-2 frases. ¿Qué hace este módulo? ¿Por qué existe?]

## STACK TÉCNICO ESPECÍFICO
[Solo si es diferente del proyecto general]
- Framework/Library X versión Y
- Dependencias únicas de este módulo
- Herramientas específicas

## ARQUITECTURA Y PATRONES
[Decisiones arquitectónicas ESPECÍFICAS de este módulo]
- Patrón usado (ej: Repository pattern, MVC, etc.)
- Estructura de archivos y su propósito
- Flujo de datos
- Interacción con otros módulos

## REGLAS Y RESTRICCIONES
[Reglas IMPERATIVAS. Usa SIEMPRE/NUNCA/OBLIGATORIO]
- ✅ SIEMPRE: [hacer esto]
- ❌ NUNCA: [hacer aquello]
- ⚠️ OBLIGATORIO: [requisito crítico]

## CONVENCIONES DE CÓDIGO
[Específicas de este módulo, si difieren del global]
- Naming conventions
- Estructura de archivos
- Patterns de imports
- Error handling

## INTEGRACIONES EXTERNAS
[Solo si este módulo se integra con servicios externos]
- API X: [propósito, credenciales donde encontrarlas, rate limits]
- Servicio Y: [configuración, endpoints]

## CONFIGURACIÓN
[Variables de entorno, archivos config específicos]
- `ENV_VAR_1`: [propósito, valores válidos]
- Config file: [ubicación, formato]

## NOTAS PARA IA
[Errores comunes, gotchas, cosas contra-intuitivas]
- ⚠️ NO modificar archivo X sin actualizar Y
- ⚠️ Cache invalidation: [cómo hacerlo]
- ⚠️ Este módulo usa CRON, coordinar con DevOps antes de cambios

## ARCHIVOS CLAVE
[Solo los 3-5 archivos MÁS importantes. Uno por línea.]
- `archivo1.ts`: [propósito específico]
- `archivo2.ts`: [propósito específico]

## TESTING
[Si tiene reglas específicas de testing]
- Framework: [Jest, Playwright, etc.]
- Ubicación tests: [path]
- Cómo ejecutar: `npm run test:[comando]`
- Coverage mínimo: [X%]

## DEPENDENCIAS CRÍTICAS
[Solo si hay dependencias técnicas que la IA debe saber]
- Depende de módulo X: [por qué, qué pasa si X falla]
- Debe ejecutarse después de: [proceso Y]
```

---

## CHECKLIST DE CALIDAD

Antes de guardar un `_CONTEXT.md`, verificar:

### ✅ ESPECIFICIDAD
- [ ] Cada afirmación es técnicamente precisa
- [ ] Incluye versiones de dependencias si son críticas
- [ ] Menciona valores concretos (timeouts, limits, etc.)
- [ ] NO hay frases genéricas tipo "maneja datos"

### ✅ UTILIDAD PARA IA
- [ ] La IA puede tomar decisiones SOLO leyendo esto
- [ ] Incluye restricciones claras (SIEMPRE/NUNCA)
- [ ] Menciona gotchas y errores comunes
- [ ] Explica decisiones NO obvias

### ✅ CONCISIÓN
- [ ] Cada sección aporta valor único
- [ ] NO repite info del _CONTEXT.md padre
- [ ] Máximo 200 líneas (idealmente < 100)
- [ ] Sin introducciones innecesarias

### ✅ MANTENIBILIDAD
- [ ] Fecha de última actualización
- [ ] Info que puede quedar obsoleta está marcada con versión
- [ ] Referencias a archivos usan paths relativos

---

## EJEMPLOS COMPARATIVOS

### EJEMPLO 1: API Endpoints

#### ❌ MAL (genérico, vago, inútil)
```markdown
## API Endpoints
Este módulo contiene los endpoints de la API. Los endpoints manejan diferentes operaciones CRUD. Usa Express.js para las rutas.
```

#### ✅ BIEN (específico, técnico, útil)
```markdown
## API Endpoints

### Arquitectura
- Pattern: Controlador → Servicio → Repository
- Validación: Zod schemas en `/schemas`
- Error handling: Middleware `errorHandler.ts` (retorna siempre formato: `{success, data, error}`)

### Reglas
- ✅ SIEMPRE validar input con Zod antes de lógica
- ✅ SIEMPRE usar status codes correctos: 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 404 (Not Found), 500 (Server Error)
- ❌ NUNCA exponer stack traces en producción (middleware detecta NODE_ENV)
- ⚠️ Rate limit global: 100 req/min por IP (middleware `rateLimiter.ts`)

### Estructura
```
api/
├── users/
│   ├── route.ts          # GET /api/users (lista), POST /api/users (crear)
│   └── [id]/route.ts     # GET, PATCH, DELETE /api/users/:id
├── auth/
│   ├── login/route.ts    # POST /api/auth/login (retorna JWT)
│   └── refresh/route.ts  # POST /api/auth/refresh (renueva token)
```

### Autenticación
- JWT en header: `Authorization: Bearer <token>`
- Middleware: `requireAuth()` valida token y añade `req.user`
- Token expiry: 1h (access), 7d (refresh)

### Archivos Clave
- `middleware/errorHandler.ts`: Formato estándar de errores
- `middleware/rateLimiter.ts`: Config rate limiting
- `lib/zodSchemas.ts`: Schemas de validación reutilizables
```

---

### EJEMPLO 2: Módulo de IA

#### ❌ MAL
```markdown
## Módulo IA
Este módulo procesa texto con IA. Usa OpenAI API.
```

#### ✅ BIEN
```markdown
## Módulo IA - Procesamiento de Transcripciones

### Stack
- OpenAI API: GPT-4 Turbo (gpt-4-turbo-preview)
- Whisper API: whisper-1
- Rate limits: 500 req/min (tier 3)

### Flujo
1. Audio (Telegram) → `processAudio()` → Whisper transcription
2. Transcription → `extractEntities()` → GPT-4 extraction
3. Entities → `saveToDatabase()` → Prisma write

### Prompts
- Ubicación: `prompts/` (archivos separados por tipo)
- Versionado: Nombre archivo = `[tipo]-v[N].txt`
- Activo: Referenciado en `model-config.ts`

### Reglas
- ✅ SIEMPRE usar `retry` con backoff exponencial (max 3 intentos)
- ✅ SIEMPRE validar response con Zod antes de guardar
- ❌ NUNCA llamar OpenAI directamente, usar `openaiClient.ts`
- ⚠️ Max tokens: 4096 (input + output). Truncar si excede.

### Configuración
- `OPENAI_API_KEY`: En `.env`, NUNCA commitear
- `OPENAI_ORG_ID`: Organización, en `.env`
- Timeout: 60s (procesamiento puede demorar)

### Notas para IA
- ⚠️ GPT-4 Turbo NO soporta function calling legacy, usar `tools` parameter
- ⚠️ Whisper retorna "undefined" si audio < 0.1s, validar duración ANTES
- ⚠️ Costos: GPT-4 Turbo = $0.01/1K input tokens, monitorear uso en `logs/openai-usage.log`
```

---

## ANTI-PATRONES (EVITAR)

### 🚫 DESCRIPCIONES SIN VALOR
```markdown
❌ "Este archivo exporta funciones útiles"
✅ "Exporta `formatDate()` (ISO → DD/MM/YYYY) y `parseDate()` (locale-aware parser)"
```

### 🚫 REDUNDANCIA VERTICAL
```markdown
❌ En /proyecto/_CONTEXT.md: "Usamos PostgreSQL"
❌ En /proyecto/api/_CONTEXT.md: "Usamos PostgreSQL" <- REDUNDANTE
✅ En /proyecto/api/_CONTEXT.md: "Pool de conexiones: max 20, timeout 30s, config en `db.ts`"
```

### 🚫 INFORMACIÓN OBSOLETA
```markdown
❌ "Usamos React 16" <- Proyecto está en React 19
✅ Actualizar o agregar: "Migrado a React 19 (2025-01), usar hooks modernos"
```

### 🚫 EXPLICACIONES DE LO OBVIO
```markdown
❌ "package.json contiene las dependencias del proyecto"
✅ [No mencionar package.json a menos que tenga algo no estándar]
✅ "Scripts custom: `npm run db:migrate:prod` ejecuta migraciones en producción sin confirmación"
```

---

## MANTENIMIENTO

### Cuándo Actualizar
- Al agregar nueva dependencia crítica
- Al cambiar arquitectura/patrón del módulo
- Al deprecar funcionalidad
- Al descubrir bug crítico o gotcha

### Cómo Actualizar
1. Editar directamente `_CONTEXT.md`
2. Agregar nota de cambio al final:
   ```markdown
   ---
   **Última actualización:** 2025-01-15
   **Cambios:** Migración de axios a fetch nativo, actualizar todos los imports
   ```

---

## RESUMEN EJECUTIVO

### Un buen _CONTEXT.md debe:
1. ✅ Permitir a la IA trabajar SIN explorar código
2. ✅ Contener SOLO info técnica específica
3. ✅ Incluir restricciones imperativas (SIEMPRE/NUNCA)
4. ✅ Mencionar gotchas y errores comunes
5. ✅ Ser conciso (< 100 líneas idealmente)

### Un mal _CONTEXT.md:
1. ❌ Repite info de niveles superiores
2. ❌ Usa lenguaje vago ("maneja", "procesa", "gestiona")
3. ❌ NO incluye valores concretos (versiones, timeouts, limits)
4. ❌ Explica lo obvio
5. ❌ Es demasiado largo (> 300 líneas)

---

**Versión:** 1.0
**Fecha:** 2025-12-26
**Autor:** Sistema de Contexto Mateos
