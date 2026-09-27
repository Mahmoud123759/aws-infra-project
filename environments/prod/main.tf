terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    # Fill in via backend-config values  e.g.:
    bucket         = "my-tfstate-bucket"
    key            = "scalable-webapp/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront WAF Web ACLs (scope=CLOUDFRONT) must be created in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  azs = var.availability_zones

  public_subnets = {
    a = { cidr = var.public_subnet_cidrs[0], az = local.azs[0] }
    b = { cidr = var.public_subnet_cidrs[1], az = local.azs[1] }
  }
  private_subnets = {
    a = { cidr = var.private_subnet_cidrs[0], az = local.azs[0] }
    b = { cidr = var.private_subnet_cidrs[1], az = local.azs[1] }
  }
  database_subnets = {
    a = { cidr = var.database_subnet_cidrs[0], az = local.azs[0] }
    b = { cidr = var.database_subnet_cidrs[1], az = local.azs[1] }
  }

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
  })
}

############################################
# VPC
############################################
module "vpc" {
  source = "../../modules/vpc"

  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  public_subnets    = local.public_subnets
  private_subnets   = local.private_subnets
  database_subnets  = local.database_subnets
  tags              = local.tags
}

############################################
# Security Groups
############################################
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  tags         = local.tags
}

############################################
# Application Load Balancer
############################################
module "alb" {
  source = "../../modules/alb"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  certificate_arn    = var.acm_certificate_arn
  health_check_path  = var.health_check_path
  tags               = local.tags
}

############################################
# WAF (regional, attached directly to the ALB)
############################################
module "waf" {
  source = "../../modules/waf"

  project_name            = var.project_name
  rate_limit              = var.waf_rate_limit
  associate_with_alb_arn  = module.alb.alb_arn
  tags                    = local.tags
}

############################################
# CloudFront (fronts the ALB)
############################################
module "cloudfront" {
  source    = "../../modules/cloudfront"
  providers = { aws = aws.us_east_1 }

  project_name         = var.project_name
  alb_dns_name         = module.alb.alb_dns_name
  acm_certificate_arn  = var.cloudfront_acm_certificate_arn
  domain_aliases       = var.domain_aliases
  tags                 = local.tags
}

############################################
# Route 53
############################################
resource "aws_route53_zone" "this" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.domain_name
  tags  = local.tags
}

resource "aws_route53_record" "root" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.create_hosted_zone ? aws_route53_zone.this[0].zone_id : var.existing_hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront's fixed hosted zone id
    evaluate_target_health = false
  }
}

############################################
# Auto Scaling Group (EC2 in private subnets)
############################################
module "asg" {
  source = "../../modules/asg"

  project_name        = var.project_name
  instance_type       = var.instance_type
  ec2_sg_id           = module.security.ec2_sg_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  target_group_arn    = module.alb.target_group_arn
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  target_cpu_utilization = var.asg_target_cpu
  tags                = local.tags
}

############################################
# RDS (Multi-AZ MySQL)
############################################
module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  database_subnet_ids   = module.vpc.database_subnet_ids
  rds_sg_id             = module.security.rds_sg_id
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  db_name               = var.rds_db_name
  master_username       = var.rds_master_username
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection   = var.rds_deletion_protection
  tags                  = local.tags
}

############################################
# Systems Manager (Session Manager access, no bastion/SSH)
############################################
module "ssm" {
  source = "../../modules/ssm"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  aws_region            = var.aws_region
  private_subnet_ids    = module.vpc.private_subnet_ids
  enable_vpc_endpoints  = var.enable_ssm_vpc_endpoints
  tags                  = local.tags
}

############################################
# SNS (alert notifications)
############################################
module "sns" {
  source = "../../modules/sns"

  project_name  = var.project_name
  alert_emails  = var.alert_emails
  tags          = local.tags
}

############################################
# CloudWatch (dashboards + alarms wired to SNS)
############################################
module "monitoring" {
  source = "../../modules/monitoring"

  project_name    = var.project_name
  aws_region      = var.aws_region
  alb_arn_suffix  = module.alb.alb_arn_suffix
  asg_name        = module.asg.asg_name
  db_instance_id  = module.rds.db_instance_id
  sns_topic_arn   = module.sns.topic_arn
}
