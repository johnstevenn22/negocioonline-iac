# 1. API Gateway Regional (HTTP API)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "Backend-API-Gateway"
  protocol_type = "HTTP"
  description   = "Fachada regional para los servicios Node.js"
}

# 2. Stage (despliegue automático)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# 3. Integración con el Balanceador (ALB)
# Listener del ALB creado en alb.tf
resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${aws_lb.main_alb.dns_name}" # Apunta al puerto 80 del ALB

  payload_format_version = "1.0"
  connection_type        = "INTERNET"
}

# 4. Ruta por defecto para capturar todo el tráfico
resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}