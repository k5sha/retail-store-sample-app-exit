# Як запустити командами

## Локально

### Всі сервіси (Docker Compose)
```bash
# З кореня репозиторію
yarn compose:up
# або
docker compose --project-directory src/app up --build --detach --wait --wait-timeout 120

# Зупинити
yarn compose:down
# або
docker compose --project-directory src/app down
```

### Тільки UI (один контейнер)
```bash
docker run -it --rm -p 8888:8080 public.ecr.aws/aws-containers/retail-store-sample-ui:1.0.0
# Відкрити http://localhost:8888
# Зупинити: Ctrl+C
```

### Один мікросервіс (Maven)
```bash
cd src/ui
./mvnw spring-boot:run
# Аналогічно: src/cart, src/catalog, src/checkout, src/orders (потрібні БД/залежності)
```

---

## Kubernetes (кластер)

### Застосувати всі маніфести з репо (без Argo CD)
```bash
# Приклад: застосувати GitOps-застосунки вручну (якщо Argo CD не використовується)
kubectl apply -f deploy/gitops/ui-staging-application.yaml
# або окремі Helm-релізи вручну з src/<service>/chart
```

### Argo CD (синхронізація з Git)
```bash
# Порт-форвард до Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Синхронізувати застосунок вручну (якщо auto-sync вимкнено)
argocd app sync retail-store-ui-staging
argocd app sync retail-store-cart-staging
# тощо
```

### Locust (навантаження в кластері)
```bash
kubectl apply -k deploy/locust
kubectl port-forward svc/locust -n locust 8089:8089
# Відкрити http://localhost:8089
```

### Перезапустити поди / переглянути логи
```bash
# Рестарт UI staging
kubectl rollout restart deployment/retail-store-ui-staging -n ui-staging

# Логи пода
kubectl logs -n ui-staging -l app.kubernetes.io/name=ui -f

# Статус подів
kubectl get pods -n ui-staging
kubectl get pods -n carts-staging
```

---

## Terraform (інфраструктура)

### Staging (EKS + VPC + Backup тощо)
```bash
cd terraform/eks/staging
terraform init
terraform plan
terraform apply
```

### Prod
```bash
cd terraform/eks/prod
terraform init
terraform plan
terraform apply
```

### Тільки ECR (образи)
```bash
cd terraform/ecr
terraform init && terraform apply
```

---

## CI / збірка образів

### Збірка одного сервісу (Docker)
```bash
cd src/ui
docker build -t retail-store-sample-ui:local .
```

### Nx (збірка, тести)
```bash
yarn nx run-many -t build --projects=tag:service --parallel=1
yarn nx affected --targets=build --base origin/main
```

Ці команди достатні, щоб запускати застосунок локально, у кластері та піднимати інфраструктуру через Terraform.
