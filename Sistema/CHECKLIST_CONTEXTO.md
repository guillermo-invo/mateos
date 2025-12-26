# CHECKLIST RÁPIDA - _CONTEXT.MD

Usa esta checklist antes de guardar o actualizar cualquier archivo `_CONTEXT.md`.

---

## ✅ ESPECIFICIDAD TÉCNICA

- [ ] Cada afirmación incluye detalles concretos (versiones, valores, timeouts)
- [ ] NO hay frases genéricas ("maneja datos", "procesa información")
- [ ] Menciono decisiones arquitectónicas específicas de este módulo
- [ ] Incluyo valores numéricos donde aplique (rate limits, timeouts, max sizes)

**Ejemplo:**
- ❌ "Este módulo maneja autenticación"
- ✅ "JWT con refresh tokens (access: 1h, refresh: 7d). Tokens en cookies httpOnly."

---

## ✅ UTILIDAD PARA IA

- [ ] La IA puede tomar decisiones SOLO leyendo este archivo
- [ ] Incluyo restricciones imperativas (SIEMPRE/NUNCA/OBLIGATORIO)
- [ ] Menciono gotchas y errores comunes
- [ ] Explico decisiones NO obvias (¿por qué X en lugar de Y?)
- [ ] Incluyo ejemplos de código si hay patterns específicos

**Ejemplo:**
- ❌ "Usar el patrón correcto"
- ✅ "SIEMPRE usar Repository pattern: Controller → Service → Repository"

---

## ✅ CERO REDUNDANCIA

- [ ] NO repito información del `_CONTEXT.md` del nivel superior (padre)
- [ ] Cada sección aporta información NUEVA y ESPECÍFICA de este módulo
- [ ] Si algo ya está en `/proyecto/_CONTEXT.md`, NO lo repito aquí
- [ ] Agrego SOLO lo que es único a esta carpeta/módulo

**Ejemplo:**
- Si en `/proyecto/_CONTEXT.md` dice "Usamos PostgreSQL 15"
- ❌ NO repetir: "Usamos PostgreSQL 15"
- ✅ SÍ agregar: "Pool de conexiones: max 20, timeout 30s, config en `db.ts`"

---

## ✅ CONCISIÓN

- [ ] Archivo tiene < 200 líneas (idealmente < 100)
- [ ] Sin introducciones innecesarias ("Este módulo es importante porque...")
- [ ] Uso bullets, NO párrafos largos
- [ ] Cada línea aporta valor técnico
- [ ] NO explico lo obvio (ej: "package.json contiene dependencias")

**Ejemplo:**
- ❌ "Este es un módulo muy importante que nos permite gestionar de manera eficiente..."
- ✅ "Rate limit: 100 req/min por IP. Redis cache con TTL 5min."

---

## ✅ ESTRUCTURA CLARA

- [ ] Uso la estructura estándar (ver GUIA_ESCRITURA_CONTEXTOS.md)
- [ ] Secciones en orden lógico
- [ ] Headers claros y descriptivos
- [ ] Archivos clave listados (máximo 5)
- [ ] Configuración documentada (variables ENV, archivos config)

---

## ✅ INFORMACIÓN ACTUAL

- [ ] Versiones de dependencias son correctas
- [ ] Decisiones arquitectónicas reflejan el estado ACTUAL
- [ ] NO hay información obsoleta
- [ ] Fecha de última actualización incluida

---

## ✅ CASOS ESPECIALES

### Si este módulo tiene integraciones externas:
- [ ] Documenté APIs/servicios externos
- [ ] Incluí rate limits y timeouts
- [ ] Mencioné dónde están las credenciales
- [ ] Expliqué error handling para fallas externas

### Si este módulo usa IA/ML:
- [ ] Especifiqué modelos y versiones
- [ ] Incluí prompts y su ubicación
- [ ] Documenté limits (tokens, costos)
- [ ] Mencioné retry logic y backoff

### Si este módulo tiene CRON/scheduled jobs:
- [ ] Documenté schedule (cron expression)
- [ ] Expliqué qué hace el job
- [ ] Mencioné dependencias con otros servicios
- [ ] Incluí cómo monitorear/debuggear

---

## ✅ NOTAS PARA IA (CRÍTICO)

- [ ] Incluí sección "Notas para IA"
- [ ] Mencioné errores comunes o gotchas
- [ ] Expliqué restricciones NO obvias
- [ ] Documenté side effects de cambios

**Ejemplo:**
- ✅ "⚠️ NO modificar `schema.prisma` sin actualizar `automatizaciones/prisma/schema.prisma` (source of truth)"
- ✅ "⚠️ Whisper retorna 'undefined' si audio < 0.1s, validar duración ANTES"

---

## ❌ ANTI-PATRONES (EVITAR)

- [ ] NO incluyo descripciones sin valor ("archivo útil", "función importante")
- [ ] NO repito info del README o documentación general
- [ ] NO uso lenguaje motivacional ("este módulo nos ayuda a...")
- [ ] NO escribo código completo (solo snippets si es necesario)
- [ ] NO explico conceptos generales (ej: qué es REST API)

---

## 🎯 TEST FINAL: "PRUEBA DE LA IA"

Imagina que la IA lee SOLO este `_CONTEXT.md` (sin explorar código):

1. **¿Puede saber qué stack/herramientas usar?** → SÍ/NO
2. **¿Puede identificar restricciones críticas?** → SÍ/NO
3. **¿Puede evitar errores comunes documentados?** → SÍ/NO
4. **¿Puede tomar decisiones arquitectónicas correctas?** → SÍ/NO
5. **¿Aprende algo NUEVO que NO está en el _CONTEXT.md padre?** → SÍ/NO

**Si alguna respuesta es NO, el _CONTEXT.md necesita mejoras.**

---

## 🚀 CHECKLIST EXPRESS (60 SEGUNDOS)

Versión ultra-rápida para revisiones:

1. [ ] ¿Incluye valores concretos? (versiones, timeouts, limits)
2. [ ] ¿Tiene restricciones SIEMPRE/NUNCA?
3. [ ] ¿NO repite info del nivel superior?
4. [ ] ¿Menciona gotchas/errores comunes?
5. [ ] ¿Es < 200 líneas?

**5/5 = ✅ Listo para guardar**
**< 5 = ⚠️ Revisar y mejorar**

---

**Versión:** 1.0
**Fecha:** 2025-12-26
**Autor:** Sistema de Contexto Mateos
