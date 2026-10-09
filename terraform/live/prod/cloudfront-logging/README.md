# Production CloudFront logging

This root module will deploy CloudFront logging and Athena analytics resources in the production AWS account.

Phase 5 adds a private S3 bucket for Athena query results. A lifecycle rule deletes results and incomplete multipart uploads after seven days.
