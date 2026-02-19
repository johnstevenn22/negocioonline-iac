# 1. El Balanceador de Carga (ALB)
resource "aws_lb" "main_alb" {
  name               = "main-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # El ALB necesita al menos dos subredes públicas en diferentes AZ
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "Main-ALB" }
}

# 2. El Target Group (A donde se envía el tráfico)
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    port                = "8080"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# 3. Listener (Escucha en el puerto 80 y redirige al TG)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}
