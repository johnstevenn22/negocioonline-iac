resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.project_name}/${var.environment}/db/username"
  type  = "SecureString"
  value = var.db_username
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "postgres" {
  identifier               = "${var.project_name}-postgres-${var.environment}"
  allocated_storage        = 20
  db_name                  = var.db_name
  engine                   = "postgres"
  engine_version           = "16"
  instance_class           = "db.t4g.micro"
  username                 = var.db_username
  password                 = var.db_password
  db_subnet_group_name     = aws_db_subnet_group.main.name
  vpc_security_group_ids   = [aws_security_group.rds_sg.id]
  skip_final_snapshot      = true
  publicly_accessible      = false
  multi_az                 = true
  backup_retention_period  = 7
  backup_window            = "03:00-04:00"
  delete_automated_backups = false
  storage_encrypted        = true

  tags = { Name = "${var.project_name}-postgres" }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-cache"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = { Name = "${var.project_name}-redis" }
}
