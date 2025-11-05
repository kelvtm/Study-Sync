# ============================================
# IAM Role for EC2 Instances
# ============================================

# ============================================
# IAM Role
# ============================================

resource "aws_iam_role" "studysync" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# ============================================
# IAM Instance Profile
# ============================================

resource "aws_iam_instance_profile" "studysync" {
  name_prefix = "${var.project_name}-${var.environment}-"
  role        = aws_iam_role.studysync.name

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-profile"
  }
}

# ============================================
# Attach Policies to IAM Role
# ============================================

# CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.studysync.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# SSM Policy (for Systems Manager)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.studysync.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ECR Read-Only (to pull Docker images if using ECR)
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.studysync.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ============================================
# Custom Policy for S3 Backups (Optional)
# ============================================

resource "aws_iam_role_policy" "s3_backups" {
  name_prefix = "s3-backups-"
  role        = aws_iam_role.studysync.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::studysync-backups-*",
          "arn:aws:s3:::studysync-backups-*/*"
        ]
      }
    ]
  })
}