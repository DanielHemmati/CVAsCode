# CloudFront Logging and Athena Plan

## Goal

Send CloudFront standard logging v2 records to Amazon S3 in JSON format. Query the records with Athena through an explicit Glue Data Catalog table and partition projection.

CloudFront access records must not enter CloudWatch Logs. This plan does not use a Glue crawler.

## Fixed Design

- Terraform `1.16.1` and AWS provider `~> 6.0`.
- One state at `prod/cloudfront-logging/terraform.tfstate`.
- One reusable module at `terraform/modules/cloudfront-logging`.
- One production root at `terraform/live/prod/cloudfront-logging`.
- Static-site remote state supplies the CloudFront distribution ID and ARN.
- JSON logs with Hive-compatible paths.
- Explicit Glue table schema with Athena partition projection.
- Access-log retention of 90 days.
- Athena-result retention of 7 days.
- SSE-S3 encryption and no bucket versioning.
- Athena scan cutoff of 100 MiB for each query.
- No Athena CloudWatch metrics.
- No cookies in the selected fields.
- Use the current AWS caller for Athena access. Do not create an analyst IAM identity.
- No native Terraform tests for this lab.
- Automatic CI apply after a successful saved plan.

AWS uses the CloudWatch Logs delivery API as the control plane. The Terraform resources named `aws_cloudwatch_log_delivery_*` send records to S3 and do not create a CloudWatch log group.

## Delivery Contract

Use this destination ARN:

```text
arn:aws:s3:::<access-log-bucket>/cloudfront
```

Use this suffix path with Hive-compatible paths enabled:

```text
{distributionid}/{yyyy}/{MM}/{dd}/{HH}
```

The resulting object path must have this form:

```text
s3://<access-log-bucket>/cloudfront/distributionid=<distribution-id>/year=2026/month=10/day=08/hour=14/<log-file>
```

Do not repeat `cloudfront` in the suffix. A bare bucket destination can add the default `AWSLogs/<account-id>/CloudFront` prefix.

## Phase Rules

Implement only one phase at a time.

For each phase:

1. Make only the listed changes.
2. Run the shared validation commands.
3. Create a saved plan when the phase adds resources.
4. Show the code diff and plan to the project owner.
5. Wait for approval before starting the next phase.

Review each phase before it reaches `main`. CI applies a successful saved plan automatically on `main`.

## Phase 1: Module Scaffold ✅

Create these directories:

```text
terraform/modules/cloudfront-logging/
terraform/live/prod/cloudfront-logging/
```

Add the standard module files, production root files, README files, and lock files. Configure:

- The S3 backend key `prod/cloudfront-logging/terraform.tfstate`.
- The AWS provider in `us-east-1`.
- The static-site remote-state data source.
- Reads of only `cloudfront_distribution_id` and `cloudfront_distribution_arn`.
- Module variables for names, retention, scan cutoff, projection years, fields, and tags.
- Production names and the standard production tags.

Do not create managed AWS resources.

Review gate:

- Both directories initialize and validate.
- The plan contains no managed resources.
- No secret, distribution ID, or principal ARN enters the repository.
- The backend reuses the account-qualified state-bucket name already used by existing production stacks.
- The static-site state and distribution do not change.

## Phase 2: Access-Log Bucket

Create only the access-log bucket and its controls:

- Full S3 Block Public Access.
- `BucketOwnerEnforced` ownership.
- SSE-S3 encryption.
- `force_destroy = true`.
- No versioning.
- Object expiry after 90 days.
- Incomplete multipart upload expiry after 7 days.
- A deny statement for requests without TLS.
- A write statement for `delivery.logs.amazonaws.com` under `cloudfront/*`.
- Source-account and deterministic delivery-source ARN conditions.
- Narrow Trivy exceptions for SSE-S3 and omitted S3 access logging.

Do not grant access to the website, state, plan-artifact, or query-results buckets.

Review gate:

- The saved plan contains only this bucket and its controls.
- The bucket is private and encrypted.
- The delivery principal can write only to `cloudfront/*`.

## Phase 3: CloudFront Log Delivery

Before planning, run the read-only delivery-source check. Stop if the distribution already has a source.

Create these resources as one working connection:

- `aws_cloudwatch_log_delivery_destination`
- `aws_cloudwatch_log_delivery_source`
- `aws_cloudwatch_log_delivery`

Configure:

- The prefixed S3 destination ARN from the delivery contract.
- JSON output.
- The existing distribution ARN.
- Log type `ACCESS_LOGS`.
- Hive-compatible paths.
- The suffix from the delivery contract.
- The approved fields below.

```text
date
time
timestamp(ms)
x-edge-location
c-ip
cs-method
cs(Host)
cs-uri-stem
cs-uri-query
sc-status
sc-bytes
cs-bytes
time-taken
time-to-first-byte
cs(Referer)
cs(User-Agent)
x-edge-result-type
x-edge-response-result-type
x-edge-detailed-result-type
x-edge-request-id
ssl-protocol
ssl-cipher
c-country
cache-behavior-path-pattern
```

Do not include `cs(Cookie)`.

Review gate:

- The plan does not update or replace the CloudFront distribution.
- No CloudWatch log group exists.
- The path contains one `cloudfront` prefix.
- Only the approved fields are selected.

After apply, generate website requests. CloudFront can take up to 12 hours to deliver the first object.

Phase 3 is complete when one JSON object appears under the expected Hive path.

## Phase 4: Glue Table and Partition Projection

Create only:

- Glue database `cvascode_prod_cloudfront`.
- External table `cloudfront_access_logs`.
- OpenX JSON SerDe mappings.
- Partition-projection properties.

Use these storage settings:

```text
location      = s3://<access-log-bucket>/cloudfront/
serde         = org.openx.data.jsonserde.JsonSerDe
input_format  = org.apache.hadoop.mapred.TextInputFormat
output_format = org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat
```

Map the CloudFront JSON fields to these SQL-safe string columns:

| Athena column | JSON field |
| --- | --- |
| `event_date` | `date` |
| `event_time` | `time` |
| `timestamp_ms` | `timestamp(ms)` |
| `x_edge_location` | `x-edge-location` |
| `c_ip` | `c-ip` |
| `cs_method` | `cs-method` |
| `cs_host` | `cs(Host)` |
| `cs_uri_stem` | `cs-uri-stem` |
| `cs_uri_query` | `cs-uri-query` |
| `sc_status` | `sc-status` |
| `sc_bytes` | `sc-bytes` |
| `cs_bytes` | `cs-bytes` |
| `time_taken` | `time-taken` |
| `time_to_first_byte` | `time-to-first-byte` |
| `cs_referer` | `cs(Referer)` |
| `cs_user_agent` | `cs(User-Agent)` |
| `x_edge_result_type` | `x-edge-result-type` |
| `x_edge_response_result_type` | `x-edge-response-result-type` |
| `x_edge_detailed_result_type` | `x-edge-detailed-result-type` |
| `x_edge_request_id` | `x-edge-request-id` |
| `ssl_protocol` | `ssl-protocol` |
| `ssl_cipher` | `ssl-cipher` |
| `c_country` | `c-country` |
| `cache_behavior_path_pattern` | `cache-behavior-path-pattern` |

Keep every data column as `string`. CloudFront can use `-` for unavailable values. Queries must use `TRY_CAST` for numeric operations.

Define these partition columns as strings:

- `distributionid`
- `year`
- `month`
- `day`
- `hour`

Use these table properties:

```text
projection.enabled               = true
projection.distributionid.type   = enum
projection.distributionid.values = <cloudfront-distribution-id>
projection.year.type             = integer
projection.year.range            = 2026,2035
projection.year.digits           = 4
projection.month.type            = integer
projection.month.range           = 1,12
projection.month.digits          = 2
projection.day.type              = integer
projection.day.range             = 1,31
projection.day.digits            = 2
projection.hour.type             = integer
projection.hour.range            = 0,23
projection.hour.digits           = 2
storage.location.template        = s3://<access-log-bucket>/cloudfront/distributionid=${distributionid}/year=${year}/month=${month}/day=${day}/hour=${hour}/
```

Do not create a crawler, stored Glue partitions, or an `MSCK REPAIR TABLE` step.

Review gate:

- The saved plan contains only the Glue database and table.
- Every selected delivery field has one SerDe mapping.
- The projection template matches the S3 delivery path.

## Phase 5: Athena Results Bucket

Create only the Athena-results bucket and its controls:

- Full S3 Block Public Access.
- `BucketOwnerEnforced` ownership.
- SSE-S3 encryption.
- `force_destroy = true`.
- No versioning.
- Object expiry after 7 days.
- Incomplete multipart upload expiry after 7 days.
- A deny statement for requests without TLS.
- Narrow Trivy exceptions for SSE-S3 and omitted S3 access logging.

Review gate:

- The saved plan contains only this bucket and its controls.
- The bucket is private and separate from the log path.
- The bucket has no CloudFront delivery permissions.

## Phase 6: Athena Workgroup

Create only the Athena workgroup. Configure:

- The dedicated query-results S3 location.
- The expected bucket owner from the caller identity.
- Enforced workgroup settings.
- SSE-S3 result encryption.
- Disabled CloudWatch metrics.
- A scan cutoff of `104857600` bytes.
- Safe workgroup teardown behavior.

Review gate:

- The saved plan contains only the workgroup.
- The result location is not shared or default.
- No named queries exist yet.

## Phase 7: Current Principal Access

Use the existing AWS principal returned by `data.aws_caller_identity.current`. Do not create an IAM user, role, group, policy, or policy attachment.

The current principal must already have permission to:

- Use the selected Athena workgroup.
- Read the selected Glue database and table.
- Read objects under the CloudFront log prefix.
- Read and write objects in the Athena-results bucket.

This stack must not grant:

- Write access to CloudFront source logs.
- Glue partition write access.
- Access to website, state, or plan-artifact buckets.
- Wildcard access to unrelated workgroups, tables, or buckets.

Review gate:

- The plan contains no IAM changes.
- The repository contains no principal ARN.
- The current principal can use the workgroup and query the table.

## Phase 8: Named Queries and Verification

Create named queries for:

- Requests by day.
- Most requested paths.
- HTTP 4xx and 5xx responses.
- Cache-hit and cache-miss rates.
- Requests by country.
- Average and percentile response time.
- Top referrers.
- Top user agents.
- Requests for missing files.

Every query must filter `distributionid`, `year`, `month`, and `day`. Add `hour` when useful. Use `TRY_CAST` for status codes, byte counts, timestamps, and timing values.

Review gate:

- No query scans all retained data by default.
- The saved plan contains only named queries.
- All queries use SQL-safe column names.

After apply:

1. Run each query for one projected day.
2. Make sure that Athena reads the expected objects.
3. Make sure that results enter only the results bucket.
4. Make sure that the 100 MiB cutoff is active.
5. Make sure that this stack did not add IAM access to unrelated resources.
6. Record the results in the module README.

## Shared Validation

Run these commands in every phase:

```bash
terraform fmt -check -recursive -diff terraform/modules
terraform fmt -check -recursive -diff terraform/live
terraform -chdir=terraform/modules/cloudfront-logging init -backend=false -input=false -lockfile=readonly
terraform -chdir=terraform/modules/cloudfront-logging validate
terraform -chdir=terraform/live/prod/cloudfront-logging init -input=false -lockfile=readonly
terraform -chdir=terraform/live/prod/cloudfront-logging validate
tflint --config=.tflint.hcl --init
tflint --chdir=terraform/modules --recursive --config="$(pwd)/.tflint.hcl"
tflint --chdir=terraform/live --recursive --config="$(pwd)/.tflint.hcl"
trivy config terraform/modules
trivy config terraform/live
```

## Final Verification

- CloudFront standard logging v2 sends JSON to S3.
- No CloudWatch log group or Glue crawler exists.
- The object path matches the delivery contract.
- Both buckets are private, encrypted, and use the approved retention.
- Athena can query a new hour without a catalog partition update.
- Athena writes only to the results bucket.
- The current AWS principal can query the logs without a new IAM identity.
- Cookies are absent from the selected fields.
- No plan updates, replaces, or destroys the CloudFront distribution.

## Rollback

To stop new logs, remove only `aws_cloudwatch_log_delivery` in a saved plan. Keep the source, destination, data, and catalog during investigation.

For full removal, use this order:

1. Named queries.
2. Athena workgroup.
3. Glue table and database.
4. Delivery connection.
5. Delivery source and destination.
6. Results bucket and access-log bucket.

Create and inspect a destroy plan before full removal. Remove the logging stack before the static-site stack because it reads static-site remote state.

## References

- [CloudFront standard logging v2](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logging.html)
- [CloudFront standard log fields](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logs-reference.html)
- [Athena partition projection](https://docs.aws.amazon.com/athena/latest/ug/partition-projection.html)
- [OpenX JSON SerDe](https://docs.aws.amazon.com/athena/latest/ug/openx-json-serde.html)
