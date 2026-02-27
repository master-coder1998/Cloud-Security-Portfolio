/*
Skeleton CloudWatch alarms for log delivery failures and validation issues.
Configure SNS targets and appropriate metric filters before enabling.
*/

resource "aws_cloudwatch_metric_alarm" "log_delivery_failure" {
  alarm_name          = "log-delivery-failure-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryFailures"
  namespace           = "AWS/Logs"
  period              = 300
  threshold           = 1
  alarm_description   = "Alert when CloudWatch Logs delivery to S3 fails"
}
