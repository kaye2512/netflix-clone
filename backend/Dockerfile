# ========================================
# Optimized Multi-Stage Dockerfile
# Node.js Application (Bun runtime)
# ========================================

FROM oven/bun:1-alpine AS base

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /app

# ========================================
# Dependencies Stage
# ========================================
FROM base AS deps

# Copy package files
COPY package.json bun.lock ./

# Install production dependencies
RUN --mount=type=cache,target=/root/.bun,sharing=locked \
    bun install --frozen-lockfile --production

# Set proper ownership
RUN chown -R nodejs:nodejs /app

# ========================================
# Build Dependencies Stage
# ========================================
FROM base AS build-deps

# Copy package files
COPY package.json bun.lock ./

# Install all dependencies
RUN --mount=type=cache,target=/root/.bun,sharing=locked \
    bun install --frozen-lockfile

# Create necessary directories and set permissions
RUN mkdir -p /app/node_modules/.vite && \
    chown -R nodejs:nodejs /app

# ========================================
# Build Stage
# ========================================
FROM build-deps AS build

# Copy only necessary files for building (respects .dockerignore)
COPY --chown=nodejs:nodejs . .

# Build the application
RUN bun run build

# Set proper ownership
RUN chown -R nodejs:nodejs /app

# ========================================
# Development Stage
# ========================================
FROM build-deps AS development

# Set environment
ENV NODE_ENV=development

# Copy source files
COPY . .

# Ensure all directories have proper permissions
RUN mkdir -p /app/node_modules/.vite && \
    chown -R nodejs:nodejs /app && \
    chmod -R 755 /app

# Switch to non-root user
USER nodejs

# Expose ports
EXPOSE 8000

# Start development server
CMD ["bun", "run", "dev:docker"]

# ========================================
# Production Stage
# ========================================
FROM oven/bun:1-alpine AS production

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /app

# Set optimized environment variables
ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=256 --no-warnings"

# Copy production dependencies from deps stage
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=deps --chown=nodejs:nodejs /app/package.json ./
# Copy application source from build stage
COPY --from=build --chown=nodejs:nodejs /app/index.js ./

# Switch to non-root user for security
USER nodejs

# Expose port
EXPOSE 8000

# Start production server
CMD ["bun", "run", "start"]
