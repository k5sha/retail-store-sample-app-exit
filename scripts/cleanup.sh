#!/usr/bin/env bash
set -euo pipefail

kubectl delete -f ./samples/autoscaling/php-apache-hpa.yaml --ignore-not-found=true
kubectl delete -f ./samples/autoscaling/php-apache.yaml --ignore-not-found=true
kubectl delete -f ./samples/monitoring/alerts/retail-prometheusrule.yaml --ignore-not-found=true

if [ -f ./samples/monitoring/servicemonitors/retail-servicemonitor.yaml ]; then
  kubectl delete -f ./samples/monitoring/servicemonitors/retail-servicemonitor.yaml --ignore-not-found=true
fi

helm uninstall kube-prom-stack -n monitoring || true
kubectl delete namespace monitoring --ignore-not-found=true