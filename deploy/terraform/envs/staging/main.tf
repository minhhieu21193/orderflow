# Staging: as cheap as a working copy of prod can be — one Fargate Spot task,
# a single NAT gateway, and the same modules as prod.

locals {
  env  = "staging"
  name = "${var.project}-${local.env}"
}

module "kms" {
  source = "../../modules/kms"

  name = local.name
}

module "network" {
  source = "../../modules/network"

  name             = local.name
  cidr             = "10.20.0.0/16"
  nat_gateway_mode = "single"
  kms_key_arn      = module.kms.key_arn
}

module "ecr" {
  source = "../../modules/ecr"

  name        = local.name
  kms_key_arn = module.kms.key_arn
}
