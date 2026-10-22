locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Generate random secure master password for MySQL
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name_prefix}-rds-mysql-credentials"
  description             = "Master credentials for ${var.project_name} RDS MySQL database"
  recovery_window_in_days = 0 # Immediate deletion upon terraform destroy

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-rds-credentials"
      Environment = var.environment
    }
  )
}

# Secrets Manager Secret Version (JSON payload)
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = "mysql"
    host     = "" # Will be populated or read alongside rds endpoint
    port     = 3306
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
  })
}
