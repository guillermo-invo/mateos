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

## 2025-12-26 21:18 | [docker] | [claude-code]

**Migración de Obsidian vault de Named Volume a Bind Mount**
- **[Razón]:** Facilitar acceso desde scripts sin necesidad de sudo
- **[Backup]:** Creado backup completo del vault (467 archivos, 23 MB)
  - Ubicación backup: `/home/azureuser/backups/obsidian_migration/vault_backup_20251226_211356.tar.gz`
- **[Migración]:** Datos copiados de volume a `/home/azureuser/obsidian/`
  - Ruta antigua: `/var/lib/docker/volumes/mateos_obsidianGfork/_data`
  - Ruta nueva: `/home/azureuser/obsidian/`
  - Permisos: `azureuser:azureuser` (sin necesidad de sudo)
- **[docker-compose.yml]:** Cambiado de named volume a bind mount
  - ANTES: `obsidianGfork:/vaults`
  - DESPUÉS: `/home/azureuser/obsidian:/vaults`
  - Volume `obsidianGfork` comentado en sección volumes (pendiente eliminación)
- **[Contenedor]:** Recreado y funcionando correctamente con bind mount
- **[Verificación]:** 467 archivos accesibles, Obsidian Sync funcionando
- **[Documentación]:** Actualizada documentación en `_CONTEXT.md` con nuevas rutas
- Próximos pasos: Monitorear estabilidad 24-48h antes de eliminar volume antiguo

## 2025-12-26 23:50 | [docker] | [claude-code]

**Verificación post-migración y corrección de permisos Obsidian**
- **[Obsidian Sync]:** Confirmado funcionamiento bidireccional (PC ↔ Cloud ↔ Server)
  - Archivos creados en PC se sincronizan correctamente a servidor
  - Archivos creados en servidor se sincronizan a PC y celular
- **[Problema resuelto]:** Permisos incorrectos impedían indexación en contenedor
  - **Causa:** PUID=1000 en contenedor, pero azureuser tiene UID=1001
  - **Solución:** Actualizado docker-compose.yml con PUID=1001, PGID=1001
  - Container recreado exitosamente
- **[Seguridad]:** Acceso web a Obsidian deshabilitado después de configuración
  - nginx location block `/obsidian/` comentado
  - Obsidian Sync sigue funcionando internamente sin exposición web
  - Acceso web solo para mantenimiento/configuración futura
- **[Estado final]:** Sistema completamente funcional
  - 467 archivos migrados y accesibles
  - Scripts pueden acceder sin sudo a `/home/azureuser/obsidian/ObsidianGfork/`
  - Sync activo 24/7
- **[Documentación]:** Actualizada BITACORA.md y _CONTEXT.md con estado final
- Próximos pasos: Scripts de generación automática de archivos markdown desde Mateos

## 2025-12-26 19:40 | [docker] | [claude-code]

**Implementación de Obsidian con KasmVNC y Obsidian Sync**
- **[docker-compose.yml]:** Agregado contenedor `mateos-obsidian` (LinuxServer Obsidian image)
- **[Volumes]:** Creado volume `obsidianGfork` para persistencia del vault
  - Ubicación: `/var/lib/docker/volumes/mateos_obsidianGfork/_data`
  - Montado en `/vaults` dentro del contenedor
- **[Configuración]:** Carpeta `./obsidian` montada en `/config` para configuración de KasmVNC
- **[Redes]:** Contenedor conectado a `app-network` e `involucra-network`
- **[Puertos]:** 1420:3000 (web), 1421:3001 (https)
- **[Obsidian Sync]:** Configurado y funcionando 24/7 para sincronización con PC/móvil
- **[Acceso web]:** Proxy reverso en nginx configurado en `/obsidian` (posteriormente deshabilitado por seguridad)
- **[Integración]:** Otras aplicaciones pueden acceder al vault montando el volume `obsidianGfork`
- Próximos pasos: Scripts de generación automática de archivos markdown desde Mateos

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
