#!/bin/bash
set -e

# ============================================
# Trivy Security Scanner Installation
# ============================================
# Installs Trivy for Docker image vulnerability scanning
# Supports Ubuntu/Debian, RHEL/CentOS, and macOS
# ============================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔒 Installing Trivy Security Scanner${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if Trivy is already installed
if command -v trivy &> /dev/null; then
    INSTALLED_VERSION=$(trivy --version | head -n1 | awk '{print $2}')
    echo -e "${GREEN}✅ Trivy is already installed (version ${INSTALLED_VERSION})${NC}"
    echo ""
    read -p "Do you want to reinstall/update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping installation${NC}"
        exit 0
    fi
fi

# Detect OS
echo -e "${BLUE}🔍 Detecting operating system...${NC}"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        echo -e "${GREEN}Detected: $PRETTY_NAME${NC}"
    else
        echo -e "${RED}❌ Cannot detect Linux distribution${NC}"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo -e "${GREEN}Detected: macOS${NC}"
else
    echo -e "${RED}❌ Unsupported operating system: $OSTYPE${NC}"
    exit 1
fi

echo ""

# Install based on OS
case $OS in
    ubuntu|debian)
        echo -e "${BLUE}📦 Installing Trivy on Ubuntu/Debian...${NC}"
        
        # Add Trivy repository
        sudo apt-get update
        sudo apt-get install -y wget apt-transport-https gnupg lsb-release
        
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        
        sudo apt-get update
        sudo apt-get install -y trivy
        ;;
        
    rhel|centos|fedora)
        echo -e "${BLUE}📦 Installing Trivy on RHEL/CentOS/Fedora...${NC}"
        
        # Add Trivy repository
        cat << EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=0
enabled=1
EOF
        
        sudo yum -y update
        sudo yum -y install trivy
        ;;
        
    macos)
        echo -e "${BLUE}📦 Installing Trivy on macOS...${NC}"
        
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}❌ Homebrew not found${NC}"
            echo -e "${YELLOW}Install Homebrew first: https://brew.sh${NC}"
            exit 1
        fi
        
        brew install aquasecurity/trivy/trivy
        ;;
        
    *)
        echo -e "${RED}❌ Unsupported OS: $OS${NC}"
        echo ""
        echo -e "${YELLOW}Install manually:${NC}"
        echo "  https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
        exit 1
        ;;
esac

# Verify installation
echo ""
echo -e "${BLUE}✅ Verifying installation...${NC}"

if command -v trivy &> /dev/null; then
    VERSION=$(trivy --version | head -n1)
    echo -e "${GREEN}✅ Trivy installed successfully!${NC}"
    echo -e "${GREEN}Version: ${VERSION}${NC}"
    
    # Update vulnerability database
    echo ""
    echo -e "${BLUE}📥 Updating vulnerability database...${NC}"
    trivy image --download-db-only
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Installation Complete!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Usage examples:${NC}"
    echo "  # Scan a Docker image"
    echo "  trivy image kelvtmoni/studysync-backend:latest"
    echo ""
    echo "  # Scan with severity filter"
    echo "  trivy image --severity HIGH,CRITICAL kelvtmoni/studysync-backend:latest"
    echo ""
    echo "  # Scan and fail on vulnerabilities"
    echo "  trivy image --exit-code 1 --severity CRITICAL kelvtmoni/studysync-backend:latest"
    echo ""
else
    echo -e "${RED}❌ Installation failed${NC}"
    exit 1
fi