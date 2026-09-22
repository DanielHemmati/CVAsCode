module "github_oidc" {
  source = "../../modules/globals/github-oidc"

  github_subject = "repo:DanielHemmati@25554446/CVAsCode@1347502526:environment:production"
  role_name      = "github-actions-cvascode"

  # Temporary read-only policy to test policy attachment.
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  tags = {
    Project     = "CVAsCode"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
