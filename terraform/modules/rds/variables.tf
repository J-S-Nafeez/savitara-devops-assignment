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

variable "db_subnet_group_name" {
  description = "DB subnet group name created in VPC module"
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS MySQL"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "savitara_db"
}

variable "db_username" {
  description = "Master database username"
  type        = string
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage limit in GB for autoscaling"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Deploy RDS across multiple AZs for high availability"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying RDS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

