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

module "observability" {
  source = "../../modules/observability"

  name                    = local.name
  kms_key_arn             = module.kms.key_arn
  alarm_email             = var.alert_email
  cluster_name            = module.service.cluster_name
  service_name            = module.service.service_name
  alb_arn_suffix          = module.service.alb_arn_suffix
  target_group_arn_suffix = module.service.target_group_arn_suffix
  min_running_tasks       = 1
}

module "service" {
  source = "../../modules/ecs-service"

  name               = local.name
  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  image              = "${module.ecr.repository_url}:${var.image_tag}"
  log_group_name     = module.observability.log_group_name
  certificate_arn    = var.certificate_arn

  capacity_provider = "FARGATE_SPOT"
  desired_count     = 1
  min_capacity      = 1
  max_capacity      = 2
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  role_name          = "${local.name}-github-deploy"
  github_repository  = var.github_repository
  github_environment = "staging"
  ecr_repository_arn = module.ecr.repository_arn
  kms_key_arn        = module.kms.key_arn
  ecs_service_arn    = module.service.service_arn
  pass_role_arns     = [module.service.execution_role_arn, module.service.task_role_arn]
}

module "budget" {
  source = "../../modules/budget"

  name              = "${local.name}-monthly"
  monthly_limit_usd = var.monthly_budget_usd
  alert_emails      = [var.alert_email]
}
