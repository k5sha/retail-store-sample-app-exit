module "tags" {
  source = "../lib/tags"

  environment_name = var.environment_name
}

locals {
  common_tags = module.tags.result
}

resource "aws_ecr_repository" "ui" {
  name                 = "${var.environment_name}-retail-store-sample-ui"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "catalog" {
  name                 = "${var.environment_name}-retail-store-sample-catalog"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "cart" {
  name                 = "${var.environment_name}-retail-store-sample-cart"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "orders" {
  name                 = "${var.environment_name}-retail-store-sample-orders"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "checkout" {
  name                 = "${var.environment_name}-retail-store-sample-checkout"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "utils" {
  name                 = "${var.environment_name}-retail-store-sample-utils"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

