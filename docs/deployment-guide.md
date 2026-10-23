# Step-by-Step Deployment Guide

This guide covers local provisioning, configuration, verification, and automated GitHub Actions CI/CD deployment for the **Savitara Infotel DevOps Assessment**.

---

## 1. Prerequisites

Before beginning, ensure the following tools are installed and configured:
- **AWS CLI v2**: `aws --version` (authenticated with Administrator or DevOps IAM permissions via `aws configure`).
- **Terraform**: `terraform -version` (>= 1.5.0 recommended).
- **Node.js**: `node -v` (v18.x or v20.x+) and `npm -v`.
- **Git**: `git --version`.

---

## 2. Repository Structure Overview

```
savitara-devops-assignment/
├── .github/workflows/
│   └── terraform-ci-cd.yml      # Automated GitHub Actions workflow (test, plan, apply, health check)
├── app/
│   ├── package.json             # Express, AWS SDK v3, MySQL2 dependencies
│   ├── server.js                # Core app logic with /health and Secrets Manager integration
│   ├── app.test.js              # Unit tests
│   ├── Dockerfile               # Multi-stage production container build
│   └── app.service              # Systemd unit configuration
├── terraform/
│   ├── main.tf                  # Root Terraform entrypoint combining all 8 modules
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Infrastructure outputs (ALB DNS, URLs, RDS endpoint)
│   ├── versions.tf              # Provider constraints (AWS, TLS, Random)
│   ├── terraform.tfvars.example # Example variable definitions
│   └── modules/
│       ├── vpc/                 # Multi-AZ VPC, subnets, IGW, NAT GW, route tables
│       ├── security_groups/     # Chained ALB -> EC2 -> RDS security groups
│       ├── secrets_manager/     # High-entropy password generation & secret vault
│       ├── s3/                  # Application storage bucket & ALB access logs bucket
│       ├── iam/                 # EC2 IAM instance profile (least-privilege)
│       ├── rds/                 # Private Amazon RDS MySQL 8.0 instance
│       ├── alb/                 # Public ALB, Target Group, HTTPS/ACM, HTTP-to-HTTPS redirect
│       └── asg/                 # Launch template, user-data bootstrap, target tracking policy
├── docs/
│   ├── architecture-diagram.md  # Mermaid diagram and network flow
│   ├── deployment-guide.md      # Detailed operational runbook
│   ├── security-matrix.md       # CIDR, Security Group, and IAM privilege specifications
│   └── screenshots/             # Deployment evidence placeholders & guide
└── README.md                    # Primary repository overview
```

---

## 3. Local Deployment via Terraform CLI

### Step 3.1: Configure Variables
Navigate into the `terraform/` directory:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Adjust parameters in `terraform.tfvars` if needed:
- `aws_region`: Target AWS region (default `ap-south-1` Mumbai).
- `project_name`: Resource naming prefix (default `savitara`).
- `environment`: `prod`.
- `enable_https`: `true`.
- `certificate_arn`: Optional existing ACM certificate ARN. If left empty `""`, a secure self-signed ACM certificate is automatically generated.

### Step 3.2: Initialize Terraform
```bash
terraform init
```

### Step 3.3: Validate Formatting and Syntax
```bash
terraform fmt -check -recursive
terraform validate
```

### Step 3.4: Review Execution Plan
```bash
terraform plan -out=tfplan
```
Review the planned 35+ AWS resources including VPC, subnets, NAT Gateway, Security Groups, Launch Template, ASG, ALB, RDS instance, and S3 buckets.

### Step 3.5: Apply Infrastructure
```bash
terraform apply tfplan
```
*Note: Provisioning the NAT Gateway and RDS MySQL instance typically takes ~4 to 7 minutes.*

### Step 3.6: Capture Outputs
Upon completion, Terraform prints the output summary:
```bash
Outputs:
alb_dns_name = "savitara-prod-alb-123456789.ap-south-1.elb.amazonaws.com"
application_url = "https://savitara-prod-alb-123456789.ap-south-1.elb.amazonaws.com"
health_check_url = "https://savitara-prod-alb-123456789.ap-south-1.elb.amazonaws.com/health"
rds_endpoint = "savitara-prod-rds-mysql.xxxxx.ap-south-1.rds.amazonaws.com:3306"
s3_alb_logs_bucket = "savitara-prod-alb-logs-xxxx"
s3_app_storage_bucket = "savitara-prod-app-storage-xxxx"
secrets_manager_arn = "arn:aws:secretsmanager:ap-south-1:123456789012:secret:savitara-prod-rds-mysql-credentials-xxxxx"
```

---

## 4. End-to-End Health Verification

### 1. Test HTTP to HTTPS Redirection:
```bash
curl -I -L http://<YOUR_ALB_DNS_NAME>
```
*Expected*: Receives HTTP `301 Moved Permanently` pointing to `https://<YOUR_ALB_DNS_NAME>`, followed by HTTP `200 OK`.

### 2. Test Application Health Endpoint:
```bash
curl -k https://<YOUR_ALB_DNS_NAME>/health
```
*Expected Output*:
```json
{
  "status": "UP",
  "timestamp": "2026-10-22T10:15:30.000Z",
  "uptime": 128.4,
  "hostname": "ip-10-0-11-84.ap-south-1.compute.internal",
  "service": "savitara-devops-app"
}
```

### 3. Test Database Connectivity:
```bash
curl -k https://<YOUR_ALB_DNS_NAME>/api/db-status
```
*Expected Output*:
```json
{
  "status": "SUCCESS",
  "message": "Successfully connected and queried Amazon RDS MySQL",
  "credentialsSource": "AWS Secrets Manager",
  "data": {
    "solution": 2,
    "current_time": "2026-10-22T10:15:35.000Z",
    "db_version": "8.0.36"
  }
}
```

### 4. Test S3 Read/Write:
```bash
curl -k https://<YOUR_ALB_DNS_NAME>/api/s3-test
```
*Expected Output*:
```json
{
  "status": "SUCCESS",
  "message": "Successfully verified S3 Bucket read/write operations",
  "bucket": "savitara-prod-app-storage-xxxx",
  "key": "health-checks/ping-1729592135000.txt"
}
```

---

## 5. GitHub Actions CI/CD Setup

1. Create a GitHub repository and push this codebase:
   ```bash
   git init
   git add .
   git commit -m "feat: complete AWS infrastructure and CI/CD pipeline"
   git branch -M main
   git remote add origin https://github.com/J-S-Nafeez/savitara-devops-assignment.git
   git push -u origin main
   ```
2. Navigate to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions**.
3. Add the following repository secrets:
   - `AWS_ACCESS_KEY_ID`: AWS IAM User Access Key.
   - `AWS_SECRET_ACCESS_KEY`: AWS IAM User Secret Key.
   - `AWS_REGION`: Target region (e.g. `ap-south-1`).
4. Any pull request automatically triggers the application unit tests and `terraform plan`.
5. Merging to `main` executes `terraform apply` followed by the automated curl health check.

---

## 6. Teardown & Resource Cleanup

To prevent ongoing cloud costs, destroy the provisioned infrastructure when evaluation is complete:
```bash
terraform destroy -auto-approve
```
*Or execute the `destroy` action via the GitHub Actions manual workflow dispatch.*

