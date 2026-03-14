variable "environment_name" {
  description = "Name of the environment"
  type        = string
  default     = "retail-store"
}

variable "istio_enabled" {
  description = "Boolean value that enables istio."
  type        = bool
  default     = false
}

variable "opentelemetry_enabled" {
  description = "Boolean value that enables OpenTelemetry."
  type        = bool
  default     = false
}

variable "container_image_overrides" {
  type = object({
    default_repository = optional(string)
    default_tag        = optional(string)

    ui       = optional(string)
    catalog  = optional(string)
    cart     = optional(string)
    checkout = optional(string)
    orders   = optional(string)
  })
  default     = {}
  description = "Object that encapsulates any overrides to default values"
}

# GitOps (Argo CD) — репо з deploy/gitops та гілка main для prod
variable "gitops_enabled" {
  description = "Install Argo CD and sync microservices from Git (deploy/gitops)."
  type        = bool
  default     = true
}

variable "gitops_repo_url" {
  description = "Git repo URL for Argo CD (HTTPS). E.g. https://github.com/org/repo.git"
  type        = string
  default     = "https://github.com/k5sha/retail-store-sample-app-exit.git"
}

variable "gitops_target_revision" {
  description = "Branch to sync for prod (default main)."
  type        = string
  default     = "main"
}

variable "gitops_path" {
  description = "Path in repo with Application manifests."
  type        = string
  default     = "deploy/gitops"
}

variable "gitops_manifests_local_path" {
  description = "Path to deploy/gitops for applying child Applications during terraform apply. Empty = skip."
  type        = string
  default     = ""
}
