# CVAsCode Project Plan

## Goal

Build a Cloud Resume Challenge-inspired project that goes beyond deploying a static `index.html`.

The project should demonstrate production-grade AWS infrastructure, multi-account governance, secure identity, automated testing, cost awareness, policy enforcement, and a polished resume/application experience.

## Core Direction

- Deploy a public resume site from static assets.
- Use AWS Organizations and IAM Identity Center as first-class parts of the architecture.
- Manage all infrastructure with Terraform.
- Test and validate Terraform before deployment.
- Keep the design scalable enough to explain how a simple static site could grow to millions of users.
- Add at least one feature beyond the standard resume challenge, such as analytics, visitor history, dynamic profile data, a contact workflow, or an authenticated admin area.

## Target AWS Architecture

- AWS Organizations for account structure and governance.
- IAM Identity Center for human access.
- Separate AWS accounts for concerns such as:
  - Management account
  - Security/logging account
  - Shared services account
  - Development account
  - Production account
- S3 for static site hosting assets.
- CloudFront for CDN, TLS, caching, and global delivery.
- Route 53 for DNS.
- ACM for certificates.
- Lambda for serverless backend logic.
- API Gateway for public API endpoints.
- DynamoDB for visitor counters, profile metadata, or feature state.
- First using cloudwatch then move to prometheus and Grafana
- Optional: AWS WAF for edge protection.
- Optional: HashiCorp Vault for secrets, if it adds value beyond AWS-native secret storage.

## Terraform Structure

Use a `Terraform: Up & Running` inspired structure. Keep deployed infrastructure, reusable modules, runnable examples, and automated tests separate:

```text
terraform/
├── live/
│   ├── management/
│   ├── security/
│   ├── shared/
│   ├── dev/
│   ├── prod/
│   └── global/
├── modules/
├── examples/
└── test/
```

`terraform/live/` contains real deployable root modules. Each leaf directory should be a focused root module with its own state file:

```text
terraform/live/
├── management/
│   ├── organization/
│   ├── identity-center/
│   └── ci-oidc/
├── security/
│   ├── logging/
│   └── security-baseline/
├── shared/
│   ├── dns/
│   └── observability/
├── dev/
│   ├── services/
│   │   ├── static-site/
│   │   └── api/
│   └── data-stores/
│       └── dynamodb/
├── prod/
│   ├── services/
│   │   ├── static-site/
│   │   └── api/
│   └── data-stores/
│       └── dynamodb/
└── global/
    ├── iam/
    └── s3-state/
```

`terraform/modules/` contains reusable Terraform modules. Do not put real environment configuration or state-specific backend config here:

```text
terraform/modules/
├── organization/
├── identity-center/
├── static-site/
├── dns/
├── api/
├── database/
├── observability/
├── security-baseline/
└── ci-oidc/
```

`terraform/examples/` contains runnable examples that show how to consume modules. Examples belong outside `terraform/modules/`:

```text
terraform/examples/
├── static-site-basic/
├── api-visitor-counter/
├── database-dynamodb/
└── observability-basic/
```

`terraform/test/` contains automated tests for modules and examples, including native Terraform tests and Terratest where useful:

```text
terraform/test/
├── static-site/
├── api/
├── database/
└── terratest/
```

Each Terraform root module should usually contain `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, and `backend.tf`. Use small focused live stacks and avoid one large Terraform state for the whole platform.

## Quality Gates

Every Terraform change should pass:

- `terraform fmt`
- `terraform validate`
- `terraform test`
- `tflint`
- `trivy config`
- `infracost`
- OPA/Rego policy checks, or a better policy-as-code tool if chosen later

Policy checks should cover:

- No public S3 buckets except intentionally configured website/CDN origins.
- CloudFront must use HTTPS.
- DynamoDB should use encryption.
- Logs should have retention configured.
- IAM policies should avoid wildcards where practical.
- Production resources should have cost and ownership tags.
- Terraform state must be remote and encrypted for real environments.

## CI/CD Plan

Use GitHub Actions or another CI system with OIDC into AWS.

Pipeline stages:

1. Format and validate Terraform.
2. Run linting and security scans.
3. Run policy-as-code checks.
4. Estimate cost changes.
5. Run unit/module tests.
6. Generate Terraform plan.
7. Require approval for production apply.
8. Deploy static site assets.
9. Run smoke tests against the deployed URL.
10. Add other steps and tools as needed

Do not store long-lived AWS credentials in the repository.

## Security Plan

- Use IAM Identity Center permission sets for human access.
- Use short-lived credentials for automation.
- Apply least privilege IAM policies.
- Enable centralized logging where possible.
- Keep secrets out of Git.
- For secret management use aws secret manager later we will use vault

## Application Feature Ideas

Choose one or more features beyond a simple resume page:

- Visitor counter with DynamoDB and Lambda.
- Resume analytics dashboard.
- Contact form with spam protection and notification workflow.
- Dynamic project list loaded from an API.
- Deployment metadata endpoint showing commit SHA, environment, and build time.
- Availability/status page for the resume infrastructure.
- Show up time of resume page
- Add more cool feature

## Observability

Add visibility from the beginning:

- CloudFront access logs or standard metrics.
- API Gateway metrics.
- Lambda logs and errors.
- DynamoDB throttling metrics.
- CloudWatch alarms for API errors and Lambda failures.
- Synthetic smoke test for the production URL.
- Basic dashboard for production health.

## Cost Management

- Use Infracost in pull requests.
- Tag resources consistently.
- Prefer serverless and pay-per-use services.
- Set AWS Budgets for non-production and production accounts.
- Document expected monthly cost.
- Avoid NAT Gateways unless there is a clear requirement.

## Milestones

1. Repository baseline
   - Finalize folder structure.
   - Add tooling docs.
   - Add local development commands.

2. Terraform foundation
   - Configure providers.
   - Add remote state approach.
   - Add naming and tagging conventions.

3. AWS organization and identity
   - Define account layout.
   - Configure IAM Identity Center.
   - Define permission sets.
   - Add initial guardrails.

4. Static resume delivery
   - Build S3, CloudFront, Route 53, and ACM modules.
   - Deploy `index.html`.
   - Add cache and TLS configuration.

5. Backend feature
   - Add API Gateway, Lambda, and DynamoDB.
   - Wire frontend to the API.
   - Add tests and observability.

6. Testing and policy
   - Add TFLint.
   - Add Trivy.
   - Add Infracost.
   - Add OPA/Rego or selected alternative.
   - Add Terraform tests and Terratest where useful.

7. CI/CD
   - Add pull request checks.
   - Add plan workflow.
   - Add deployment workflow.
   - Add production approval gate.

8. Production readiness
   - Add alarms.
   - Add cost budgets.
   - Add security documentation.
   - Add architecture diagram.
   - Add final README walkthrough.

## Definition of Done

The project is complete when:

- The resume site is publicly available over HTTPS.
- Infrastructure is reproducible from Terraform.
- Human AWS access uses IAM Identity Center.
- Automation uses short-lived credentials.
- Terraform checks run automatically.
- Security, cost, and policy checks are part of CI.
- A dynamic feature is deployed and observable.
- The README explains the architecture, tradeoffs, commands, and cost model.
