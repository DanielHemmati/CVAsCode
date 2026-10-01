data "aws_caller_identity" "current" {}

module "static_site" {
  source = "../../../modules/static-site"

  bucket_name = "cvascode-${data.aws_caller_identity.current.account_id}-prod-static-site"

  tags = {
    Project     = "CVAsCode"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "DanielHemmati"
  }
}
