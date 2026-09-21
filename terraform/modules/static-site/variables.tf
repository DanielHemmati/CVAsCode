variable "bucket_name" {
  description = "Globally unique name for private website S3 bucket"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must contain between 3 and 63 characters."
  }
}

variable "default_root_object" {
  description = "Object CloudFront returns for request to th root path."
  type        = string
  default     = "index.html"
  nullable    = false
}

# docs: https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_DistributionConfig.html#cloudfront-Type-DistributionConfig-PriceClass
variable "price_class" {
  description = "CloudFront edge-location price class."
  type        = string
  default     = "PriceClass_100" # it's the least expensive
  nullable    = false

  validation {
    condition = contains([
      "PriceClass_100",
      "PriceClass_200",
      "PriceClass_All",
    ], var.price_class)

    error_message = "price_class must be PriceClass_100, PriceClass_200, PriceClass_All"
  }
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
