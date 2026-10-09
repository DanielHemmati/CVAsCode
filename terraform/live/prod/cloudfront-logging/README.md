# Production CloudFront logging

This root module will deploy CloudFront logging and Athena analytics resources in the production AWS account.

Phase 2 creates the private and encrypted S3 bucket for CloudFront access logs. The bucket deletes logs after 90 days.
