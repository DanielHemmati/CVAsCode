# Resume Summary Module

This module will manage the resume summary API, Lambda function, IAM access, logs, and alarms.

The module creates a local Lambda ZIP package with `handler.py` and `index.md` at its root.

The current module creates the Lambda function, its execution role, a scoped runtime policy, and a 7-day log group. A later phase will add API Gateway.

## Inputs

The caller supplies resource names, the verified Nova Micro ID, the allowed website origin, throttle values, source paths, and tags.

## Outputs

The module exposes Lambda, IAM, log, route, and package values. API values remain null until Phase 5 creates the HTTP API.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | = 1.16.1 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.summary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_name"></a> [api\_name](#input\_api\_name) | Name of the API Gateway HTTP API. | `string` | n/a | yes |
| <a name="input_bedrock_model_id"></a> [bedrock\_model\_id](#input\_bedrock\_model\_id) | Verified Amazon Nova Micro model or inference profile ID. | `string` | n/a | yes |
| <a name="input_cors_allowed_origin"></a> [cors\_allowed\_origin](#input\_cors\_allowed\_origin) | Exact HTTPS website origin allowed to call the HTTP API. | `string` | n/a | yes |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Name of the Lambda function that summarizes the resume. | `string` | n/a | yes |
| <a name="input_lambda_handler_source_path"></a> [lambda\_handler\_source\_path](#input\_lambda\_handler\_source\_path) | Path to the Python Lambda handler source file. | `string` | n/a | yes |
| <a name="input_resume_markdown_source_path"></a> [resume\_markdown\_source\_path](#input\_resume\_markdown\_source\_path) | Path to the Markdown resume source file. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to supported resources. | `map(string)` | `{}` | no |
| <a name="input_throttle_burst_limit"></a> [throttle\_burst\_limit](#input\_throttle\_burst\_limit) | Shared burst limit for the summary route. | `number` | `2` | no |
| <a name="input_throttle_rate_limit"></a> [throttle\_rate\_limit](#input\_throttle\_rate\_limit) | Shared request rate limit for the summary route in requests per second. | `number` | `1` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | Base URL of the summary HTTP API. This value is null until Phase 5. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | ID of the summary HTTP API. This value is null until Phase 5. |
| <a name="output_lambda_execution_role_arn"></a> [lambda\_execution\_role\_arn](#output\_lambda\_execution\_role\_arn) | ARN of the Lambda execution role. |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the resume summary Lambda function. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the resume summary Lambda function. |
| <a name="output_lambda_log_group_name"></a> [lambda\_log\_group\_name](#output\_lambda\_log\_group\_name) | Name of the Lambda CloudWatch log group. |
| <a name="output_lambda_package_base64sha256"></a> [lambda\_package\_base64sha256](#output\_lambda\_package\_base64sha256) | Base64-encoded SHA-256 digest of the Lambda ZIP package. |
| <a name="output_lambda_package_path"></a> [lambda\_package\_path](#output\_lambda\_package\_path) | Path of the generated Lambda ZIP package. |
| <a name="output_summary_route_key"></a> [summary\_route\_key](#output\_summary\_route\_key) | Route key that serves resume summaries. |
<!-- END_TF_DOCS -->