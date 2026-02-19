# 1. Cola SQS para recibir mensajes de error del Backend
resource "aws_sqs_queue" "error_queue" {
  name = "backend-error-queue"
}

# 2. Rol de IAM para que la Lambda pueda ejecutarse y escribir logs
resource "aws_iam_role" "lambda_role" {
  name = "error_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. La Función Lambda (Funcion Error)
resource "aws_lambda_function" "error_func" {
  filename      = "lambda/funcion_error.zip"
  function_name = "Funcion_Error"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  # Evita errores si el zip aún no existe físicamente
  source_code_hash = filebase64sha256("lambda/funcion_error.zip")
}

# 4. Conectar SNS con Lambda 
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