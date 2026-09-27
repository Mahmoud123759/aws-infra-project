variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "enable_vpc_endpoints" {
  description = "Create Interface VPC Endpoints so Session Manager traffic never leaves the AWS network via NAT Gateway"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
