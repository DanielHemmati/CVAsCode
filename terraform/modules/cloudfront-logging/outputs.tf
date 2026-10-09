output "access_log_bucket_arn" {
  description = "ARN of the S3 bucket that stores CloudFront access logs."
  value       = aws_s3_bucket.access_logs.arn
}

output "access_log_bucket_name" {
  description = "Name of the S3 bucket that stores CloudFront access logs."
  value       = aws_s3_bucket.access_logs.id
}

output "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket that stores Athena query results."
  value       = aws_s3_bucket.athena_results.arn
}

output "athena_results_bucket_name" {
  description = "Name of the S3 bucket that stores Athena query results."
  value       = aws_s3_bucket.athena_results.id
}

output "athena_workgroup_arn" {
  description = "ARN of the Athena workgroup for CloudFront access-log queries."
  value       = aws_athena_workgroup.cloudfront_access_logs.arn
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup for CloudFront access-log queries."
  value       = aws_athena_workgroup.cloudfront_access_logs.name
}

output "glue_database_name" {
  description = "Name of the Glue Data Catalog database for CloudFront access logs."
  value       = aws_glue_catalog_database.cloudfront_access_logs.name
}

output "glue_table_name" {
  description = "Name of the Glue Data Catalog table for CloudFront access logs."
  value       = aws_glue_catalog_table.cloudfront_access_logs.name
}
