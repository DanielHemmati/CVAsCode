output "access_log_bucket_arn" {
  description = "ARN of the S3 bucket that stores CloudFront access logs."
  value       = module.cloudfront_logging.access_log_bucket_arn
}

output "access_log_bucket_name" {
  description = "Name of the S3 bucket that stores CloudFront access logs."
  value       = module.cloudfront_logging.access_log_bucket_name
}

output "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket that stores Athena query results."
  value       = module.cloudfront_logging.athena_results_bucket_arn
}

output "athena_results_bucket_name" {
  description = "Name of the S3 bucket that stores Athena query results."
  value       = module.cloudfront_logging.athena_results_bucket_name
}

output "glue_database_name" {
  description = "Name of the Glue Data Catalog database for CloudFront access logs."
  value       = module.cloudfront_logging.glue_database_name
}

output "glue_table_name" {
  description = "Name of the Glue Data Catalog table for CloudFront access logs."
  value       = module.cloudfront_logging.glue_table_name
}
