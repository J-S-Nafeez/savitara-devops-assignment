output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "The hostname / address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

output "db_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}
