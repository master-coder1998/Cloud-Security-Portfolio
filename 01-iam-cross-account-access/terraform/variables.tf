variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., production, staging, dev)"
  type        = string
}

variable "security_account_id" {
  description = "AWS Account ID of the security/admin account that will assume roles"
  type        = string
  sensitive   = true
}

variable "external_id" {
  description = "External ID for role assumption (prevents confused deputy problem)"
  type        = string
  sensitive   = true
}

variable "allowed_source_ips" {
  description = "List of allowed source IP addresses for incident response role"
  type        = list(string)
  default     = []
}

variable "cicd_role_arn" {
  description = "ARN of the CI/CD role that will assume the deployment role"
  type        = string
}

variable "deployment_bucket" {
  description = "S3 bucket name for deployment artifacts"
  type        = string
}
