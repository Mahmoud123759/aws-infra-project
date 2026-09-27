variable "project_name" {
  type = string
}

variable "rate_limit" {
  description = "Max requests per 5-minute period per IP before blocking"
  type        = number
  default     = 2000
}

variable "associate_with_alb_arn" {
  description = "ALB ARN to associate this Web ACL with. Leave empty if only used with CloudFront."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
