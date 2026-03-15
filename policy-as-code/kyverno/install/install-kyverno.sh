#!/usr/bin/env bash
set -euo pipefail

kubectl get namespace kyverno >/dev/null 2>&1 || kubectl create namespace kyverno

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  -n kyverno \
  --wait

echo "Kyverno installed successfully."
kubectl get pods -n kyverno