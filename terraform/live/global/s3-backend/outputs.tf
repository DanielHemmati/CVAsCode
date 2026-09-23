output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state."
  value       = module.s3_state_backend.bucket_name
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state."
  value       = module.s3_state_backend.bucket_arn
}

output "state_bucket_region" {
  description = "AWS region containing the Terraform state bucket."
  value       = module.s3_state_backend.bucket_region
}
