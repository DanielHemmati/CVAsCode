data "aws_caller_identity" "current" {}

data "terraform_remote_state" "static_site" {
  backend = "s3"

  config = {
    bucket = "cvascode-${data.aws_caller_identity.current.account_id}-terraform-state"
    key    = "prod/static-site/terraform.tfstate"
    region = "us-east-1"
  }
}

module "cloudfront_logging" {
  source = "../../../modules/cloudfront-logging"

  cloudfront_distribution_id  = data.terraform_remote_state.static_site.outputs.cloudfront_distribution_id
  cloudfront_distribution_arn = data.terraform_remote_state.static_site.outputs.cloudfront_distribution_arn

  access_log_bucket_name     = "cvascode-${data.aws_caller_identity.current.account_id}-prod-cloudfront-logs"
  athena_results_bucket_name = "cvascode-${data.aws_caller_identity.current.account_id}-prod-athena-results"
  athena_workgroup_name      = "cvascode-prod-cloudfront"

  access_log_retention_days       = 90
  athena_result_retention_days    = 7
  athena_bytes_scanned_cutoff     = 104857600
  partition_projection_start_year = 2026
  partition_projection_end_year   = 2035

  tags = {
    Project     = "CVAsCode"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "DanielHemmati"
  }
}
