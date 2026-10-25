variable "name" {
  description = "Identifier for the instance and its subnet/parameter groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group (at least two AZs)."
  type        = list(string)
}

variable "client_security_group_id" {
  description = "Security group allowed to connect on 5432 (the ECS tasks)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for storage and the master-password secret."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major version; RDS applies minor upgrades automatically."
  type        = string
  default     = "18"
}

variable "instance_class" {
  description = "Instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage_gb" {
  description = "Initial gp3 storage; autoscaling may grow it to 5x."
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Name of the initial database."
  type        = string
  default     = "orderflow"
}

variable "master_username" {
  description = "Master username (the password is managed by RDS in Secrets Manager)."
  type        = string
  default     = "orderflow"
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Block deletion and keep a final snapshot. Off so teardown is one command."
  type        = bool
  default     = false
}
