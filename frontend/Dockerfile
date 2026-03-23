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

