#!/bin/bash
set -e

# ============================================
# StudySync Docker Build Script
# ============================================
# Builds production Docker images with:
# - Semantic versioning
# - Build metadata
# - Multi-tagging (version + latest)
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🏗️  StudySync Docker Build${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================
# Configuration
# ============================================
DOCKER_USERNAME="${DOCKER_USERNAME:-kelvtmoni}"
BACKEND_IMAGE="${DOCKER_USERNAME}/studysync-backend"
FRONTEND_IMAGE="${DOCKER_USERNAME}/studysync-frontend"

# ============================================
# Get Version Information
# ============================================
# Try to get version from git tag, fallback to package.json, fallback to BUILD_NUMBER, fallback to latest
if [ -n "$BUILD_NUMBER" ]; then
    VERSION="v1.0.${BUILD_NUMBER}"
    echo -e "${GREEN}📦 Using Jenkins Build Number: ${VERSION}${NC}"
elif git describe --tags --exact-match 2>/dev/null; then
    VERSION=$(git describe --tags --exact-match)
    echo -e "${GREEN}📦 Using Git Tag: ${VERSION}${NC}"
elif [ -f "package.json" ]; then
    VERSION="v$(node -p "require('./package.json').version")"
    echo -e "${GREEN}📦 Using package.json Version: ${VERSION}${NC}"
else
    VERSION="latest"
    echo -e "${YELLOW}⚠️  No version found, using: ${VERSION}${NC}"
fi

# Get build metadata
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo -e "${GREEN}📅 Build Date: ${BUILD_DATE}${NC}"
echo -e "${GREEN}🔖 Git Commit: ${VCS_REF}${NC}"
echo -e "${GREEN}🐳 Docker Username: ${DOCKER_USERNAME}${NC}"
echo ""

# ============================================
# Build Backend
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔨 Building Backend Image${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

docker build \
  --file docker/Dockerfile.prod \
  --tag ${BACKEND_IMAGE}:${VERSION} \
  --tag ${BACKEND_IMAGE}:latest \
  --build-arg BUILD_DATE=${BUILD_DATE} \
  --build-arg VCS_REF=${VCS_REF} \
  --build-arg VERSION=${VERSION} \
  --progress=plain \
  .

echo -e "${GREEN}✅ Backend image built successfully${NC}"
echo ""

# ============================================
# Build Frontend
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔨 Building Frontend Image${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

docker build \
  --file docker/dockerfile.frontend.prod \
  --tag ${FRONTEND_IMAGE}:${VERSION} \
  --tag ${FRONTEND_IMAGE}:latest \
  --build-arg BUILD_DATE=${BUILD_DATE} \
  --build-arg VCS_REF=${VCS_REF} \
  --build-arg VERSION=${VERSION} \
  --progress=plain \
  ./vue-project

echo -e "${GREEN}✅ Frontend image built successfully${NC}"
echo ""

# ============================================
# Display Results
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Build Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}Built Images:${NC}"
docker images | grep -E "(REPOSITORY|studysync)" | head -5

echo ""
echo -e "${GREEN}Image Sizes:${NC}"
echo "Backend:  $(docker images ${BACKEND_IMAGE}:${VERSION} --format '{{.Size}}')"
echo "Frontend: $(docker images ${FRONTEND_IMAGE}:${VERSION} --format '{{.Size}}')"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Build Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test images locally:"
echo "     docker run -d --name backend-test -p 3000:3000 ${BACKEND_IMAGE}:${VERSION}"
echo ""
echo "  2. Push to DockerHub:"
echo "     ./scripts/docker-push.sh"
echo ""
echo "  3. Deploy to production:"
echo "     ./scripts/docker-deploy.sh ${VERSION}"
echo ""

# Export version for use in other scripts
echo "VERSION=${VERSION}" > .build-version