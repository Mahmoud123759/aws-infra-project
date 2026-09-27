variable "project_name" {
  type = string
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  type    = number
  default = 50
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "master_username" {
  type    = string
  default = "admin"
}

variable "master_password" {
  description = "Leave empty to auto-generate a random password (recommended: manage via Secrets Manager instead)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
