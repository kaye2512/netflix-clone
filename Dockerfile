# ─────────────────────────────────────────────
# Stage 1: Build frontend (React + Vite)
# ─────────────────────────────────────────────
FROM node:20-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy frontend deps first (layer cache)
COPY frontend/package*.json ./
RUN npm ci --silent

# Copy source and build
COPY frontend/ .
RUN npm run build


# ─────────────────────────────────────────────
# Stage 2: Production image (Node.js backend)
# The backend serves the frontend static files
# ─────────────────────────────────────────────
FROM node:20-alpine AS production

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy backend deps
COPY backend/package*.json ./backend/
RUN npm ci --prefix backend --omit=dev --silent

# Copy backend source
COPY backend/ ./backend/

# Copy built frontend from stage 1
# The backend serves frontend/dist in production
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

# Copy root package.json (needed by backend path resolution)
COPY package.json ./

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

WORKDIR /app/backend

# Health check: verify the API responds
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:${SERVER_PORT:-8000}/api/v1/health || exit 1

EXPOSE 8000

ENV NODE_ENV=production

CMD ["node", "index.js"]
