# Configuration & Deployment Screenshots Guide

This directory holds screenshots demonstrating end-to-end verification of the deployed AWS infrastructure and CI/CD pipelines.

## Checklist of Expected Deliverables

When submitting the assignment, capture and include screenshots of the following views:

| Item | Description | Screenshot File |
|---|---|---|
| **1. VPC & Subnets** | AWS Console showing VPC `savitara-prod-vpc`, route tables, Internet Gateway, and NAT Gateway | `01-vpc-and-subnets.png` |
| **2. Security Groups** | Rules chaining ALB -> EC2 -> RDS | `02-security-groups.png` |
| **3. Application Load Balancer** | ALB showing Active status, Listeners (Port 80 redirect, Port 443 HTTPS), and ACM certificate | `03-alb-https-listener.png` |
| **4. ALB Target Group** | Target group showing healthy EC2 instances responding 200 on `/health` | `04-alb-target-group-healthy.png` |
| **5. EC2 Auto Scaling Group** | ASG showing 2 desired instances running across 2 private AZ subnets | `05-asg-instances.png` |
| **6. Amazon RDS MySQL** | RDS database status Available in private DB subnet group with storage encryption enabled | `06-rds-mysql-available.png` |
| **7. AWS Secrets Manager** | Secret storing RDS MySQL master credentials | `07-secrets-manager.png` |
| **8. S3 Buckets** | App storage bucket and ALB access logs bucket with SSE-S3 encryption | `08-s3-buckets-and-logs.png` |
| **9. Live HTTPS Web Application** | Browser screenshot showing HTTPS lock icon and the application web dashboard | `09-live-https-dashboard.png` |
| **10. GitHub Actions CI/CD** | Green pipeline execution showing test, plan, apply, and health check pass | `10-github-actions-success.png` |

---

## Sample Text Representation of Live Verification

```
$ curl -I http://savitara-prod-alb-123456789.ap-south-1.elb.amazonaws.com
HTTP/1.1 301 Moved Permanently
Server: awselb/2.0
Date: Thu, 22 Oct 2026 10:20:00 GMT
Content-Type: text/html
Content-Length: 134
Location: https://savitara-prod-alb-123456789.ap-south-1.elb.amazonaws.com:443/

$ curl -k https://savitara-prod-alb-123456789.ap-south-1.elb.amazonaws.com/health
{
  "status": "UP",
  "timestamp": "2026-10-22T10:20:05.123Z",
  "uptime": 142.6,
  "hostname": "ip-10-0-11-84.ap-south-1.compute.internal",
  "service": "savitara-devops-app"
}
```
