# Grafana dashboards (auto-loaded)

ConfigMaps у цій директорії деплояться в namespace `monitoring`. Grafana (kube-prometheus-stack) sidecar шукає ConfigMap з label `grafana_dashboard: "1"` і автоматично підхоплює дашборди.

**Джерело дашбордів:** `samples/monitoring/dashboards/`. Щоб додати або оновити дашборд:
1. Поклади або онови `.json` у `samples/monitoring/dashboards/`.
2. Скопіюй у `deploy/monitoring-dashboards/dashboards/`.
3. Додай файл у `kustomization.yaml` → `configMapGenerator[].files`, якщо новий.
4. Закоміть і запуш — Argo CD (Application `monitoring-dashboards`) оновить ConfigMap, Grafana підхопить зміни.
