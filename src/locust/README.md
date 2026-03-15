# Locust — навантажувальне тестування з веб-інтерфейсом

[Locust](https://locust.io/) генерує навантаження на Retail Store і має **графічний веб-інтерфейс** (графіки, статистика, керування тестом).

## Локально

```bash
cd src/locust
pip install -r requirements.txt
# Запуск: веб-UI на http://localhost:8089
locust -f locustfile.py --host http://localhost:8888
```

Відкрийте http://localhost:8089, вкажіть кількість користувачів і RPS, натисніть Start.

## Docker

```bash
docker build -t retail-store-locust -f src/locust/Dockerfile src/locust
docker run -p 8089:8089 -e TARGET_HOST=http://host.docker.internal:8888 retail-store-locust
# або з аргументом:
docker run -p 8089:8089 retail-store-locust --host http://host.docker.internal:8888
```

## Kubernetes (у кластері)

Застосувати манифести (namespace `locust`, ConfigMap з locustfile, Deployment, Service):

```bash
kubectl apply -k deploy/locust
```

Вказати URL UI для навантаження: у `deploy/locust/deployment.yaml` змінна середовища `TARGET_HOST` (за замовчуванням `http://ui.ui-staging.svc.cluster.local`). Щоб змінити, відредагуйте value або задайте через Kustomize/Helm.

Відкрити веб-інтерфейс Locust:

```bash
kubectl port-forward svc/locust -n locust 8089:8089
```

У браузері: http://localhost:8089. Далі вказати число users і spawn rate, натиснути Start.

Після тесту — видалити ресурси:

```bash
kubectl delete -k deploy/locust
```

## Сценарії в locustfile.py

- **browse_and_checkout** (вага 10): повний цикл — home, catalog, товари, додати в кошик, checkout (адреса, доставка, оплата).
- **browse_catalog_only** (5): лише головна та каталог.
- **view_cart** (2): головна та кошик.

Джерело сценарію: `src/locust/locustfile.py`. Для деплою в кластер використовується копія в `deploy/locust/locustfile.py` (Kustomize ConfigMap); при зміні сценарію оновіть обидва файли або синхронізуйте їх.
