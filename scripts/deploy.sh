#!/usr/bin/env bash
set -euo pipefail

echo "=== Checking required tools ==="
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required"; exit 1; }

echo "=== Checking cluster access ==="
kubectl get nodes >/dev/null

echo "=== Creating monitoring namespace if needed ==="
kubectl get namespace monitoring >/dev/null 2>&1 || kubectl create namespace monitoring

echo "=== Adding Helm repo ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

echo "=== Installing kube-prometheus-stack ==="
helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ./samples/monitoring/kube-prometheus-stack/values.yaml

echo "=== Applying alert rules ==="
kubectl apply -f ./deploy/monitoring-rules/retail-prometheusrule.yaml

echo "=== Applying ServiceMonitor if file exists and is not empty ==="
if [ -s ./samples/monitoring/servicemonitors/retail-servicemonitor.yaml ]; then
  kubectl apply -f ./samples/monitoring/servicemonitors/retail-servicemonitor.yaml
else
  echo "ServiceMonitor file missing or empty, skipping"
fi

echo "=== Deploying workload ==="
kubectl apply -f ./deploy/autoscaling/php-apache.yaml

echo "=== Waiting for deployment ==="
kubectl rollout status deployment/php-apache -n default

echo "=== Applying HPA ==="
kubectl apply -f ./deploy/autoscaling/php-apache-hpa.yaml

echo "=== Current status ==="
kubectl get pods -A
kubectl get hpa -A

echo ""
echo "=== Done ==="
echo "Prometheus: kubectl port-forward -n monitoring svc/kube-prom-stack-kube-prome-prometheus 9090:9090"
echo "Grafana:    kubectl port-forward -n monitoring svc/kube-prom-stack-grafana 3000:80"
echo "Alertmgr:   kubectl port-forward -n monitoring svc/kube-prom-stack-kube-prome-alertmanager 9093:9093"