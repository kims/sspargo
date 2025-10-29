kubectl create namespace dev1 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev2 --dry-run=client -o yaml | kubectl apply -f -
kubectl patch configmap argocd-cm -n argocd --patch-file ConfigMap.argocd-cm-patch.yaml
kubectl patch configmap argocd-rbac-cm -n argocd --patch-file ConfigMap.argocd-rbac-cm-patch.yaml
kubectl apply -f AppProjects.app-project.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
ARGOCD_SERVER="localhost:8080"
ADMIN_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
argocd login $ARGOCD_SERVER --username admin --password "$ADMIN_PASSWORD" --insecure


HASH=$(htpasswd -bnBC 10 "" "password123" | tr -d ':\n')
kubectl patch secret argocd-secret -n argocd --type merge \
  -p "{\"stringData\":{
    \"accounts.dev1.password\":\"$HASH\",
    \"accounts.dev1.passwordMtime\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }}"
kubectl patch secret argocd-secret -n argocd --type merge \
  -p "{\"stringData\":{
    \"accounts.dev2.password\":\"$HASH\",
    \"accounts.dev2.passwordMtime\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }}"

argocd repo add git@github.com:kims/ssp-argocd --ssh-private-key-path ~/.ssh/flux_app_key

kubectl create -f app1/Application.yaml
kubectl create -f app2/Application.yaml

kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout status deployment argocd-server -n argocd --timeout=60s
kubectl rollout status deployment argocd-repo-server -n argocd --timeout=60s

pkill -f "kubectl port-forward svc/argocd-server -n argocd 8080:443"
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null
