FROM node:20-alpine AS backend-builder

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy backend deps
COPY backend/package*.json ./backend/
RUN npm ci --prefix backend --omit=dev --silent

# Copy backend source
COPY backend/ ./backend/

WORKDIR /app

CMD ["node", "index.js"]
