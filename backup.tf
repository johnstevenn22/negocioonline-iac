# Bóveda de Backup (Backup Vault)
resource "aws_backup_vault" "main_vault" {
  name = "boveda-principal-restaurante"
}

resource "aws_backup_plan" "main_plan" {
  name = "plan-continuidad-negocio"

  # Backups Incrementales cada 24 horas
  rule {
    rule_name         = "incremental-diario"
    target_vault_name = aws_backup_vault.main_vault.name
    schedule          = "cron(0 5 * * ? *)" # todos los dias a las 05:00 UTC
    
    lifecycle {
      delete_after = 30 # Guardar por 30 días
    }
  }

  # Full Backups Mensuales
  rule {
    rule_name         = "full-mensual"
    target_vault_name = aws_backup_vault.main_vault.name
    schedule          = "cron(0 5 1 * ? *)" # El primer día de cada mes
    
    lifecycle {
      delete_after = 365 # Guardar por 1 año para auditoría
    }
  }
}

# 3. Selección de Recursos
resource "aws_backup_selection" "backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "respaldo-infraestructura-critica"
  plan_id      = aws_backup_plan.main_plan.id

  # Selección dinámica por etiquetas y ARN de RDS
  resources = [
    aws_db_instance.postgres.arn
  ]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Role"
    value = "Backend"
  }
}

# Rol de IAM necesario para que AWS Backup funcione
resource "aws_iam_role" "backup_role" {
  name = "backup_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}