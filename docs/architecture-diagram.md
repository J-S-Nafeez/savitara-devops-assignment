# AWS Infrastructure Architecture Diagram

This document provides visual diagrams and architectural flow specifications for the **Savitara Infotel DevOps Assessment** infrastructure.

## High-Level Architecture Flow

```mermaid
flowchart TD
    Client(["🌐 Internet Users"]) -->|HTTPS: 443 / HTTP: 80| IGW["AWS Internet Gateway (IGW)"]
    
    subgraph VPC ["AWS Virtual Private Cloud (VPC: 10.0.0.0/16)"]
        
        subgraph PublicSubnets ["Public Subnets (Multi-AZ)"]
            ALB["Application Load Balancer (ALB)<br/>HTTP -> HTTPS 301 Redirect"]
            NAT["NAT Gateway (Elastic IP)"]
        end

        subgraph PrivateAppSubnets ["Private Application Subnets (Multi-AZ)"]
            subgraph ASG ["EC2 Auto Scaling Group (min: 2, max: 5)"]
                EC2_1["EC2 Instance (AZ-a)<br/>Node.js / Express App (Port 3000)"]
                EC2_2["EC2 Instance (AZ-b)<br/>Node.js / Express App (Port 3000)"]
            end
        end

        subgraph PrivateDBSubnets ["Private Database Subnets (Multi-AZ)"]
            RDS[("Amazon RDS MySQL 8.0<br/>Multi-AZ Subnet Group<br/>Port: 3306 (Encrypted gp3)")]
        end

    end

    subgraph AWSServices ["Managed AWS Cloud Services"]
        ACM["AWS Certificate Manager (ACM)<br/>TLS / SSL Encryption"]
        SM["AWS Secrets Manager<br/>Encrypted DB Master Password"]
        S3_Logs[("Amazon S3<br/>ALB Access Logs (SSE-S3)")]
        S3_App[("Amazon S3<br/>Application Storage Bucket")]
        CW["Amazon CloudWatch<br/>Metrics & Target Tracking"]
    end

    %% Network Connections
    IGW --> ALB
    ALB -->|Forward Port 3000| EC2_1
    ALB -->|Forward Port 3000| EC2_2
    ALB -.->|Access Logs| S3_Logs
    ACM -.->|SSL Offloading| ALB

    EC2_1 -->|Query Port 3306| RDS
    EC2_2 -->|Query Port 3306| RDS
    
    EC2_1 -.->|Outbound updates| NAT
    EC2_2 -.->|Outbound updates| NAT
    NAT --> IGW

    %% IAM / Secrets Access
    EC2_1 -.->|Fetch Credentials via IAM| SM
    EC2_2 -.->|Fetch Credentials via IAM| SM
    EC2_1 -.->|Read / Write Storage| S3_App
    EC2_2 -.->|Read / Write Storage| S3_App
    
    ASG -.->|CPU Scaling Metrics| CW
    CW -.->|Target Tracking 70% CPU| ASG
```

---

## Detailed Traffic and Security Flow

1. **Inbound Web Traffic**:
   - Clients send web requests to `https://<alb-dns-name>`.
   - If a client attempts `http://<alb-dns-name>` on Port 80, the ALB listener issues an immediate HTTP `301 Moved Permanently` redirect to HTTPS (Port 443).
   - The ALB terminates SSL/TLS using the AWS Certificate Manager (ACM) certificate.
   - The ALB validates target instance health via `/health` HTTP probe.

2. **Application Tier (EC2 Auto Scaling Group)**:
   - EC2 instances are hosted in strictly private subnets (`10.0.11.0/24`, `10.0.12.0/24`) with zero public IP addresses.
   - Instances only accept inbound traffic from the ALB's Security Group on TCP port 3000.
   - Outbound traffic to the internet (for package installation, OS updates, and AWS API calls) is routed through the NAT Gateway located in the public subnet.

3. **Database Tier (Amazon RDS MySQL)**:
   - MySQL 8.0 is deployed in isolated database private subnets (`10.0.21.0/24`, `10.0.22.0/24`).
   - The RDS Security Group strictly allows TCP port 3306 inbound only from the EC2 Application Security Group.
   - Storage is encrypted at rest using AWS KMS AES-256.

4. **Credential Security**:
   - The database master password is generated with 24 characters of high entropy and stored directly in AWS Secrets Manager.
   - The EC2 instances assume an IAM role granting least-privilege `secretsmanager:GetSecretValue` access to load credentials into memory dynamically at runtime.
   - No passwords or secrets are ever hardcoded in code, Terraform files, or version control.

