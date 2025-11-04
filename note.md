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

<!--
# VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

Resource Declaration:
resource is a Terraform keyword that defines an infrastructure component
"aws_vpc" is the resource type for an AWS Virtual Private Cloud
"main" is a logical name used to refer to this VPC within your Terraform code
VPC Configuration:
cidr_block: Defines the IP address range for the VPC using CIDR notation
enable_dns_hostnames: Boolean flag to enable/disable DNS hostnames in the VPC
enable_dns_support: Boolean flag to enable/disable DNS support in the VPC
Tags:
Creates an AWS tag for the VPC
Uses string interpolation (${}) to combine variables into a name
The format will be: [project_name]-[environment]-vpc
Variables:
The code references several variables (var.vpc_cidr, var.enable_dns_hostnames, etc.) which should be defined elsewhere in your Terraform configuration, typically in a variables.tf file.
This code specifically creates a Virtual Private Cloud (VPC) in AWS, which is a logically isolated section of the AWS cloud where you can launch AWS resources in a virtual network that you define. -->
