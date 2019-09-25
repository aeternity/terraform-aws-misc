locals {
  releases_fqdn         = "releases.${var.domain}"
  releases_s3_origin_id = "S3-aeternity-node-releases"
  ops_releases_fqdn     = "releases.${var.ops_domain}"
}

resource "aws_s3_bucket" "aeternity-node-releases" {
  bucket        = "aeternity-node-releases"
  region        = "eu-central-1"
  acl           = "public-read"
  force_destroy = false
}

resource "aws_acm_certificate" "releases" {
  provider                  = aws.us-east-1
  domain_name               = local.releases_fqdn
  subject_alternative_names = [local.ops_releases_fqdn]
  validation_method         = "DNS"
}

resource "aws_route53_record" "releases_cert_validation" {
  zone_id = var.zone_id
  name    = aws_acm_certificate.releases.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.releases.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.releases.domain_validation_options.0.resource_record_value]
  ttl     = 300
}

resource "aws_route53_record" "ops_releases_cert_validation" {
  zone_id = var.ops_zone_id
  name    = aws_acm_certificate.releases.domain_validation_options.1.resource_record_name
  type    = aws_acm_certificate.releases.domain_validation_options.1.resource_record_type
  records = [aws_acm_certificate.releases.domain_validation_options.1.resource_record_value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "releases" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.releases.arn
  validation_record_fqdns = [
    aws_route53_record.releases_cert_validation.fqdn,
    aws_route53_record.ops_releases_cert_validation.fqdn
  ]
}

resource "aws_cloudfront_distribution" "releases" {
  enabled         = true
  aliases         = [local.releases_fqdn, local.ops_releases_fqdn]
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
    acm_certificate_arn      = aws_acm_certificate_validation.releases.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

resource "aws_route53_record" "releases" {
  zone_id = var.zone_id
  name    = local.releases_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.releases.domain_name
    zone_id                = aws_cloudfront_distribution.releases.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ops_releases" {
  zone_id = var.ops_zone_id
  name    = local.ops_releases_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.releases.domain_name
    zone_id                = aws_cloudfront_distribution.releases.hosted_zone_id
    evaluate_target_health = false
  }
}
