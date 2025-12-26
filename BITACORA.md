# BITÁCORA - Proyecto Mateos (Raíz)

Esta bitácora registra cambios arquitectónicos globales, actualizaciones de infraestructura (Docker, .env), y operaciones DevOps del proyecto.

**Formato de entrada:**
```
## YYYY-MM-DD HH:mm | [raiz] | [claude-code/manual/otro]

**Título de la actividad**
- Descripción de cambios
- Decisiones tomadas
- Próximos pasos (si los hay)
```

---

## 2025

### Diciembre

## 2025-12-26 15:00 | [raiz] | [claude-code]

**Inicialización del sistema de contexto y bitácora**
- Creada carpeta `Sistema/` con guías completas de documentación
- Creados 10 archivos `_CONTEXT.md` en carpetas relevantes:
  - next-app/ y subcarpetas (api/, components/, lib/)
  - automatizaciones/ y subcarpetas (ia/, prisma/)
  - telegram-bot/
  - scripts/db/ y scripts/python/
- Creados 4 archivos `BITACORA.md` en carpetas principales (raíz, next-app, automatizaciones, scripts)
- Decisión: Sistema de documentación en cascada (general → específico, cero redundancia)
- Próximos pasos: Validar sistema con primera sesión de trabajo real
