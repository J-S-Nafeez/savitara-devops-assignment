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
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Port the application server listens on (e.g., 3000)"
  type        = number
  default     = 3000
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
