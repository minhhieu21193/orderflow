variable "name" {
  description = "Budget name."
  type        = string
}

variable "monthly_limit_usd" {
  description = "Monthly budget in USD."
  type        = number
}

variable "alert_emails" {
  description = "Email addresses notified at 80%/100% actual and 100% forecast."
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "At least one alert email is required."
  }
}

variable "cost_filter_tag" {
  description = "Optional cost allocation tag to scope the budget, e.g. { key = \"Env\", value = \"staging\" }. Null = whole account."
  type = object({
    key   = string
    value = string
  })
  default = null
}
