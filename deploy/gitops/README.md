# GitOps CD (Argo CD) — відповідність ТЗ

**У проді:** Argo CD ставиться разом з кластером через Terraform. Задай у корені EKS (prod/staging) змінні `gitops_repo_url` та при потребі `gitops_target_revision` — після `terraform apply` Argo CD і bootstrap Application вже будуть у кластері, мікросервіси підтягнуться з Git автоматично.

## Вимоги та виконання

| Вимога | Статус | Реалізація |
|--------|--------|-------------|
| **Argo CD або Flux (мінімум 2 сервіси)** | ✅ | Використано **Argo CD**. Задеплоєно **5 сервісів**: UI, Catalog, Cart, Orders, Checkout (prod + staging). |
| **Деплой з окремого "config repo" або окремої директорії в основному репо** | ✅ | Конфіг у **окремій директорії** в основному репо: `deploy/gitops/` (Application-манифести) та `src/<service>/chart` (Helm-чарти). Окреме config repo не використовується — обрано директорію в тому ж репо, щоб зміни коду й деплою були в одному місці. |
| **Якщо обрано інший підхід — обґрунтувати** | ✅ | Обрано **директорія в основному репо**, а не окремий config repo: один репо, простіший доступ, CI оновлює теги образів у цій же директорії. |

## Критерій успіху

> Зміни в config repo/directory **автоматично синхронізуються** в кластер, можна **показати синхронізацію**.

- **Автосинхронізація**: у кожного Application увімкнено `syncPolicy.automated` з `prune: true` та `selfHeal: true` — зміни в Git застосовуються в кластер без ручного sync.
- **Як показати синхронізацію** — див. нижче.

---

## Як показати синхронізацію

### 1. Через Argo CD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Відкрити https://localhost:8080, логін admin, пароль з секрету argocd-initial-admin-secret
```

У UI: список Application → стан **Synced** / **Healthy**; при зміні в Git — **OutOfSync** → через кілька хвилин знову **Synced**.

### 2. Через CLI

```bash
argocd app list
argocd app get retail-store-ui-prod
```

### 3. Демонстрація по кроках

1. Змінити в Git щось у `deploy/gitops/` або в `src/ui/chart` (наприклад, тег образу в `ui-application.yaml`).
2. Запушити зміни.
3. Через 1–3 хв перевірити: `argocd app get retail-store-ui-prod` — має бути **Synced**, у кластері `kubectl get pods -n ui-prod` — новий деплой відповідно до змін.

---

## Оновлення UI після зміни коду

Код UI (наприклад `src/ui/...`) потрапляє в кластер через **Docker-образ**. Щоб зміни з’явились:

1. **Зібрати і запушити новий образ** у ECR (тег `staging-latest` для staging або `latest` для prod).
2. **Оновити деплой** одним із способів:
   - У `ui-staging-application.yaml` (або `ui-application.yaml`) збільшити `app/buildId` (наприклад з `"1"` на `"2"`), закомітити і запушити в `staging`/`main`. Argo CD підхопить зміну і зробить rollout; завдяки `pullPolicy: Always` поди підтягнуть новий образ.
   - Або вручну: `kubectl rollout restart deployment -n ui-staging retail-store-ui-staging` (після push нового образу з тим самим тегом).

---

## Приватний репо (HTTPS)

У манифестах використано **HTTPS** URL. Для приватного репо додай креденшіали в Argo CD (UI: Settings → Repositories, або CLI: `argocd repo add`).

---

## Структура

- **Prod** (гілка `main`): `ui-application.yaml`, `catalog-application.yaml`, `cart-application.yaml`, `orders-application.yaml`, `checkout-application.yaml`, `monitoring-application.yaml`, `monitoring-rules-application.yaml` → namespaces `ui-prod`, `catalog`, `cart`, `orders`, `checkout`, `monitoring`.
- **Staging** (гілка `staging`): `*-staging-application.yaml` + ті самі `monitoring-application.yaml` та `monitoring-rules-application.yaml` → namespaces `ui-staging`, `catalog-staging`, … + `monitoring`.

**Моніторинг** (Prometheus, Grafana, Alertmanager, правила та дашборди) деплоїться через CD в обох середовищах.

**Якщо бачиш помилки:** (1) *"deploy/monitoring-dashboards: app path does not exist"* — видали старий Application: `kubectl delete application monitoring-dashboards -n argocd`. (2) *"connection refused" до Prometheus:9090* — переконайся, що под Prometheus Running (`kubectl get pods -n monitoring`), потім Sync monitoring. (3) **monitoring у стані Missing / OutOfSync / Sync failed** — одноразово: в Argo CD відкрий застосунок **monitoring** → Sync → увімкни **Replace** → Sync. Або повністю перестворити namespace: `kubectl delete namespace monitoring`, потім Sync застосунків monitoring і monitoring-rules (спочатку monitoring, щоб створив namespace і CRD). Application `monitoring-rules` синхронізує `deploy/monitoring-rules/`: PrometheusRule (алерти) + ConfigMap з дашбордами. **Дашборди підхоплюються автоматично:** Grafana sidecar шукає ConfigMap з label `grafana_dashboard: "1"` (у monitoring-application вказано `labelValue: "1"`), дашборди з’являються в Grafana без ручного імпорту (опційно — у папці Retail за label `grafana_dashboard_folder`). **Алертинг:** PrometheusRule з label `release: monitoring` обирається Prometheus (у нас `ruleSelectorNilUsesHelmValues: false`, тому підхоплюються всі правила в namespace); алерти потрапляють в Alertmanager (UI: port-forward на alertmanager). Джерело дашбордів і правил: `samples/monitoring/dashboards/`, `samples/monitoring/alerts/` — при оновленні скопіюй .json у `deploy/monitoring-rules/dashboards/` і додай у kustomization.yaml. **Дашборд «Retail Store — Replicas & CPU» показує репліки, готові поди та CPU по неймспейсах застосунку (ui-prod, ui-staging, catalog, carts, orders, checkout та їхні staging); у змінній «Namespaces (regex)» можна змінити список.** Усі сервіси — **ClusterIP** (без LoadBalancer). Доступ до Grafana: `kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80`, далі http://localhost:3000 (логін admin, пароль з values). Зміни в `deploy/monitoring-rules/` після push у `main` підхоплює Argo CD. Якщо Application `monitoring` не синхронізується, додай репо в Argo CD: Settings → Repositories → `https://prometheus-community.github.io/helm-charts`, type Helm.

CI при push у `main`/`staging` оновлює тег образу у відповідних Application-файлах; Argo CD бачить зміну в Git і синхронізує кластер.
