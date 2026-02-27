resource "aws_s3_bucket" "log_archive" {
  bucket = var.log_archive_bucket != "" ? var.log_archive_bucket : "central-log-archive-${var.environment}-${random_id.bucket_id.hex}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.log_key.id
      }
    }
  }

  lifecycle_rule {
    id      = "archive"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  # Note: Object Lock and MFA Delete require special bucket creation and cannot
  # be toggled after creation. Enable via the console or provider-specific
  # configuration when needed; variables exist to signal intent.
}

resource "random_id" "bucket_id" {
  byte_length = 4
}
