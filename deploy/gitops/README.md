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

- **Prod** (гілка `main`): `ui-application.yaml`, `catalog-application.yaml`, … , `monitoring-application.yaml`, `monitoring-rules-application.yaml` → namespaces `ui-prod`, `catalog`, … , `monitoring` (n8n тільки на staging).
- **Staging** (гілка `staging`): `*-staging-application.yaml` + `monitoring-application.yaml`, `monitoring-rules-application.yaml`, `n8n-staging-application.yaml` → namespaces `ui-staging`, `catalog-staging`, … , `monitoring`, `n8n`.
- **Sync (45 с):** Argo CD перевіряє Git кожні **45 секунд** для **всіх** Application (UI, catalog, cart, orders, checkout, monitoring, n8n-staging тощо). Параметр `timeout.reconciliation=45` заданий у Terraform (`terraform/lib/eks/argocd.tf`); зміни в deploy/gitops або в шляхах Application застосовуються автоматично.

**Моніторинг** (Prometheus, Grafana, Alertmanager, правила та дашборди) деплоїться через CD в обох середовищах.

**Якщо бачиш помилки:** (1) *"deploy/monitoring-dashboards: app path does not exist"* — видали старий Application: `kubectl delete application monitoring-dashboards -n argocd`. (2) *"connection refused" до Prometheus:9090* — переконайся, що под Prometheus Running (`kubectl get pods -n monitoring`), потім Sync monitoring. (3) **monitoring у стані Missing / OutOfSync / Sync failed** — одноразово: в Argo CD відкрий застосунок **monitoring** → Sync → увімкни **Replace** → Sync. (4) У логах sidecar **grafana-sc-datasources** з’являється *Connection refused* до `/api/admin/provisioning/datasources/reload` — це нормально при старті пода: sidecar стартує раніше за Grafana і робить retry; після того як основний контейнер Grafana стане Ready, виклики проходять успішно. Або повністю перестворити namespace: `kubectl delete namespace monitoring`, потім Sync застосунків monitoring і monitoring-rules (спочатку monitoring, щоб створив namespace і CRD). Application `monitoring-rules` синхронізує `deploy/monitoring-rules/`: PrometheusRule (алерти) + ConfigMap з дашбордами. **Дашборди підхоплюються автоматично:** Grafana sidecar шукає ConfigMap з label `grafana_dashboard: "1"` (у monitoring-application вказано `labelValue: "1"`), дашборди з’являються в Grafana без ручного імпорту (опційно — у папці Retail за label `grafana_dashboard_folder`). **Алертинг:** PrometheusRule з label `release: monitoring` обирається Prometheus (у нас `ruleSelectorNilUsesHelmValues: false`, тому підхоплюються всі правила в namespace); алерти потрапляють в Alertmanager (UI: port-forward на alertmanager). Джерело дашбордів і правил: `samples/monitoring/dashboards/`, `samples/monitoring/alerts/` — при оновленні скопіюй .json у `deploy/monitoring-rules/dashboards/` і додай у kustomization.yaml. **Дашборд «Retail Store — Replicas & CPU» показує репліки, готові поди та CPU по неймспейсах застосунку (ui-prod, ui-staging, catalog, carts, orders, checkout та їхні staging); у змінній «Namespaces (regex)» можна змінити список.** Усі сервіси — **ClusterIP** (без LoadBalancer). Доступ до Grafana: `kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80`, далі http://localhost:3000 (логін admin, пароль з values). Зміни в `deploy/monitoring-rules/` після push у `main` підхоплює Argo CD. Якщо Application `monitoring` не синхронізується, додай репо в Argo CD: Settings → Repositories → `https://prometheus-community.github.io/helm-charts`, type Helm.

CI при push у `main`/`staging` оновлює тег образу у відповідних Application-файлах; Argo CD бачить зміну в Git і синхронізує кластер.

---

## Перевірка моніторингу (дашборди, алерти)

**Де дивитися скейлінг HPA:** дашборд **«Retail Store — Replicas & CPU»** (uid: `retail-hpa-demo`). Зверху вибери змінну **Namespaces** → обери **All** або тільки staging: `carts-staging`, `ui-staging`, `catalog-staging`, `checkout-staging`, `orders-staging`. Графіки **«Replicas by Deployment (тут видно скейлінг HPA)»** та **«Ready Pods by Namespace (зростання = більше подів)»** — саме там під час навантаження (наприклад Locust) має зростати кількість реплік/подів. Якщо скейлінг не видно — переконайся, що в Namespaces обрано staging-неймспейси (а не лише prod). Якщо CPU на графіках росте, а репліки лишаються 1 — перевір, що в кластері є **metrics-server** (потрібен для HPA): `kubectl get deployment metrics-server -n kube-system`, та що HPA існують: `kubectl get hpa -n carts-staging`. Якщо metrics-server немає — увімкни його в Terraform EKS: `enable_metrics_server = true` у модулі `eks_blueprints_addons`, потім `terraform apply`.

**Дашборд «Retail Store — Replicas & CPU» з’являється тільки якщо в кластері є ConfigMap з нашим дашбордом.** Його створює Application **monitoring-rules** (Kustomize з `deploy/monitoring-rules/`). Якщо дашборди/алерти не з'являються — перевірте, що **monitoring-rules** вказує на репо й гілку, куди ви пушите (див. **deploy/monitoring-rules/TROUBLESHOOTING.md**). Якщо в `kubectl get configmap -n monitoring -l grafana_dashboard=1` немає запису на кшталт `grafana-dashboards-retail-*` — зробіть Sync застосунку **monitoring-rules** в Argo CD (або переконайтесь, що він вказує на репо/шлях з цим kustomization).

- Перевірка ConfigMap дашбордів: `kubectl get configmap -n monitoring -l grafana_dashboard=1 | grep grafana-dashboards-retail`
- Логи sidecar дашбордів (у chart контейнер називається **grafana-sc-dashboard**, однина):  
  `kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -c grafana-sc-dashboard --tail=50`  
  Якщо ім’я інше — перевір: `kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].spec.containers[*].name}'`

**Перевірка алертів:** (1) Є PrometheusRule: `kubectl get prometheusrule -n monitoring | grep retail` — має бути **retail-alerts**. Якщо бачиш лише **retail-autoscaling-alerts**, синхронізуй застосунок **monitoring-rules** з гілки, де в `deploy/monitoring-rules/retail-prometheusrule.yaml` вказано `name: retail-alerts`. (2) Правила в Prometheus: `kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090`, у браузері http://localhost:9090 → **Status** → **Rules** (або /alerts) — має з’явитися група **retail.rules**. Prometheus у цьому stack — **StatefulSet**, не Deployment, тому `kubectl exec deploy/...` не спрацює; використовуй port-forward. (3) Alertmanager: `kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093` → http://localhost:9093 → вкладка **Alerts**.

**SLI-дашборд і сповіщення:** У Grafana є дашборд **«Retail Store — SLI (rate, errors, latency)»**: request rate, 5xx error rate, latency p50/p95/p99 (метрики з `/actuator/prometheus` застосунків). Алерти **RetailHigh5xxRate** (5xx > 1%) та **RetailHighLatencyP95** (p95 > 500 ms) оголошуються в групі **retail.sli**. Щоб отримувати сповіщення (месенджер, пошта, SMS), налаштуй Alertmanager: у `deploy/gitops/monitoring-application.yaml` в секції `alertmanager.config.receivers` заміни webhook URL на свій (Slack, Telegram, SMS-шлюз тощо) або додай `email_configs` з SMTP — потім пересинхронізуй Application **monitoring** в Argo CD.

---

## n8n (автоматизація, GitHub PR review) — тільки staging

**n8n** деплоїться лише на **staging** через Application **n8n-staging** (Kustomize з `deploy/n8n/`, гілка staging). Використовуй для автоматизації, зокрема для **GitHub Pull Request review**.

**Перед першим Sync** (на staging-кластері) створи секрет:

```bash
kubectl create namespace n8n
kubectl create secret generic n8n-secrets -n n8n --from-literal=N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
```

Далі Sync застосунку **n8n-staging** в Argo CD. Доступ: `kubectl port-forward svc/n8n -n n8n 5678:5678` → http://localhost:5678, або через Ingress: `kubectl get ingress -n n8n`. Детальніше: `deploy/n8n/README.md`.
