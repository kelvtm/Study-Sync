sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Create directory and move .env file
mkdir -p /home/ubuntu/Study-Sync
sudo mv /tmp/.env.prod /home/ubuntu/Study-Sync/.env.prod
sudo chown ubuntu:ubuntu /home/ubuntu/Study-Sync/.env.prod
sudo chmod 600 /home/ubuntu/Study-Sync/.env.prod

# Pull images
docker pull kelvtmoni/studysync-backend:latest
docker pull kelvtmoni/studysync-frontend:latest
# Start backend
docker run -d \
  --name studysync-backend \
  --restart unless-stopped \
  --env-file /home/ubuntu/Study-Sync/.env.prod \
  -p 3000:3000 \
  kelvtmoni/studysync-backend:latest

# Start frontend
docker run -d \
  --name studysync-frontend \
  --restart unless-stopped \
  --link studysync-backend:backend \
  -p 8080:80 \
  kelvtmoni/studysync-frontend:latest

echo "Deployment complete! Backend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"