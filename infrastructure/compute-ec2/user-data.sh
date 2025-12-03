#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Study-Sync deployment with SSL at $(date)"

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get install -y docker.io nginx certbot python3-certbot-nginx

# Configure Docker
echo "Configuring Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Create directory structure
echo "Setting up application directory..."
mkdir -p /home/ubuntu/Study-Sync
chown ubuntu:ubuntu /home/ubuntu/Study-Sync

# Write .env file
echo "Creating environment file..."
cat << 'ENVEOF' > /home/ubuntu/Study-Sync/.env.prod
${env_content}
ENVEOF

chown ubuntu:ubuntu /home/ubuntu/Study-Sync/.env.prod
chmod 600 /home/ubuntu/Study-Sync/.env.prod

# Wait for Docker
echo "Waiting for Docker to be ready..."
sleep 10

# Pull Docker images
echo "Pulling Docker images..."
sudo docker pull kelvtmoni/studysync-backend:latest
sudo docker pull kelvtmoni/studysync-frontend:latest

# Start backend
echo "Starting backend container..."
sudo docker run -d \
  --name studysync-backend \
  --restart unless-stopped \
  --env-file /home/ubuntu/Study-Sync/.env.prod \
  -p 3000:3000 \
  kelvtmoni/studysync-backend:latest

sleep 5

# Start frontend
echo "Starting frontend container..."
sudo docker run -d \
  --name studysync-frontend \
  --restart unless-stopped \
  --link studysync-backend:backend \
  -p 8080:80 \
  kelvtmoni/studysync-frontend:latest

# Configure Nginx
echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/${domain_name} << 'NGINXCONF'
server {
    listen 80;
    server_name ${domain_name} www.${domain_name};

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINXCONF

# Enable site
ln -sf /etc/nginx/sites-available/${domain_name} /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
nginx -t
systemctl reload nginx

# Get SSL certificate (DNS must be propagated first)
echo "Waiting 30 seconds before attempting SSL certificate..."
sleep 30
echo "Getting SSL certificate..."
certbot --nginx -d ${domain_name} -d www.${domain_name} --non-interactive --agree-tos -m admin@${domain_name} --redirect

echo "Deployment complete at $(date)!"
echo "Access your app at: http://${domain_name}"
echo "Backend API: http://${domain_name}/api"

touch /home/ubuntu/deployment-complete.txt
echo "Study-Sync deployed successfully at $(date)" > /home/ubuntu/deployment-complete.txt
chown ubuntu:ubuntu /home/ubuntu/deployment-complete.txt