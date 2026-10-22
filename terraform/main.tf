# ==============================================================================
# Savitara Infotel DevOps Assessment - Complete AWS Infrastructure
# High Availability, Least Privilege, Multi-AZ, IaC with Terraform
# ==============================================================================

# 1. AWS Networking (VPC, Subnets, Gateways, Route Tables)
module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  single_nat_gateway       = true
  tags                     = var.tags
}

# 2. Security Groups (ALB, EC2 ASG, RDS)
module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  app_port     = var.app_port
  tags         = var.tags
}

# 3. AWS Secrets Manager (RDS Credentials with secure rotation/storage)
module "secrets_manager" {
  source = "./modules/secrets_manager"

  project_name = var.project_name
  environment  = var.environment
  db_username  = var.db_username
  db_name      = var.db_name
  tags         = var.tags
}

# 4. S3 Buckets (Application Storage + ALB Access Logs)
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = var.tags
}

# 5. IAM Roles and Policies (Least Privilege Instance Profile)
module "iam" {
  source = "./modules/iam"

  project_name      = var.project_name
  environment       = var.environment
  db_secret_arn     = module.secrets_manager.secret_arn
  app_s3_bucket_arn = module.s3.app_bucket_arn
  tags              = var.tags
}

# 6. RDS MySQL Database (Deployed in Private Subnets)
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.security_groups.rds_security_group_id
  db_name               = var.db_name
  db_username           = module.secrets_manager.db_username
  db_password           = module.secrets_manager.db_password
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  multi_az              = var.rds_multi_az
  skip_final_snapshot   = true
  tags                  = var.tags
}

# 7. Application Load Balancer with HTTPS & HTTP Redirect
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  app_port              = var.app_port
  health_check_path     = "/health"
  alb_logs_bucket       = module.s3.alb_logs_bucket_id
  enable_https          = var.enable_https
  certificate_arn       = var.certificate_arn
  tags                  = var.tags
}

# 8. EC2 Auto Scaling Group with Launch Template
module "asg" {
  source = "./modules/asg"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  ec2_security_group_id  = module.security_groups.ec2_security_group_id
  instance_profile_name  = module.iam.instance_profile_name
  target_group_arn       = module.alb.target_group_arn
  instance_type          = var.instance_type
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  db_secret_arn          = module.secrets_manager.secret_arn
  app_s3_bucket          = module.s3.app_bucket_id
  tags                   = var.tags

  depends_on = [module.rds]
}
