# 1. Definición del WAF corregida
resource "aws_wafv2_web_acl" "main" {
  name        = "api-web-acl"
  description = "Proteccion contra SQLi y XSS"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }

  rule {
    name     = "AWSCommonRule"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "main-waf"
    sampled_requests_enabled   = true
  }
}

# 2. Asociación con el Balanceador
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = aws_lb.main_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# 3. SES (Simple Email Service) para el envío de correos desde la Lambda
resource "aws_ses_email_identity" "email" {
  email = "rodrigo.baldeonj@gmail.com" # mismo correo que SNS para verificarlo en AWS
}

# Security Group para Balanceador (Capa Exterior)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Permite trafico HTTP desde internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SecurityGroup"
  }
}

# Security Group para el Backend (Capa Media)
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Permite trafico solo desde el ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # solo acepta del ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Backend-SecurityGroup"
  }
}

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Permite trafico PostgreSQL desde el backend"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id] # Solo el backend entra
  }

  tags = {
    Name = "RDS-SecurityGroup"
  }
}