# 1. Dashboard personalizado para ver todo de un vistazo
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Dashboard-Proyecto"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.backend_asg.name}" ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-2"
          title  = "Uso de CPU - Backends"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${aws_db_instance.postgres.identifier}" ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-2"
          title  = "Uso de CPU - Base de Datos"
        }
      }
    ]
  })
}

# 2. Alarma de CPU alta para el Backend A
resource "aws_cloudwatch_metric_alarm" "cpu_group_alarm" {
  alarm_name          = "cpu-alta-backend-group"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70" 
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }
}

# Crear el tema de notificaciones
resource "aws_sns_topic" "alerts" {
  name = "infra-alerts-topic"
}

# Aquí podrías suscribir tu email
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "rodrigo.baldeonj@gmail.com"
}