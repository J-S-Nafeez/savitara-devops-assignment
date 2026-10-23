variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "savitara"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for RDS credentials"
  type        = string
}

variable "app_s3_bucket_arn" {
  description = "ARN of the application S3 storage bucket"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

