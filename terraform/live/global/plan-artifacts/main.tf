data "aws_caller_identity" "current" {}

module "plan_artifacts" {
  source = "../../../modules/globals/plan-artifacts"

  bucket_name = "cvascode-${data.aws_caller_identity.current.account_id}-terraform-plans"
  allowed_principal_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-cvascode",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/daniel-freelancing-account",
  ]
  retention_days = 5

  tags = {
    Project     = "CVAsCode"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
