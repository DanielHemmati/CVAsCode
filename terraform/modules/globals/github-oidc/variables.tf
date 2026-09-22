variable "github_subject" {
  description = "Exact GitHub OIDC subject allowed to assume the IAM role."
  type        = string
  nullable    = false

  validation {
    condition = can(regex(
      "^repo:[^*]+:environment:[A-Za-z0-9_.-]+$",
      var.github_subject,
    ))
    error_message = "github_subject must identify one repository environment and must not contain wildcards."
  }
}

variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.role_name))
    error_message = "role_name must be between 1 and 64 valid IAM role-name characters."
  }
}

variable "managed_policy_arns" {
  description = "IAM managed policies attached to the GitHub Actions role."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for arn in var.managed_policy_arns :
      can(regex("^arn:[^:]+:iam::[^:]+:policy/.+$", arn))
    ])
    error_message = "Every managed_policy_arns value must be an IAM policy ARN."
  }
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
