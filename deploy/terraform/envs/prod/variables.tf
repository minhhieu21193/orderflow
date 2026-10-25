variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Project name, used in resource names and the Project tag."
  type        = string
  default     = "orderflow"
}

variable "owner" {
  description = "Value of the Owner tag (person or team responsible)."
  type        = string
}

variable "image_tag" {
  description = "Tag of the API image in this env's ECR repository (the Makefile passes the git SHA)."
  type        = string
}

variable "alert_email" {
  description = "Email for alarm and budget notifications."
  type        = string
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS on the ALB."
  type        = string
  default     = null
}

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to deploy through OIDC."
  type        = string
  default     = "minhhieu21193/orderflow"
}

variable "monthly_budget_usd" {
  description = "Monthly AWS Budgets limit in USD (alerts at 80% and 100%)."
  type        = number
  default     = 100
}

variable "enable_rds" {
  description = "Create a PostgreSQL instance and inject its connection settings into the task."
  type        = bool
  default     = false
}
