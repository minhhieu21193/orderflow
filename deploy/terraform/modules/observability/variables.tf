variable "name" {
  description = "Name prefix for the log group, topic, alarms and dashboard."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for the log group and SNS topic."
  type        = string
}

variable "log_retention_days" {
  description = "Retention of the application log group."
  type        = number
  default     = 14
}

variable "alarm_email" {
  description = "Email address subscribed to alarm notifications (null for none)."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "service_name" {
  description = "ECS service name."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix."
  type        = string
}

variable "min_running_tasks" {
  description = "Alarm when fewer tasks than this are running."
  type        = number
  default     = 1
}

variable "http_5xx_threshold" {
  description = "Alarm when 5xx responses per minute exceed this."
  type        = number
  default     = 5
}

variable "latency_p95_threshold_seconds" {
  description = "Alarm when p95 target response time exceeds this many seconds."
  type        = number
  default     = 1
}

variable "cpu_threshold_percent" {
  description = "Alarm when service average CPU exceeds this percentage."
  type        = number
  default     = 80
}
