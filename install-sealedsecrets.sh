#!/bin/bash
#
export KUBESEAL_VERSION="0.32.2"   # pick the version you want


openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout sealed-secrets.key \
  -out sealed-secrets.crt \
  -subj "/CN=sealed-secrets"


kubectl -n kube-system create secret tls sealed-secrets-custom-key \
  --cert=sealed-secrets.crt \
  --key=sealed-secrets.key

# Label it so the controller picks it up as the active key
kubectl -n kube-system label secret sealed-secrets-custom-key \
  sealedsecrets.bitnami.com/sealed-secrets-key=active

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

helm install sealed-secrets -n kube-system \
  --create-namespace \
  --set-string fullnameOverride=sealed-secrets-controller \
  sealed-secrets/sealed-secrets

curl -LO "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf "kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
kubeseal --version
