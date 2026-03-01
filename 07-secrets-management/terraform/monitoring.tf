# CloudWatch log group for secret access
resource "aws_cloudwatch_log_group" "secret_access" {
  name              = "/aws/secretsmanager/${var.project_name}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.secrets.arn

  tags = var.tags
}

# Metric filter for failed secret retrievals
resource "aws_cloudwatch_log_metric_filter" "failed_secret_access" {
  name           = "${var.project_name}-failed-secret-access"
  log_group_name = aws_cloudwatch_log_group.secret_access.name
  pattern        = "[time, request_id, event_type = GetSecretValue, status = Failed*, ...]"

  metric_transformation {
    name      = "FailedSecretAccess"
    namespace = "SecretsManager"
    value     = "1"
  }
}

# Alarm for failed access attempts
resource "aws_cloudwatch_metric_alarm" "failed_secret_access" {
  alarm_name          = "${var.project_name}-failed-secret-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedSecretAccess"
  namespace           = "SecretsManager"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert on multiple failed secret access attempts"
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# Metric filter for rotation failures
resource "aws_cloudwatch_log_metric_filter" "rotation_failure" {
  name           = "${var.project_name}-rotation-failure"
  log_group_name = aws_cloudwatch_log_group.secret_access.name
  pattern        = "[time, request_id, event_type = RotateSecret, status = Failed*, ...]"

  metric_transformation {
    name      = "RotationFailure"
    namespace = "SecretsManager"
    value     = "1"
  }
}

# Alarm for rotation failures
resource "aws_cloudwatch_metric_alarm" "rotation_failure" {
  alarm_name          = "${var.project_name}-rotation-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RotationFailure"
  namespace           = "SecretsManager"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert on secret rotation failures"
  treat_missing_data  = "notBreaching"

  tags = var.tags
}
