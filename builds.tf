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

resource "aws_acm_certificate" "builds" {
  provider          = aws.us-east-1
  domain_name       = local.builds_fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "builds_cert_validation" {
  zone_id = var.zone_id
  name    = aws_acm_certificate.builds.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.builds.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.builds.domain_validation_options.0.resource_record_value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "builds" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.builds.arn
  validation_record_fqdns = [aws_route53_record.builds_cert_validation.fqdn]
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
    acm_certificate_arn      = aws_acm_certificate_validation.builds.certificate_arn
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
