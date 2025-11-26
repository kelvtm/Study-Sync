#!/bin/bash

# ============================================
# StudySync EC2 Bootstrap Script
# ============================================
# This script runs on first boot to setup the server
# Environment: ${environment}
# Project: ${project}
# ============================================

set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting StudySync Server Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment: ${environment}"
echo "Timestamp: $(date)"
echo ""

# ============================================
# Update System
# ============================================
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# ============================================
# Install Docker
# ============================================
echo ""
echo "🐳 Installing Docker..."

# Remove old versions
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Install dependencies
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

echo "✅ Docker installed: $(docker --version)"

# ============================================
# Install Nginx
# ============================================
echo ""
echo "🌐 Installing Nginx..."

apt-get install -y nginx

# Enable Nginx
systemctl enable nginx

echo "✅ Nginx installed: $(nginx -v 2>&1)"

# ============================================
# Install Certbot for SSL
# ============================================
echo ""
echo "🔒 Installing Certbot..."

apt-get install -y certbot python3-certbot-nginx

echo "✅ Certbot installed"

# ============================================
# Install Git
# ============================================
echo ""
echo "📥 Installing Git..."

apt-get install -y git

echo "✅ Git installed: $(git --version)"

# ============================================
# Install AWS CLI
# ============================================
echo ""
echo "☁️  Installing AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

echo "✅ AWS CLI installed: $(aws --version)"

# ============================================
# Install CloudWatch Agent (Optional)
# ============================================
echo ""
echo "📊 Installing CloudWatch Agent..."

wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

echo "✅ CloudWatch Agent installed"

# ============================================
# Create Application Directory
# ============================================
echo ""
echo "📁 Creating application directories..."

mkdir -p /home/ubuntu/Study-Sync
chown ubuntu:ubuntu /home/ubuntu/Study-Sync

# ============================================
# Configure Docker to Start on Boot
# ============================================
echo ""
echo "⚙️  Configuring services..."

# Create systemd service for Docker containers (placeholder)
cat > /etc/systemd/system/studysync-docker.service << 'EOF'
[Unit]
Description=StudySync Docker Containers
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=ubuntu
WorkingDirectory=/home/ubuntu/Study-Sync
ExecStart=/bin/bash -c 'docker ps'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable studysync-docker.service

# ============================================
# Setup Firewall (UFW)
# ============================================
echo ""
echo "🔥 Configuring firewall..."

apt-get install -y ufw

# Allow SSH, HTTP, HTTPS
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Enable UFW (non-interactive)
echo "y" | ufw enable

echo "✅ Firewall configured"

# ============================================
# Install Monitoring Tools
# ============================================
echo ""
echo "📈 Installing monitoring tools..."

apt-get install -y htop iotop nethogs

# ============================================
# Set Timezone
# ============================================
echo ""
echo "🕐 Setting timezone..."

timedatectl set-timezone UTC

# ============================================
# Create Swap File (if needed)
# ============================================
echo ""
echo "💾 Checking swap..."

if [ $(free | grep Swap | awk '{print $2}') -eq 0 ]; then
    echo "Creating 2GB swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✅ Swap created"
else
    echo "✅ Swap already exists"
fi

# ============================================
# Final System Info
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Server Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 System Information:"
echo "  OS: $(lsb_release -ds)"
echo "  Kernel: $(uname -r)"
echo "  Docker: $(docker --version)"
echo "  Nginx: $(nginx -v 2>&1)"
echo "  Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  Disk: $(df -h / | tail -1 | awk '{print $2}')"
echo ""
echo "🎉 Ready for deployment!"
echo ""

# Signal completion
touch /var/lib/cloud/instance/user-data-finished