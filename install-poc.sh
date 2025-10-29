#!/bin/bash
set -e

echo "=== ArgoCD Configuration Setup ==="
echo ""

# Create namespaces if they don't exist
echo "1. Creating namespaces..."
kubectl create namespace app1 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace app2 --dry-run=client -o yaml | kubectl apply -f -

# Backup existing configs (optional but recommended)
echo ""
echo "2. Backing up existing configurations..."
kubectl get configmap argocd-cm -n argocd -o yaml > argocd-cm-backup.yaml
kubectl get configmap argocd-rbac-cm -n argocd -o yaml > argocd-rbac-cm-backup.yaml
kubectl get secret argocd-secret -n argocd -o yaml > argocd-secret-backup.yaml
echo "   Backups saved to: argocd-*-backup.yaml"

# Patch ConfigMaps and Secret
echo ""
echo "3. Patching ArgoCD configurations..."
kubectl patch configmap argocd-cm -n argocd --patch-file argocd-cm-patch.yaml
kubectl patch configmap argocd-rbac-cm -n argocd --patch-file argocd-rbac-cm-patch.yaml
kubectl patch secret argocd-secret -n argocd --patch-file argocd-secret-patch.yaml

# Apply AppProjects
echo ""
echo "4. Creating AppProjects..."
kubectl apply -f argocd-projects.yaml

# Restart ArgoCD components
echo ""
echo "5. Restarting ArgoCD components..."
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-repo-server -n argocd

echo ""
echo "6. Waiting for rollout to complete..."
kubectl rollout status deployment argocd-server -n argocd --timeout=60s
kubectl rollout status deployment argocd-repo-server -n argocd --timeout=60s

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "👤 User Accounts Created:"
echo "   • dev1 (access to app1 namespace)"
echo "   • dev2 (access to app2 namespace)"
echo ""
echo "🔐 Default Password: password123 (CHANGE THIS!)"
echo ""
echo "📦 Repositories Configured:"
echo "   • repo-app1"
echo "   • repo-app2"
echo ""
echo "📝 Next Steps:"
echo "   1. Update repository URLs in argocd-cm-patch.yaml"
echo "   2. Change user passwords:"
echo "      argocd login <argocd-server>"
echo "      argocd account update-password --account dev1"
echo "      argocd account update-password --account dev2"
echo ""
echo "   3. Get admin password (if needed):"
echo "      kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
echo ""
