variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "db_instance_id" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "alb_5xx_threshold" {
  type    = number
  default = 10
}

variable "asg_cpu_threshold" {
  type    = number
  default = 80
}

variable "rds_cpu_threshold" {
  type    = number
  default = 80
}

variable "rds_free_storage_threshold_bytes" {
  type    = number
  default = 5368709120 # 5 GiB
}
