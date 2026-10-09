# cloudfront-logging

This module will deliver CloudFront standard logging v2 records to Amazon S3 and expose them to Athena through the Glue Data Catalog.

Phase 3 connects the CloudFront distribution to the access-log bucket. It uses standard logging v2 with JSON records and Hive-compatible paths.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_delivery.cloudfront_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery) | resource |
| [aws_cloudwatch_log_delivery_destination.cloudfront_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery_destination) | resource |
| [aws_cloudwatch_log_delivery_source.cloudfront_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery_source) | resource |
| [aws_s3_bucket.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_log_bucket_name"></a> [access\_log\_bucket\_name](#input\_access\_log\_bucket\_name) | Globally unique name of the S3 bucket that stores CloudFront access logs. | `string` | n/a | yes |
| <a name="input_access_log_retention_days"></a> [access\_log\_retention\_days](#input\_access\_log\_retention\_days) | Number of days to retain CloudFront access logs. | `number` | `90` | no |
| <a name="input_athena_bytes_scanned_cutoff"></a> [athena\_bytes\_scanned\_cutoff](#input\_athena\_bytes\_scanned\_cutoff) | Maximum number of bytes that one Athena query can scan. | `number` | `104857600` | no |
| <a name="input_athena_result_retention_days"></a> [athena\_result\_retention\_days](#input\_athena\_result\_retention\_days) | Number of days to retain Athena query results. | `number` | `7` | no |
| <a name="input_athena_results_bucket_name"></a> [athena\_results\_bucket\_name](#input\_athena\_results\_bucket\_name) | Globally unique name of the S3 bucket that stores Athena query results. | `string` | n/a | yes |
| <a name="input_athena_workgroup_name"></a> [athena\_workgroup\_name](#input\_athena\_workgroup\_name) | Name of the Athena workgroup for CloudFront analytics. | `string` | n/a | yes |
| <a name="input_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#input\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution that produces access logs. | `string` | n/a | yes |
| <a name="input_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#input\_cloudfront\_distribution\_id) | ID of the CloudFront distribution that produces access logs. | `string` | n/a | yes |
| <a name="input_glue_database_name"></a> [glue\_database\_name](#input\_glue\_database\_name) | Name of the Glue Data Catalog database for CloudFront logs. | `string` | `"cvascode_prod_cloudfront"` | no |
| <a name="input_glue_table_name"></a> [glue\_table\_name](#input\_glue\_table\_name) | Name of the Glue Data Catalog table for CloudFront logs. | `string` | `"cloudfront_access_logs"` | no |
| <a name="input_partition_projection_end_year"></a> [partition\_projection\_end\_year](#input\_partition\_projection\_end\_year) | Last year available to Athena partition projection. | `number` | `2035` | no |
| <a name="input_partition_projection_start_year"></a> [partition\_projection\_start\_year](#input\_partition\_projection\_start\_year) | First year available to Athena partition projection. | `number` | `2026` | no |
| <a name="input_record_fields"></a> [record\_fields](#input\_record\_fields) | CloudFront access-log fields delivered to S3. | `list(string)` | <pre>[<br/>  "date",<br/>  "time",<br/>  "timestamp(ms)",<br/>  "x-edge-location",<br/>  "c-ip",<br/>  "cs-method",<br/>  "cs(Host)",<br/>  "cs-uri-stem",<br/>  "cs-uri-query",<br/>  "sc-status",<br/>  "sc-bytes",<br/>  "cs-bytes",<br/>  "time-taken",<br/>  "time-to-first-byte",<br/>  "cs(Referer)",<br/>  "cs(User-Agent)",<br/>  "x-edge-result-type",<br/>  "x-edge-response-result-type",<br/>  "x-edge-detailed-result-type",<br/>  "x-edge-request-id",<br/>  "ssl-protocol",<br/>  "ssl-cipher",<br/>  "c-country",<br/>  "cache-behavior-path-pattern"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to supported resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_log_bucket_arn"></a> [access\_log\_bucket\_arn](#output\_access\_log\_bucket\_arn) | ARN of the S3 bucket that stores CloudFront access logs. |
| <a name="output_access_log_bucket_name"></a> [access\_log\_bucket\_name](#output\_access\_log\_bucket\_name) | Name of the S3 bucket that stores CloudFront access logs. |
<!-- END_TF_DOCS -->
