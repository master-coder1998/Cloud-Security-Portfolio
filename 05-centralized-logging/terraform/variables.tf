variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "log_archive_bucket" {
  description = "Name of the centralized log archive bucket"
  type        = string
  default     = ""
}

variable "enable_object_lock" {
  description = "Whether to enable S3 Object Lock (WORM)"
  type        = bool
  default     = false
}
