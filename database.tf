resource "aws_ssm_parameter" "db_username" {
  name   = "/${var.project_name}/${var.environment}/db/username"
  type   = "SecureString"
  value  = var.db_username
  key_id = aws_kms_key.main.id
}

resource "aws_ssm_parameter" "db_password" {
  name   = "/${var.project_name}/${var.environment}/db/password"
  type   = "SecureString"
  value  = var.db_password
  key_id = aws_kms_key.main.id
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attachment" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-postgres-params"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name        = "${var.project_name}-postgres-params"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier                            = "${var.project_name}-postgres-${var.environment}"
  allocated_storage                     = 20
  db_name                               = var.db_name
  engine                                = "postgres"
  engine_version                        = "16"
  instance_class                        = "db.t4g.micro"
  username                              = var.db_username
  password                              = var.db_password
  db_subnet_group_name                  = aws_db_subnet_group.main.name
  parameter_group_name                  = aws_db_parameter_group.postgres.name
  vpc_security_group_ids                = [aws_security_group.rds_sg.id]
  skip_final_snapshot                   = false
  final_snapshot_identifier             = "${var.project_name}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  publicly_accessible                   = false
  multi_az                              = true
  backup_retention_period               = 7
  backup_window                         = "03:00-04:00"
  delete_automated_backups              = false
  storage_encrypted                     = true
  kms_key_id                            = aws_kms_key.main.arn
  auto_minor_version_upgrade            = true
  deletion_protection                   = true
  iam_database_authentication_enabled   = true
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.main.arn
  performance_insights_retention_period = 7

  tags = { Name = "${var.project_name}-postgres" }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id               = "${var.project_name}-cache"
  engine                   = "redis"
  node_type                = "cache.t4g.micro"
  num_cache_nodes          = 1
  parameter_group_name     = "default.redis7"
  port                     = 6379
  subnet_group_name        = aws_elasticache_subnet_group.main.name
  security_group_ids       = [aws_security_group.redis_sg.id]
  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"

  tags = { Name = "${var.project_name}-redis" }
}
