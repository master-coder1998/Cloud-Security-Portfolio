terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure remote state backend as needed
    # bucket = "your-terraform-state-bucket"
    # key    = "centralized-logging/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CloudSecurityPortfolio"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
