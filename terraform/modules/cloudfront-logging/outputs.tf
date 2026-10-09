output "access_log_bucket_arn" {
  description = "ARN of the S3 bucket that stores CloudFront access logs."
  value       = aws_s3_bucket.access_logs.arn
}

output "access_log_bucket_name" {
  description = "Name of the S3 bucket that stores CloudFront access logs."
  value       = aws_s3_bucket.access_logs.id
}
