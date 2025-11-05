# ============================================
# Auto Scaling Group
# ============================================

resource "aws_autoscaling_group" "studysync" {
  name_prefix         = "${var.project_name}-${var.environment}-asg-"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns = [
    aws_lb_target_group.backend.arn,
    aws_lb_target_group.frontend.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity

  launch_template {
    id      = aws_launch_template.studysync.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "AutoScaling"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  depends_on = [
    aws_lb.main,
    aws_lb_target_group.backend,
    aws_lb_target_group.frontend
  ]
}

# ============================================
# Auto Scaling Policies
# ============================================

# Scale Up Policy (CPU > 70%)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.studysync.name
}

# Scale Down Policy (CPU < 30%)
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.studysync.name
}

# ============================================
# CloudWatch Alarms for Auto Scaling
# ============================================

# High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This metric monitors high CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.studysync.name
  }
}

# Low CPU Alarm
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "This metric monitors low CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.studysync.name
  }
}

# ============================================
# Scheduled Scaling (Optional)
# ============================================

# Scale up during business hours
resource "aws_autoscaling_schedule" "scale_up_morning" {
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-up-morning"
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.desired_capacity
  recurrence             = "0 8 * * MON-FRI"
  autoscaling_group_name = aws_autoscaling_group.studysync.name
}

# Scale down after business hours
resource "aws_autoscaling_schedule" "scale_down_evening" {
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-down-evening"
  min_size               = 1
  max_size               = var.max_size
  desired_capacity       = 1
  recurrence             = "0 20 * * MON-FRI"
  autoscaling_group_name = aws_autoscaling_group.studysync.name
}