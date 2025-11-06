# Changelog - Next App

## [1.1.0] - 2025-11-06

### ✨ Added

#### Integración con Servicio de Automatizaciones

**Archivos modificados:**
- `src/app/api/process-audio/route.ts` - Agregado llamado a webhook de automatizaciones
- `src/lib/automatizaciones-webhook.ts` - **NUEVO** Helper para llamar webhook

**Funcionalidad:**

Después de transcribir exitosamente un audio, el sistema ahora:

1. Guarda la transcripción en `transcripciones_db` (como siempre)
2. ✨ **NUEVO:** Notifica al servicio de automatizaciones vía webhook
3. Automatizaciones procesa con IA para extraer: tareas, registros, compromisos, ideas

**Flujo completo:**

```
Usuario graba audio en Telegram
    ↓
telegram-webhook recibe el update
    ↓
Descarga audio de Telegram servers
    ↓
Llama a /api/process-audio con FormData
    ↓
process-audio:
  - Sube a R2
  - Transcribe con Whisper
  - Guarda en BD (transcripciones_db)
  - ✨ NUEVO: Llama webhook de automatizaciones
    ↓
Automatizaciones:
  - Detecta tipo (teo/juan/ide/compa)
  - Extrae entidades con GPT-4o-mini
  - Guarda en BD extendida (asistente_db)
    ↓
Usuario ve resultado en Telegram
Usuario ve entidades estructuradas en NocoDB
```

**Configuración requerida:**

Variable de entorno en `docker-compose.yml`:

```yaml
WEBHOOK_AUTOMATIZACIONES_URL: http://automatizaciones:3100/webhook
```

**Características:**

- ✅ **No bloqueante**: El webhook se llama en background, no afecta el tiempo de respuesta al usuario
- ✅ **Resiliente**: Si el webhook falla, no afecta el procesamiento principal
- ✅ **Opcional**: Si no está configurado `WEBHOOK_AUTOMATIZACIONES_URL`, simplemente no se llama
- ✅ **Timeout**: 10 segundos máximo para evitar cuelgues
- ✅ **Logging completo**: Todos los errores/éxitos se loguean

**Testing:**

```bash
# Verificar que la variable de entorno está configurada
docker-compose exec next-app env | grep WEBHOOK

# Ver logs después de enviar audio
docker-compose logs -f next-app
docker-compose logs -f automatizaciones

# Deberías ver:
# next-app: "Notificando a automatizaciones"
# next-app: "Webhook de automatizaciones exitoso"
# automatizaciones: "📨 Webhook recibido"
# automatizaciones: "✅ PROCESAMIENTO COMPLETADO"
```

**Rollback:**

Si necesitas deshabilitar temporalmente:

```bash
# Opción 1: Comentar la variable en docker-compose.yml
# WEBHOOK_AUTOMATIZACIONES_URL: http://automatizaciones:3100/webhook

# Opción 2: Detener servicio de automatizaciones
docker-compose stop automatizaciones

# El sistema seguirá funcionando normalmente, solo sin procesamiento IA
```

---

## [1.0.0] - 2025-11-04

### Initial Release

- Transcripción de audio con Whisper
- Subida a Cloudflare R2
- Integración con Telegram bot
- Base de datos PostgreSQL
