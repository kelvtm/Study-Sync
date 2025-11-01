bash# === DEVELOPMENT ===
docker-compose -f docker-compose.pattern3.dev.yml up --build

# Access:

# Frontend: http://localhost:5173

# Backend: http://localhost:3000/api/health

# === PRODUCTION ===

# Build images

./scripts/build-prod.sh

# Check image sizes

docker images | grep studysync

# Run production

docker-compose -f docker-compose.pattern3.prod.yml up -d

# Check health

docker-compose -f docker-compose.pattern3.prod.yml ps

# Test

curl http://localhost/api/health
open http://localhost

# Scale backend

docker-compose -f docker-compose.pattern3.prod.yml up --scale backend=5 -d

# View logs

docker-compose -f docker-compose.pattern3.prod.yml logs -f backend

✅ Pattern 3 Benefits:

✅ Production-grade - Rate limiting, caching, load balancing
✅ Optimized images - Multi-stage builds, minimal size
✅ Security - Non-root users, security headers, tini init
✅ Scalable - Easy to scale backend instances
✅ Observable - Health checks, logging, metrics
✅ Flexible - Dev simple, prod powerful
✅ Redis ready - Session caching optional
✅ CI/CD ready - Build scripts, versioning
