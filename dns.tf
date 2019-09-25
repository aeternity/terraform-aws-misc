resource "aws_route53_record" "api_docs" {
  zone_id = var.zone_id
  type    = "CNAME"
  name    = "api-docs.${var.domain}"
  records = ["aeternity.github.io"]
  ttl     = 300
}

resource "aws_route53_record" "docs" {
  zone_id = var.zone_id
  type    = "CNAME"
  name    = "docs.${var.domain}"
  records = ["readthedocs.io"]
  ttl     = 3600
}

resource "aws_route53_record" "install" {
  zone_id = var.zone_id
  type    = "CNAME"
  name    = "install.${var.domain}"
  records = ["aeternity.github.io"]
  ttl     = 300
}
