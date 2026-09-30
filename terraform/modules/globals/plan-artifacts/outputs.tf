output "bucket_name" {
  description = "Name of the S3 bucket used for private Terraform plans."
  value       = aws_s3_bucket.plan_artifacts.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket used for private Terraform plans."
  value       = aws_s3_bucket.plan_artifacts.arn
}

output "bucket_region" {
  description = "AWS region containing the Terraform plan bucket."
  value       = aws_s3_bucket.plan_artifacts.region
}
