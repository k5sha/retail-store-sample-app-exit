data "aws_acm_certificate" "zipzip" {
  domain      = "zipzip.online"
  statuses   = ["ISSUED"]
  most_recent = true
}

resource "local_file" "ui_application" {
  content  = templatefile("${path.module}/templates/ui-application.yaml.tpl", { cert_arn = data.aws_acm_certificate.zipzip.arn })
  filename = "${path.module}/../../../deploy/gitops/ui-application.yaml"
}
