FROM oven/bun:1-alpine AS base
WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /app

# ========================================
# Dependencies Stage
# ========================================
FROM base AS deps
COPY package.json bun.lock ./
RUN --mount=type=cache,target=/root/.bun,sharing=locked \
    bun install --frozen-lockfile --production
RUN chown -R nodejs:nodejs /app

# ========================================
# Production Stage
# ========================================
FROM base AS production

ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=256 --no-warnings"

# Copier les prod dependencies
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=deps --chown=nodejs:nodejs /app/package.json ./

# Copier directement les sources — pas de COPY --from=build
COPY --chown=nodejs:nodejs . .

USER nodejs
EXPOSE 8000
CMD ["bun", "run", "start"]
