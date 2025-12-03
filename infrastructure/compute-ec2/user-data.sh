#!/bin/bash
set -e  # Exit on error

# Log everything to a file for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Study-Sync deployment at $(date)"

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get install -y docker.io

# Configure Docker
echo "Configuring Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Create directory structure
echo "Setting up application directory..."
mkdir -p /home/ubuntu/Study-Sync
chown ubuntu:ubuntu /home/ubuntu/Study-Sync

# Write .env file from template variable
echo "Creating environment file..."
cat << 'ENVEOF' > /home/ubuntu/Study-Sync/.env.prod
${env_content}
ENVEOF

# Set proper permissions
chown ubuntu:ubuntu /home/ubuntu/Study-Sync/.env.prod
chmod 600 /home/ubuntu/Study-Sync/.env.prod

# Wait for Docker to be fully ready
echo "Waiting for Docker to be ready..."
sleep 10

# Pull Docker images
echo "Pulling Docker images..."
sudo docker pull kelvtmoni/studysync-backend:latest
sudo docker pull kelvtmoni/studysync-frontend:latest

# Start backend container
echo "Starting backend container..."
sudo docker run -d \
  --name studysync-backend \
  --restart unless-stopped \
  --env-file /home/ubuntu/Study-Sync/.env.prod \
  -p 3000:3000 \
  kelvtmoni/studysync-backend:latest

# Wait for backend to start
echo "Waiting for backend to initialize..."
sleep 5

# Start frontend container
echo "Starting frontend container..."
sudo docker run -d \
  --name studysync-frontend \
  --restart unless-stopped \
  --link studysync-backend:backend \
  -p 8080:80 \
  kelvtmoni/studysync-frontend:latest

echo "Deployment complete at $(date)!"
echo "Backend running on port 3000"
echo "Frontend running on port 8080"

# Create a completion marker
touch /home/ubuntu/deployment-complete.txt
echo "Study-Sync deployed successfully at $(date)" > /home/ubuntu/deployment-complete.txt
chown ubuntu:ubuntu /home/ubuntu/deployment-complete.txt