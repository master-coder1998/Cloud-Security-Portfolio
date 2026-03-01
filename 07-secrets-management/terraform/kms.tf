resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting secrets"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-secrets-key"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# Separate KMS key for RDS credentials
resource "aws_kms_key" "rds_secrets" {
  description             = "KMS key for RDS database credentials"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-rds-secrets-key"
  })
}

resource "aws_kms_alias" "rds_secrets" {
  name          = "alias/${var.project_name}-rds-secrets"
  target_key_id = aws_kms_key.rds_secrets.key_id
}
