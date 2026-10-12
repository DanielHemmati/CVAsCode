resource "aws_iam_role" "lambda" {
  name               = local.lambda_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.tags, {
    Name = local.lambda_execution_role_name
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.lambda_function_name}-logs"
  })
}

resource "aws_iam_role_policy" "lambda_runtime" {
  name   = "${var.lambda_function_name}-runtime"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_runtime.json
}

resource "aws_lambda_function" "summary" {
  architectures = ["arm64"]
  filename      = data.archive_file.lambda.output_path
  function_name = var.lambda_function_name
  handler       = "handler.lambda_handler"
  memory_size   = 512
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.13"

  reserved_concurrent_executions = 2
  source_code_hash               = data.archive_file.lambda.output_base64sha256
  timeout                        = 25

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.lambda.name
    system_log_level      = "WARN"
  }

  tags = merge(var.tags, {
    Name = var.lambda_function_name
  })

  depends_on = [aws_iam_role_policy.lambda_runtime]
}
