# Моніторинг (дашборди, алерти, сповіщення) — діагностика

Якщо після sync нічого не з’являється в Grafana/Prometheus/Alertmanager — перевірте кроки нижче.

## 0. Швидке відновлення (після перезапуску зовсім немає)

Якщо після перезапуску Grafana або кластера retail-дашбордів і алертів немає — застосуйте ресурси **локально** з цього репо:

```bash
# З кореня репо
kubectl apply -k deploy/monitoring-rules
```

Потім перезапустіть Grafana: `kubectl rollout restart deployment -n monitoring -l app.kubernetes.io/name=grafana`

Перевірка: `kubectl get configmap,prometheusrule,servicemonitor -n monitoring | grep -E 'retail|grafana-dashboards-retail'`

**Увага:** якщо Argo CD робить sync з Git (prune: true), при наступному sync він може знову прибрати ресурси, якщо їх немає в репо. Запуште вміст `deploy/monitoring-rules/` у репо, на який вказує Application **monitoring-rules**.

## 1. Звідки Argo CD бере матеріал (найчастіша причина)

Application **monitoring-rules** вказує на репозиторій і гілку. Якщо ви пушите зміни в **інший** репо або гілку, Argo CD їх не побачить.

Перевірте поточне джерело:

```bash
kubectl get application monitoring-rules -n argocd -o jsonpath='{.spec.source.repoURL} {.spec.source.path} {.spec.source.targetRevision}'
echo
```

- Має бути **repoURL** = репо, куди ви реально пушите (наприклад `https://github.com/YOUR_USER/retail-store-sample-app.git` або `.../retail-store-sample-app-exit.git`).
- **path** = `deploy/monitoring-rules`
- **targetRevision** = гілка (наприклад `main` або `staging`).

Якщо repoURL вказує на інший репо — або змініть його в `deploy/gitops/monitoring-rules-application.yaml` на свій репо і закомітьте/запуште цей манифест (через bootstrap або вручну), або пушите зміни з `deploy/monitoring-rules/` у той репо, на який вказує Argo CD.

Після зміни репо/гілки — зробіть **Sync** застосунку **monitoring-rules** в Argo CD (UI або `argocd app sync monitoring-rules`).

---

## 2. Чи синхронізовано monitoring-rules

```bash
kubectl get application monitoring-rules -n argocd
argocd app get monitoring-rules
```

- Стан має бути **Synced** / **Healthy**. Якщо **OutOfSync** або **Sync Failed** — відкрийте події/помилки в Argo CD UI або в `argocd app get monitoring-rules` і виправте (наприклад, недоступний репо, помилка Kustomize).

Примусовий sync:

```bash
argocd app sync monitoring-rules
# або в UI: monitoring-rules → Sync → Sync
```

---

## 3. Чи є в кластері ресурси з deploy/monitoring-rules

```bash
# Правила та ServiceMonitor
kubectl get prometheusrule,servicemonitor -n monitoring | grep -E 'retail|NAME'

# ConfigMap з дашбордами (має бути з label grafana_dashboard=1)
kubectl get configmap -n monitoring -l grafana_dashboard=1
```

Очікується щось на кшталт:

- `retail-alerts` (PrometheusRule)
- `retail-store` (ServiceMonitor)
- ConfigMap з іменем типу `grafana-dashboards-retail-<hash>` і міткою `grafana_dashboard=1`.

Якщо цих ресурсів немає — Argo CD не застосував матеріал з `deploy/monitoring-rules` (див. п. 1–2).

---

## 4. Grafana — чому не з’являється дашборд

- Sidecar шукає ConfigMap у **namespace monitoring** з міткою `grafana_dashboard=1` (у `monitoring-application` задано `labelValue: "1"`).
- Переконайтесь, що ConfigMap існує і з правильним лейблом (команда з п. 3).
- Після появи ConfigMap sidecar за кілька хвилин підхопить дашборди; при потребі перезапустіть под Grafana:

```bash
kubectl rollout restart deployment -n monitoring -l app.kubernetes.io/name=grafana
```

У Grafana: **Dashboards** → (папка **Retail**, якщо є) — мають з’явитися **Retail Store — Replicas & CPU** та **Retail Store — SLI (rate, errors, latency)**.

- Якщо дашборд є, але графіки порожні — перевірте, що Prometheus скрейпить застосунки (п. 5).

---

## 5. Prometheus — чи скрейпляться retail-сервіси

ServiceMonitor **retail-store** вибирає сервіси з лейблом `app.kubernetes.io/owner=retail-store-sample` у вказаних namespace.

Перевірка таргетів:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
# У браузері: http://localhost:9090 → Status → Targets
# Знайдіть job з retail namespaces (наприклад ui-prod, catalog, carts, orders, checkout).
```

Якщо таких таргетів немає:

- Переконайтесь, що сервіси в цих namespace мають лейбл `app.kubernetes.io/owner: retail-store-sample` (це задано в Helm-чартах).
- Перевірте, що ServiceMonitor створений: `kubectl get servicemonitor retail-store -n monitoring -o yaml`.

---

## 6. Prometheus — чи видно правила retail.sli

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
# У браузері: http://localhost:9090 → Status → Rules
```

Мають бути групи **retail.sli** (алерти RetailHigh5xxRate, RetailHighLatencyP95) та **retail.rules**. Якщо їх немає — перевірте наявність PrometheusRule `retail-alerts` (п. 3) і що в ньому є `labels.release: monitoring` (так вибирає цей stack).

---

## 7. Alertmanager — сповіщення

- Конфіг задається в `deploy/gitops/monitoring-application.yaml` у секції `alertmanager.config`. За замовчуванням там placeholder webhook URL.
- Щоб сповіщення реально кудись приходили: замініть URL на свій (Slack, Telegram, тощо) або додайте `email_configs`, потім пересинхронізуйте Application **monitoring** (не monitoring-rules).
- Перевірка, що Alertmanager отримує алерти:  
  `kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093` → http://localhost:9093 → вкладка **Alerts**. При firing-алертах вони з’являться тут; якщо webhook/email налаштовані — прийдуть сповіщення.

---

## Швидкий чеклист

1. Репо та гілка в `monitoring-rules-application.yaml` збігаються з тим, куди ви пушите.
2. `argocd app get monitoring-rules` — Synced/Healthy.
3. `kubectl get configmap -n monitoring -l grafana_dashboard=1` — є ConfigMap з дашбордами.
4. У Prometheus **Targets** є job з retail-сервісів.
5. У Prometheus **Rules** є групи **retail.sli** та **retail.rules**.
6. У Alertmanager підставлений реальний webhook або email і пересинхроновано **monitoring**.
