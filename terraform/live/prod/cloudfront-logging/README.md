# Production CloudFront logging

This root module will deploy CloudFront logging and Athena analytics resources in the production AWS account.

Phase 8 adds nine saved Athena queries for common CloudFront access-log reports. Each query reads one projected day by default.

This stack uses the current AWS principal for Athena access. It does not create or change IAM resources.
