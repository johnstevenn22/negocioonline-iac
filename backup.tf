resource "aws_backup_vault" "main_vault" {
  name = "${var.project_name}-vault-${var.environment}"
}

resource "aws_backup_plan" "main_plan" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "incremental-diario"
    target_vault_name = aws_backup_vault.main_vault.name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }

  rule {
    rule_name         = "full-mensual"
    target_vault_name = aws_backup_vault.main_vault.name
    schedule          = "cron(0 5 1 * ? *)"

    lifecycle {
      delete_after = 365
    }
  }
}

resource "aws_backup_selection" "backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.project_name}-backup-selection"
  plan_id      = aws_backup_plan.main_plan.id

  resources = [
    aws_db_instance.postgres.arn
  ]
}

resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}
