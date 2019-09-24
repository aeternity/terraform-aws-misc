resource "aws_s3_bucket" "aeternity-database-backups" {
  bucket = "aeternity-database-backups"

  acl           = "private"
  force_destroy = false
  region        = "eu-central-1"
}

resource "aws_s3_bucket" "aeternity-node-releases" {
  bucket        = "aeternity-node-releases"
  region        = "eu-central-1"
  acl           = "public-read"
  force_destroy = false
}
