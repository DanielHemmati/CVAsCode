resource "aws_athena_workgroup" "cloudfront_access_logs" {
  name          = var.athena_workgroup_name
  description   = "Queries for CloudFront access logs"
  force_destroy = false
  state         = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = var.athena_bytes_scanned_cutoff
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      expected_bucket_owner = data.aws_caller_identity.current.account_id
      output_location       = "s3://${aws_s3_bucket.athena_results.id}/"

      encryption_configuration {
        // though we have specify this in athean-results.tf,
        // it's nice to explicit
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = var.tags
}
