# CloudWatch monitoring for cross-account role assumptions

resource "aws_cloudwatch_log_metric_filter" "security_audit_role_assumption" {
  name           = "SecurityAuditRoleAssumption"
  log_group_name = "/aws/cloudtrail/organization"
  
  pattern = <<PATTERN
{
  ($.eventName = "AssumeRole") &&
  ($.requestParameters.roleArn = "${aws_iam_role.security_audit_role.arn}")
}
PATTERN

  metric_transformation {
    name      = "SecurityAuditRoleAssumptionCount"
    namespace = "CrossAccountAccess"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_audit_role_assumption_alarm" {
  alarm_name          = "SecurityAuditRoleAssumed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityAuditRoleAssumptionCount"
  namespace           = "CrossAccountAccess"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when Security Audit Role is assumed"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "failed_role_assumption" {
  name           = "FailedCrossAccountRoleAssumption"
  log_group_name = "/aws/cloudtrail/organization"
  
  pattern = <<PATTERN
{
  ($.eventName = "AssumeRole") &&
  ($.errorCode = "*") &&
  (($.requestParameters.roleArn = "${aws_iam_role.security_audit_role.arn}") ||
   ($.requestParameters.roleArn = "${aws_iam_role.incident_response_role.arn}") ||
   ($.requestParameters.roleArn = "${aws_iam_role.deployment_role.arn}"))
}
PATTERN

  metric_transformation {
    name      = "FailedRoleAssumptionCount"
    namespace = "CrossAccountAccess"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_role_assumption_alarm" {
  alarm_name          = "FailedCrossAccountRoleAssumption"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedRoleAssumptionCount"
  namespace           = "CrossAccountAccess"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Alert when multiple failed role assumption attempts detected"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "incident_response_role_assumption" {
  name           = "IncidentResponseRoleAssumption"
  log_group_name = "/aws/cloudtrail/organization"
  
  pattern = <<PATTERN
{
  ($.eventName = "AssumeRole") &&
  ($.requestParameters.roleArn = "${aws_iam_role.incident_response_role.arn}")
}
PATTERN

  metric_transformation {
    name      = "IncidentResponseRoleAssumptionCount"
    namespace = "CrossAccountAccess"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "incident_response_role_assumption_alarm" {
  alarm_name          = "IncidentResponseRoleAssumed-URGENT"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "IncidentResponseRoleAssumptionCount"
  namespace           = "CrossAccountAccess"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "URGENT: Incident Response Role has been assumed"
  treat_missing_data  = "notBreaching"
}
