# AWS Backup module

Створює **AWS Backup** vault, plan та selection для автоматичного бекапу ресурсів (RDS, EBS тощо), позначених тегами `created-by = retail-store-sample-app` та `environment-name = <env>`.

## Що створюється

- **Backup vault** — сховище recovery points.
- **Backup plan** — правило щоденнего бекапу о 05:00 UTC; через 7 днів перехід у cold storage, видалення через 35 днів (можна змінити в `variables.tf`).
- **Backup selection** — вибір ресурсів за тегами (лише ресурси з тегами `created-by` та `environment-name` відповідно до переданих у модуль).
- **IAM role** — роль для сервісу Backup (backup + restore).

## Підключення

Модуль викликається з `terraform/eks/staging/main.tf` та `terraform/eks/prod/main.tf`. Ресурси, створені через `lib/dependencies` (RDS Aurora для catalog/orders тощо), вже мають потрібні теги з `module.tags.result`, тому потрапляють у selection автоматично.

## Змінні (опційно)

У виклику модуля можна передати:

- `backup_rule_schedule` — cron (за замовчуванням щодня о 05:00 UTC).
- `cold_storage_after_days`, `delete_after_days` — lifecycle.
- `selection_tag_key`, `selection_tag_value` — тег для відбору (за замовчуванням `created-by = retail-store-sample-app`).

Після `terraform apply` бекапи будуть виконуватися за розкладом у консолі AWS Backup.
