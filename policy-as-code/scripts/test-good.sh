#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

kubectl apply -f kyverno/tests/good-deployment.yaml
kubectl get deployment good-app
kubectl get pods