#!/bin/bash
# argocd-install.sh - Install ArgoCD on EKS

set -e

echo "🚀 Installing ArgoCD on EKS..."

# 1. Create ArgoCD namespace
echo "📦 Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD
echo "⬇️  Installing ArgoCD components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

echo "✅ ArgoCD installed successfully!"

# 4. Get initial admin password
echo ""
echo "🔑 Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ArgoCD Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 ArgoCD Credentials:"
echo "   Username: admin"
echo "   Password: ${ARGOCD_PASSWORD}"
echo ""
echo "🌐 To access ArgoCD UI:"
echo "   1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   2. Open: https://localhost:8080"
echo "   3. Login with credentials above"
echo ""
echo "💡 IMPORTANT: Change the admin password after first login!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"