output "ecr_repository_url" {
  description = "ECR repository for the API image."
  value       = module.ecr.repository_url
}

output "url" {
  description = "Public URL of the API."
  value       = module.service.url
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.service.cluster_name
}

output "service_name" {
  description = "ECS service name."
  value       = module.service.service_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard."
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards/dashboard/${module.observability.dashboard_name}"
}

output "github_deploy_role_arn" {
  description = "Set as AWS_DEPLOY_ROLE_ARN for the 'production' GitHub Environment (and the repo variable for staging)."
  value       = module.github_oidc.role_arn
}
