output "security_audit_role_arn" {
  description = "ARN of the Security Audit Role"
  value       = aws_iam_role.security_audit_role.arn
}

output "incident_response_role_arn" {
  description = "ARN of the Incident Response Role"
  value       = aws_iam_role.incident_response_role.arn
}

output "deployment_role_arn" {
  description = "ARN of the Deployment Role"
  value       = aws_iam_role.deployment_role.arn
}

output "role_assumption_command_security_audit" {
  description = "AWS CLI command to assume the Security Audit Role"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.security_audit_role.arn} --role-session-name security-audit-session --external-id <EXTERNAL_ID> --serial-number <MFA_DEVICE_ARN> --token-code <MFA_CODE>"
}

output "role_assumption_command_incident_response" {
  description = "AWS CLI command to assume the Incident Response Role"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.incident_response_role.arn} --role-session-name incident-response-session --external-id <EXTERNAL_ID> --serial-number <MFA_DEVICE_ARN> --token-code <MFA_CODE>"
}
