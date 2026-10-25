output "ecr_repository_url" {
  description = "ECR repository for the API image."
  value       = module.ecr.repository_url
}
