# CVAsCode Project Plan

## Goal

Build a Cloud Resume Challenge-inspired project that goes beyond deploying a static `index.html`.

The project should demonstrate production-grade AWS infrastructure, secure identity, automated testing, cost awareness, policy enforcement, and a polished resume/application experience.

## Core Direction

- Deploy a public resume site from static assets.
- Use AWS Organizations and IAM Identity Center as first-class parts of the architecture.
- Manage all infrastructure with Terraform.
- Test and validate Terraform before deployment.
- Keep the design scalable enough to explain how a simple static site could grow to millions of users.
- Add at least one feature beyond the standard resume challenge, such as analytics, visitor history, dynamic profile data, a contact workflow, or an authenticated admin area.

## Implementation Documents

`PLAN.md` defines the high-level objectives and milestones for the project.

The `docs/` directory contains the step-by-step implementation plan for each phase. Name each document with a three-digit sequence number and a short topic, such as `001-cf-logging.md`.

The current implementation document is [`docs/001-cf-logging.md`](docs/001-cf-logging.md).

## Target AWS Architecture

- IAM Identity Center for human access.
- S3 for static site hosting assets.
- CloudFront for CDN, TLS, caching, and global delivery.
- Route 53 for DNS (currently not possible b/c our aws account is fresh)
- Lambda for serverless backend logic.
- API Gateway for public API endpoints.
- DynamoDB for visitor counters, profile metadata, or feature state.
- Use S3, AWS Glue Data Catalog, and Athena for CloudFront access-log analytics.
- Optional: AWS WAF for edge protection.
- Optional: HashiCorp Vault for secrets, if it adds value beyond AWS-native secret storage.

## Terraform Structure

Use a modified `Terraform: Up & Running` inspired structure. Keep deployed infrastructure, reusable modules, runnable examples (not needed until now), and automated tests separate:

```text
terraform/
├── live/
│   ├── global/
│   └── prod/
├── modules/
```

`terraform/live/` contains real deployable root modules. Each leaf directory should be a focused root module with its own state file:

```text
terraform/live/
├── global/
│   ├── github-oidc/
│   ├── plan-artifacts/
│   └── s3-backend/
└── prod/
    └── static-site/
```

`terraform/modules/` contains reusable Terraform modules. Do not put real environment configuration or state-specific backend config here:

```text
terraform/modules/
├── organization/
├── identity-center/
├── static-site/
├── cloudfront-logging/
├── dns/
├── api/
├── database/
├── observability/
├── security-baseline/
└── ci-oidc/
```

Each Terraform root module should usually contain `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, and `backend.tf`. Use small focused live stacks and avoid one large Terraform state for the whole platform.

This project is temporary and will be destroyed with Terraform. Project-owned data buckets, including CloudFront access-log and Athena query-results buckets, should set `force_destroy = true` so their objects do not block teardown. Do not apply this rule to Terraform state buckets unless a separate, reviewed teardown process protects the state needed to destroy the remaining infrastructure.

## Definition of Done

The project is complete when:

- The resume site is publicly available over HTTPS.
- Infrastructure is reproducible from Terraform.
- Automation uses short-lived credentials.
- Terraform checks run automatically.
- Security, cost, and policy checks are part of CI.
- A dynamic feature is deployed and observable.
- The README explains the architecture, tradeoffs, commands, and cost model.
