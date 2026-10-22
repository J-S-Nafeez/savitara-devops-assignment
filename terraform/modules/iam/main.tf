locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -------------------------------------------------------------
# EC2 IAM Role
# -------------------------------------------------------------
resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

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

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-ec2-role"
    }
  )
}

# -------------------------------------------------------------
# Secrets Manager Least-Privilege Policy
# -------------------------------------------------------------
resource "aws_iam_policy" "secrets_manager" {
  name        = "${local.name_prefix}-secrets-manager-policy"
  description = "Allows EC2 instance to read RDS database credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.secrets_manager.arn
}

# -------------------------------------------------------------
# S3 App Storage Access Policy
# -------------------------------------------------------------
resource "aws_iam_policy" "s3_access" {
  name        = "${local.name_prefix}-s3-app-policy"
  description = "Allows EC2 instance to read and write to the application S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.app_s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.app_s3_bucket_arn}/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# -------------------------------------------------------------
# AWS Systems Manager (SSM) Managed Policy
# Enables secure terminal access to private instances without open SSH ports
# -------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -------------------------------------------------------------
# CloudWatch Agent Policy for Logs & Metrics
# -------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# -------------------------------------------------------------
# IAM Instance Profile
# -------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2.name

  tags = var.tags
}
