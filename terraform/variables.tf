# ============================================
# Terraform Variables
# ============================================
# Define all input variables for the infrastructure
# These can be overridden via terraform.tfvars
# ============================================

# ============================================
# General Configuration
# ============================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "studysync"
}

# ============================================
# VPC Configuration
# ============================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

# ============================================
# EC2 Configuration
# ============================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
  default     = ""
}

variable "enable_public_ip" {
  description = "Associate public IP address with EC2 instances"
  type        = bool
  default     = true
}

# ============================================
# Application Configuration
# ============================================

variable "backend_port" {
  description = "Port for backend application"
  type        = number
  default     = 3000
}

variable "frontend_port" {
  description = "Port for frontend application"
  type        = number
  default     = 8080
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "jettoner.xyz"
}

# ============================================
# Auto Scaling Configuration
# ============================================

variable "min_size" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in auto scaling group"
  type        = number
  default     = 2
}

# ============================================
# Cache Configuration
# ============================================

variable "enable_elasticache" {
  description = "Enable ElastiCache Redis cluster"
  type        = bool
  default     = false
}

# ============================================
# Monitoring Configuration
# ============================================

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = ""
}

# ============================================
# Tags
# ============================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}