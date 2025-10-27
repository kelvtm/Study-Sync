# Use official Node.js 24.3.0 image (Alpine = lightweight Linux but slim is more campatible for production server)
FROM node:24.3.0-slim

# Set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json to container first (for layer caching package)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code COPY <source> <destination>
COPY . .

# Expose port 3000
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]