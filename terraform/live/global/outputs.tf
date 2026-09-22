output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions."
  value       = module.github_oidc.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "IAM role name for GitHub Actions."
  value       = module.github_oidc.github_actions_role_name
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = module.github_oidc.oidc_provider_arn
}

output "trusted_github_subject" {
  description = "GitHub OIDC subject trusted by AWS."
  value       = module.github_oidc.trusted_github_subject
}
