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

## Якщо под у Pending (unbound PersistentVolumeClaims)

Помилка `pod has unbound immediate PersistentVolumeClaims` означає, що PVC `n8n-data` не отримав том. Зазвичай це через відсутність default StorageClass у кластері.

1. Перевір класи: `kubectl get storageclass` — має бути один з `(default)`.
2. У `deploy/n8n/pvc.yaml` вказано `storageClassName: gp2` (типово для EKS). Якщо в кластері лише `gp3` або інший клас — зміни значення на його ім’я і зроби Sync.
3. Якщо PVC вже створений без `storageClassName`, його не оновити. Видали його і дай Argo CD перестворити:  
   `kubectl delete pvc n8n-data -n n8n`  
   Після наступного Sync PVC створиться з новим класом і под має піти в Running.

4. Якщо PVC вже з `gp2`, але і PVC, і под у Pending: у EKS клас `gp2` часто має **WaitForFirstConsumer** — том створюється після планування пода. Перезапусти под:  
   `kubectl delete pod -n n8n -l app.kubernetes.io/name=n8n`  
   Новий под запланується на ноду, provisioner створить EBS і прив’яже PVC.

5. **Якщо планувальник все одно не ставить под** (unbound immediate PersistentVolumeClaims): у маніфестах тимчасово використано **emptyDir** замість PVC — под стартує без томів. Дані (workflows, credentials) не зберігаються після рестарту пода. Щоб повернути збереження: у `deploy/n8n/deployment.yaml` заміни `emptyDir: {}` на `persistentVolumeClaim: claimName: n8n-data` і виріши проблему з PVC в кластері (наприклад, default StorageClass або EBS CSI driver).

## Ресурси

- Дані: зараз **emptyDir** (без персистенції після рестарту). Для персистенції — PVC `n8n-data` (5Gi), див. крок 5 вище.
- Образ: `docker.n8n.io/n8nio/n8n:latest`. Оновлення: змінити тег у `deploy/n8n/deployment.yaml` і закомітити, Argo CD зробить rollout.
