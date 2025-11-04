#!/bin/bash
set -e

# ============================================
# StudySync DockerHub Push Script
# ============================================
# Pushes Docker images to DockerHub with:
# - Authentication check
# - Version tagging
# - Latest tag
# - Progress display
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📤 StudySync DockerHub Push${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================
# Configuration
# ============================================
DOCKER_USERNAME="${DOCKER_USERNAME:-kelvtmoni}"
BACKEND_IMAGE="${DOCKER_USERNAME}/studysync-backend"
FRONTEND_IMAGE="${DOCKER_USERNAME}/studysync-frontend"

# Get version from build or argument
if [ -f ".build-version" ]; then
    source .build-version
    echo -e "${GREEN}📦 Using build version: ${VERSION}${NC}"
elif [ -n "$1" ]; then
    VERSION=$1
    echo -e "${GREEN}📦 Using provided version: ${VERSION}${NC}"
else
    VERSION="latest"
    echo -e "${YELLOW}⚠️  No version specified, using: ${VERSION}${NC}"
fi

echo ""

# ============================================
# Check Docker Login
# ============================================
echo -e "${BLUE}🔐 Checking DockerHub authentication...${NC}"

if ! docker info | grep -q "Username: ${DOCKER_USERNAME}"; then
    echo -e "${YELLOW}⚠️  Not logged in to DockerHub${NC}"
    
    if [ -n "$DOCKER_PASSWORD" ]; then
        echo -e "${BLUE}🔑 Logging in with credentials...${NC}"
        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    else
        echo -e "${RED}❌ DOCKER_PASSWORD not set${NC}"
        echo -e "${YELLOW}Please run: docker login${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Authenticated as: ${DOCKER_USERNAME}${NC}"
echo ""

# ============================================
# Verify Images Exist
# ============================================
echo -e "${BLUE}🔍 Verifying images exist...${NC}"

if ! docker images ${BACKEND_IMAGE}:${VERSION} | grep -q ${VERSION}; then
    echo -e "${RED}❌ Backend image not found: ${BACKEND_IMAGE}:${VERSION}${NC}"
    echo -e "${YELLOW}Run: ./scripts/docker-build.sh first${NC}"
    exit 1
fi

if ! docker images ${FRONTEND_IMAGE}:${VERSION} | grep -q ${VERSION}; then
    echo -e "${RED}❌ Frontend image not found: ${FRONTEND_IMAGE}:${VERSION}${NC}"
    echo -e "${YELLOW}Run: ./scripts/docker-build.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Both images found locally${NC}"
echo ""

# ============================================
# Push Backend
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📤 Pushing Backend Image${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}Pushing: ${BACKEND_IMAGE}:${VERSION}${NC}"
docker push ${BACKEND_IMAGE}:${VERSION}

if [ "${VERSION}" != "latest" ]; then
    echo -e "${YELLOW}Pushing: ${BACKEND_IMAGE}:latest${NC}"
    docker push ${BACKEND_IMAGE}:latest
fi

echo -e "${GREEN}✅ Backend pushed successfully${NC}"
echo ""

# ============================================
# Push Frontend
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📤 Pushing Frontend Image${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}Pushing: ${FRONTEND_IMAGE}:${VERSION}${NC}"
docker push ${FRONTEND_IMAGE}:${VERSION}

if [ "${VERSION}" != "latest" ]; then
    echo -e "${YELLOW}Pushing: ${FRONTEND_IMAGE}:latest${NC}"
    docker push ${FRONTEND_IMAGE}:latest
fi

echo -e "${GREEN}✅ Frontend pushed successfully${NC}"
echo ""

# ============================================
# Display Results
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Push Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}Pushed Images:${NC}"
echo "  Backend:  ${BACKEND_IMAGE}:${VERSION}"
echo "  Backend:  ${BACKEND_IMAGE}:latest"
echo "  Frontend: ${FRONTEND_IMAGE}:${VERSION}"
echo "  Frontend: ${FRONTEND_IMAGE}:latest"

echo ""
echo -e "${YELLOW}View on DockerHub:${NC}"
echo "  https://hub.docker.com/r/${DOCKER_USERNAME}/studysync-backend/tags"
echo "  https://hub.docker.com/r/${DOCKER_USERNAME}/studysync-frontend/tags"

echo ""
echo -e "${YELLOW}Pull commands:${NC}"
echo "  docker pull ${BACKEND_IMAGE}:${VERSION}"
echo "  docker pull ${FRONTEND_IMAGE}:${VERSION}"

echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Deploy to production: ./scripts/docker-deploy.sh ${VERSION}"
echo ""