output "backup_vault_arn" {
  value       = aws_backup_vault.main.arn
  description = "ARN of the backup vault."
}

output "backup_vault_name" {
  value       = aws_backup_vault.main.name
  description = "Name of the backup vault."
}

output "backup_plan_arn" {
  value       = aws_backup_plan.main.arn
  description = "ARN of the backup plan."
}

output "backup_plan_id" {
  value       = aws_backup_plan.main.id
  description = "ID of the backup plan."
}
