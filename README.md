# 🎤 MVP Transcripción Telegram → PostgreSQL

Sistema de transcripción de notas de voz de Telegram usando Whisper AI y almacenamiento en PostgreSQL.

## 🚀 Stack Tecnológico

- **Runtime**: Node.js 20.11.0+
- **Frontend/API**: Next.js 15.5 (App Router)
- **Base de Datos**: PostgreSQL 15.5
- **ORM**: Prisma 6.18.0
- **Bot**: node-telegram-bot-api 0.66.0
- **Transcripción**: OpenAI Whisper API
- **Storage**: Cloudflare R2 (S3-compatible)
- **Containerización**: Docker + Docker Compose

## 📋 Requisitos Previos

- Node.js >= 20.0.0
- npm >= 10.0.0
- Docker Engine >= 24.0
- Docker Compose >= 2.23

## 🛠️ Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone <tu-repo>
cd chatbotag
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con tus credenciales reales
```

### 3. Instalar dependencias (desarrollo local)

```bash
# Next.js
cd next-app
npm install
cd ..

# Telegram Bot
cd telegram-bot
npm install
cd ..
```

### 4. Iniciar servicios con Docker

```bash
# Construir e iniciar todos los servicios
docker-compose up --build -d

# Ver logs
docker-compose logs -f

# Verificar estado
docker-compose ps
```

### 5. Ejecutar migraciones de Prisma

```bash
# Desde el host (con DATABASE_HOST_URL)
cd next-app
DATABASE_URL="postgresql://asistente:n8npass@localhost:8832/transcripciones_db" npx prisma migrate dev --name init

# O desde el contenedor
docker-compose exec next-app npx prisma migrate deploy
```

## 📂 Estructura del Proyecto

```
chatbotag/
├── next-app/              # Servicio API Next.js
│   ├── src/
│   │   ├── app/api/      # API Routes
│   │   ├── lib/          # Clientes (Prisma, R2, Whisper)
│   │   └── types/        # TypeScript types
│   ├── prisma/           # Schema y migraciones
│   └── Dockerfile
├── telegram-bot/         # Servicio Bot Telegram
│   ├── src/
│   └── Dockerfile
├── scripts/              # Scripts de utilidad
├── docker-compose.yml
└── .env
```

## 🔌 API Endpoints

### POST /api/process-audio

Procesa un archivo de audio y retorna la transcripción.

**Request:**
```
Content-Type: multipart/form-data

audio: File
metadata: {
  telegramFileId: string
  userId: number
  messageId: number
  duration?: number
}
```

**Response:**
```json
{
  "success": true,
  "transcriptionId": 123,
  "texto": "Transcripción del audio..."
}
```

### GET /api/health

Health check del servicio.

## 🧪 Testing

```bash
# Probar endpoint de health
curl http://localhost:8800/api/health

# Ver logs del bot
docker-compose logs -f telegram-bot

# Ver logs de la API
docker-compose logs -f next-app

# Acceder a Prisma Studio
cd next-app
DATABASE_URL="postgresql://asistente:n8npass@localhost:8832/transcripciones_db" npx prisma studio
```

## 🐳 Comandos Docker Útiles

```bash
# Reiniciar servicios
docker-compose restart

# Detener servicios
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v

# Ver logs de un servicio específico
docker-compose logs -f next-app
docker-compose logs -f telegram-bot

# Ejecutar comando en contenedor
docker-compose exec next-app sh
```

## 📊 Puertos

- **Next.js API**: 8800 → 3000
- **PostgreSQL**: 8832 → 5432

## 🔒 Seguridad

- No commitear el archivo `.env` (ya está en `.gitignore`)
- Rotar las credenciales de R2 y OpenAI regularmente
- Usar contraseñas fuertes para PostgreSQL en producción
- Implementar rate limiting en producción

## 📝 Notas

- El bot usa polling (no webhooks) para simplicidad en desarrollo
- Los audios se almacenan en R2 antes de ser procesados
- La transcripción usa el modelo `whisper-1` de OpenAI
- El idioma de transcripción está configurado en español

## 🐛 Troubleshooting

### El bot no responde

```bash
# Verificar logs del bot
docker-compose logs telegram-bot

# Verificar token de Telegram
echo $TELEGRAM_BOT_TOKEN
```

### Error de conexión a la base de datos

```bash
# Verificar estado de PostgreSQL
docker-compose exec postgres-db pg_isready -U asistente

# Ver logs de PostgreSQL
docker-compose logs postgres-db
```

### Error en la transcripción

```bash
# Verificar API key de OpenAI
echo $OPENAI_API_KEY

# Ver logs de Next.js
docker-compose logs next-app
```

## 📚 Recursos

- [Documentación de Next.js](https://nextjs.org/docs)
- [Documentación de Prisma](https://www.prisma.io/docs)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [OpenAI Whisper](https://platform.openai.com/docs/guides/speech-to-text)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)

## 📄 Licencia

MIT
