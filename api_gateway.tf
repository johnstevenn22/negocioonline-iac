resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name        = "${var.project_name}-apigw-logs"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api-gateway"
  protocol_type = "HTTP"

  tags = {
    Name        = "${var.project_name}-api-gateway"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${aws_lb.main_alb.dns_name}"
  connection_type    = "INTERNET"
}

resource "aws_apigatewayv2_route" "proxy_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
  authorization_type = "AWS_IAM"
}
