# 📄 MATEOS - Resumen Ejecutivo (1 página)

## 🎯 ¿Qué es MATEOS?

**MATEOS** es un asistente personal inteligente que transforma notas de voz en información estructurada:

```
Nota de voz: "Teo, llamar a María mañana a las 3pm"
      ↓ (vía Telegram)
Whisper transcribe → "Teo, llamar a María mañana a las 3pm"
      ↓
GPT-4o-mini extrae → Tarea: "Llamar a María" (prioridad: MEDIA, vencimiento: mañana 3pm)
      ↓
PostgreSQL almacena → BD estructurada
      ↓
Usuario ve en NocoDB → Dashboard intuitivo
```

---

## 🏗️ Arquitectura (Ultra-Simplificada)

```
┌─────────────┐
│  Telegram   │ User
└──────┬──────┘
       │ 📱 (nota de voz)
       ▼
┌─────────────────────────┐
│    Telegram Bot         │ ← telegram-bot/
└──────┬──────────────────┘
       │ download + POST
       ▼
┌─────────────────────────────────────────────────────┐
│         Next.js API (next-app)         │ ← next-app/
│  • Valida entrada (Zod)                 │
│  • Sube audio a R2 (Cloudflare)         │
│  • Transcribe (OpenAI Whisper) ──────┐  │
│  • Guarda en BD (Prisma)             │  │
│  • Llama webhook ─────────────────┐  │  │
└──────────────────────────────────┼──┼──┘
                                   │  │
                                   │  └─→ Cloudflare R2 (Storage)
                                   │
                                   ▼
                    ┌──────────────────────────────────┐
                    │  Automatizaciones (Express)      │ ← automatizaciones/
                    │  • Detecta tipo (fuzzy match)    │
                    │  • Extrae entidades (GPT-4o-mini)│
                    │  • Guarda en BD (Prisma)         │
                    │  • Envía resumen a Telegram      │
                    └──────────────────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────────┐
                    │      PostgreSQL (2 BDs)          │
                    │  • transcripciones_db            │
                    │  • asistente_db                  │
                    └──────────────────────────────────┘
```

---

## 🛠️ Stack Tecnológico

| Componente | Tecnología | Por qué |
|-----------|-----------|---------|
| **API** | Next.js 15.5 | Moderno, rápido, TypeScript |
| **Backend** | Express.js | Ligero para procesamiento IA |
| **Base de Datos** | PostgreSQL 15 | Confiable, índices, ACID |
| **ORM** | Prisma 6.18 | Tipado, migraciones automáticas |
| **Transcripción** | OpenAI Whisper | Estado del arte (SOTA) |
| **Extracción IA** | GPT-4o-mini | Barato ($0.00015/req) pero poderoso |
| **Storage** | Cloudflare R2 | Gratis primeros 10GB, sin egress |
| **Matching** | Levenshtein | Fuzzy matching tolerante a errores |
| **Validación** | Zod | Schemas en TypeScript |
| **Logging** | Winston | Estructurado, JSON |
| **Containerización** | Docker Compose | Local = Producción |

---

## 📊 Bases de Datos

### transcripciones_db (next-app)
```
Transcripcion {
  id, texto, r2_url, r2_key,
  telegram_file_id (UNIQUE),
  estado (PROCESANDO|COMPLETADO|ERROR)
}
```
**Propósito**: Fuente de verdad de audios originales

### asistente_db (automatizaciones)
```
NotaAudio {
  transcripcionId (FK), tipoDetectado, ...
  ├─ 1:N Tarea { titulo, fechaVencimiento, prioridad }
  ├─ 1:N Registro { descripcion, duracionHoras, personas }
  ├─ 1:N Compromiso { titulo, personaNombre, yoMeComprometi }
  └─ 1:N IdeaCapturada { titulo, categoria, implementada }
}
```
**Propósito**: Datos enriquecidos y estructurados

---

## 🔄 Flujo de Datos (Timeline)

| Tiempo | Acción | Latencia |
|--------|--------|----------|
| T+0s | Usuario envía nota de voz | - |
| T+1s | Bot descarga audio | 1s |
| T+2-8s | API: upload R2 + transcribe (paralelo) | 6s |
| T+8-9s | Guarda en BD | 1s |
| T+9s | Webhook a automatizaciones (fire-and-forget) | async |
| T+9s | Retorna al usuario | **9 segundos total** ✅ |
| T+10-15s | [BACKGROUND] Procesamiento IA | N/A |
| T+15s | Entidades guardadas en BD | - |

---

## 💡 Decisiones Arquitectónicas Clave

1. **Dos BDs independientes** → Escalabilidad + resilencia
2. **Fire-and-forget webhook** → Latencia baja para usuario
3. **Polling Telegram** → Funciona localmente sin dominio
4. **Fuzzy matching** → Tolera errores de transcripción
5. **GPT-4o-mini** → Costo-beneficio óptimo
6. **Docker Compose** → Local = Producción
7. **Transacciones Prisma** → Consistencia garantizada

---

## 📈 Costos Mensuales (100 audios/día)

| Servicio | Costo |
|----------|-------|
| OpenAI Whisper | $3-5 |
| GPT-4o-mini | $0.45 |
| Cloudflare R2 | $0 (< 10GB) |
| PostgreSQL (self-hosted) | $0 |
| **Total** | **~$4-6/mes** ✅ |

---

## 📁 Estructura de Carpetas

```
mateos/
├─ next-app/              ← API principal (Next.js)
│  ├─ src/app/api/process-audio/route.ts  ⭐ ENTRY POINT
│  └─ prisma/schema.prisma
├─ automatizaciones/      ← Procesamiento IA (Express)
│  ├─ src/processor.ts    ⭐ ORQUESTADOR
│  ├─ src/ai-extractor.ts
│  └─ prisma/schema.prisma
├─ telegram-bot/          ← Bot (polling)
└─ docker-compose.yml     ← Orquestación
```

---

## 🚀 Cómo Empezar

```bash
# 1. Setup (15 min)
docker-compose build && docker-compose up -d
sleep 15
docker-compose exec next-app npx prisma migrate deploy
docker-compose exec automatizaciones npm run prisma:deploy

# 2. Verificar
curl http://localhost:1400/api/health  ✅
curl http://localhost:1410/health      ✅

# 3. Ver BD (opcional)
docker-compose exec next-app npx prisma studio
# Abre http://localhost:5555
```

---

## 📚 Documentación

| Documento | Contenido | Tiempo |
|-----------|----------|--------|
| `ONBOARDING.md` | Para nuevo desarrollador | 30 min |
| `DEVELOPER_GUIDE.md` | Cómo agregar features | 45 min |
| `ARCHITECTURE.md` | Diseño completo | 90 min |
| `DEPLOYMENT.md` | Cómo desplegar | 20 min |
| `DOCUMENTACION.md` | Índice de todo | 5 min |

**→ Empieza por `ONBOARDING.md`**

---

## 🎯 Próximas Fases

- **Fase 2**: Frontend web (dashboard)
- **Fase 3**: Vector DB (búsqueda semántica)
- **Fase 4**: Integraciones (Google Calendar, Slack, n8n)
- **Fase 5**: Machine Learning (fine-tuning, predicciones)

---

## ✨ Fortalezas del Proyecto

✅ Stack moderno (Next.js 15, TypeScript)
✅ Separación clara de responsabilidades
✅ Costo muy bajo (~$5/mes)
✅ Fácil de desplegar (Docker)
✅ Documentación exhaustiva
✅ Escalable para futuras fases

---

## 📞 Quick Links

- **Setup**: `QUICKSTART.md`
- **Desarrollo**: `DEVELOPER_GUIDE.md`
- **Arquitectura**: `ARCHITECTURE.md`
- **Documentación**: `DOCUMENTACION.md`
- **Onboarding**: `ONBOARDING.md`

---

**Versión**: 1.0.0
**Actualizado**: Diciembre 2025
**Estado**: Producción Ready ✅
