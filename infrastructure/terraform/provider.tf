# ============================================
# AWS Provider Configuration
# ============================================
# This file configures the AWS provider for Terraform
# The provider is responsible for understanding API interactions
# and making requests to AWS services
# ============================================

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  # Tags applied to all resources
  default_tags {
    tags = {
      Project     = "StudySync"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Owner       = "DevOps-Team"
    }
  }
}

# ============================================
# Data Sources
# ============================================
# Fetch information about existing AWS resources

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}