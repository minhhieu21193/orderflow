# Prod: tasks spread across two AZs on on-demand Fargate, one NAT gateway per
# AZ so losing an AZ does not take outbound traffic down with it.

locals {
  env  = "prod"
  name = "${var.project}-${local.env}"
}

module "kms" {
  source = "../../modules/kms"

  name = local.name
}

module "network" {
  source = "../../modules/network"

  name             = local.name
  cidr             = "10.30.0.0/16"
  nat_gateway_mode = "per_az"
  kms_key_arn      = module.kms.key_arn
}

module "ecr" {
  source = "../../modules/ecr"

  name        = local.name
  kms_key_arn = module.kms.key_arn
}
