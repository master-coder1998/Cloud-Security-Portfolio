output "db_credentials_secret_arn" {
  description = "ARN of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "api_key_secret_arn" {
  description = "ARN of API key secret"
  value       = aws_secretsmanager_secret.api_key.arn
}

output "oauth_credentials_secret_arn" {
  description = "ARN of OAuth credentials secret"
  value       = aws_secretsmanager_secret.oauth_credentials.arn
}

output "app_role_arn" {
  description = "ARN of application IAM role"
  value       = aws_iam_role.app_role.arn
}

output "api_service_role_arn" {
  description = "ARN of API service IAM role"
  value       = aws_iam_role.api_service_role.arn
}

output "kms_key_id" {
  description = "KMS key ID for secrets encryption"
  value       = aws_kms_key.secrets.id
}

output "rotation_lambda_arn" {
  description = "ARN of rotation Lambda function"
  value       = aws_lambda_function.rotate_secret.arn
}
