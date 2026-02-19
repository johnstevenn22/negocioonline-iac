resource "aws_sqs_queue" "error_queue" {
  name                              = "${var.project_name}-error-queue"
  kms_master_key_id                 = aws_kms_key.main.id
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name        = "${var.project_name}-error-queue"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                              = "${var.project_name}-lambda-dlq"
  kms_master_key_id                 = aws_kms_key.main.id
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600

  tags = {
    Name        = "${var.project_name}-lambda-dlq"
    Environment = var.environment
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main_vpc.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lambda-sg"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_ses" {
  name = "${var.project_name}-lambda-ses"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = [
        "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${var.project_name}-lambda-sqs"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ]
      Resource = [
        aws_sqs_queue.lambda_dlq.arn,
        aws_sqs_queue.error_queue.arn
      ]
    }]
  })
}

resource "aws_signer_signing_profile" "lambda_signing" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "${replace(var.project_name, "-", "")}lambdasigning${var.environment}"

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }

  tags = {
    Name        = "${var.project_name}-lambda-signing"
    Environment = var.environment
  }
}

resource "aws_lambda_code_signing_config" "lambda_code_signing" {
  description = "Code signing config for Lambda functions"

  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_signing.arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

resource "aws_lambda_function" "error_func" {
  filename                       = "lambda/funcion_error.zip"
  function_name                  = "${var.project_name}-error-handler"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  source_code_hash               = filebase64sha256("lambda/funcion_error.zip")
  reserved_concurrent_executions = 50
  code_signing_config_arn        = aws_lambda_code_signing_config.lambda_code_signing.arn

  vpc_config {
    subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ALERT_EMAIL = var.alert_email
      ENVIRONMENT = var.environment
    }
  }

  kms_key_arn = aws_kms_key.main.arn

  tags = {
    Name        = "${var.project_name}-error-handler"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.error_func.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.error_func.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}
