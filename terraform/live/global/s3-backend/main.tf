data "aws_caller_identity" "current" {}

module "s3_state_backend" {
  source = "../../../modules/globals/s3-backend"

  bucket_name = "cvascode-${data.aws_caller_identity.current.account_id}-terraform-state"

  tags = {
    Project     = "CVAsCode"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
