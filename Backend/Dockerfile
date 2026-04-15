# ── ReservAqui Backend ─────────────────────────────────────────
# Build: docker compose build
# Run:   docker compose up
# ───────────────────────────────────────────────────────────────

FROM node:20-alpine

WORKDIR /app

# Install dependencies first (cache layer)
COPY package.json ./
RUN npm install

# Copy source code
COPY . .

EXPOSE 3000

# Dev mode with hot-reload
CMD ["npx", "ts-node-dev", "--respawn", "--transpile-only", "src/app.ts"]
