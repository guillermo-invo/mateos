# BITÁCORA - Next App

Esta bitácora registra desarrollo en el frontend (páginas, componentes), nuevos endpoints API, y refactors en el código Next.js.

**Formato de entrada:**
```
## YYYY-MM-DD HH:mm | [next-app] | [claude-code/manual/otro]

**Título de la actividad**
- **[Subcarpeta]:** Descripción de lo que se hizo (si aplica)
- Decisiones tomadas
- Próximos pasos (si los hay)
```

**Subcarpetas típicas:** [api], [components], [proyectos], [tareas], [lib], [pages]

---

## 2025

### Diciembre

## 2025-12-26 15:00 | [next-app] | [claude-code]

**Setup inicial del sistema de contexto**
- Creados archivos `_CONTEXT.md` en:
  - **[raíz]:** Contexto general de Next.js (App Router, RSC vs Client Components)
  - **[api]:** Arquitectura de API Routes, formato de respuestas, validación Zod
  - **[components]:** Patrones de componentes, HeroUI, Tailwind, dark mode
  - **[lib]:** Utilidades (Prisma, Winston, R2, Whisper)
- Documentadas reglas de negocio: límite de 3 proyectos en DOING, estados Kanban
- Próximos pasos: Continuar desarrollo de features con documentación actualizada
