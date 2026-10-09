output "access_log_bucket_arn" {
  description = "ARN of the S3 bucket that stores CloudFront access logs."
  value       = module.cloudfront_logging.access_log_bucket_arn
}

output "access_log_bucket_name" {
  description = "Name of the S3 bucket that stores CloudFront access logs."
  value       = module.cloudfront_logging.access_log_bucket_name
}
