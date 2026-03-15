# Policy-as-Code with Kyverno

## Мета
Реалізувати Policy-as-Code для Kubernetes через Kyverno, щоб блокувати небезпечні або неякісно налаштовані ресурси ще на етапі admission control.

## Реалізовані політики
1. Заборона privileged containers
2. Обов'язкові CPU/memory requests та limits
3. Дозвіл лише image з digest
4. Обов'язковий runAsNonRoot=true

## Структура
- `kyverno/install/` — встановлення Kyverno
- `kyverno/policies/` — ClusterPolicy
- `kyverno/tests/` — good/bad manifests
- `scripts/` — допоміжні скрипти

## Встановлення Kyverno

Виконувати з кореня папки `policy-as-code`:

```bash
cd policy-as-code
bash kyverno/install/install-kyverno.sh
```

## Застосування політик

```bash
cd policy-as-code
bash scripts/apply-policies.sh
```

## Робота в кластері (завжди)

Щоб Kyverno і політики працювали **постійно в Kubernetes** і перевіряли кожен створений/оновлений Pod:

1. **Argo CD** — додай у репо два Application (уже в репо):
   - `deploy/gitops/kyverno-application.yaml` — ставить Kyverno з Helm-репо в namespace `kyverno`.
   - `deploy/gitops/kyverno-policies-application.yaml` — синхронізує ClusterPolicy з `policy-as-code/kyverno/policies`.

2. **Перед першим деплоєм** у Argo CD додай Helm-репозиторій Kyverno:
   - Settings → Repositories → Connect Repo
   - Type: **Helm**, URL: `https://kyverno.github.io/kyverno/`

3. Застосуй Applications (або дозволь Argo CD синхронізувати з Git):
   ```bash
   kubectl apply -f deploy/gitops/kyverno-application.yaml
   kubectl apply -f deploy/gitops/kyverno-policies-application.yaml
   ```

Після синку Kyverno працює в кластері, політики застосовуються до всіх відповідних ресурсів (Pod тощо). Зміни в політиках у Git підтягуються Argo CD (selfHeal), перевірка виконується завжди при admission.

## Перевірка (тести)

- **Хороший манифест** — має пройти всі політики:
  ```bash
  cd policy-as-code && bash scripts/test-good.sh
  ```
- **Погані манифести** — мають бути відхилені (кожен тест очікує помилку):
  ```bash
  cd policy-as-code && bash scripts/test-bad.sh
  ```