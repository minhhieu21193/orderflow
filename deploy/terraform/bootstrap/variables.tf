variable "region" {
  description = "AWS region for the state bucket."
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
