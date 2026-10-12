module "resume_summary" {
  source = "../../../modules/resume-summary"

  api_name             = "cvascode-prod-resume-summary"
  lambda_function_name = "cvascode-prod-resume-summary"
  bedrock_model_id     = "amazon.nova-micro-v1:0"
  cors_allowed_origin  = "https://d2nopx32yk57y6.cloudfront.net"

  throttle_rate_limit  = 1
  throttle_burst_limit = 2

  lambda_handler_source_path  = "${path.root}/../../../../application/resume_summary/handler.py"
  resume_markdown_source_path = "${path.root}/../../../../resume-page/index.md"

  tags = {
    Project     = "CVAsCode"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "DanielHemmati"
  }
}
