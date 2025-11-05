# 🚀 Guía de Inicio Rápido

## ⚡ Inicio Rápido (Recomendado - Docker)

### 1. Verificar Requisitos

```bash
# Verificar Node.js >= 20
node --version

# Verificar npm >= 10
npm --version

# Verificar Docker
docker --version
docker-compose --version
```

### 2. Verificar que el archivo .env esté configurado

El archivo `.env` ya está creado con las credenciales correctas. Verifica que contenga:

- `TELEGRAM_BOT_TOKEN`
- `OPENAI_API_KEY`
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY`, `R2_SECRET_KEY`, `R2_BUCKET_NAME`
- `DATABASE_URL`

### 3. Iniciar el Sistema con Docker

```bash
# Construir las imágenes
docker-compose build

# Iniciar los servicios
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### 4. Inicializar la Base de Datos

```bash
# Esperar a que PostgreSQL esté listo (unos 10-15 segundos)
sleep 15

# Ejecutar migraciones de Prisma
docker-compose exec next-app npx prisma migrate deploy
```

Si quieres crear la migración inicial:

```bash
docker-compose exec next-app npx prisma migrate dev --name init
```

### 5. Verificar que Todo Funcione

```bash
# Verificar estado de servicios
bash scripts/health-check.sh

# O manualmente:
curl http://localhost:8800/api/health
```

### 6. Probar el Bot

1. Abre Telegram
2. Busca tu bot (token: `8584619698:AAFrG_EyNpG7o18fEUrtQxOEnOX5ym0TnVQ`)
3. Envía `/start` para verificar que responde
4. Envía una nota de voz para transcribirla

---

## 🛠️ Comandos Útiles

### Ver Logs

```bash
# Todos los servicios
docker-compose logs -f

# Solo API
docker-compose logs -f next-app

# Solo Bot
docker-compose logs -f telegram-bot

# Solo PostgreSQL
docker-compose logs -f postgres-db
```

### Gestión de Servicios

```bash
# Detener servicios
docker-compose stop

# Reiniciar servicios
docker-compose restart

# Detener y eliminar contenedores
docker-compose down

# Detener y eliminar volúmenes (¡CUIDADO! Borra la DB)
docker-compose down -v
```

### Base de Datos

```bash
# Acceder a Prisma Studio (GUI para ver/editar datos)
docker-compose exec next-app npx prisma studio
# Luego abre http://localhost:5555

# Ejecutar migraciones
docker-compose exec next-app npx prisma migrate deploy

# Ver datos en PostgreSQL directamente
docker-compose exec postgres-db psql -U asistente -d transcripciones_db -c "SELECT * FROM transcripciones LIMIT 10;"

# Acceder a PostgreSQL shell
docker-compose exec postgres-db psql -U asistente -d transcripciones_db
```

### Rebuild (cuando cambias código)

```bash
# Rebuild y reiniciar
docker-compose up --build -d

# Rebuild solo un servicio
docker-compose up --build -d next-app
docker-compose up --build -d telegram-bot
```

---

## 🐛 Troubleshooting

### El bot no responde

```bash
# Ver logs del bot
docker-compose logs telegram-bot

# Verificar que el token sea correcto
echo $TELEGRAM_BOT_TOKEN

# Reiniciar el bot
docker-compose restart telegram-bot
```

### Error de conexión a la base de datos

```bash
# Verificar que PostgreSQL esté funcionando
docker-compose exec postgres-db pg_isready -U asistente

# Ver logs de PostgreSQL
docker-compose logs postgres-db

# Reiniciar PostgreSQL
docker-compose restart postgres-db
```

### Error en la transcripción

```bash
# Verificar API key de OpenAI
echo $OPENAI_API_KEY

# Ver logs de la API
docker-compose logs next-app

# Verificar que R2 esté configurado correctamente
echo $R2_ACCOUNT_ID
echo $R2_ACCESS_KEY
```

### Puerto ya en uso

Si los puertos 8800 o 8832 ya están en uso:

```bash
# Ver qué está usando los puertos
sudo lsof -i :8800
sudo lsof -i :8832

# Cambiar puertos en docker-compose.yml
# next-app: "8801:3000" en vez de "8800:3000"
# postgres-db: "8833:5432" en vez de "8832:5432"
```

### Problemas con permisos en WSL

Si estás en WSL y tienes problemas con permisos:

```bash
# Asegúrate de que Docker esté corriendo
sudo service docker start

# Si npm install falla, usa --no-bin-links
cd next-app && npm install --no-bin-links
cd ../telegram-bot && npm install --no-bin-links
```

---

## 📊 Monitoreo

### Estado de Contenedores

```bash
# Ver estado de todos los contenedores
docker-compose ps

# Ver uso de recursos
docker stats
```

### Health Checks

```bash
# API Health
curl http://localhost:8800/api/health

# PostgreSQL Health
docker-compose exec postgres-db pg_isready -U asistente
```

---

## 🧹 Limpieza

### Limpiar Contenedores y Volúmenes

```bash
# Detener y eliminar todo
docker-compose down -v

# Eliminar imágenes también
docker-compose down -v --rmi all

# Limpiar todo Docker (¡CUIDADO!)
docker system prune -a --volumes
```

---

## 📝 Desarrollo Local (sin Docker)

Si quieres desarrollar sin Docker:

### 1. Instalar PostgreSQL localmente

```bash
# Ubuntu/Debian
sudo apt install postgresql-15

# macOS
brew install postgresql@15
```

### 2. Crear Base de Datos

```bash
sudo -u postgres psql
CREATE DATABASE transcripciones_db;
CREATE USER asistente WITH PASSWORD 'n8npass';
GRANT ALL PRIVILEGES ON DATABASE transcripciones_db TO asistente;
\q
```

### 3. Actualizar .env

```bash
# Cambiar DATABASE_URL a localhost
DATABASE_URL="postgresql://asistente:n8npass@localhost:5432/transcripciones_db?schema=public"
```

### 4. Instalar Dependencias e Iniciar

```bash
# Next.js
cd next-app
npm install --no-bin-links
npx prisma migrate dev --name init
npm run dev

# En otra terminal - Telegram Bot
cd telegram-bot
npm install --no-bin-links
npm run dev
```

---

## 🎯 Próximos Pasos

Una vez que todo esté funcionando:

1. ✅ Envía una nota de voz al bot
2. ✅ Verifica que se transcribe correctamente
3. ✅ Revisa los logs para asegurarte de que no hay errores
4. ✅ Accede a Prisma Studio para ver los datos en la DB
5. 🔒 En producción, cambia las contraseñas y tokens
6. 📊 Configura monitoreo (opcional)
7. 🔄 Configura backups de la base de datos (opcional)

---

## 📚 Recursos Adicionales

- [Documentación de Next.js](https://nextjs.org/docs)
- [Documentación de Prisma](https://www.prisma.io/docs)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [OpenAI Whisper](https://platform.openai.com/docs/guides/speech-to-text)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)
