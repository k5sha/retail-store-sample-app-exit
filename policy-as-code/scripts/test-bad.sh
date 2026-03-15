#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Testing bad-privileged-deployment.yaml"
kubectl apply -f kyverno/tests/bad-privileged-deployment.yaml || true
echo

echo "Testing bad-no-resources.yaml"
kubectl apply -f kyverno/tests/bad-no-resources.yaml || true
echo

echo "Testing bad-tag-image.yaml"
kubectl apply -f kyverno/tests/bad-tag-image.yaml || true
echo

echo "Testing bad-root-user.yaml"
kubectl apply -f kyverno/tests/bad-root-user.yaml || true
echo