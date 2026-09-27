variable "project_name" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "web_acl_arn" {
  description = "ARN of a CloudFront-scope (us-east-1) WAFv2 Web ACL. Leave empty to skip."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM cert in us-east-1 for custom domain aliases. Leave empty to use the default CloudFront certificate."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
