# Locust у Kubernetes

Locust з веб-інтерфейсом для навантажувального тесту Retail Store у кластері.

## Швидкий старт

```bash
# Застосувати (namespace locust, Deployment + Service + ConfigMap)
kubectl apply -k deploy/locust

# Відкрити веб-UI Locust
kubectl port-forward svc/locust -n locust 8089:8089
```

У браузері: **http://localhost:8089**. Вкажіть Number of users і Spawn rate, натисніть **Start swarming**.

## Налаштування цільового URL

За замовчуванням навантаження йде на `http://retail-store-ui-staging.ui-staging.svc.cluster.local` (сервіс UI = Helm release name у namespace ui-staging). Змінити можна в `deployment.yaml` (env `TARGET_HOST`) або через patch:

```bash
kubectl set env deployment/locust -n locust TARGET_HOST=http://retail-store-ui-prod.ui-prod.svc.cluster.local
kubectl rollout restart deployment/locust -n locust
```

## Видалення

```bash
kubectl delete -k deploy/locust
```

## Структура

- `namespace.yaml` — namespace `locust`
- `deployment.yaml` — один под з образом `locustio/locust`, ConfigMap з locustfile
- `service.yaml` — ClusterIP на порту 8089
- `locustfile.py` — сценарій тесту (копія з `src/locust/`); при зміні сценарію оновіть і тут, і в `src/locust/`, потім `kubectl apply -k deploy/locust` і перезапустіть deployment при потребі
