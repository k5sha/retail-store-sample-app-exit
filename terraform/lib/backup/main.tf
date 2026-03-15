# AWS Backup: vault, plan, selection, IAM role.
# Backs up resources tagged with selection_tag_key = selection_tag_value and environment-name = environment_name (e.g. RDS, EBS).

resource "aws_backup_vault" "main" {
  name        = "${var.environment_name}-backup-vault"
  tags        = var.tags
}

resource "aws_backup_plan" "main" {
  name = "${var.environment_name}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.backup_rule_schedule

    lifecycle {
      cold_storage_after = var.cold_storage_after_days
      delete_after       = var.delete_after_days
    }
  }

  tags = var.tags
}

# IAM role for AWS Backup to assume (required for backup/restore).
resource "aws_iam_role" "backup" {
  name = "${var.environment_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Select resources by tags (created-by AND environment-name) so each env backs up only its own resources.
resource "aws_backup_selection" "main" {
  name         = "${var.environment_name}-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/${var.selection_tag_key}"
      value = var.selection_tag_value
    }
    string_equals {
      key   = "aws:ResourceTag/environment-name"
      value = var.environment_name
    }
  }
}
