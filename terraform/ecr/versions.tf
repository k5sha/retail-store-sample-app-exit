terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "retail-store-tfstate-eu-central-1"
    key            = "ecr/terraform.tfstate"
    region         = "eu-central-1"
    use_lockfile   = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

