variable "name" {
  description = "Name for the cluster, service, task family, ALB and target group."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR; tasks may open TCP connections inside it (e.g. to RDS)."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnets for the tasks."
  type        = list(string)
}

variable "image" {
  description = "Full image reference, e.g. <registry>/<repo>:<tag>."
  type        = string
}

variable "container_port" {
  description = "Port the API listens on (passed to the app as PORT)."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64. Must match the image."
  type        = string
  default     = "X86_64"
}

variable "environment" {
  description = "Extra plain environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variables injected from Secrets Manager: name => valueFrom ARN (optionally with :json-key::)."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secret ARNs the execution role may read (the base ARNs behind var.secrets)."
  type        = list(string)
  default     = []
}

variable "secrets_kms_key_arn" {
  description = "KMS key that encrypts the injected secrets, if customer-managed."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "CloudWatch log group for container logs."
  type        = string
}

variable "health_check_path" {
  description = "ALB target health check path."
  type        = string
  default     = "/readyz"
}

variable "capacity_provider" {
  description = "FARGATE (on-demand) or FARGATE_SPOT."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.capacity_provider)
    error_message = "capacity_provider must be FARGATE or FARGATE_SPOT."
  }
}

variable "desired_count" {
  description = "Initial number of tasks (autoscaling adjusts it afterwards)."
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Autoscaling minimum task count."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Autoscaling maximum task count."
  type        = number
  default     = 2
}

variable "cpu_target_percent" {
  description = "Target average CPU utilisation for scaling."
  type        = number
  default     = 60
}

variable "requests_per_task_target" {
  description = "Target ALB requests per task per minute for scaling."
  type        = number
  default     = 1000
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, adds an HTTPS listener and redirects HTTP to HTTPS."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "ALB deletion protection. Off by default so teardown is one command."
  type        = bool
  default     = false
}
