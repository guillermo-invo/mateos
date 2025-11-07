# Changelog de Cambios

## [2025-11-07] - Versión Actual

### 🆕 Nuevas Características
- **Configuración de NocoDB**: Se agregó documentación completa para conectar NocoDB a la base de datos `asistente_db` del proyecto Mateos.

### 🔄 Cambios Realizados

#### 1. Configuración de Base de Datos para NocoDB
- **Archivo creado**: [`NOCDB_CONFIG.md`](mateos/NOCDB_CONFIG.md)
- **Propósito**: Documentar los parámetros de conexión necesarios para que NocoDB se conecte a la base de datos PostgreSQL del proyecto Mateos a través de la red `involucra-network`.

#### 2. Parámetros de Conexión Documentados
- **Host**: `postgres-db` (nombre del servicio en Docker Compose)
- **Puerto**: `5432` (puerto interno del contenedor)
- **Usuario**: `asistente`
- **Contraseña**: `n8npass`
- **Base de Datos**: `asistente_db`
- **SSL**: No requerido para comunicación entre contenedores

#### 3. Requisitos de Red
- **Red Docker**: `involucra-network` (red externa compartida)
- **Visibilidad**: Los contenedores pueden comunicarse usando nombres de servicio
- **Seguridad**: La comunicación es interna y segura dentro de la red Docker

### 📋 Archivos Modificados
- [`docker-compose.yml`](mateos/docker-compose.yml): Se agregó el servicio `telegram-bot` (cambio previo)

### 📝 Notas Importantes
- La configuración permite a NocoDB acceder a la base de datos `asistente_db` utilizada por el servicio de automatizaciones
- No se requiere SSL para la conexión entre contenedores en la misma red Docker
- La documentación incluye ejemplos de configuración para contenedores NocoDB

### 🔗 URL de Conexión Completa
```
postgresql://asistente:n8npass@postgres-db:5432/asistente_db
```

---

## Historial de Versiones Anteriores

*Para versiones anteriores, consultar el historial de commits en el repositorio.*