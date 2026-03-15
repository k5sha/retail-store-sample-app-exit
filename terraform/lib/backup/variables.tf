variable "environment_name" {
  type        = string
  description = "Environment name (e.g. staging-retail-store, prod). Used for vault/plan naming and tag-based selection."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to backup resources. Selection uses tag created-by and environment-name from here."
}

variable "backup_rule_schedule" {
  type        = string
  default     = "cron(0 5 ? * * *)"
  description = "Cron expression for backup schedule. Default: daily at 05:00 UTC."
}

variable "cold_storage_after_days" {
  type        = number
  default     = 7
  description = "Days after which to move backups to cold storage."
}

variable "delete_after_days" {
  type        = number
  default     = 35
  description = "Days after which to delete recovery points."
}

variable "selection_tag_key" {
  type        = string
  default     = "created-by"
  description = "Tag key used to select resources for backup (must match resources created by this project)."
}

variable "selection_tag_value" {
  type        = string
  default     = "retail-store-sample-app"
  description = "Tag value for selection_tag_key."
}
