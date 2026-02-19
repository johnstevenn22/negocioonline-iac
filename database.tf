# Grupo de subredes para la DB
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# Instancia de RDS (PostgreSQL) 
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  db_name                = "mi_base_de_datos"
  engine                 = "postgres"
  engine_version         = "16" # <--- "16" para la sub-versión estable más reciente
  instance_class         = "db.t4g.micro"
  username               = "dbadmin"
  password               = "PasswordSeguro123"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = true # Requisito de disponibilidad
  backup_retention_period = 7    # Retener backups por 7 días
  backup_window           = "03:00-04:00" # Ventana de backup diaria 
  delete_automated_backups = false
}

# Grupo de subredes para Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# Cluster de Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "backend-cache"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
}