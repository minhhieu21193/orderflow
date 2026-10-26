output "state_bucket" {
  description = "S3 bucket for Terraform state; passed to the env backends by the Makefile."
  value       = aws_s3_bucket.state.bucket
}

output "region" {
  description = "Region of the state bucket."
  value       = var.region
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider used by the env deploy roles."
  value       = aws_iam_openid_connect_provider.github.arn
}
