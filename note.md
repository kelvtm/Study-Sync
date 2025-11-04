bash# === DEVELOPMENT ===
docker-compose -f docker-compose.pattern3.dev.yml up --build
mu note

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
┌─────────────────────────────────────────┐
│ EC2 Instance (98.94.8.178) │
│ │
│ ┌───────────────────────────────────┐ │
│ │ PM2 Process │ │
│ │ │ │
│ │ Node.js Backend (server.js) │ │
│ │ Port 3000 │ │
│ │ │ │
│ │ Serves: │ │
│ │ - /api/_ → Backend API │ │
│ │ - /_ → Vue.js dist/ (static)│ │
│ │ │ │
│ └───────────────────────────────────┘ │
│ │
│ MongoDB Atlas (external) │
└─────────────────────────────────────────┘

User → Port 80/443 → Backend serves everything

```

### **How it worked:**
1. Vue builds to `dist/` folder
2. Backend serves `dist/` as static files
3. Single PM2 process handles everything
4. No containers, just Node.js process

---

## **🟢 NEW DEPLOYMENT (Microservices with Docker - Best Practice)**
```

┌──────────────────────────────────────────────────────────────┐
│ EC2 Instance (98.94.8.178) │
│ │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Nginx Container (Frontend) │ │
│ │ Port 80/443 │ │
│ │ │ │
│ │ - Serves Vue.js static files │ │
│ │ - Reverse proxy to backend │ │
│ │ - SSL termination │ │
│ │ - Rate limiting │ │
│ │ - Caching │ │
│ └─────────────────┬──────────────────────────────────────┘ │
│ │ Proxy /api/\* requests │
│ ↓ │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ Backend Container (Node.js) │ │
│ │ Port 3000 (internal only) │ │
│ │ │ │
│ │ - API endpoints only │ │
│ │ - Socket.IO │ │
│ │ - Business logic │ │
│ └─────────────────┬──────────────────────────────────────┘ │
│ │ │
│ ↓ │
│ MongoDB Atlas (external) │
└──────────────────────────────────────────────────────────────┘

User → Nginx (80/443) → Backend (3000)
↓
Static files served directly
