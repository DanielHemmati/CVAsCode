output "api_endpoint" {
  description = "Base URL of the summary HTTP API. This value is null until Phase 5."
  value       = null
}

output "api_id" {
  description = "ID of the summary HTTP API. This value is null until Phase 5."
  value       = null
}

output "summary_route_key" {
  description = "Route key that serves resume summaries."
  value       = local.summary_route_key
}

output "lambda_function_name" {
  description = "Name of the resume summary Lambda function."
  value       = aws_lambda_function.summary.function_name
}

output "lambda_function_arn" {
  description = "ARN of the resume summary Lambda function."
  value       = aws_lambda_function.summary.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.lambda.arn
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "lambda_package_path" {
  description = "Path of the generated Lambda ZIP package."
  value       = data.archive_file.lambda.output_path
}

output "lambda_package_base64sha256" {
  description = "Base64-encoded SHA-256 digest of the Lambda ZIP package."
  value       = data.archive_file.lambda.output_base64sha256
}
