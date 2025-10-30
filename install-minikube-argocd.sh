#!/bin/bash
minikube start 

kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm &>/dev/null
helm repo update &>/dev/null
helm install argocd argo/argo-cd --namespace argocd --wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s >/dev/null

[ -x /usr/local/bin/argocd ] || { sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && sudo chmod +x /usr/local/bin/argocd; } && argocd version

LATEST=$(curl -sL https://api.github.com/repos/kubernetes/kubernetes/releases/latest | grep '"tag_name"' | awk -F': ' '{print $2}' | tr -d '",'); INSTALLED=$(command -v kubectl &> /dev/null && kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion');
if [[ "${INSTALLED}" != "${LATEST}" ]]; then curl -sLO "https://storage.googleapis.com/kubernetes-release/release/${LATEST}/bin/linux/amd64/kubectl" && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl; fi

