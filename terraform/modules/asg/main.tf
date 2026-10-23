locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Fetch latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# -------------------------------------------------------------
# EC2 Launch Template
# -------------------------------------------------------------
resource "aws_launch_template" "main" {
  name_prefix   = "${local.name_prefix}-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_security_group_id]
  }

  # Render user-data script
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tftpl", {
    aws_region    = var.aws_region
    db_secret_arn = var.db_secret_arn
    db_host       = var.db_host
    app_s3_bucket = var.app_s3_bucket
  }))

  # Enforce IMDSv2 (AWS Security Best Practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name        = "${local.name_prefix}-asg-instance"
        Environment = var.environment
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------------------------------------------
# Auto Scaling Group
# -------------------------------------------------------------
resource "aws_autoscaling_group" "main" {
  name_prefix         = "${local.name_prefix}-asg-"
  vpc_zone_identifier = var.private_app_subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app-node"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# -------------------------------------------------------------
# Target Tracking Scaling Policy (CPU Utilization 70%)
# -------------------------------------------------------------
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
