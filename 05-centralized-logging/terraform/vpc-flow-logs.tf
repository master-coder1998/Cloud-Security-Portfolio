resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.environment}"
  retention_in_days = 90
}

resource "aws_flow_log" "vpc_flow" {
  iam_role_arn = "" # fill with appropriate role
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type = "ALL"
  vpc_id = "" # set via variable or data source
}
