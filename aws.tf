terraform {
  backend "s3" {
    bucket         = "aeternity-terraform-states"
    key            = "ae-misc.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  version = "2.19.0"
  region  = "eu-central-1"
  alias   = "eu-central-1"
}
