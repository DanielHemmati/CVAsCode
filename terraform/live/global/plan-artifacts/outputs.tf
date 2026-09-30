output "plan_bucket_name" {
  description = "Name of the S3 bucket used for private Terraform plans."
  value       = module.plan_artifacts.bucket_name
}

output "plan_bucket_arn" {
  description = "ARN of the S3 bucket used for private Terraform plans."
  value       = module.plan_artifacts.bucket_arn
}

output "plan_bucket_region" {
  description = "AWS region containing the Terraform plan bucket."
  value       = module.plan_artifacts.bucket_region
}
