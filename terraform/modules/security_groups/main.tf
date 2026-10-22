locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -------------------------------------------------------------
# 1. Application Load Balancer Security Group
# -------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for public facing Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow HTTP inbound from anywhere (for redirect to HTTPS)"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow HTTPS inbound from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-alb-sg"
      Tier = "Public-ALB"
    }
  )
}

# -------------------------------------------------------------
# 2. EC2 Auto Scaling Application Security Group
# -------------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-app-sg"
  description = "Security group for private EC2 instances hosting the app"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic ONLY from ALB security group on application port"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound Internet via NAT Gateway for OS updates, S3, and Secrets Manager"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-ec2-app-sg"
      Tier = "Private-App"
    }
  )
}

# -------------------------------------------------------------
# 3. RDS MySQL Database Security Group
# -------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-mysql-sg"
  description = "Security group for private RDS MySQL database instance"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL traffic ONLY from EC2 application security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "No outbound traffic required for isolated RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-rds-sg"
      Tier = "Private-Database"
    }
  )
}
