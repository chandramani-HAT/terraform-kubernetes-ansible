resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name           = var.vpc_name,
    Environment    = var.environment,
    Owner          = var.owner,
    Project        = var.project,
    Classification = var.classification
  })
}
