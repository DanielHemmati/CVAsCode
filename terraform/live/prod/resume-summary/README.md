# Production Resume Summary

This root module configures the production resume summary feature in `us-east-1`.

Terraform stores its state at `prod/resume-summary/terraform.tfstate`. The current stack manages the Lambda function, its IAM role, and its log group.

The configured website origin is the current CloudFront domain. Update it when the static-site domain changes.
