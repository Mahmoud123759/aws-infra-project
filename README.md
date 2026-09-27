# Scalable Web Application with ALB and Auto Scaling — AWS Solution Architecture

Terraform implementation of a highly available, secure, and auto-scaling 3-tier web
application on AWS: **Route 53 → CloudFront → WAF → ALB → Auto Scaling Group (EC2) →
Multi-AZ RDS**, with centralized monitoring via CloudWatch and SNS, and keyless
instance access via Systems Manager Session Manager.

## Architecture

```
Users
  │
  ▼
Route 53 (DNS)
  │
  ▼
CloudFront (CDN)
  │
  ▼
WAF (Web Application Firewall)
  │
  ▼
Application Load Balancer (ALB)
  │
  ├────────────────────────────┬────────────────────────────┐
  ▼                             ▼                            │
VPC (10.0.0.0/16)                                            │
  │                                                           │
  ├── Availability Zone A                Availability Zone B │
  │   ├── Public Subnet 10.0.1.0/24      Public Subnet 10.0.3.0/24
  │   │     NAT Gateway  ─▶ Internet      NAT Gateway ─▶ Internet
  │   │                                                       │
  │   ├── Private Subnet 10.0.11.0/24    Private Subnet 10.0.12.0/24
  │   │     Auto Scaling Group            Auto Scaling Group
  │   │       EC2 · EC2 · EC2 ...           EC2 · EC2 · EC2 ...
  │   │       (EC2 SG: allow only ALB)      (EC2 SG: allow only ALB)
  │   │                                                       │
  │   └── Database Subnet 10.0.21.0/24   Database Subnet 10.0.22.0/24
  │         RDS Primary (Writer)  ◀── Multi-AZ Replication ──▶  RDS Standby (Reader)
  │         (RDS SG: allow only EC2 SG)
  │
  ├── Systems Manager Session Manager ──▶ access to EC2 instances (no SSH/bastion)
  ├── CloudWatch ──▶ Dashboards, Alarms, Logs & Metrics
  └── SNS ──▶ Notifications (email/sms on alarm)
```

The diagram this project implements is included at
[`docs/aws_infra_project.png`](docs/aws_infra_project.png).

### Key components

| Component | Purpose |
|---|---|
| **Route 53** | DNS for the application domain, aliased to CloudFront |
| **CloudFront** | CDN in front of the ALB, TLS termination for viewers, optional custom domain |
| **WAF** | Managed rule groups (Common, Known Bad Inputs) + IP rate limiting, attached to the ALB |
| **ALB** | Public-facing load balancer across 2 AZs, HTTP→HTTPS redirect, health checks |
| **Auto Scaling Group** | EC2 instances in private subnets across 2 AZs, target-tracking policy on CPU |
| **Launch Template** | EC2 configuration: AMI, instance type, IAM instance profile, IMDSv2 enforced |
| **RDS (MySQL)** | Multi-AZ (Primary/Standby) in isolated database subnets |
| **NAT Gateway** | One per AZ — outbound internet access for private-subnet EC2 instances |
| **Systems Manager** | Session Manager access to EC2 — no SSH keys, no bastion host |
| **CloudWatch** | Dashboard (ALB/ASG/RDS metrics) + alarms for 5xx errors, CPU, RDS storage |
| **SNS** | Alarm notification topic (email subscriptions) |
| **Security Groups** | ALB SG (80/443 from Internet) → EC2 SG (80/443 from ALB only) → RDS SG (3306 from EC2 only) |
| **NACLs** | Stateless subnet-level rules for public / private / database subnets |

### High availability, scalability, security, monitoring, management

| Pillar | Implementation |
|---|---|
| High Availability | Multi-AZ for both EC2 (ASG spans 2 AZs) and RDS (Primary/Standby) |
| Scalability | Auto Scaling Group with target-tracking (CPU) policy |
| Security | WAF + layered Security Groups + NACLs, private/isolated subnets |
| Monitoring | CloudWatch dashboards, alarms, SNS notifications |
| Management | Systems Manager Session Manager (no exposed SSH) |

## Repository layout

```
.
├── README.md
├── environments/
│   └── prod/
│       ├── main.tf                  # Wires all modules together
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── backend.hcl.example
└── modules/
    ├── vpc/                # VPC, subnets, route tables, NAT GWs, NACLs
    ├── security/            # ALB / EC2 / RDS security groups
    ├── alb/                 # Application Load Balancer + target group + listeners
    ├── waf/                 # WAFv2 Web ACL (regional, attached to ALB)
    ├── cloudfront/          # CloudFront distribution in front of the ALB
    ├── asg/                 # Launch Template + Auto Scaling Group + IAM role for SSM
    ├── rds/                 # Multi-AZ MySQL RDS instance
    ├── monitoring/          # CloudWatch dashboard + alarms
    ├── sns/                 # SNS topic + email subscriptions
    └── ssm/                 # Optional Interface VPC Endpoints for Session Manager
```

Each module contains `main.tf`, `variables.tf`, and `outputs.tf`. `environments/prod`
is the root module you actually run `terraform` against; add `environments/dev` or
`environments/staging` the same way if you need more environments — they can reuse
every module as-is.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6.0
- AWS CLI configured with credentials that have permission to create the resources
  above (VPC, EC2, ELBv2, WAFv2, CloudFront, RDS, Route 53, IAM, CloudWatch, SNS, SSM)
- An S3 bucket + DynamoDB table for remote state (recommended), or remove the
  `backend "s3"` block in `environments/prod/main.tf` to use local state instead
- (Optional) An ACM certificate for HTTPS — one in the ALB's region, one in
  `us-east-1` for CloudFront if you use a custom domain
- (Optional) A Route 53 hosted zone if you want DNS managed by this project

## Deploying

```bash
cd environments/prod

# 1. Configure remote state
cp backend.hcl.example backend.hcl
# edit backend.hcl with your bucket/table

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — at minimum review CIDR ranges, instance sizes,
# and alert_emails

# 3. Initialize
terraform init -backend-config=backend.hcl

# 4. Review the plan
terraform plan -var-file=terraform.tfvars

# 5. Apply
terraform apply -var-file=terraform.tfvars
```

After apply, Terraform outputs the ALB DNS name, CloudFront domain, RDS endpoint
(sensitive), Auto Scaling Group name, SNS topic ARN, and CloudWatch dashboard name.

### Connecting to an EC2 instance (no SSH required)

```bash
aws ssm start-session --target <instance-id>
```

This works because each instance's IAM role (created in the `asg` module) is
attached to `AmazonSSMManagedInstanceCore`. Set `enable_ssm_vpc_endpoints = true`
in `terraform.tfvars` if you want Session Manager traffic to stay on the AWS
private network instead of routing out through the NAT Gateway.

### Destroying

```bash
terraform destroy -var-file=terraform.tfvars
```

RDS has `deletion_protection = true` by default — disable it in `terraform.tfvars`
(`rds_deletion_protection = false`) before destroying, or delete the instance
manually first.

## Variables of note

| Variable | Description | Default |
|---|---|---|
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `public_subnet_cidrs` / `private_subnet_cidrs` / `database_subnet_cidrs` | Per-AZ subnet CIDRs | matches diagram (`10.0.1.0/24` … `10.0.22.0/24`) |
| `instance_type` | EC2 instance type for the ASG | `t3.micro` |
| `asg_min_size` / `asg_max_size` / `asg_desired_capacity` | Auto Scaling Group sizing | `2` / `6` / `2` |
| `asg_target_cpu` | Target-tracking CPU % | `50` |
| `rds_instance_class` | RDS instance class | `db.t3.medium` |
| `acm_certificate_arn` | Regional ACM cert for the ALB HTTPS listener | `""` (HTTP only) |
| `cloudfront_acm_certificate_arn` | us-east-1 ACM cert for CloudFront custom domain | `""` (default CF cert) |
| `domain_name` | Apex domain managed in Route 53 | `""` (DNS skipped) |
| `alert_emails` | Emails subscribed to the SNS alert topic | `[]` |

See `environments/prod/variables.tf` for the full list.

## Notes and assumptions

- The MySQL master password is auto-generated via `random_password` if
  `rds_master_password` is left blank. For production, wire RDS to **AWS Secrets
  Manager** or **Secrets Manager RDS integration** instead of a plain Terraform
  variable.
- The ALB WAF Web ACL is regional (`scope = REGIONAL`) and attaches directly to the
  ALB, matching the diagram's WAF → ALB flow. If you also want WAF rules evaluated
  at the CloudFront edge, create a second Web ACL with `scope = CLOUDFRONT` in the
  `us-east-1` provider alias and pass its ARN into the `cloudfront` module's
  `web_acl_arn` variable.
- One NAT Gateway is deployed per AZ (2 total) for AZ-independent outbound access,
  matching the diagram.
- The Launch Template defaults to the latest Amazon Linux 2023 AMI and a minimal
  `httpd` bootstrap via user data — replace `var.user_data` / `var.ami_id` with your
  own application image or bootstrap script.
- IMDSv2 is enforced (`http_tokens = "required"`) on all instances.
