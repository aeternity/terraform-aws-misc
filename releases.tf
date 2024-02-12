locals {
  releases_fqdn         = "releases.${var.domain}"
  releases_s3_origin_id = "S3-aeternity-node-releases"
}

resource "aws_s3_bucket" "aeternity-node-releases" {
  bucket        = "aeternity-node-releases"
  force_destroy = false

  tags = {
    Name = "aeternity-node-releases"
  }
}

resource "aws_s3_bucket_acl" "aeternity-node-releases" {
  bucket = aws_s3_bucket.aeternity-node-releases.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "aeternity-node-releases" {
  bucket = aws_s3_bucket.aeternity-node-releases.id

  cors_rule {
    allowed_headers = []
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 0
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aeternity-node-releases" {
  bucket = aws_s3_bucket.aeternity-node-releases.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_distribution" "releases" {
  enabled         = true
  aliases         = [local.releases_fqdn]
  is_ipv6_enabled = true
  price_class     = "PriceClass_200"

  origin {
    domain_name = aws_s3_bucket.aeternity-node-releases.bucket_domain_name
    origin_id   = local.releases_s3_origin_id
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
    target_origin_id       = local.releases_s3_origin_id
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
