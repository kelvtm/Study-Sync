#!/bin/bash

# ============================================
# StudySync ASG Instance Bootstrap Script
# ============================================
# Environment: ${environment}
# Project: ${project}
# ALB DNS: ${alb_dns_name}
# ============================================

set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 StudySync ASG Instance Bootstrap"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment: ${environment}"
echo "Instance ID: $(ec2-metadata --instance-id | cut -d: -f2 | tr -d ' ')"
echo "AZ: $(ec2-metadata --availability-zone | cut -d: -f2 | tr -d ' ')"
echo "Timestamp: $(date)"
echo ""

# ============================================
# Update System
# ============================================
echo "📦 Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# ============================================
# Install Docker
# ============================================
echo ""
echo "🐳 Installing Docker..."

apt-get install -y ca-certificates curl gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

echo "✅ Docker installed: $(docker --version)"

# ============================================
# Install CloudWatch Agent
# ============================================
echo ""
echo "📊 Installing CloudWatch Agent..."

wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "metrics": {
    "namespace": "StudySync/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [{"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/studysync/${environment}/user-data",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/studysync/${environment}/syslog",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "✅ CloudWatch Agent configured"

# ============================================
# Pull Docker Images
# ============================================
echo ""
echo "📥 Pulling Docker images from DockerHub..."

docker pull ${docker_backend}:latest
docker pull ${docker_frontend}:latest

echo "✅ Docker images pulled"

# ============================================
# Start Backend Container
# ============================================
echo ""
echo "🚀 Starting backend container..."

# Create .env file
echo "Creating .env file..."
cat > /home/ubuntu/studysync.env << 'EOF'
${env_content}
EOF

docker run -d \
  --name studysync-backend \
  --restart unless-stopped \
  -p ${backend_port}:3000 \
  --env-file /home/ubuntu/studysync.env \
  -e PORT=3000 \
  ${docker_backend}:latest

echo "✅ Backend container started"

# ============================================
# Start Frontend Container
# ============================================
echo ""
echo "🎨 Starting frontend container..."

docker run -d \
  --name studysync-frontend \
  --restart unless-stopped \
  --link studysync-backend:backend \
  -p ${frontend_port}:80 \
  ${docker_frontend}:latest

echo "✅ Frontend container started"

# ============================================
# Health Check
# ============================================
echo ""
echo "🏥 Running health checks..."

sleep 10

if curl -f http://localhost:${backend_port}/api/health > /dev/null 2>&1; then
    echo "✅ Backend health check passed"
else
    echo "❌ Backend health check failed"
    docker logs studysync-backend --tail 50
fi

if curl -f http://localhost:${frontend_port} > /dev/null 2>&1; then
    echo "✅ Frontend health check passed"
else
    echo "⚠️  Frontend health check failed"
    docker logs studysync-frontend --tail 50
fi

# ============================================
# Finalization
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Bootstrap Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔗 Load Balancer: ${alb_dns_name}"
echo "🎉 Instance ready to serve traffic!"

# Signal completion
touch /var/lib/cloud/instance/user-data-finished