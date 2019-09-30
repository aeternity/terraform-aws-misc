locals {
  snapshots_fqdn         = "snapshots.${var.domain}"
  snapshots_s3_origin_id = "S3-aeternity-node-snapshots"
}

resource "aws_s3_bucket" "aeternity-node-snapshots" {
  bucket        = "aeternity-database-backups"
  region        = "eu-central-1"
  acl           = "public-read"
  force_destroy = false

  lifecycle_rule {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 2

    expiration {
      days = 60
    }
  }
}

resource "aws_acm_certificate" "snapshots" {
  provider          = aws.us-east-1
  domain_name       = local.snapshots_fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "snapshots_cert_validation" {
  zone_id = var.zone_id
  name    = aws_acm_certificate.snapshots.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.snapshots.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.snapshots.domain_validation_options.0.resource_record_value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "snapshots" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.snapshots.arn
  validation_record_fqdns = [aws_route53_record.snapshots_cert_validation.fqdn]
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
    acm_certificate_arn      = aws_acm_certificate_validation.snapshots.certificate_arn
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