# ============================================
# Terraform Outputs
# ============================================
# Define outputs that will be displayed after terraform apply
# These values can be used by other Terraform configs or scripts
# ============================================

# ============================================
# Account Information
# ============================================

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

# ============================================
# VPC Outputs
# ============================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

# ============================================
# Load Balancer Outputs
# ============================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# ============================================
# Auto Scaling Outputs
# ============================================

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.studysync.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.studysync.arn
}

# ============================================
# Security Group Outputs
# ============================================

output "web_security_group_id" {
  description = "ID of web security group"
  value       = aws_security_group.web.id
}

# ============================================
# Connection Information
# ============================================

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for i, instance in aws_instance.studysync :
    "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_eip.studysync[i].public_ip}"
  ]
}

output "application_url" {
  description = "Application URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_eip.studysync[0].public_ip}"
}

# ============================================
# Summary Output
# ============================================

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment    = var.environment
    region         = var.aws_region
    vpc_id         = aws_vpc.main.id
    instance_count = length(aws_instance.studysync)
    elastic_ip     = aws_eip.studysync[0].public_ip
    domain         = var.domain_name
  }
}