FROM node:20.11.0-alpine AS base

# ============================================
# Dependencies stage
# ============================================
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --only=production && \
    npm cache clean --force

# ============================================
# Builder stage
# ============================================
FROM base AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

# ============================================
# Runner stage
# ============================================
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 botuser

COPY --from=deps --chown=botuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=botuser:nodejs /app/dist ./dist
COPY --from=builder /app/package.json ./

# Create logs directory
RUN mkdir -p /app/logs && chown botuser:nodejs /app/logs

USER botuser

CMD ["node", "dist/index.js"]
