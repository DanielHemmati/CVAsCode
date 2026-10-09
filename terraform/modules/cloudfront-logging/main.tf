locals {
  delivery_destination_name = "cloudfront-${var.cloudfront_distribution_id}-s3"
  delivery_source_name      = "cloudfront-${var.cloudfront_distribution_id}"
  delivery_source_arn       = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:delivery-source:${local.delivery_source_name}"

  record_field_columns = {
    "date"                        = "event_date"
    "time"                        = "event_time"
    "timestamp(ms)"               = "timestamp_ms"
    "x-edge-location"             = "x_edge_location"
    "c-ip"                        = "c_ip"
    "cs-method"                   = "cs_method"
    "cs(Host)"                    = "cs_host"
    "cs-uri-stem"                 = "cs_uri_stem"
    "cs-uri-query"                = "cs_uri_query"
    "sc-status"                   = "sc_status"
    "sc-bytes"                    = "sc_bytes"
    "cs-bytes"                    = "cs_bytes"
    "time-taken"                  = "time_taken"
    "time-to-first-byte"          = "time_to_first_byte"
    "cs(Referer)"                 = "cs_referer"
    "cs(User-Agent)"              = "cs_user_agent"
    "x-edge-result-type"          = "x_edge_result_type"
    "x-edge-response-result-type" = "x_edge_response_result_type"
    "x-edge-detailed-result-type" = "x_edge_detailed_result_type"
    "x-edge-request-id"           = "x_edge_request_id"
    "ssl-protocol"                = "ssl_protocol"
    "ssl-cipher"                  = "ssl_cipher"
    "c-country"                   = "c_country"
    "cache-behavior-path-pattern" = "cache_behavior_path_pattern"
  }

  access_log_bucket_tags = merge(var.tags, {
    Name = var.access_log_bucket_name
  })
}

resource "aws_s3_bucket" "access_logs" {
  bucket        = var.access_log_bucket_name
  force_destroy = true

  tags = local.access_log_bucket_tags
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.access_log_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = data.aws_iam_policy_document.access_logs.json

  depends_on = [aws_s3_bucket_public_access_block.access_logs]
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront_access_logs" {
  name          = local.delivery_destination_name
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = "${aws_s3_bucket.access_logs.arn}/cloudfront"
  }

  tags = var.tags

  depends_on = [aws_s3_bucket_policy.access_logs]
}

resource "aws_cloudwatch_log_delivery_source" "cloudfront_access_logs" {
  name         = local.delivery_source_name
  log_type     = "ACCESS_LOGS"
  resource_arn = var.cloudfront_distribution_arn

  tags = var.tags
}

resource "aws_cloudwatch_log_delivery" "cloudfront_access_logs" {
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront_access_logs.arn
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront_access_logs.name
  record_fields            = var.record_fields

  s3_delivery_configuration = [{
    enable_hive_compatible_path = true
    suffix_path                 = "{distributionid}/{yyyy}/{MM}/{dd}/{HH}"
  }]

  tags = var.tags
}

resource "aws_glue_catalog_database" "cloudfront_access_logs" {
  name = var.glue_database_name

  tags = var.tags
}

resource "aws_glue_catalog_table" "cloudfront_access_logs" {
  name          = var.glue_table_name
  database_name = aws_glue_catalog_database.cloudfront_access_logs.name
  table_type    = "EXTERNAL_TABLE"

  // https://docs.aws.amazon.com/athena/latest/ug/partition-projection-supported-types.html
  parameters = {
    "EXTERNAL"                         = "TRUE" // enable partition projection
    "projection.enabled"               = "true"
    "projection.distributionid.type"   = "enum"
    "projection.distributionid.values" = var.cloudfront_distribution_id
    "projection.year.type"             = "integer"
    "projection.year.range"            = "${var.partition_projection_start_year},${var.partition_projection_end_year}"
    "projection.year.digits"           = "4"
    "projection.month.type"            = "integer"
    "projection.month.range"           = "1,12"
    "projection.month.digits"          = "2"
    "projection.day.type"              = "integer"
    "projection.day.range"             = "1,31"
    "projection.day.digits"            = "2"
    "projection.hour.type"             = "integer"
    "projection.hour.range"            = "0,23"
    "projection.hour.digits"           = "2"
    "storage.location.template"        = "s3://${aws_s3_bucket.access_logs.id}/cloudfront/distributionid=$${distributionid}/year=$${year}/month=$${month}/day=$${day}/hour=$${hour}/"
  }

  partition_keys {
    name = "distributionid"
    type = "string"
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }

  partition_keys {
    name = "hour"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.access_logs.id}/cloudfront/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    dynamic "columns" {
      for_each = var.record_fields

      content {
        name = local.record_field_columns[columns.value]
        type = "string"
      }
    }

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters = {
        for record_field in var.record_fields :
        "mapping.${local.record_field_columns[record_field]}" => record_field
      }
    }
  }
}
