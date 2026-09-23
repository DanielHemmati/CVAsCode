module "github_oidc" {
  source = "../../../modules/globals/github-oidc"

  github_subject = "repo:DanielHemmati@25554446/CVAsCode@1347502526:environment:production"
  role_name      = "github-actions-cvascode"

  # NOTE: Not a good idea for prod env, but i'm the only admin for this project so it's fine
  # for now
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]

  tags = {
    Project     = "CVAsCode"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
