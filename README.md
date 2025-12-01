[![CI/CD Pipeline](https://github.com/kelvtm/Study-Sync/actions/workflows/deploy.yml/badge.svg)](https://github.com/kelvtm/Study-Sync/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue.svg)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange.svg)](https://aws.amazon.com/eks/)

> A production-grade, cloud-native study collaboration platform demonstrating enterprise DevOps practices, microservices architecture, and modern infrastructure automation.

![Architecture Overview](docs/images/architecture-overview.png)

## 🎯 Overview

StudySync is a **real-time collaborative study platform** built with a focus on **DevOps excellence, cloud-native architecture, and production-grade reliability**. This project demonstrates end-to-end implementation of modern DevOps practices, from infrastructure provisioning to automated deployments and comprehensive monitoring.

### Key Features

- ✅ Real-time collaboration with WebSocket support
- ✅ Microservices architecture (Backend API + Frontend SPA)
- ✅ Multi-environment deployments (Dev, Staging, Production)
- ✅ Zero-downtime deployments with Canary strategy
- ✅ Automated CI/CD with GitHub Actions
- ✅ GitOps workflow with ArgoCD
- ✅ Comprehensive monitoring with Prometheus & Grafana
- ✅ Infrastructure as Code with Terraform & Helm
- ✅ Container orchestration on Kubernetes (EKS & KOPS)

---

## 🏗️ Architecture

### High-Level Architecture

![High-Level Architecture](vue-project/public/image.png)

## 🛠️ Tech Stack

### Infrastructure & Platform

| Category                    | Technologies                                          |
| --------------------------- | ----------------------------------------------------- |
| **Cloud Provider**          | AWS (EKS, EC2, VPC, ALB, CloudWatch, Secrets Manager) |
| **Container Orchestration** | Kubernetes 1.28+, Amazon EKS,                         |
| **Infrastructure as Code**  | Terraform, Helm Charts                                |
| **Service Discovery**       | AWS VPC CNI, CoreDNS                                  |
| **Load Balancing**          | AWS Application Load Balancer (ALB)                   |
| **Autoscaling**             | Horizontal Pod Autoscaler (HPA), Cluster Autoscaler   |

### DevOps & Automation

| Category                     | Technologies    |
| ---------------------------- | --------------- |
| **CI/CD**                    | GitHub Actions, |
| **GitOps**                   | ArgoCD          |
| **Container Registry**       | Docker Hub      |
| **Configuration Management** | Helm            |
| **Security Scanning**        | Trivy, Snyk     |

### Monitoring & Observability

| Category          | Technologies                              |
| ----------------- | ----------------------------------------- |
| **Metrics**       | Prometheus, CloudWatch Container Insights |
| **Visualization** | Grafana Dashboards                        |
| **Logging**       | Fluent Bit, CloudWatch Logs               |
| **Tracing**       | AWS X-Ray                                 |
| **Alerting**      | Prometheus Alertmanager, Slack Webhooks   |

### Application Stack

| Component       | Technology                     |
| --------------- | ------------------------------ |
| **Backend**     | Node.js, Express.js, Socket.io |
| **Frontend**    | Vue.js 3, Vite, TailwindCSS    |
| **Database**    | MongoDB Atlas                  |
| **API Gateway** | Nginx Ingress Controller       |

---

### Network Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (us-east-1a, us-east-1b)
│   ├── NAT Gateways
│   ├── Application Load Balancer
│   └── Bastion Host
├── Private Subnets (us-east-1a, us-east-1b)
│   ├── EKS Worker Nodes
│   └── ElastiCache (future)
└── Security Groups
    ├── ALB (80, 443)
    ├── Worker Nodes (All from ALB)
    └── Control Plane (443 from workers)
```

## 📊 Monitoring & Observability

### Prometheus Metrics

- **Application Metrics**: Request rate, latency, error rate (RED method)
- **Infrastructure Metrics**: CPU, memory, disk, network (USE method)
- **Custom Business Metrics**: Active users, study sessions, collaboration events

### Grafana Dashboards

- **Cluster Overview**: Node health, pod status, resource utilization
- **Application Performance**: Request throughput, response times, error rates
- **Database Metrics**: Query performance, connection pools
- **Cost Tracking**: Resource usage by namespace/team

## 🔐 Security

### Security Measures Implemented

✅ **Network Security**

- VPC isolation with public/private subnets
- Security groups with least-privilege rules
- Network policies for pod-to-pod communication
- WAF integration (planned)

✅ **Container Security**

- Trivy vulnerability scanning in CI pipeline
- Non-root containers
- Read-only root filesystem where possible
- Resource limits enforced

✅ **Secrets Management**

- AWS Secrets Manager for sensitive data
- Secrets Store CSI Driver for pod injection
- No secrets in Git (validated by pre-commit hooks)
- Automatic rotation enabled

✅ **Access Control**

- IAM Roles for Service Accounts (IRSA)
- RBAC policies for namespace isolation
- Pod Security Standards enforced
- Audit logging enabled

✅ **Compliance**

- Container image signing
- SAST/DAST in pipeline
- Dependency scanning
- Security patch automation

---
