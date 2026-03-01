# Lambda execution role for secret rotation
resource "aws_iam_role" "rotation_lambda" {
  name = "${var.project_name}-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rotation_lambda" {
  name = "${var.project_name}-rotation-policy"
  role = aws_iam_role.rotation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.rds_secrets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# Lambda function for rotation
# Note: Run 'cd lambda && zip rotation.zip rotation.py' before terraform apply
resource "aws_lambda_function" "rotate_secret" {
  filename         = "${path.module}/lambda/rotation.zip"
  function_name    = "${var.project_name}-rotate-secret"
  role             = aws_iam_role.rotation_lambda.arn
  handler          = "rotation.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = fileexists("${path.module}/lambda/rotation.zip") ? filebase64sha256("${path.module}/lambda/rotation.zip") : null

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# Permission for Secrets Manager to invoke Lambda
resource "aws_lambda_permission" "allow_secrets_manager" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secret.function_name
  principal     = "secretsmanager.amazonaws.com"
}
