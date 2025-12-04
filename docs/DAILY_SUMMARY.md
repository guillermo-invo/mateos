# 📊 Resumen Diario Automático

## 🎯 Qué es

El servicio de automatizaciones ahora envía **automáticamente** un resumen diario por Telegram con:

- ✅ **Registros**: Lo que hiciste en el día
- 📋 **Tareas**: Tareas pendientes que creaste hoy
- 🤝 **Compromisos**: Compromisos asumidos o recibidos
- 💡 **Ideas**: Ideas que capturaste

El resumen se envía **todos los días a las 8:00 PM** (configurable).

---

## ⚙️ Configuración

### 1. Obtener tu Chat ID de Telegram

**Opción A: Ver logs del bot**

```bash
# Envía cualquier mensaje a tu bot
# Luego mira los logs
docker-compose logs telegram-bot | grep "chat"

# O en automatizaciones
docker-compose logs automatizaciones | grep "chat"
```

**Opción B: Usar la API de Telegram**

```bash
# Envía /start a tu bot
# Luego ejecuta:
curl https://api.telegram.org/bot<TU_TOKEN>/getUpdates

# Busca "chat":{"id":123456789}
# Ese número es tu CHAT_ID
```

### 2. Configurar Variables de Entorno

Edita tu archivo `.env`:

```bash
# Chat ID (reemplaza con el tuyo)
TELEGRAM_CHAT_ID=123456789

# Horario del resumen (formato cron)
# 0 20 * * * = 8:00 PM todos los días
DAILY_SUMMARY_TIME="0 20 * * *"

# Usar IA para resumen más natural
USE_AI_SUMMARY=true

# Timezone (importante!)
TZ=America/Montevideo
```

### 3. Reiniciar Servicio

```bash
docker-compose restart automatizaciones

# Ver logs para confirmar
docker-compose logs -f automatizaciones
```

Deberías ver:

```
✅ Chat ID configurado: 123456789
⏰ Horario de resumen: 0 20 * * * (a las 20:00 todos los días)
🧠 Usar IA: Sí
✅ Resumen diario programado
```

---

## 🕐 Formatos de Horario (Cron)

El horario se configura con formato cron: `minuto hora día mes día_semana`

### Ejemplos Comunes

| Horario | Cron Expression | Descripción |
|---------|-----------------|-------------|
| 8:00 PM todos los días | `0 20 * * *` | Por defecto |
| 9:00 PM todos los días | `0 21 * * *` | Una hora más tarde |
| 7:00 PM todos los días | `0 19 * * *` | Una hora antes |
| 12:00 PM lun-vie | `0 12 * * 1-5` | Mediodía días de semana |
| 6:00 PM sábados | `0 18 * * 6` | Solo sábados |
| 10:00 AM domingos | `0 10 * * 0` | Solo domingos |

### Día de Semana

- 0 = Domingo
- 1 = Lunes
- 2 = Martes
- 3 = Miércoles
- 4 = Jueves
- 5 = Viernes
- 6 = Sábado

---

## 🧠 Resumen con IA vs Simple

### Con IA (Recomendado)

```env
USE_AI_SUMMARY=true
```

Genera un resumen **natural y conversacional**:

```
¡Hola! 👋

Hoy fue un día productivo. Trabajaste 5 horas en el proyecto X junto con Pedro y María, y completaste la reunión con el cliente. ¡Bien hecho! 💪

Tienes 3 tareas pendientes para mañana:
🔴 Llamar a cliente (urgente)
🟠 Preparar presentación (alta prioridad)
🟡 Revisar documentación

También asumiste un compromiso con Juan para entregar el reporte el viernes. Asegúrate de tenerlo listo! 📅

Por último, capturaste 2 ideas interesantes:
💡 Dashboard de métricas
💡 Automatizar reportes semanales

¡Sigue así! 🚀
```

### Sin IA (Simple)

```env
USE_AI_SUMMARY=false
```

Genera un resumen **estructurado en texto plano**:

```
📅 Resumen del Día - miércoles, 6 de noviembre de 2024

✅ LO QUE HICISTE HOY (2)
━━━━━━━━━━━━━━━━━━━━
1. Trabajé en proyecto X (5h) con Pedro, María
2. Reunión con cliente (2h)

📋 TAREAS PENDIENTES (3)
━━━━━━━━━━━━━━━━━━━━
1. 🔴 Llamar a cliente - vence 07/11/2024
2. 🟠 Preparar presentación
3. 🟡 Revisar documentación

🤝 COMPROMISOS (1)
━━━━━━━━━━━━━━━━━━━━
1. Entregar reporte (yo me comprometí) - para 08/11/2024

💡 IDEAS (2)
━━━━━━━━━━━━━━━━━━━━
1. Dashboard de métricas [innovación]
2. Automatizar reportes semanales [mejora]
```

---

## 🧪 Probar Manualmente

Para recibir el resumen **ahora mismo** (sin esperar a las 8 PM):

```bash
curl -X POST http://localhost:1410/test/daily-summary
```

O desde fuera del servidor:

```bash
curl -X POST http://tu-servidor:1410/test/daily-summary
```

Deberías recibir el resumen por Telegram en unos segundos.

---

## 📋 Qué se Incluye en el Resumen

El resumen muestra **solo las actividades del día actual** (de 00:00 a 23:59).

### Registros (lo que hiciste)

- Todas las actividades con keyword "Juan" creadas hoy
- Incluye: duración, proyecto, personas involucradas

### Tareas (pendientes)

- Tareas con keyword "Teo" creadas hoy
- Solo las que están **pendientes** (no completadas)
- Ordenadas por prioridad (Urgente → Alta → Media → Baja)

### Compromisos (activos)

- Compromisos con keyword "Compa" creados hoy
- Solo los que **no están cumplidos**
- Muestra quién se comprometió (tú u otra persona)

### Ideas (capturadas)

- Ideas con keyword "Ide" creadas hoy
- Incluye categoría si está especificada

---

## ⏰ Cómo Funciona

### Flujo Automático

```
8:00 PM (hora configurada)
    ↓
Scheduler se activa (node-cron)
    ↓
Consulta BD: registros, tareas, compromisos, ideas del día
    ↓
Si hay datos:
  ↓
  Genera resumen (con IA o simple)
  ↓
  Envía por Telegram al CHAT_ID configurado
    ↓
Si no hay datos:
  ↓
  Envía mensaje: "No registraste actividades hoy"
```

### Logs que Verás

```
⏰ CRON JOB: Ejecutando resumen diario...
📊 Consultando datos del 06/11/2024...
✅ Datos obtenidos: 2 registros, 3 tareas, 1 compromiso, 2 ideas
🧠 Generando resumen con IA...
✅ Resumen IA generado
✅ Mensaje enviado a chat 123456789
✅ CRON JOB: Resumen diario completado
```

---

## 🔧 Troubleshooting

### No recibo el resumen

**1. Verificar Chat ID:**

```bash
docker-compose exec automatizaciones env | grep TELEGRAM_CHAT_ID
```

Si está vacío o incorrecto, actualiza `.env` y reinicia.

**2. Verificar Token del Bot:**

```bash
docker-compose exec automatizaciones env | grep TELEGRAM_BOT_TOKEN
```

**3. Ver logs del scheduler:**

```bash
docker-compose logs automatizaciones | grep -i "scheduler\|cron\|resumen"
```

Si ves:
- `⚠️ TELEGRAM_CHAT_ID no configurado` → Falta configurar
- `❌ Error inicializando bot` → Token inválido
- `✅ Resumen diario programado` → Todo OK

### El horario no coincide

Verifica la zona horaria:

```bash
docker-compose exec automatizaciones date
```

Si muestra hora incorrecta, agrega en `docker-compose.yml`:

```yaml
environment:
  TZ: America/Montevideo
```

Y reinicia:

```bash
docker-compose restart automatizaciones
```

### Resumen vacío

Si todos los días dice "No registraste actividades":

1. Verifica que estás usando las keywords: **Teo, Juan, Ide, Compa**
2. Revisa la BD:

```bash
docker-compose exec postgres-db psql -U asistente -d asistente_db -c "
  SELECT
    (SELECT COUNT(*) FROM registros WHERE DATE(created_at) = CURRENT_DATE) as registros,
    (SELECT COUNT(*) FROM tareas WHERE DATE(created_at) = CURRENT_DATE) as tareas,
    (SELECT COUNT(*) FROM compromisos WHERE DATE(created_at) = CURRENT_DATE) as compromisos,
    (SELECT COUNT(*) FROM ideas WHERE DATE(created_at) = CURRENT_DATE) as ideas;
"
```

### Error de IA

Si el resumen con IA falla, automáticamente hace fallback a resumen simple.

Ver logs:

```bash
docker-compose logs automatizaciones | grep "❌"
```

Si ves errores de OpenAI, verifica:
- `OPENAI_API_KEY` esté configurado
- Tengas créditos en tu cuenta de OpenAI
- La API key sea válida

---

## 🔄 Desactivar Resumen Automático

Si quieres detener los resúmenes automáticos:

**Opción 1: Borrar Chat ID**

```env
# .env
TELEGRAM_CHAT_ID=
```

```bash
docker-compose restart automatizaciones
```

**Opción 2: Detener el servicio**

```bash
docker-compose stop automatizaciones
```

El resto del sistema (transcripciones) seguirá funcionando.

---

## 🎯 Próximas Mejoras (Futuras)

- [ ] Múltiples usuarios (varios CHAT_IDs)
- [ ] Resumen semanal (domingos)
- [ ] Resumen mensual
- [ ] Gráficas de productividad
- [ ] Comparación día a día
- [ ] Recordatorios de tareas pendientes

---

## 📞 Comandos Útiles

```bash
# Ver próxima ejecución del cron
docker-compose logs automatizaciones | grep "Resumen diario programado"

# Ejecutar resumen manual
curl -X POST http://localhost:1410/test/daily-summary

# Ver logs en tiempo real
docker-compose logs -f automatizaciones

# Reiniciar scheduler
docker-compose restart automatizaciones

# Verificar variables de entorno
docker-compose exec automatizaciones env | grep -E "TELEGRAM|DAILY|TZ"
```

---

**¡Disfruta de tus resúmenes diarios automáticos!** 📊✨
