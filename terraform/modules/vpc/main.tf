locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -------------------------------------------------------------
# VPC
# -------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-vpc"
      Environment = var.environment
    }
  )
}

# -------------------------------------------------------------
# Internet Gateway
# -------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-igw"
      Environment = var.environment
    }
  )
}

# -------------------------------------------------------------
# Public Subnets (ALB & NAT Gateway)
# -------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                     = "${local.name_prefix}-public-subnet-${var.availability_zones[count.index]}"
      Type                     = "Public"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# -------------------------------------------------------------
# Private App Subnets (EC2 Auto Scaling Group)
# -------------------------------------------------------------
resource "aws_subnet" "private_app" {
  count                   = length(var.private_app_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-private-app-subnet-${var.availability_zones[count.index]}"
      Type = "Private-App"
    }
  )
}

# -------------------------------------------------------------
# Private Database Subnets (RDS MySQL)
# -------------------------------------------------------------
resource "aws_subnet" "private_db" {
  count                   = length(var.private_db_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-private-db-subnet-${var.availability_zones[count.index]}"
      Type = "Private-Database"
    }
  )
}

# -------------------------------------------------------------
# Elastic IP & NAT Gateway
# -------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-nat-eip"
    }
  )
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-nat-gw"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# -------------------------------------------------------------
# Route Tables & Associations
# -------------------------------------------------------------

# Public Route Table (Outbound via IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private App Route Table (Outbound via NAT Gateway)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-private-app-rt"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# Private DB Route Table (Fully isolated, internal only)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-private-db-rt"
    }
  )
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}

# -------------------------------------------------------------
# RDS DB Subnet Group
# -------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${var.project_name} RDS MySQL"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-db-subnet-group"
    }
  )
}
