# _CONTEXT.md - Telegram Bot

## PROPÓSITO

Servicio standalone Node.js que ejecuta un bot de Telegram para captura de notas de voz y comandos de texto. Interfaz principal de entrada rápida al sistema Mateos.

---

## STACK TÉCNICO ESPECÍFICO

- **Runtime:** Node.js 20+
- **Library:** node-telegram-bot-api 0.64-0.66
- **Logger:** Winston 3.11.0
- **TypeScript:** 5.x

---

## ARQUITECTURA Y DECISIONES

### Polling vs Webhook Mode

**Actual:** Polling mode

**Razón:**
- Más simple para desarrollo local
- NO requiere HTTPS ni dominio público
- Evita configuración de reverse proxy
- Suficiente para volumen de uso actual

**Alternativa (webhook mode):**
- Requiere HTTPS y URL pública
- Más eficiente (push vs pull)
- Considerar si escala significativamente

### Flujo de Procesamiento

```
Usuario envía nota de voz
  → Bot recibe update (polling)
  → Descarga audio de Telegram servers
  → Envía a Next.js API: POST /api/process-audio
  → Next.js procesa (Whisper + IA)
  → Bot recibe confirmación
  → Bot notifica al usuario
```

---

## ESTRUCTURA DE ARCHIVOS

```
src/
├── index.ts          [Bot principal - 8KB]
├── logger.ts         [Configuración Winston]
└── types.ts          [Tipos TypeScript]

logs/                 [Logs del bot]
├── error.log
└── combined.log
```

---

## COMANDOS SOPORTADOS

### Comandos de Usuario

#### `/start`
Mensaje de bienvenida y ayuda.

**Response:**
```
¡Hola! Soy el asistente Mateos.

Puedes enviarme:
- Notas de voz: las transcribiré y procesaré automáticamente
- Texto: lo guardaré como idea rápida

Comandos disponibles:
/help - Mostrar esta ayuda
/status - Estado del sistema
```

#### `/help`
Muestra ayuda y comandos disponibles (igual que `/start`).

#### `/status`
Verifica estado del sistema (DB, APIs).

**Response:**
```
Estado del sistema:
✅ Bot: Activo
✅ Base de datos: Conectada
✅ API Next.js: Disponible
```

### Mensajes de Voz

**Formato soportado:** OGG (formato por defecto de Telegram)

**Procesamiento:**
1. Bot descarga audio de Telegram servers
2. Envía buffer a `/api/process-audio`
3. API transcribe con Whisper
4. API extrae entidades con GPT
5. API guarda en DB
6. Bot notifica resultado al usuario

**Límites:**
- Max file size Telegram: 20MB
- Max duration Telegram: 10 minutos
- Min duration Whisper: 0.1s

### Mensajes de Texto

**Procesamiento:**
- Texto guardado como `Idea` en DB
- Clasificación básica por keywords (opcional)
- Confirmación al usuario

---

## REGLAS Y RESTRICCIONES

### Bot Token Security

#### ✅ SIEMPRE:
- Token en `.env`, NUNCA commitear
- Validar que token existe al inicio
- NO loggear token completo (solo primeros 6 chars)

```typescript
const token = process.env.TELEGRAM_BOT_TOKEN
if (!token) {
  throw new Error('TELEGRAM_BOT_TOKEN no definido en .env')
}

logger.info(`Bot iniciado con token: ${token.substring(0, 6)}...`)
```

#### ❌ NUNCA:
- Hardcodear token
- Exponer token en logs o errores
- Compartir token (revocar si se filtra)

### Error Handling

#### ✅ SIEMPRE:
- Try/catch en TODOS los event handlers
- Loggear errores con contexto (userId, messageId)
- Notificar al usuario si proceso falla
- NO crashear bot por error de un mensaje

```typescript
bot.on('voice', async (msg) => {
  try {
    await processVoiceMessage(msg)
  } catch (error) {
    logger.error('Error procesando nota de voz:', {
      error: error.message,
      userId: msg.from.id,
      messageId: msg.message_id,
    })

    await bot.sendMessage(
      msg.chat.id,
      '❌ Error procesando tu nota de voz. Intenta de nuevo.'
    )
  }
})
```

#### ❌ NUNCA:
- Dejar errores sin catch (crashea bot)
- Ignorar errores silenciosamente
- Enviar stack traces al usuario

### Rate Limiting

**Telegram API limits:**
- 30 mensajes/segundo por bot
- 20 mensajes/minuto por chat
- 1 req/segundo para `getMe` y similar

**Implementación:**
- NO necesario por ahora (volumen bajo)
- Considerar si escala: usar `bottleneck` library

---

## CONFIGURACIÓN

### Variables de Entorno (.env)

```bash
# Telegram
TELEGRAM_BOT_TOKEN="123456:ABC-DEF..."

# Next.js API
NEXT_API_URL="http://next-app:3000"  # Docker network
# o http://localhost:3000 (local dev)

# Logging
LOG_LEVEL=info  # debug | info | warn | error
```

### Docker Compose

**Service name:** `telegram-bot`
**Restart policy:** `unless-stopped`
**Depends on:** NO (independiente)
**Network:** `mateos-network` (para comunicarse con next-app)

---

## INTEGRACIONES

### Next.js API

**Endpoint:** `POST /api/process-audio`

**Payload:**
```typescript
{
  audioBuffer: Buffer,
  filename: string,
  userId: string,
  chatId: number,
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transcription": "...",
    "entities": {
      "ideas": [...],
      "tareas": [...]
    }
  }
}
```

---

## NOTAS PARA IA

### ⚠️ Telegram Bot API Limitations
- Polling mode tiene delay (1-3s)
- NO recibe updates mientras bot está offline
- Updates se pierden si > 24h offline

### ⚠️ File Download
```typescript
// Telegram retorna file_id, NO el archivo directamente
const fileId = msg.voice.file_id

// Descargar archivo
const fileLink = await bot.getFileLink(fileId)
const response = await fetch(fileLink)
const buffer = await response.buffer()
```

### ⚠️ Audio Format
- Telegram voice messages: OGG/OPUS codec
- Whisper soporta OGG directamente
- NO necesita conversión (enviar buffer directo)

### ⚠️ User Privacy
- NO almacenar username/nombre sin consentimiento
- Solo guardar chatId para notificaciones
- Cumplir GDPR si usuarios europeos

---

## ARCHIVOS CLAVE

- `src/index.ts`: Bot principal, event handlers
- `src/logger.ts`: Configuración Winston
- `logs/`: Logs persistentes

---

## TESTING

### Manual Testing
```bash
# Enviar mensaje al bot en Telegram
# Verificar logs
tail -f logs/combined.log
```

### Mocking
```typescript
// Mock bot.on() para tests unitarios
const mockBot = {
  on: jest.fn(),
  sendMessage: jest.fn(),
}
```

---

## PRÓXIMOS PASOS (Planificados)

- [ ] Implementar comandos de consulta (`/proyectos`, `/tareas`)
- [ ] Agregar botones inline (teclado interactivo)
- [ ] Migrar a webhook mode (si escala)
- [ ] Soportar imágenes (OCR con GPT-4 Vision)

---

**Última actualización:** 2025-12-26
**Versión:** 1.0
