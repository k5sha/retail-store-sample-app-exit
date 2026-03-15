output "zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "Route 53 hosted zone ID"
}

output "name_servers" {
  value       = aws_route53_zone.main.name_servers
  description = "NS records — делегуй домен на ці сервери у реєстратора"
}

output "certificate_arn" {
  value       = aws_acm_certificate.main.arn
  description = "ACM certificate ARN for *.domain and domain (HTTPS)"
}
