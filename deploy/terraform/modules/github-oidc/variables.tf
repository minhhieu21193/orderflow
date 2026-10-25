variable "role_name" {
  description = "Name of the deploy role."
  type        = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, as owner/name."
  type        = string
}

variable "github_environment" {
  description = "GitHub Environment the deploying job must declare."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository the role may push to."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key encrypting the ECR repository."
  type        = string
}

variable "ecs_service_arn" {
  description = "ECS service the role may update."
  type        = string
}

variable "pass_role_arns" {
  description = "Task and execution role ARNs the role may pass to new task definitions."
  type        = list(string)
}

variable "task_family" {
  description = "Task definition family the role registers revisions of."
  type        = string
}
