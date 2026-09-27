variable "project_name" {
  type = string
}

variable "ami_id" {
  description = "Custom AMI id. Leave empty to use the latest Amazon Linux 2023 AMI."
  type        = string
  default     = ""
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_sg_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "user_data" {
  description = "Raw (non-base64) user-data script for bootstrapping the instance"
  type        = string
  default     = <<-EOT
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd
    echo "OK" > /var/www/html/health
  EOT
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "target_cpu_utilization" {
  type    = number
  default = 50
}

variable "tags" {
  type    = map(string)
  default = {}
}
