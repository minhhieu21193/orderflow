variable "name" {
  description = "Repository name."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt images."
  type        = string
}

variable "keep_images" {
  description = "Number of most recent images to keep; older ones expire."
  type        = number
  default     = 20
}

variable "force_delete" {
  description = "Delete the repository even if it still contains images."
  type        = bool
  default     = true
}
