variable "bucket_name" {
  description = "Globally unique name of the S3 bucket used for private Terraform plans."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters of lowercase letters, numbers and hyphens, starting and ending with a letter or number."
  }
}

variable "allowed_principal_arns" {
  description = "IAM principal ARNs allowed to access the plan bucket."
  type        = set(string)
  nullable    = false

  validation {
    condition = length(var.allowed_principal_arns) > 0 && alltrue([
      for arn in var.allowed_principal_arns :
      can(regex("^arn:[^:]+:iam::[0-9]{12}:(role|user)/.+$", arn)) &&
      !strcontains(arn, "*")
    ])
    error_message = "allowed_principal_arns must contain IAM role or user ARNs without wildcards."
  }
}

variable "retention_days" {
  description = "Number of days that S3 retains plan files."
  type        = number
  default     = 5
  nullable    = false

  validation {
    condition     = var.retention_days == floor(var.retention_days) && var.retention_days >= 1 && var.retention_days <= 30
    error_message = "retention_days must be a whole number between 1 and 30."
  }
}

variable "tags" {
  description = "Tags applied to the Terraform plan bucket."
  type        = map(string)
  default     = {}
  nullable    = false
}
