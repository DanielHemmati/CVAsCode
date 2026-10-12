# tflint-ignore-file: terraform_unused_declarations
# Later phases consume the remaining inputs in this module contract.

variable "api_name" {
  description = "Name of the API Gateway HTTP API."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.api_name)) > 0 && length(var.api_name) <= 128
    error_message = "api_name must contain between 1 and 128 characters."
  }
}

variable "lambda_function_name" {
  description = "Name of the Lambda function that summarizes the resume."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9-_]{1,64}$", var.lambda_function_name))
    error_message = "lambda_function_name must contain 1 to 64 letters, numbers, hyphens, or underscores."
  }
}

variable "bedrock_model_id" {
  description = "Verified Amazon Nova Micro model or inference profile ID."
  type        = string
  nullable    = false

  validation {
    condition = contains([
      "amazon.nova-micro-v1:0",
      "us.amazon.nova-micro-v1:0",
    ], var.bedrock_model_id)
    error_message = "bedrock_model_id must select the verified Nova Micro base model or US inference profile."
  }
}

variable "cors_allowed_origin" {
  description = "Exact HTTPS website origin allowed to call the HTTP API."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^https://[^/]+$", var.cors_allowed_origin))
    error_message = "cors_allowed_origin must be one HTTPS origin without a trailing slash."
  }
}

variable "throttle_rate_limit" {
  description = "Shared request rate limit for the summary route in requests per second."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.throttle_rate_limit > 0
    error_message = "throttle_rate_limit must be greater than zero."
  }
}

variable "throttle_burst_limit" {
  description = "Shared burst limit for the summary route."
  type        = number
  default     = 2
  nullable    = false

  validation {
    condition     = var.throttle_burst_limit > 0 && floor(var.throttle_burst_limit) == var.throttle_burst_limit
    error_message = "throttle_burst_limit must be a positive whole number."
  }
}

variable "lambda_handler_source_path" {
  description = "Path to the Python Lambda handler source file."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.lambda_handler_source_path)) > 0
    error_message = "lambda_handler_source_path must not be empty."
  }
}

variable "resume_markdown_source_path" {
  description = "Path to the Markdown resume source file."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.resume_markdown_source_path)) > 0
    error_message = "resume_markdown_source_path must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
