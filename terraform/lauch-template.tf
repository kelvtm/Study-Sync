# ============================================
# Launch Template for Auto Scaling
# ============================================
# Defines how EC2 instances should be launched
# Used by Auto Scaling Group
# ============================================

resource "aws_launch_template" "studysync" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  description   = "Launch template for StudySync application"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  # Network interface configuration
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.backend.id]
    delete_on_termination       = true
  }

  # Storage configuration
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # IAM instance profile (for CloudWatch, SSM, etc.)
  iam_instance_profile {
    name = aws_iam_instance_profile.studysync.name
  }

  # User data - bootstrap script
  user_data = base64encode(templatefile("${path.module}/user-data-asg.sh", {
    environment     = var.environment
    project         = var.project_name
    alb_dns_name    = aws_lb.main.dns_name
    backend_port    = var.backend_port
    frontend_port   = var.frontend_port  // Add this line
   env_content    = templatefile("${path.module}/templates/env.tpl", {
      mongodb_uri  = var.mongodb_uri
    })
    docker_username = "kelvtmoni"
    docker_backend  = "kelvtmoni/studysync-backend"
    docker_frontend = "kelvtmoni/studysync-frontend"
  }))

  # Instance metadata options (security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-asg-instance"
      Environment = var.environment
      ManagedBy   = "AutoScaling"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-launch-template"
  }

  lifecycle {
    create_before_destroy = true
  }
}