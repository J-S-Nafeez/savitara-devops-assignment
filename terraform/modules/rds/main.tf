locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -------------------------------------------------------------
# RDS MySQL Parameter Group (UTF-8 encoding)
# -------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-mysql8-params"
  family      = "mysql8.0"
  description = "Custom parameter group for ${var.project_name} MySQL 8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = var.tags
}

# -------------------------------------------------------------
# RDS MySQL Database Instance
# -------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier                 = "${local.name_prefix}-rds-mysql"
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  storage_type               = "gp3"
  storage_encrypted          = true
  multi_az                   = var.multi_az
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "Sun:04:30-Sun:05:30"
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${local.name_prefix}-rds-final-snapshot"
  deletion_protection       = false

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-rds-mysql"
      Environment = var.environment
    }
  )
}
