resource "aws_s3_bucket" "aeternity-database-backups" {
  bucket = "aeternity-database-backups"

  acl           = "private"
  force_destroy = false
  region        = "eu-central-1"
}
