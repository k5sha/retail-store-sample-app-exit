# n8n у кластері (тільки staging)

Workflow-автоматизація (n8n) деплоїться **лише на staging** в namespace `n8n` через Argo CD Application **n8n-staging** (джерело: `deploy/n8n/`, гілка staging).

## Перший запуск

1. **Секрет для n8n** (обов’язково — без нього под не стартує):

   ```bash
   kubectl create namespace n8n
   kubectl create secret generic n8n-secrets -n n8n --from-literal=N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
   ```

2. У Argo CD зроби **Sync** застосунку **n8n-staging** (або дочекайся автосинку).

3. **Доступ до UI:**  
   `kubectl port-forward svc/n8n -n n8n 5678:5678`  
   Відкрий http://localhost:5678 — перший вхід: створення облікового запису власника.

## GitHub Pull Request review (автоматизація)

Щоб n8n реагував на події GitHub (наприклад, створення/відкриття PR) і міг робити review або коментарі:

1. **GitHub Personal Access Token (PAT):**  
   GitHub → Settings → Developer settings → Personal access tokens → Generate. Права: `repo`, `pull_requests:write` (та інші за потреби).

2. **У n8n:**  
   - Credentials → Add credential → **GitHub API** → вставте PAT.  
   - Новий workflow: тригер **Webhook** (GitHub надсилає події на webhook URL) або **GitHub Trigger** (якщо доступно).  
   - Далі ноди **GitHub** для читання PR, створення review (approve/comment).  
   - Якщо використовуєш Webhook: у репо GitHub → Settings → Webhooks → Add webhook. Payload URL: публічна URL твого n8n (наприклад через Ingress або ngrok), Content type `application/json`, подія «Pull requests».

3. **Webhook URL у кластері:**  
   Для n8n налаштовано **Ingress** (ALB). Після Sync застосунку n8n перевір Ingress: `kubectl get ingress -n n8n` — поле **ADDRESS** (або хост) і є публічний URL. У GitHub Webhook вкажи `https://<ADDRESS>/webhook/...` (шлях webhook дає n8n у картці вузла Webhook). Якщо webhook-посилання в n8n показують localhost, задай змінну середовища **N8N_HOST**: онови в Deployment `env` значення `N8N_HOST` на DNS Ingress/ALB (або створи ConfigMap/Secret і підстав через `valueFrom`), потім перезапусти под.

## Ресурси

- Дані (workflows, credentials) зберігаються на PVC `n8n-data` (5Gi), монтованому в `/home/node/.n8n`.
- Образ: `docker.n8n.io/n8nio/n8n:latest`. Оновлення: змінити тег у `deploy/n8n/deployment.yaml` і закомітити, Argo CD зробить rollout.
