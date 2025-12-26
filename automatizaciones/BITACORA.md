# BITÁCORA - Automatizaciones

Esta bitácora registra cambios en el procesamiento IA, nuevos workflows, cambios en prompts o modelos, y actualizaciones del microservicio de automatizaciones.

**Formato de entrada:**
```
## YYYY-MM-DD HH:mm | [automatizaciones] | [claude-code/manual/otro]

**Título de la actividad**
- **[Subcarpeta]:** Descripción de lo que se hizo (si aplica)
- Decisiones tomadas
- Próximos pasos (si los hay)
```

**Subcarpetas típicas:** [ia], [prisma], [src]

---

## 2025

### Diciembre

## 2025-12-26 15:00 | [automatizaciones] | [claude-code]

**Setup inicial del sistema de contexto**
- Creados archivos `_CONTEXT.md` en:
  - **[raíz]:** Arquitectura del microservicio Express, CRON jobs, webhooks
  - **[ia]:** Procesamiento GPT, prompts engineering, validación Zod
  - **[prisma]:** Source of truth del schema, proceso de migraciones
- Documentada decisión arquitectónica: ¿Por qué separado de Next.js? (procesamiento largo, CRON jobs, aislamiento)
- Documentado proceso de sincronización de schema Prisma
- Próximos pasos: Continuar optimización de prompts y workflows IA
