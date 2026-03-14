# Disaster Recovery (stateful workloads)

Backup and restore для stateful компонентів: **PostgreSQL** (orders), **MySQL** (catalog).

## Вимоги

- `kubectl` з доступом до кластера (контекст вже вибраний)
- Namespace `orders` з StatefulSet `orders-postgresql`, namespace `catalog` з `catalog-mysql` (або змінні середовища нижче)

## Backup

Перед **кожним деплоєм** потрібно робити бекап:

```bash
# З кореня репозиторію
export PYTHONPATH="$(pwd)"
python -m ops.dr backup
```

Бекапи зберігаються в `ops/backups/<target_id>/dump_<timestamp>.sql`. Каталог можна змінити: `export DR_BACKUP_DIR=/path/to/backups`.

Бекап одного тільки сервісу:

```bash
python -m ops.dr backup --target orders-postgresql
python -m ops.dr backup --target catalog-mysql
```

## Restore

Відновлення з файлу бекапу:

```bash
python -m ops.dr restore --target orders-postgresql --file ops/backups/orders-postgresql/dump_20250314T120000Z.sql
python -m ops.dr restore --target catalog-mysql -f ops/backups/catalog-mysql/dump_20250314T120000Z.sql
```

Перелік наявних бекапів:

```bash
python -m ops.dr list-backups
```

## Backup перед кожним деплоєм

Скрипт **backup-before-deploy** спочатку робить бекап, потім виконує деплой:

```bash
./ops/backup-before-deploy.sh
```

Поведінка деплою:

- Якщо задано `DEPLOY_CMD` — виконується вона (наприклад `DEPLOY_CMD='helmfile apply'`).
- Якщо встановлено `argocd` — синхронізуються застосунки `retail-store-orders`, `retail-store-catalog`.
- Інакше скрипт лише виводить підказку виконати деплой вручну.

У CI додайте крок:

```yaml
- run: ./ops/backup-before-deploy.sh
  env:
    DEPLOY_CMD: "helmfile apply"   # або argocd app sync ...
```

## Namespace та імена (helmfile vs Argo CD)

- **Helmfile** (один namespace `default`):  
  `export DR_ORDERS_NAMESPACE=default` та `DR_CATALOG_NAMESPACE=default`.  
  Поді: `orders-postgresql-0`, `catalog-mysql-0`.

- **Argo CD** (namespace `orders`, `catalog`): за замовчуванням очікуються поди `orders-postgresql-0`, `catalog-mysql-0`. Якщо release name інший (наприклад `retail-store-orders`), под може називатися `retail-store-orders-orders-postgresql-0`. Тоді задайте:
  ```bash
  export DR_ORDERS_POSTGRESQL_SERVICE_NAME=retail-store-orders-orders-postgresql
  export DR_CATALOG_MYSQL_SERVICE_NAME=retail-store-catalog-catalog-mysql
  ```
  (без суфікса `-0`; фактичне ім’я пода перевірте: `kubectl get pods -n orders`, `kubectl get pods -n catalog`).
