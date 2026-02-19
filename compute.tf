data "aws_ami" "amazon_linux_arm" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-arm64"]
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-template-"
  image_id      = data.aws_ami.amazon_linux_arm.id
  instance_type = "t4g.small" 
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nodejs
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Role = "Backend"
    }
  }
}

resource "aws_autoscaling_group" "backend_asg" {
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "target-tracking-cpu"
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0 # Escalar al 60%
  }
}