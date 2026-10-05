locals {
  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  # NOTE: Not good for prod env but i am going to delete this project evntaully
  # So it doesn't matter
  force_destroy = true

  tags = local.tags
}

# INFO: learn more about this
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "website" {
  name = "${var.bucket_name}-security-headers"

  security_headers_config {
    # INFO: this can be way more complicated which is highly depend onf the kind
    # of application you are building
    content_security_policy {
      content_security_policy = join(" ", [
        "default-src 'self';",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;",
        "font-src https://fonts.gstatic.com;",
        "img-src 'self' data:;",
        "connect-src 'self' https://*.execute-api.us-east-1.amazonaws.com;",
        "object-src 'none';",
        "frame-ancestors 'none';",
      ])
      override = true
    }

    # aws s3 sync sets each object's Content-Type; this prevents browsers from guessing a different type.
    content_type_options {
      override = true
    }

    # This adds the HTTP header X-Frame-Options: DENY. It prevents any website from displaying your resume inside an <iframe>,
    # which reduces clickjacking attacks. override = true tells CloudFront to replace the header if S3 already supplies one.
    # It overlaps with frame-ancestors 'none' in the CSP, but supports older browsers that do not understand that CSP rule.
    # Block iframe embedding to reduce clickjacking.
    frame_options {
      frame_option = "DENY"
      override     = true
    }

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Referrer-Policy#strict-origin-when-cross-origin_2
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = false
      preload                    = false
      override                   = true
    }
  }

  # Though not necessary it's just fun to have it :)
  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=()"
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website for ${var.bucket_name}"
  default_root_object = var.default_root_object # index.html
  price_class         = var.price_class

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    target_origin_id           = "s3-${aws_s3_bucket.website.id}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.website.id
    compress                   = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # docs: https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_ViewerCertificate.html#cloudfront-Type-ViewerCertificate-MinimumProtocolVersion:~:text=If,empty
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website.json

  depends_on = [aws_s3_bucket_public_access_block.website]
}
