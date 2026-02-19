output "alb_dns_name" {
  description = "URL pública del balanceador de carga"
  value       = aws_lb.main_alb.dns_name
}

output "website_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "api_gateway_endpoint" {
  description = "URL final para consumir tu API de Node.js"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}