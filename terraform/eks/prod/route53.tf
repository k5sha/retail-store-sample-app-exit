data "aws_route53_zone" "zipzip" {
  name         = "zipzip.online."
  private_zone = false
}
