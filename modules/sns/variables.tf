variable "project_name" {
  type = string
}

variable "alert_emails" {
  description = "Email addresses to subscribe to the alerts SNS topic"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
