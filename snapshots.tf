locals {
  snapshots_fqdn         = "snapshots.${var.domain}"
  snapshots_s3_origin_id = "S3-aeternity-node-snapshots"
}

resource "aws_s3_bucket" "aeternity-node-snapshots" {
  bucket        = "aeternity-database-backups"
  force_destroy = false

  tags = {
    Name = "aeternity-database-backups"
  }
}

resource "aws_s3_bucket_acl" "aeternity-node-snapshots" {
  bucket = aws_s3_bucket.aeternity-node-snapshots.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "aeternity-node-snapshots" {
  bucket = aws_s3_bucket.aeternity-node-snapshots.id

  cors_rule {
    allowed_headers = []
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 0
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aeternity-node-snapshots" {
  bucket = aws_s3_bucket.aeternity-node-snapshots.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "aeternity-node-snapshots" {
  bucket = aws_s3_bucket.aeternity-node-snapshots.id

  rule {
    id     = "rule-1"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 2
    }

    expiration {
      days = 60
    }
  }
}

resource "aws_cloudfront_distribution" "snapshots" {
  enabled         = true
  aliases         = [local.snapshots_fqdn]
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.aeternity-node-snapshots.bucket_domain_name
    origin_id   = local.snapshots_s3_origin_id
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      headers = [
        "Accept-Encoding",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "Origin",
      ]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = local.snapshots_s3_origin_id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cert_arn_wildcard_services
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

resource "aws_route53_record" "snapshots" {
  zone_id = var.zone_id
  name    = local.snapshots_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.snapshots.domain_name
    zone_id                = aws_cloudfront_distribution.snapshots.hosted_zone_id
    evaluate_target_health = false
  }
}
