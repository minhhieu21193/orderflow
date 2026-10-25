variable "name" {
  description = "Name prefix for network resources."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones (one public and one private subnet each)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 (the ALB needs at least two AZs)."
  }
}

variable "availability_zones" {
  description = "Candidate AZ names; the first az_count available ones are used. Empty means <region>a, b and c."
  type        = list(string)
  default     = []
}

variable "nat_gateway_mode" {
  description = "Outbound internet for private subnets: none, single or per_az."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: none, single, per_az."
  }
}

variable "enable_interface_endpoints" {
  description = "Create interface endpoints for ECR, CloudWatch Logs and Secrets Manager (needed when there is no NAT)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send rejected-traffic VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention of the flow log group."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "KMS key for the flow log group."
  type        = string
}
