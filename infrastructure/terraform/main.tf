# ============================================
# StudySync Infrastructure - Simple Start
# ============================================
# This creates a basic EC2 instance to get started
# We'll build on this to create a full production setup
# ============================================

# ============================================
# VPC (Virtual Private Cloud)
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ============================================
# Internet Gateway
# ============================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ============================================
# Public Subnet
# ============================================

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type = "public"
  }
}

# ============================================
# Route Table
# ============================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Security Group - Web Server
# ============================================

resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Backend API
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Backend API"
  }

  # SSH (restrict to your IP in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere (change in production!)"
  }

  # Outbound - allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# EC2 Instance - StudySync Server
# ============================================

resource "aws_instance" "studysync" {
  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = var.enable_public_ip

  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    project     = var.project_name
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-server-${count.index + 1}"
    Environment = var.environment
    Backup      = "true"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

# ============================================
# Elastic IP (Optional but Recommended)
# ============================================

resource "aws_eip" "studysync" {
  count    = 1
  domain   = "vpc"
  instance = aws_instance.studysync[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}