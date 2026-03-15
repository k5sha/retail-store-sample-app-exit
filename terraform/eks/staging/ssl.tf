data "aws_acm_certificate" "zipzip" {
  domain      = "zipzip.online"
  statuses   = ["ISSUED"]
  most_recent = true
}

resource "local_file" "ui_staging_application" {
  content  = templatefile("${path.module}/templates/ui-staging-application.yaml.tpl", { cert_arn = data.aws_acm_certificate.zipzip.arn })
  filename = "${path.module}/../../../deploy/gitops/ui-staging-application.yaml"
}

resource "local_file" "n8n_ingress" {
  content  = templatefile("${path.module}/templates/n8n-ingress.yaml.tpl", { cert_arn = data.aws_acm_certificate.zipzip.arn })
  filename = "${path.module}/../../../deploy/n8n/ingress.yaml"
}
