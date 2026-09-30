locals {
  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket" "plan_artifacts" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_ownership_controls" "plan_artifacts" {
  bucket = aws_s3_bucket.plan_artifacts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "plan_artifacts" {
  bucket = aws_s3_bucket.plan_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "plan_artifacts" {
  bucket = aws_s3_bucket.plan_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "plan_artifacts" {
  bucket = aws_s3_bucket.plan_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "plan_artifacts" {
  bucket = aws_s3_bucket.plan_artifacts.id

  rule {
    id     = "expire-plan-artifacts"
    status = "Enabled"

    // NOTE: apply this lifecycle to every object in the bucket
    filter {}

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.plan_artifacts]
}

data "aws_iam_policy_document" "plan_artifacts" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.plan_artifacts.arn,
      "${aws_s3_bucket.plan_artifacts.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUnapprovedPrincipals"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.plan_artifacts.arn,
      "${aws_s3_bucket.plan_artifacts.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnNotEquals"
      variable = "aws:PrincipalArn"
      values   = sort(tolist(var.allowed_principal_arns))
    }
  }

  statement {
    sid    = "DenyNonConditionalWrites"
    effect = "Deny"

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.plan_artifacts.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Null"
      variable = "s3:if-none-match"
      values   = ["true"]
    }

    condition {
      test     = "Bool"
      variable = "s3:ObjectCreationOperation"
      values   = ["true"]
    }
  }
}

resource "aws_s3_bucket_policy" "plan_artifacts" {
  bucket = aws_s3_bucket.plan_artifacts.id
  policy = data.aws_iam_policy_document.plan_artifacts.json

  depends_on = [aws_s3_bucket_public_access_block.plan_artifacts]
}
