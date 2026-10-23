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

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "private_app_subnet_ids" {
  description = "Private application subnets for EC2 instances"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "Security Group ID for EC2 instances"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name attached to EC2 instances"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN of the Application Load Balancer"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret for database credentials"
  type        = string
}

variable "db_host" {
  description = "Host endpoint of the RDS MySQL instance"
  type        = string
  default     = ""
}

variable "app_s3_bucket" {
  description = "Name of application S3 storage bucket"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

