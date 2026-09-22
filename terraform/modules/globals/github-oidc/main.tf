locals {
  github_oidc_url      = "https://token.actions.githubusercontent.com"
  github_oidc_audience = "sts.amazonaws.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = local.github_oidc_url

  client_id_list = [
    local.github_oidc_audience
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    sid     = "GitHubActionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [local.github_oidc_audience]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_subject] # in this case it should match production
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name        = var.role_name
  description = "Role assumed by Github Actions through OIDC."

  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = merge(var.tags, {
    Name = var.role_name
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
