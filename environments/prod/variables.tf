variable "project_name" {
  type    = string
  default = "scalable-webapp"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

############################################
# Networking
############################################
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.21.0/24", "10.0.22.0/24"]
}

############################################
# ALB / WAF / CloudFront / DNS
############################################
variable "health_check_path" {
  type    = string
  default = "/"
}

variable "acm_certificate_arn" {
  description = "Regional ACM cert (same region as ALB) for HTTPS listener"
  type        = string
  default     = ""
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM cert in us-east-1 for CloudFront custom domain aliases"
  type        = string
  default     = ""
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "domain_name" {
  description = "Apex domain to manage in Route 53, e.g. example.com. Leave empty to skip DNS."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  type    = list(string)
  default = []
}

variable "create_hosted_zone" {
  description = "Create a new Route 53 hosted zone. Set false to use existing_hosted_zone_id instead."
  type        = bool
  default     = false
}

variable "existing_hosted_zone_id" {
  type    = string
  default = ""
}

############################################
# Compute / Auto Scaling
############################################
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 6
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_target_cpu" {
  type    = number
  default = 50
}

############################################
# RDS
############################################
variable "rds_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "rds_allocated_storage" {
  type    = number
  default = 50
}

variable "rds_db_name" {
  type    = string
  default = "appdb"
}

variable "rds_master_username" {
  type    = string
  default = "admin"
}

variable "rds_backup_retention_period" {
  type    = number
  default = 7
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

############################################
# Systems Manager
############################################
variable "enable_ssm_vpc_endpoints" {
  type    = bool
  default = false
}

############################################
# Alerting
############################################
variable "alert_emails" {
  type    = list(string)
  default = []
}

############################################
# Tags
############################################
variable "tags" {
  type    = map(string)
  default = {}
}
