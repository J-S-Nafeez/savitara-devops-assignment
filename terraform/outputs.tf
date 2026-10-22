output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "Direct URL to access the deployed application"
  value       = module.alb.app_url
}

output "health_check_url" {
  description = "Direct URL to verify application health"
  value       = "${module.alb.app_url}/health"
}

output "rds_endpoint" {
  description = "RDS MySQL connection endpoint"
  value       = module.rds.db_endpoint
}

output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret for database credentials"
  value       = module.secrets_manager.secret_arn
}

output "s3_app_storage_bucket" {
  description = "S3 bucket for application storage"
  value       = module.s3.app_bucket_id
}

output "s3_alb_logs_bucket" {
  description = "S3 bucket storing ALB access logs"
  value       = module.s3.alb_logs_bucket_id
}

output "autoscaling_group_name" {
  description = "Name of the EC2 Auto Scaling Group"
  value       = module.asg.autoscaling_group_name
}
