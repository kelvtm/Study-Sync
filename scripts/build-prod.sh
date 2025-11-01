#!/bin/bash
set -e

echo "🏗️  Building StudySync Pattern 3 Production Images..."

# Get version from package.json or git tag
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "latest")
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "📦 Version: $VERSION"
echo "📅 Build Date: $BUILD_DATE"
echo "🔖 VCS Ref: $VCS_REF"

# Build backend
echo ""
echo "🔨 Building backend..."
docker build \
  -f docker/Dockerfile.prod \
  -t studysync-backend:$VERSION \
  -t studysync-backend:latest \
  --build-arg BUILD_DATE=$BUILD_DATE \
  --build-arg VCS_REF=$VCS_REF \
  .

# Build frontend
echo ""
echo "🔨 Building frontend..."
docker build \
  -f docker/dockerfile.frontend.prod \
  -t studysync-frontend:$VERSION \
  -t studysync-frontend:latest \
  --build-arg BUILD_DATE=$BUILD_DATE \
  --build-arg VCS_REF=$VCS_REF \
  ./vue-project

echo ""
echo "✅ Build complete!"
echo ""
echo "📊 Image sizes:"
docker images | grep studysync

echo ""
echo "🚀 To run production stack:"
echo "   export VERSION=$VERSION"
echo "   docker-compose -f docker-compose.pattern3.prod.yml up -d"