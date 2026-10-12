output "api_endpoint" {
  description = "Base URL of the summary HTTP API. This value is null until Phase 5."
  value       = module.resume_summary.api_endpoint
}

output "api_id" {
  description = "ID of the summary HTTP API. This value is null until Phase 5."
  value       = module.resume_summary.api_id
}

output "summary_route_key" {
  description = "Route key that serves resume summaries."
  value       = module.resume_summary.summary_route_key
}

output "lambda_function_name" {
  description = "Name of the resume summary Lambda function."
  value       = module.resume_summary.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the resume summary Lambda function."
  value       = module.resume_summary.lambda_function_arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = module.resume_summary.lambda_execution_role_arn
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group."
  value       = module.resume_summary.lambda_log_group_name
}

output "lambda_package_path" {
  description = "Path of the generated Lambda ZIP package."
  value       = module.resume_summary.lambda_package_path
}

output "lambda_package_base64sha256" {
  description = "Base64-encoded SHA-256 digest of the Lambda ZIP package."
  value       = module.resume_summary.lambda_package_base64sha256
}
