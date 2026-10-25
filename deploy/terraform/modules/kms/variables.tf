variable "name" {
  description = "Name of the key alias (alias/<name>)."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion completes."
  type        = number
  default     = 7
}
