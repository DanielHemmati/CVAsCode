locals {
  delivery_destination_name = "cloudfront-${var.cloudfront_distribution_id}-s3"
  delivery_source_name      = "cloudfront-${var.cloudfront_distribution_id}"
  delivery_source_arn       = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:delivery-source:${local.delivery_source_name}"

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
