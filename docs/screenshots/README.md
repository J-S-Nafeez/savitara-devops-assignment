# Live Infrastructure & Deployment Verification Evidence

This document catalogues all live deployment verification evidence captured directly from the AWS Management Console, live HTTPS web application, API endpoints, and GitHub Actions CI/CD pipeline for the **Savitara Infotel DevOps Practical Assessment**.

---

## 📸 Comprehensive Verification Evidence Index

The following screenshots document every single architectural requirement running live in AWS Region `ap-south-1` (Mumbai), deployed under Account ID `878021513476`.

### 1. Live Web Application & API Health Verification
| Item | Verification View | Live AWS Evidence Observed | Screenshot Reference |
|---|---|---|---|
| **1.1** | **Application Web Dashboard** | • HTTPS locked connection to `https://savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com`<br/>• System status: **Healthy & Running**<br/>• Database Status: **UP** (Connected to RDS MySQL 8.0)<br/>• EC2 Hostname: `ip-10-0-12-12.ap-south-1.compute.internal`<br/>• AWS Region: `ap-south-1` | `01-live-app-dashboard.png` |
| **1.2** | **RDS MySQL Connectivity Endpoint** | • URL: `/api/db-status`<br/>• JSON Response: `{"status":"UP","details":{"solution":2,"server_time":"2026-10-24T02:20:18.000Z","db_version":"8.0.46-eol-2-rds.20260908"}}`<br/>• Demonstrates successful query execution over private TCP port 3306 | `02-api-db-status.png` |
| **1.3** | **S3 Integration Test Endpoint** | • URL: `/api/s3-test`<br/>• JSON Response: `{"status":"SUCCESS","bucket":"savitara-prod-app-storage-dlq50jqw","verifiedKey":"health-checks/ping-1792808428133.txt"}`<br/>• Demonstrates IAM Role instance profile writing and reading from S3 | `03-api-s3-test.png` |

---

### 2. Application Load Balancer (ALB) & Routing
| Item | Verification View | Live AWS Evidence Observed | Screenshot Reference |
|---|---|---|---|
| **2.1** | **ALB Core Details** | • Name: `savitara-prod-alb`<br/>• Status: **Active**<br/>• Scheme: **Internet-facing**<br/>• DNS: `savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com`<br/>• Multi-AZ Subnets attached: `savitara-prod-public-subnet-1`, `savitara-prod-public-subnet-2` | `04-alb-details-active.png` |
| **2.2** | **ALB Listeners & 301 Redirect** | • **HTTP: 80**: Rule 1 default action `Redirect to HTTPS://#{host}:443/#{path}?#{query}` with status code **HTTP 301**<br/>• **HTTPS: 443**: Forwarding to target group `savitara-prod-tg`<br/>• SSL Certificate attached from ACM | `05-alb-listeners-and-rules.png` |
| **2.3** | **Target Group Health** | • Name: `savitara-prod-tg`<br/>• Protocol / Port: `HTTP: 3000`<br/>• Health check path: `/health`<br/>• Healthy instances: **2 / 2 Healthy** (`ip-10-0-11-209`, `ip-10-0-12-12`) | `06-alb-target-group-healthy.png` |

---

### 3. Compute: EC2 Auto Scaling Group & Launch Template
| Item | Verification View | Live AWS Evidence Observed | Screenshot Reference |
|---|---|---|---|
| **3.1** | **Auto Scaling Group Status** | • ASG Name: `savitara-prod-asg-2026102402143112800000000d`<br/>• Desired Capacity: **2**, Min: **2**, Max: **5**<br/>• Status: Updating capacity completed, 2 instances running | `07-asg-group-status.png` |
| **3.2** | **Multi-AZ Distribution** | • Launch Template: `savitara-prod-ec2-launch-template`<br/>• Network: Distributed strictly in Private Subnets across `ap-south-1a` and `ap-south-1b`<br/>• IMDSv2 Token requirement enforced | `08-asg-launch-template-subnets.png` |
| **3.3** | **Health Check Configuration** | • Health check type: **EC2 and ELB**<br/>• Health check grace period: **300 seconds**<br/>• Monitoring: Detailed CloudWatch metrics enabled | `09-asg-health-checks.png` |

---

### 4. Database: Amazon RDS MySQL 8.0 & Security
| Item | Verification View | Live AWS Evidence Observed | Screenshot Reference |
|---|---|---|---|
| **4.1** | **RDS Instance Summary** | • DB Identifier: `savitara-prod-rds-mysql`<br/>• Engine: **MySQL Community 8.0.46**<br/>• Status: **Available**<br/>• Instance Class: `db.t3.micro`<br/>• Storage Encryption: **Enabled** (KMS AWS managed key)<br/>• Active Client Connections: **2** (EC2 ASG worker nodes) | `10-rds-mysql-available.png` |
| **4.2** | **RDS Connectivity & Network Isolation** | • Endpoint: `savitara-prod-rds-mysql.ctymeqgac0f1.ap-south-1.rds.amazonaws.com:3306`<br/>• DB Subnet Group: `savitara-prod-db-subnet-group` (Isolated private subnets)<br/>• Public Accessibility: **No (False)**<br/>• Security Group: `savitara-prod-rds-sg` allowing TCP 3306 inbound exclusively from `savitara-prod-ec2-sg` | `11-rds-connectivity-security.png` |

---

### 5. Storage: Amazon S3 Buckets & Verification
| Item | Verification View | Live AWS Evidence Observed | Screenshot Reference |
|---|---|---|---|
| **5.1** | **Provisioned S3 Buckets** | • `savitara-prod-alb-logs-dlq50jqw` (ALB Access Logs bucket with SSE-S3)<br/>• `savitara-prod-app-storage-dlq50jqw` (Application Storage bucket with Public Access Block) | `12-s3-buckets-list.png` |
| **5.2** | **S3 Live Object Storage** | • S3 Bucket `savitara-prod-app-storage-dlq50jqw`<br/>• Folder: `health-checks/`<br/>• Live verified files: `ping-1792808391453.txt`, `ping-1792808428133.txt` written live via EC2 IAM credentials | `13-s3-health-checks-objects.png` |

---

### 6. Automated CI/CD: GitHub Actions Pipelines
| Item | Verification View | Live AWS Evidence Observed | Screenshot Reference |
|---|---|---|---|
| **6.1** | **GitHub Actions Execution History** | • All pipeline runs reporting **100% Green (Success)**<br/>• Workflow `Terraform CI/CD Pipeline #14` passed in `9m 31s` (Lint, Test, Plan, Apply, Live Health Check)<br/>• Workflow `Destroy / Cleanup AWS Resources` available and verified for zero cloud cost overhead | `14-github-actions-all-green.png` |

---

## 🧪 Terminal Live Smoke Test Log

```bash
# 1. HTTP to HTTPS 301 Redirect Check
$ curl -I http://savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com
HTTP/1.1 301 Moved Permanently
Server: awselb/2.0
Date: Sat, 24 Oct 2026 02:20:00 GMT
Content-Type: text/html
Content-Length: 134
Location: https://savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com:443/

# 2. Application Health Endpoint
$ curl -k https://savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com/health
{
  "status": "UP",
  "timestamp": "2026-10-24T02:20:08.854Z",
  "uptime": 246.643730576,
  "hostname": "ip-10-0-12-12.ap-south-1.compute.internal",
  "service": "savitara-devops-app"
}

# 3. RDS MySQL Query Status
$ curl -k https://savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com/api/db-status
{
  "status": "UP",
  "details": {
    "solution": 2,
    "server_time": "2026-10-24T02:20:18.000Z",
    "db_version": "8.0.46-eol-2-rds.20260908"
  }
}

# 4. Amazon S3 PutObject Verification
$ curl -k https://savitara-prod-alb-1429244812.ap-south-1.elb.amazonaws.com/api/s3-test
{
  "status": "SUCCESS",
  "bucket": "savitara-prod-app-storage-dlq50jqw",
  "verifiedKey": "health-checks/ping-1792808428133.txt"
}
```


