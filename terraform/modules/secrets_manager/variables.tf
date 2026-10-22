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

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "savitara_db"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
