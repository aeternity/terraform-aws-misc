locals {
  repositories = toset([
    "aemon",
    "aerepl-web",
    "aesophia_http",
    "mdw-frontend",
    "aepp-base",
    "aepp-base-backend",
    "aepp-contracts",
    "aepp-faucet-nodejs",
    "aepp-hyperchain",
    "aepp-bridge",
    "aepp-graffiti",
    "graffiti-server",
    "aepp-governance",
    "governance-server",
  ])
}

resource "aws_ecrpublic_repository" "repo" {
  for_each        = local.repositories
  repository_name = each.key

  provider = aws.us-east-1
}
