locals {
  lambda_execution_role_name = substr("${var.lambda_function_name}-execution", 0, 64)
  summary_route_key          = "GET /summary"

  bedrock_model_resources = startswith(var.bedrock_model_id, "us.") ? [
    "arn:${data.aws_partition.current.partition}:bedrock:*::foundation-model/${trimprefix(var.bedrock_model_id, "us.")}",
    "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.bedrock_model_id}",
    ] : [
    "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}::foundation-model/${var.bedrock_model_id}",
  ]
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.root}/build/resume-summary.zip" # terraform/live/prod/resume-summary/build/resume-summary.zip

  source {
    content  = file(var.lambda_handler_source_path)
    filename = "handler.py"
  }

  source {
    content  = file(var.resume_markdown_source_path)
    filename = "index.md"
  }
}
