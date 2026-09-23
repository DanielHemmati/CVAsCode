variable "bucket_name" {
  description = "Globally unique name of the S3 bucket used for Terraform state."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters of lowercase letters, numbers and hyphens, starting and ending with a letter or number."
  }
}

variable "tags" {
  description = "tags applied to the Terraform state bucket."
  type        = map(string)
  default     = {}
  nullable    = false
}
