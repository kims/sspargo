#!/bin/bash
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout sealed-secrets.key \
  -out sealed-secrets.crt \
  -subj "/CN=sealed-secrets"


kubectl -n kube-system create secret tls sealed-secrets-custom-key \
  --cert=sealed-secrets.crt \
  --key=sealed-secrets.key

kubectl -n kube-system label secret sealed-secrets-custom-key \
  sealedsecrets.bitnami.com/sealed-secrets-key=active

rm -f sealed-secrets.crt sealed-secrets.key

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

helm install sealed-secrets -n kube-system \
  --create-namespace \
  --set-string fullnameOverride=sealed-secrets-controller \
  sealed-secrets/sealed-secrets

K_VERSION=$(curl -sL https://api.github.com/repos/bitnami/sealed-secrets/releases/latest | grep '"tag_name"' | awk -F': ' '{print $2}' | tr -d '",'); [ -x /usr/local/bin/kubeseal ] || { curl -sLO "https://github.com/bitnami/sealed-secrets/releases/download/${K_VERSION}/kubeseal-linux-amd64" && sudo install -m 755 kubeseal-linux-amd64 /usr/local/bin/kubeseal && rm kubeseal-linux-amd64; } && kubeseal version

kubectl create secret generic dev1-db-pass --from-literal=username=dev1 --from-literal=password=dev123 --dry-run=client -o json | kubeseal --namespace=dev1 --format=yaml > app1/templates/SealedSecret.db-pass.yaml
kubectl create secret generic dev2-db-pass --from-literal=username=dev2 --from-literal=password=dev123 --dry-run=client -o json | kubeseal --namespace=dev2 --format=yaml > app2/templates/SealedSecret.db-pass.yaml
