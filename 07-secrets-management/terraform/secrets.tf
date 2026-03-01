# Database credentials secret with automatic rotation
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-${var.environment}-db-credentials"
  description             = "Database credentials with automatic rotation"
  kms_key_id              = aws_kms_key.rds_secrets.id
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name        = "${var.project_name}-db-credentials"
    Environment = var.environment
    Rotation    = "enabled"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = "postgres"
    host     = "db.example.com"
    port     = 5432
    dbname   = "production"
  })
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

# API key secret without rotation (third-party managed)
resource "aws_secretsmanager_secret" "api_key" {
  name                    = "${var.project_name}-${var.environment}-external-api-key"
  description             = "Third-party API key (manual rotation)"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name        = "${var.project_name}-api-key"
    Environment = var.environment
    Rotation    = "manual"
  })
}

# OAuth credentials
resource "aws_secretsmanager_secret" "oauth_credentials" {
  name                    = "${var.project_name}-${var.environment}-oauth-credentials"
  description             = "OAuth client credentials"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name        = "${var.project_name}-oauth-credentials"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "oauth_credentials" {
  secret_id = aws_secretsmanager_secret.oauth_credentials.id
  secret_string = jsonencode({
    client_id     = "example-client-id"
    client_secret = random_password.oauth_secret.result
    token_url     = "https://auth.example.com/oauth/token"
  })
}

resource "random_password" "oauth_secret" {
  length  = 40
  special = false
}

# Rotation schedule for database credentials
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
