# Production CloudFront logging

This root module will deploy CloudFront logging and Athena analytics resources in the production AWS account.

Phase 3 sends CloudFront standard logging v2 records to the private S3 bucket. The delivery uses JSON records and Hive-compatible paths.
