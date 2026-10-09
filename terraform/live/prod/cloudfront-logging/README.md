# Production CloudFront logging

This root module will deploy CloudFront logging and Athena analytics resources in the production AWS account.

Phase 6 adds an Athena workgroup with enforced query settings. The workgroup writes encrypted results to the dedicated results bucket and limits each query to 100 MiB.
