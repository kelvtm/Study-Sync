# Use official Node.js 24.3.0 image (Alpine = lightweight Linux but slim is more campatible for production server)
FROM node:24.3.0-slim AS builder

# Set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json to container first (for layer caching package)
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy application code COPY <source> <destination>
COPY . .

# Optional: Run tests during build
# RUN npm test

# ===== STAGE 2: Production =====
FROM node:24.3.0-slim AS production

# Add metadata labels
LABEL maintainer="kelvtmoni@gmail.com"
LABEL version="1.0"
LABEL description="StudySync Backend API"

# Create non-root user for security
# Create group
RUN groupadd -g 1001 nodejs

# Create user and add to group
RUN useradd -u 1001 -g 1001 -m -s /bin/bash nodejs
WORKDIR /app

# Copy only production dependencies from builder
COPY --from=builder /app/package*.json ./
RUN npm ci --production && npm cache clean --force

# Copy application code from builder
# Copy only source files (exclude node_modules from builder)
COPY --from=builder /app ./

# Change ownership to non-root user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

# Start application
CMD ["node", "server.js"]