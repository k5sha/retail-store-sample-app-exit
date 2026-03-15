variable "environment_name" {
  description = "Name of the environment"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.31"
}

variable "tags" {
  description = "List of tags to be associated with resources."
  default     = {}
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID used to create EKS cluster."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC ID used to create EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs used by EKS cluster nodes."
  type        = list(string)
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

# GitOps (Argo CD) — встановлюється разом з кластером, синхронізує мікросервіси з Git
variable "gitops_enabled" {
  description = "Install Argo CD and bootstrap Application that syncs microservices from Git."
  type        = bool
  default     = true
}

variable "gitops_repo_url" {
  description = "Git repo URL for Argo CD (HTTPS). Example: https://github.com/org/repo.git"
  type        = string
  default     = ""
}

variable "gitops_target_revision" {
  description = "Branch or tag to sync (e.g. main for prod, staging for staging)."
  type        = string
  default     = "main"
}

variable "gitops_path" {
  description = "Path in repo containing Application manifests (e.g. deploy/gitops)."
  type        = string
  default     = "deploy/gitops"
}

# Якщо задано — під час apply застосовуються дочірні Application з цієї директорії (обходить обмеження directory sync).
variable "gitops_manifests_local_path" {
  description = "Absolute or relative path to deploy/gitops (e.g. from root: path.module/../../deploy/gitops). When set, child Applications are applied from here during terraform apply."
  type        = string
  default     = ""
}

# Route 53 + ExternalDNS: zone для записів Ingress (zipzip.online / staging.zipzip.online).
variable "route53_zone_id" {
  description = "Route 53 hosted zone ID (e.g. for zipzip.online). When set, ExternalDNS is enabled."
  type        = string
  default     = ""
}

variable "external_dns_domain_filter" {
  description = "Domain filter for ExternalDNS (e.g. staging.zipzip.online or zipzip.online)."
  type        = string
  default     = ""
}
