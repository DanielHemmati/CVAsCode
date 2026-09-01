# AWS Organization Terraform Plan

This document defines the Terraform module and local AWS CLI profile strategy for managing the AWS Organization from the management account.

The current target structure is:

```text
Root
├── Shared
├── Sandbox
└── Production
```

The management account owns the organization structure. Member accounts such as Shared, Sandbox, and Production should not manage the AWS Organization root.

## Goals

- Manage AWS Organizations from Terraform.
- Create top-level OUs for shared resources, sandbox, and production.
- Create AWS accounts under those OUs when needed.
- Use stable Terraform addresses so reordering config does not recreate resources.
- Keep account destruction difficult by default.
- Use project-local AWS config profiles for local work.
- Assume roles into member accounts from the management account.
- Avoid storing AWS access keys or secrets in the repository.

## Folder Layout

```text
terraform/
├── organization-plan.md
├── aws-config/
│   └── config
├── modules/
│   └── organization/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── live/
    ├── management/
    │   └── organization/
    │       ├── backend.tf
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── providers.tf
    │       └── versions.tf
    ├── shared/
    ├── sandbox/
    └── production/
```

## Module Implementation

Create the reusable organization module at:

```text
terraform/modules/organization/
```

This module does not create the AWS Organization itself. It assumes the organization already exists and that Terraform is running with management account credentials.

### `terraform/modules/organization/versions.tf`

```hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### `terraform/modules/organization/variables.tf`

```hcl
variable "organizational_units" {
  description = "Top-level OUs to create under the AWS Organizations root. Keys must be stable logical names."
  type = map(object({
    name = string
    tags = optional(map(string), {})
  }))
}

variable "accounts" {
  description = "AWS accounts to create under managed OUs. Keys must be stable logical names."
  type = map(object({
    name                       = string
    email                      = string
    organizational_unit_key    = string
    role_name                  = optional(string, "OrganizationAccountAccessRole")
    iam_user_access_to_billing = optional(string, "DENY")
    tags                       = optional(map(string), {})
  }))

  default = {}
}

variable "tags" {
  description = "Common tags applied to OUs and accounts."
  type        = map(string)
  default     = {}
}
```

### `terraform/modules/organization/main.tf`

```hcl
data "aws_organizations_organization" "current" {}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = local.root_id

  tags = merge(var.tags, each.value.tags)
}

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  parent_id                  = aws_organizations_organizational_unit.this[each.value.organizational_unit_key].id
  role_name                  = each.value.role_name
  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  close_on_deletion          = false

  tags = merge(var.tags, each.value.tags)

  lifecycle {
    prevent_destroy = true
  }
}
```

### `terraform/modules/organization/outputs.tf`

```hcl
output "organizational_unit_ids" {
  description = "OU IDs keyed by logical OU key."
  value = {
    for key, ou in aws_organizations_organizational_unit.this :
    key => ou.id
  }
}

output "organizational_unit_arns" {
  description = "OU ARNs keyed by logical OU key."
  value = {
    for key, ou in aws_organizations_organizational_unit.this :
    key => ou.arn
  }
}

output "account_ids" {
  description = "Account IDs keyed by logical account key."
  value = {
    for key, account in aws_organizations_account.this :
    key => account.id
  }
}

output "account_arns" {
  description = "Account ARNs keyed by logical account key."
  value = {
    for key, account in aws_organizations_account.this :
    key => account.arn
  }
}
```

## Live Management Stack

Create the live stack at:

```text
terraform/live/management/organization/
```

This stack must be run with management account credentials.

### `terraform/live/management/organization/versions.tf`

```hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### `terraform/live/management/organization/providers.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Do not hardcode `profile` in the provider. Use `AWS_PROFILE` from the shell so the same Terraform code works locally and in CI.

### `terraform/live/management/organization/backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket       = "cvascode-terraform-state"
    key          = "management/organization/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The backend bucket must exist before this stack can be initialized. Bootstrap it manually at first or create a separate one-time bootstrap stack.

### `terraform/live/management/organization/main.tf`

```hcl
module "organization" {
  source = "../../../modules/organization"

  tags = {
    Project   = "CVAsCode"
    ManagedBy = "Terraform"
  }

  organizational_units = {
    shared = {
      name = "Shared"
    }

    sandbox = {
      name = "Sandbox"
    }

    production = {
      name = "Production"
    }
  }

  accounts = {
    shared_dns = {
      name                    = "Shared DNS"
      email                   = "REPLACE_WITH_SHARED_DNS_ACCOUNT_EMAIL"
      organizational_unit_key = "shared"
    }

    sandbox = {
      name                    = "Sandbox"
      email                   = "REPLACE_WITH_SANDBOX_ACCOUNT_EMAIL"
      organizational_unit_key = "sandbox"
    }

    production = {
      name                    = "Production"
      email                   = "REPLACE_WITH_PRODUCTION_ACCOUNT_EMAIL"
      organizational_unit_key = "production"
    }
  }
}
```

Use unique email addresses for each AWS account. AWS account email addresses cannot be reused, including emails from closed accounts.

If you only want to create OUs first, set `accounts = {}` or omit the `accounts` argument.

### `terraform/live/management/organization/outputs.tf`

```hcl
output "organizational_unit_ids" {
  description = "OU IDs keyed by logical OU key."
  value       = module.organization.organizational_unit_ids
}

output "account_ids" {
  description = "Account IDs keyed by logical account key."
  value       = module.organization.account_ids
}
```

## Existing OUs and Accounts

The AWS console currently shows an existing `test` OU and several closed accounts.

Do not add the closed accounts to Terraform. Terraform should not manage closed accounts.

For the existing `test` OU, choose one of these options:

1. Leave `test` unmanaged and create new `Shared`, `Sandbox`, and `Production` OUs.
2. Import `test` into Terraform and rename it to `Sandbox` only after reviewing an import plan.

The safer first step is option 1. Importing and renaming can be done later once the base module is working.

## AWS Config Management Plan

Keep a project-local AWS CLI config file at:

```text
terraform/aws-config/config
```

This file may be committed because it contains profile names, SSO settings, role ARNs, regions, and output formats. It must not contain access keys or secrets.

Do not commit a project-local credentials file. If static credentials are temporarily needed, keep them outside the repo in `~/.aws/credentials` or in an ignored local file.

### Project AWS Config File

Create this file:

```text
terraform/aws-config/config
```

Initial contents:

```ini
[default]
region = us-east-1
output = json

[sso-session cvascode]
sso_start_url = REPLACE_WITH_IAM_IDENTITY_CENTER_START_URL
sso_region = us-east-1
sso_registration_scopes = sso:account:access

[profile cvascode-management]
sso_session = cvascode
sso_account_id = REPLACE_WITH_MANAGEMENT_ACCOUNT_ID
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile cvascode-shared]
role_arn = arn:aws:iam::REPLACE_WITH_SHARED_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = cvascode-management
region = us-east-1
output = json

[profile cvascode-sandbox]
role_arn = arn:aws:iam::REPLACE_WITH_SANDBOX_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = cvascode-management
region = us-east-1
output = json

[profile cvascode-production]
role_arn = arn:aws:iam::REPLACE_WITH_PRODUCTION_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = cvascode-management
region = us-east-1
output = json
```

This gives the local machine one management profile and three assume-role profiles.

The flow is:

```text
IAM Identity Center login
└── cvascode-management profile
    ├── assumes role into Shared
    ├── assumes role into Sandbox
    └── assumes role into Production
```

### Using the Project AWS Config File

From the project root:

```bash
export AWS_CONFIG_FILE="$PWD/terraform/aws-config/config"
export AWS_SDK_LOAD_CONFIG=1
```

Then log in to the management account through IAM Identity Center:

```bash
aws sso login --profile cvascode-management
```

Verify the management account identity:

```bash
AWS_PROFILE=cvascode-management aws sts get-caller-identity
```

Verify a member account assume-role profile:

```bash
AWS_PROFILE=cvascode-shared aws sts get-caller-identity
AWS_PROFILE=cvascode-sandbox aws sts get-caller-identity
AWS_PROFILE=cvascode-production aws sts get-caller-identity
```

The returned account ID must match the expected account before running Terraform.

### Terraform Profile Mapping

Use this profile mapping:

```text
terraform/live/management/organization  -> AWS_PROFILE=cvascode-management
terraform/live/shared/*                 -> AWS_PROFILE=cvascode-shared
terraform/live/sandbox/*                -> AWS_PROFILE=cvascode-sandbox
terraform/live/production/*             -> AWS_PROFILE=cvascode-production
```

Example management run:

```bash
export AWS_CONFIG_FILE="$PWD/terraform/aws-config/config"
export AWS_SDK_LOAD_CONFIG=1

cd terraform/live/management/organization
AWS_PROFILE=cvascode-management aws sts get-caller-identity
AWS_PROFILE=cvascode-management terraform init
AWS_PROFILE=cvascode-management terraform plan -out=tfplan
terraform show tfplan
```

Example shared DNS run:

```bash
export AWS_CONFIG_FILE="$PWD/terraform/aws-config/config"
export AWS_SDK_LOAD_CONFIG=1

cd terraform/live/shared/dns
AWS_PROFILE=cvascode-shared aws sts get-caller-identity
AWS_PROFILE=cvascode-shared terraform init
AWS_PROFILE=cvascode-shared terraform plan -out=tfplan
terraform show tfplan
```

## Role Strategy

When `aws_organizations_account` creates a new account, AWS creates the role named by `role_name`. The module defaults to:

```text
OrganizationAccountAccessRole
```

Use this role for initial access to member accounts.

Later, create a dedicated automation role in each member account:

```text
TerraformExecutionRole
```

Long term profile shape:

```ini
[profile cvascode-production]
role_arn = arn:aws:iam::REPLACE_WITH_PRODUCTION_ACCOUNT_ID:role/TerraformExecutionRole
source_profile = cvascode-management
region = us-east-1
output = json
```

The `OrganizationAccountAccessRole` is powerful and useful for bootstrap. The `TerraformExecutionRole` should be scoped down to what each stack needs.

## Validation Plan

Run these from the project root after creating the module and live stack files:

```bash
terraform fmt -check -recursive terraform
```

Run these from `terraform/live/management/organization`:

```bash
export AWS_CONFIG_FILE="$PWD/../../../aws-config/config"
export AWS_SDK_LOAD_CONFIG=1

AWS_PROFILE=cvascode-management aws sts get-caller-identity
AWS_PROFILE=cvascode-management terraform init
AWS_PROFILE=cvascode-management terraform validate
AWS_PROFILE=cvascode-management terraform plan -out=tfplan
terraform show tfplan
```

Security and policy checks from the project root:

```bash
trivy config terraform
tflint --recursive
```

Do not apply until the saved `tfplan` has been reviewed.

## Rollback and Safety Notes

- Keep `prevent_destroy = true` on `aws_organizations_account` resources.
- Keep `close_on_deletion = false` unless the explicit goal is to close accounts.
- Keep the reviewed `tfplan`, apply logs, and state version for evidence.
- Never run `terraform destroy` against this stack without first running `terraform plan -destroy` and reviewing every resource that would be deleted.
- If an OU is created with the wrong name, prefer correcting the name in Terraform and reviewing the plan instead of deleting manually in the console.
- If Terraform state and AWS console drift, stop and reconcile with `terraform import`, `terraform state show`, and a reviewed plan.

## Response Contract

Assumptions and version floor: local runtime is Terraform `v1.15.9`; OpenTofu is not installed. AWS provider is pinned to `~> 5.0` in the examples. The organization already exists, and execution is from the AWS Organizations management account. Real state should use an encrypted S3 backend with native lockfile support. Environment criticality is high because this controls AWS account structure.

Risk category addressed: identity churn, secret exposure, blast radius, CI drift, compliance gaps, state corruption, provider upgrade risk, and testing blind spots.

Chosen remediation and tradeoffs: the module uses map-based `for_each` for stable resource identity and a simple top-level OU model. This is less flexible than a recursive arbitrary-depth OU tree, but it is safer and easier to review for the current Shared, Sandbox, and Production structure. The AWS config plan stores only non-secret profile configuration in the repo and keeps credentials out of version control.

Validation plan: use `terraform fmt -check -recursive terraform`, `terraform validate`, `terraform plan -out=tfplan`, `terraform show tfplan`, `trivy config terraform`, and `tflint --recursive`. Always verify the active AWS account with `aws sts get-caller-identity` before Terraform commands.

Rollback notes: this plan does not perform destructive actions by itself. Future organization applies are state-mutating. Keep plan artifacts and state versions. Do not destroy organization resources without a destroy plan, full review of deleted resources, and explicit approval.
