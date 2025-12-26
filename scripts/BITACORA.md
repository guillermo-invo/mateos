# BITÁCORA - Scripts

Esta bitácora registra nuevos scripts de automatización, cambios en migraciones SQL, mejoras en backups/health checks, y scripts Python.

**Formato de entrada:**
```
## YYYY-MM-DD HH:mm | [scripts] | [claude-code/manual/otro]

**Título de la actividad**
- **[Subcarpeta]:** Descripción de lo que se hizo (si aplica)
- Decisiones tomadas
- Próximos pasos (si los hay)
```

**Subcarpetas típicas:** [db], [python], [backup], [health-check]

---

## 2025

### Diciembre

## 2025-12-26 15:00 | [scripts] | [claude-code]

**Setup inicial del sistema de contexto**
- Creados archivos `_CONTEXT.md` en:
  - **[db]:** Convenciones SQL, migraciones manuales, sistema de tareas recurrentes
  - **[python]:** Script de generación de instancias recurrentes, conexión PostgreSQL
- Documentado sistema de tareas recurrentes (migrations/recurrentes/)
- Documentadas convenciones: snake_case, vistas con prefijo `v_`, funciones con verbo al inicio
- Próximos pasos: Implementar soft delete, auditoría, y archivado de datos antiguos
