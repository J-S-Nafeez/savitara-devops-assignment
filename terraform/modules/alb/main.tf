locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -------------------------------------------------------------
# Optional Self-Signed Certificate when no custom ACM cert is provided
# -------------------------------------------------------------
resource "tls_private_key" "self_signed" {
  count     = var.enable_https && var.certificate_arn == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed" {
  count           = var.enable_https && var.certificate_arn == "" ? 1 : 0
  private_key_pem = tls_private_key.self_signed[0].private_key_pem

  subject {
    common_name  = "savitara-devops.internal"
    organization = "Savitara Infotel"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self_signed" {
  count            = var.enable_https && var.certificate_arn == "" ? 1 : 0
  private_key      = tls_private_key.self_signed[0].private_key_pem
  certificate_body = tls_self_signed_cert.self_signed[0].cert_pem

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-self-signed-cert"
    }
  )
}

locals {
  effective_cert_arn = var.certificate_arn != "" ? var.certificate_arn : (
    var.enable_https ? aws_acm_certificate.self_signed[0].arn : ""
  )
}

# -------------------------------------------------------------
# Application Load Balancer
# -------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-alb"
      Environment = var.environment
    }
  )
}

# -------------------------------------------------------------
# ALB Target Group
# -------------------------------------------------------------
resource "aws_lb_target_group" "main" {
  name                 = "${local.name_prefix}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-target-group"
    }
  )
}

# -------------------------------------------------------------
# HTTP Listener (Port 80) -> Redirect to HTTPS if enabled, or forward
# -------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-http-listener"
    }
  )
}

# -------------------------------------------------------------
# HTTPS Listener (Port 443)
# -------------------------------------------------------------
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.effective_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-https-listener"
    }
  )
}
