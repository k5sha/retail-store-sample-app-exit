variable "domain" {
  description = "Root domain for Route 53 hosted zone"
  type        = string
  default     = "zipzip.online"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
