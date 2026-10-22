# Security & Least Privilege Matrix

This document outlines the defense-in-depth security architecture implemented for Savitara Infotel's AWS infrastructure.

## 1. Network Subnetting Architecture

| Subnet Type | AZ | CIDR Block | Route Table Target | Exposed to Internet? |
|---|---|---|---|---|
| **Public Subnet 1** | ap-south-1a | `10.0.1.0/24` | `0.0.0.0/0` -> Internet Gateway | Yes (ALB & NAT GW) |
| **Public Subnet 2** | ap-south-1b | `10.0.2.0/24` | `0.0.0.0/0` -> Internet Gateway | Yes (ALB standby) |
| **Private App Subnet 1** | ap-south-1a | `10.0.11.0/24` | `0.0.0.0/0` -> NAT Gateway | No (Private EC2 ASG) |
| **Private App Subnet 2** | ap-south-1b | `10.0.12.0/24` | `0.0.0.0/0` -> NAT Gateway | No (Private EC2 ASG) |
| **Private DB Subnet 1** | ap-south-1a | `10.0.21.0/24` | Local VPC Only | No (Isolated RDS) |
| **Private DB Subnet 2** | ap-south-1b | `10.0.22.0/24` | Local VPC Only | No (Isolated RDS) |

---

## 2. Security Group Chaining Matrix

| Security Group | Direction | Protocol | Port | Source / Destination | Rationale |
|---|---|---|---|---|---|
| **ALB SG** | Inbound | TCP | 80 | `0.0.0.0/0`, `::/0` | Redirect incoming HTTP requests to HTTPS |
| **ALB SG** | Inbound | TCP | 443 | `0.0.0.0/0`, `::/0` | Secure public user HTTPS traffic |
| **ALB SG** | Outbound | TCP | 3000 | `EC2 App SG` | Forward traffic to healthy backend instances |
| **EC2 App SG** | Inbound | TCP | 3000 | `ALB SG` | Only ALB can communicate with app instances |
| **EC2 App SG** | Outbound | TCP / UDP | ALL | `0.0.0.0/0` (via NAT) | OS updates, NPM packages, AWS API calls |
| **EC2 App SG** | Outbound | TCP | 3306 | `RDS SG` | Database queries to MySQL |
| **RDS DB SG** | Inbound | TCP | 3306 | `EC2 App SG` | Isolated database only accepts connections from app nodes |
| **RDS DB SG** | Outbound | - | - | None | RDS does not initiate outbound connections |

---

## 3. IAM Least-Privilege Policies

| Resource | Role / Identity | Permission Granted | Target Scope |
|---|---|---|---|
| **EC2 Instance Profile** | `savitara-prod-ec2-role` | `secretsmanager:GetSecretValue`<br/>`secretsmanager:DescribeSecret` | Strictly the RDS Secret ARN |
| **EC2 Instance Profile** | `savitara-prod-ec2-role` | `s3:GetObject`<br/>`s3:PutObject`<br/>`s3:DeleteObject`<br/>`s3:ListBucket` | Strictly `savitara-prod-app-storage-*` bucket ARN |
| **EC2 Instance Profile** | `savitara-prod-ec2-role` | `AmazonSSMManagedInstanceCore` | Allows AWS Systems Manager Session Manager access (eliminates open SSH port 22) |
| **EC2 Instance Profile** | `savitara-prod-ec2-role` | `CloudWatchAgentServerPolicy` | Shipping application metrics and system logs |

---

## 4. Encryption Standards

1. **In-Transit Encryption**:
   - Client to Application Load Balancer: Enforced TLS 1.3 / TLS 1.2 with modern cipher suites.
   - HTTP to HTTPS 301 redirection active on Port 80.
   - ALB to EC2 App: Internal VPC encrypted transit.
   - EC2 to AWS APIs: HTTPS over TLS with AWS SDK v3 SigV4.

2. **At-Rest Encryption**:
   - **Amazon RDS MySQL**: AWS KMS AES-256 encrypted block storage (`storage_encrypted = true`).
   - **Amazon S3 App Bucket**: Server-Side Encryption with Amazon S3 managed keys (`SSE-AES256`).
   - **Amazon S3 ALB Logs Bucket**: Server-Side Encryption enabled, S3 Public Access Blocked.
   - **AWS Secrets Manager**: Stored with envelope encryption and automatic zero-window destruction on teardown.
   - **EC2 Instance Metadata Service**: Enforced IMDSv2 (`http_tokens = "required"`, hop limit 1) preventing SSRF credential theft.
