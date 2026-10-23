output "app_bucket_id" {
  description = "Name of the application storage S3 bucket"
  value       = aws_s3_bucket.app_storage.id
}

output "app_bucket_arn" {
  description = "ARN of the application storage S3 bucket"
  value       = aws_s3_bucket.app_storage.arn
}

output "alb_logs_bucket_id" {
  description = "Name of the ALB access logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB access logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.arn
}

