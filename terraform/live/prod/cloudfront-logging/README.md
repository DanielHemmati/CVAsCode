# Production CloudFront logging

This root module will deploy CloudFront logging and Athena analytics resources in the production AWS account.

Phase 4 catalogs the JSON records in Glue. Athena uses partition projection to read the Hive-compatible paths without stored partitions or a Glue crawler.
