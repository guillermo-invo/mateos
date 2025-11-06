FROM node:20-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache \
    openssl \
    libc6-compat

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./
COPY tsconfig.json ./
COPY prisma ./prisma/

# Instalar dependencias
RUN npm ci

# Generar cliente Prisma
RUN npm run prisma:generate

# Copiar código fuente
COPY src ./src

# Compilar TypeScript
RUN npm run build

# Exponer puerto
EXPOSE 3100

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3100

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3100/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando de inicio
CMD ["node", "dist/index.js"]
