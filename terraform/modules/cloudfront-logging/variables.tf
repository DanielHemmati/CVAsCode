# tflint-ignore-file: terraform_unused_declarations
# Later phases consume the remaining inputs in this module contract.

variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution that produces access logs."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.cloudfront_distribution_id)) > 0
    error_message = "cloudfront_distribution_id must not be empty."
  }
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution that produces access logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws:cloudfront::[0-9]{12}:distribution/[A-Z0-9]+$", var.cloudfront_distribution_arn))
    error_message = "cloudfront_distribution_arn must be a valid CloudFront distribution ARN."
  }
}

variable "access_log_bucket_name" {
  description = "Globally unique name of the S3 bucket that stores CloudFront access logs."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.access_log_bucket_name) >= 3 && length(var.access_log_bucket_name) <= 63
    error_message = "access_log_bucket_name must contain between 3 and 63 characters."
  }
}

variable "athena_results_bucket_name" {
  description = "Globally unique name of the S3 bucket that stores Athena query results."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.athena_results_bucket_name) >= 3 && length(var.athena_results_bucket_name) <= 63
    error_message = "athena_results_bucket_name must contain between 3 and 63 characters."
  }
}

variable "glue_database_name" {
  description = "Name of the Glue Data Catalog database for CloudFront logs."
  type        = string
  default     = "cvascode_prod_cloudfront"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.glue_database_name))
    error_message = "glue_database_name must contain only lowercase letters, numbers, and underscores."
  }
}

variable "glue_table_name" {
  description = "Name of the Glue Data Catalog table for CloudFront logs."
  type        = string
  default     = "cloudfront_access_logs"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.glue_table_name))
    error_message = "glue_table_name must contain only lowercase letters, numbers, and underscores."
  }
}

variable "athena_workgroup_name" {
  description = "Name of the Athena workgroup for CloudFront analytics."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.athena_workgroup_name)) > 0
    error_message = "athena_workgroup_name must not be empty."
  }
}

variable "access_log_retention_days" {
  description = "Number of days to retain CloudFront access logs."
  type        = number
  default     = 90
  nullable    = false

  validation {
    condition     = var.access_log_retention_days > 0
    error_message = "access_log_retention_days must be greater than zero."
  }
}

variable "athena_result_retention_days" {
  description = "Number of days to retain Athena query results."
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.athena_result_retention_days > 0
    error_message = "athena_result_retention_days must be greater than zero."
  }
}

# athena query do occur cost, in order to control that we can speicify how much
# data atehna can query
variable "athena_bytes_scanned_cutoff" {
  description = "Maximum number of bytes that one Athena query can scan."
  type        = number
  default     = 104857600 # 100 MiB
  nullable    = false

  validation {
    condition     = var.athena_bytes_scanned_cutoff >= 10485760
    error_message = "athena_bytes_scanned_cutoff must be at least 10485760 bytes."
  }
}

variable "partition_projection_start_year" {
  description = "First year available to Athena partition projection."
  type        = number
  default     = 2026
  nullable    = false

  validation {
    condition     = var.partition_projection_start_year >= 2000 && var.partition_projection_start_year <= 9999
    error_message = "partition_projection_start_year must contain four digits."
  }
}

variable "partition_projection_end_year" {
  description = "Last year available to Athena partition projection."
  type        = number
  default     = 2035
  nullable    = false

  validation {
    condition     = var.partition_projection_end_year >= var.partition_projection_start_year && var.partition_projection_end_year <= 9999
    error_message = "partition_projection_end_year must be at least partition_projection_start_year and contain four digits."
  }
}

variable "record_fields" {
  description = "CloudFront access-log fields delivered to S3."
  type        = list(string)
  default = [
    "date",
    "time",
    "timestamp(ms)",
    "x-edge-location",
    "c-ip",
    "cs-method",
    "cs(Host)",
    "cs-uri-stem",
    "cs-uri-query",
    "sc-status",
    "sc-bytes",
    "cs-bytes",
    "time-taken",
    "time-to-first-byte",
    "cs(Referer)",
    "cs(User-Agent)",
    "x-edge-result-type",
    "x-edge-response-result-type",
    "x-edge-detailed-result-type",
    "x-edge-request-id",
    "ssl-protocol",
    "ssl-cipher",
    "c-country",
    "cache-behavior-path-pattern",
  ]
  nullable = false

  validation {
    condition     = length(var.record_fields) > 0 && length(var.record_fields) == length(distinct(var.record_fields))
    error_message = "record_fields must contain at least one field and must not contain duplicates."
  }

  validation {
    condition     = !contains(var.record_fields, "cs(Cookie)")
    error_message = "record_fields must not include cs(Cookie)."
  }

  validation {
    condition = length(setsubtract(toset(var.record_fields), toset([
      "date",
      "time",
      "timestamp(ms)",
      "x-edge-location",
      "c-ip",
      "cs-method",
      "cs(Host)",
      "cs-uri-stem",
      "cs-uri-query",
      "sc-status",
      "sc-bytes",
      "cs-bytes",
      "time-taken",
      "time-to-first-byte",
      "cs(Referer)",
      "cs(User-Agent)",
      "x-edge-result-type",
      "x-edge-response-result-type",
      "x-edge-detailed-result-type",
      "x-edge-request-id",
      "ssl-protocol",
      "ssl-cipher",
      "c-country",
      "cache-behavior-path-pattern",
    ]))) == 0
    error_message = "record_fields must contain only approved CloudFront access-log fields."
  }
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
