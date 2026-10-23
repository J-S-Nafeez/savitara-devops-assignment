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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID for the ALB"
  type        = string
}

variable "app_port" {
  description = "Port the target instances listen on"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/health"
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "enable_https" {
  description = "Whether to enable HTTPS listener and redirect HTTP to HTTPS"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ARN of ACM SSL certificate for HTTPS listener (optional, self-signed created if empty and enable_https=true)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

