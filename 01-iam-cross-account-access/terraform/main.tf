terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure your backend here
    # bucket = "your-terraform-state-bucket"
    # key    = "iam-cross-account/terraform.tfstate"
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
