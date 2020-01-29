locals {
  builds_fqdn         = "builds.${var.domain}"
  builds_s3_origin_id = "S3-aeternity-node-builds"
}

resource "aws_s3_bucket" "aeternity-node-builds" {
  bucket = "aeternity-node-builds"

  acl           = "public-read"
  force_destroy = false

  lifecycle_rule {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 2

    expiration {
      days = 30
    }
  }
}

resource "aws_cloudfront_distribution" "builds" {
  enabled         = true
  aliases         = [local.builds_fqdn]
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.aeternity-node-builds.bucket_domain_name
    origin_id   = local.builds_s3_origin_id
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = local.builds_s3_origin_id
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

resource "aws_route53_record" "builds" {
  zone_id = var.zone_id
  name    = local.builds_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.builds.domain_name
    zone_id                = aws_cloudfront_distribution.builds.hosted_zone_id
    evaluate_target_health = false
  }
}
